import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/config.dart';
import '../../core/sources.dart';
import '../../core/tokens.dart';
import '../../data/models.dart';
import '../../data/native_bridge.dart';
import '../../data/web_store.dart';
import '../../widgets/ui.dart';
import '../result/result_sheet.dart';
import '../settings/settings_screen.dart';
import '../source/source_screen.dart';
import '../status/status_screen.dart';
import 'tab_switcher.dart';
import 'tabs_controller.dart';

/// The "Tab" tab: orange search bar on top, then either the start page or a live website.
class TabPage extends StatefulWidget {
  const TabPage({super.key});
  @override
  State<TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<TabPage> {
  final _search = TextEditingController();
  final _focus = FocusNode();
  bool _resolving = false;

  TabsController get tabs => context.read<TabsController>();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus) {
        _search.selection = TextSelection(baseOffset: 0, extentOffset: _search.text.length);
      } else {
        _syncField();
      }
      setState(() {});
    });
    final t = context.read<TabsController>();
    t.incoming.addListener(_onIncoming);
    t.addListener(_syncField);
  }

  void _onIncoming() {
    final text = tabs.incoming.value;
    if (text == null) return;
    tabs.incoming.value = null;
    _go(text);
  }

  void _syncField() {
    if (_focus.hasFocus) return;
    final u = tabs.current.url ?? '';
    if (_search.text != u) _search.text = u;
  }

  static final _igCode = RegExp(r'instagram\.com/(?:[A-Za-z0-9._]+/)?(?:p|reels?|tv)/([A-Za-z0-9_-]{5,})');
  static final _igStory = RegExp(r'instagram\.com/stories/[^/]+/(\d+)');
  Timer? _pendingTimer;

  /// Search bar logic: a downloadable link downloads straight away, anything else is browsed or searched.
  Future<void> _go(String raw) async {
    _focus.unfocus();
    final text = raw.trim();
    if (text.isEmpty) return;
    final link = LinkParser.extract(text) ?? text;
    final isUsername = RegExp(r'^@[A-Za-z0-9._]{1,30}$').hasMatch(text);
    final url = LinkParser.normalize(isUsername ? text : link);
    if (isUsername || Source.isItem(url)) {
      final code = _igCode.firstMatch(url)?.group(1);
      if (code != null) {
        _openAndCapture(url, code); // Instagram: open it in the browser and grab it from the page
      } else {
        await _download(url);
      }
      return;
    }
    tabs.current.load(webAddress(text));
  }

  /// Opens an Instagram post/reel in the browser, then pops the download sheet as soon as the page has it.
  void _openAndCapture(String url, String code) {
    final tab = tabs.current;
    tab.pendingCode = code;
    final ig = code != '*';
    tab.load(!ig ? url : (url.contains('/p/') ? 'https://www.instagram.com/p/$code/' : 'https://www.instagram.com/reels/$code/'));
    setState(() => _resolving = true);
    final started = DateTime.now();
    _pendingTimer?.cancel();
    _pendingTimer = Timer.periodic(const Duration(milliseconds: 500), (t) async {
      if (!mounted || tab.pendingCode != code) {
        t.cancel();
        return;
      }
      final ready = ig ? tab.codes.contains(code) : tab.mediaSrc != null;
      final waited = DateTime.now().difference(started) > Duration(seconds: ig ? 15 : 20);
      if (ready || waited) {
        t.cancel();
        tab.pendingCode = null;
        setState(() => _resolving = false);
        if (ig) {
          await _download(url, retried: true); // page capture first, then the engine
        } else {
          await _fromPlayer(url);
        }
      }
    });
  }

  Future<void> _download(String url, {bool retried = false}) async {
    if (_resolving && !retried) return;
    final src = Source.detect(url);
    if (src == Source.youtube && !Config.youtubeEnabled) {
      toast(context, 'YouTube saving isn’t available in this version.', error: true);
      return;
    }
    final bridge = context.read<NativeBridge>();
    final tab = tabs.current;
    HapticFeedback.mediumImpact();
    setState(() => _resolving = true);
    try {
      MediaInfo? info;
      final key = _igCode.firstMatch(url)?.group(1) ?? _igStory.firstMatch(url)?.group(1);
      if (key != null && !tab.isStart) {
        final payload = await tab.captured(key);
        if (payload != null) info = await bridge.fromPage(payload, url);
      }
      if (info == null && key != null && src == Source.instagram && !retried && !url.contains('/stories/')) {
        _openAndCapture(url, key); // not loaded yet: open it via the route that plays logged-out
        return;
      }
      if (info == null) {
        try {
          info = await bridge.resolve(url);
        } on PluckException {
          final media = tab.mediaSrc; // the player's own video file (TikTok, Facebook…)
          if (media != null && !tab.isStart) {
            info = await bridge.fromPage(jsonEncode({'video_url': media, '_title': tab.title}), tab.url ?? url);
          } else if (!retried && src != Source.instagram) {
            _openAndCapture(url, '*'); // open the page and take the video straight from its player
            return;
          } else {
            rethrow;
          }
        }
      }
      if (!mounted) return;
      final found = info!;
      if (found.items.isEmpty) throw const PluckException('Nothing downloadable found here.');
      setState(() => _resolving = false);
      await showResultSheet(context, found);
    } on PluckException catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted && tabs.current.pendingCode == null) setState(() => _resolving = false);
    }
  }

  Future<void> _fromPlayer(String url) async {
    final tab = tabs.current;
    final media = tab.mediaSrc;
    if (media == null) {
      _showError(const PluckException('This video didn’t start playing, so there was nothing to save. Tap play, then the red download button.'));
      return;
    }
    try {
      final info = await context.read<NativeBridge>().fromPage(jsonEncode({'video_url': media, '_title': tab.title}), tab.url ?? url);
      if (mounted) await showResultSheet(context, info);
    } on PluckException catch (e) {
      if (mounted) _showError(e);
    }
  }

  void _showError(PluckException e) {
    showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Couldn’t download'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.message, style: const TextStyle(fontSize: 15, height: 1.4)),
            if (e.detail != null && e.detail!.isNotEmpty)
              Theme(
                data: Theme.of(d).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Details', style: TextStyle(fontSize: 14, color: Palette.muted)),
                  children: [SelectableText(e.detail!, style: const TextStyle(fontSize: 12, color: Palette.muted))],
                ),
              ),
          ]),
        ),
        actions: [
          if (e.detail != null)
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '${e.message}\n${e.detail}'));
                Navigator.pop(d);
              },
              child: const Text('Copy details'),
            ),
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _paste() async {
    final t = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    if (t.trim().isEmpty) {
      if (mounted) toast(context, 'Clipboard is empty. Copy a link first.', error: true);
      return;
    }
    _go(t);
  }

  void _openSite(Source s) {
    if (s == Source.whatsapp) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Scaffold(body: StatusScreen())));
      return;
    }
    tabs.current.load(s.home);
  }

  @override
  void dispose() {
    _pendingTimer?.cancel();
    tabs.incoming.removeListener(_onIncoming);
    tabs.removeListener(_syncField);
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TabsController>();
    return ListenableBuilder(
      listenable: Listenable.merge([controller, controller.current, context.read<WebStore>()]),
      builder: (context, _) {
        final tab = controller.current;
        return Column(children: [
          _TopBar(
            tab: tab,
            count: controller.tabs.length,
            search: _search,
            focus: _focus,
            onSubmit: _go,
            onPaste: _paste,
            onTabs: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TabSwitcher())),
            onMenu: (v) => _menu(v, tab),
          ),
          if (tab.isStart)
            Expanded(child: _StartPage(onSite: _openSite, onOpen: (u) => tab.load(u), resolving: _resolving))
          else
            Expanded(
              child: Stack(children: [
                WebViewWidget(key: ValueKey(tab.id), controller: tab.web),
                if (tab.progress < 100)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: LinearProgressIndicator(value: tab.progress / 100, minHeight: 3, color: Palette.brand, backgroundColor: Colors.transparent),
                  ),
                Positioned(
                  right: 16,
                  bottom: 24,
                  child: AnimatedScale(
                    scale: tab.target == null ? 0 : 1,
                    duration: Motion.base,
                    curve: Motion.curve,
                    child: _DownloadFab(busy: _resolving, onTap: () => tab.target == null ? null : _download(tab.target!)),
                  ),
                ),
              ]),
            ),
        ]);
      },
    );
  }

  void _menu(String v, BrowserTab tab) {
    final store = context.read<WebStore>();
    switch (v) {
      case 'new':
        tabs.newTab();
      case 'home':
        tab.goStart();
      case 'bookmark':
        if (tab.url != null) {
          store.toggleBookmark(tab.title, tab.url!);
          toast(context, store.isBookmarked(tab.url) ? 'Bookmarked' : 'Bookmark removed');
        }
      case 'copy':
        if (tab.url != null) {
          Clipboard.setData(ClipboardData(text: tab.url!));
          toast(context, 'Link copied');
        }
      case 'paste':
        _paste();
      case 'status':
        _openSite(Source.whatsapp);
      case 'howto':
        final src = Source.detect(tab.url ?? '') ?? Source.instagram;
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => SourceScreen(source: src)));
      case 'settings':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    }
  }
}

/// Turns typed text into a URL: links stay links, anything else becomes a Google search.
String webAddress(String input) {
  final t = input.trim();
  final found = LinkParser.extract(t);
  if (found != null) return found;
  if (!t.contains(' ') && t.contains('.')) return 'https://$t';
  return 'https://www.google.com/search?q=${Uri.encodeQueryComponent(t)}';
}

// ── Orange top bar ───────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.tab,
    required this.count,
    required this.search,
    required this.focus,
    required this.onSubmit,
    required this.onPaste,
    required this.onTabs,
    required this.onMenu,
  });
  final BrowserTab tab;
  final int count;
  final TextEditingController search;
  final FocusNode focus;
  final ValueChanged<String> onSubmit;
  final VoidCallback onPaste;
  final VoidCallback onTabs;
  final ValueChanged<String> onMenu;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final store = context.read<WebStore>();
    final bookmarked = store.isBookmarked(tab.url);
    return Container(
      color: Palette.brand,
      padding: EdgeInsets.fromLTRB(14, top + 10, 4, 12),
      child: Row(children: [
        Pressable(
          onTap: onTabs,
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2.6), borderRadius: BorderRadius.circular(4)),
            child: Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.only(left: 18, right: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: search,
                  focusNode: focus,
                  onSubmitted: onSubmit,
                  textInputAction: TextInputAction.go,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 17, color: Palette.text),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Search or paste link',
                    hintStyle: TextStyle(fontSize: 17, color: Palette.faint),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(focus.hasFocus || tab.isStart ? Icons.content_paste_rounded : Icons.refresh_rounded, color: Palette.muted),
                tooltip: focus.hasFocus || tab.isStart ? 'Paste' : 'Reload',
                onPressed: focus.hasFocus || tab.isStart ? onPaste : () => tab.web.reload(),
              ),
            ]),
          ),
        ),
        const SizedBox(width: 4),
        if (tab.isStart)
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 28),
            tooltip: 'Settings',
            onPressed: () => onMenu('settings'),
          )
        else
          IconButton(
            icon: Icon(bookmarked ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.white, size: 28),
            tooltip: 'Bookmark',
            onPressed: () => onMenu('bookmark'),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 28),
          color: Colors.white,
          onSelected: onMenu,
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'new', child: Text('New tab')),
            if (!tab.isStart) const PopupMenuItem(value: 'home', child: Text('Home')),
            if (!tab.isStart) PopupMenuItem(value: 'bookmark', child: Text(bookmarked ? 'Remove bookmark' : 'Add bookmark')),
            if (!tab.isStart) const PopupMenuItem(value: 'copy', child: Text('Copy link')),
            const PopupMenuItem(value: 'paste', child: Text('Download copied link')),
            const PopupMenuItem(value: 'status', child: Text('Status saver')),
            const PopupMenuItem(value: 'howto', child: Text('How to download')),
            const PopupMenuItem(value: 'settings', child: Text('Settings')),
          ],
        ),
      ]),
    );
  }
}

// ── Start page ───────────────────────────────────────────────────────────────
class _StartPage extends StatefulWidget {
  const _StartPage({required this.onSite, required this.onOpen, required this.resolving});
  final ValueChanged<Source> onSite;
  final ValueChanged<String> onOpen;
  final bool resolving;
  @override
  State<_StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<_StartPage> {
  int _section = 0; // 0 favourite sites, 1 bookmarks

  static const _order = [
    Source.facebook,
    Source.instagram,
    Source.vimeo,
    Source.dailymotion,
    Source.youtube,
    Source.tiktok,
    Source.twitter,
    Source.whatsapp,
    Source.pinterest,
  ];

  @override
  Widget build(BuildContext context) {
    final store = context.read<WebStore>();
    final sites = _order.where((s) => s != Source.youtube || Config.youtubeEnabled).toList();
    return Column(children: [
      Container(
        color: Palette.brand,
        child: Row(children: [
          for (final (i, label) in const ['FAVORITE SITES', 'BOOKMARKS'].indexed)
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _section = i),
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: _section == i ? Colors.white : Colors.transparent, width: 4)),
                  ),
                  child: Text(label,
                      style: TextStyle(
                        color: _section == i ? Colors.white : Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 0.3,
                      )),
                ),
              ),
            ),
        ]),
      ),
      if (widget.resolving) const LinearProgressIndicator(minHeight: 3, color: Palette.brand, backgroundColor: Colors.transparent),
      Expanded(
        child: ListView(padding: EdgeInsets.zero, children: [
          if (_section == 0)
            Container(
              color: Palette.bg,
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 24),
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 18,
                childAspectRatio: 0.78,
                children: [for (final s in sites) _SiteTile(source: s, onTap: () => widget.onSite(s))],
              ),
            )
          else
            _EntryList(
              entries: store.bookmarks,
              empty: 'No bookmarks yet.\nOpen a site and tap ☆ to save it here.',
              onOpen: widget.onOpen,
              onDelete: store.removeBookmark,
            ),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SourceScreen(source: Source.instagram))),
              icon: const Icon(Icons.help_outline_rounded, size: 20, color: Palette.muted),
              label: const Text('How to download',
                  style: TextStyle(color: Palette.muted, fontSize: 16, decoration: TextDecoration.underline)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 6, 0),
            child: Row(children: [
              const Expanded(child: Text('HISTORY', style: TextStyle(color: Palette.muted, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.4))),
              IconButton(
                tooltip: 'Clear history',
                icon: const Icon(Icons.delete_rounded, color: Palette.muted),
                onPressed: store.history.isEmpty ? null : store.clearHistory,
              ),
            ]),
          ),
          _EntryList(
            entries: store.history.take(30).toList(),
            empty: 'Sites you open will show up here.',
            onOpen: widget.onOpen,
            onDelete: store.removeHistory,
          ),
          const SizedBox(height: 24),
        ]),
      ),
    ]);
  }
}

/// Font Awesome Free brand icons (CC BY 4.0), bundled as assets/fonts/fa-brands-400.ttf.
abstract final class Brand {
  static const _f = 'FABrands';
  static const facebook = IconData(0xf39e, fontFamily: _f);
  static const instagram = IconData(0xf16d, fontFamily: _f);
  static const vimeo = IconData(0xf27d, fontFamily: _f);
  static const dailymotion = IconData(0xe052, fontFamily: _f);
  static const youtube = IconData(0xf167, fontFamily: _f);
  static const tiktok = IconData(0xe07b, fontFamily: _f);
  static const x = IconData(0xe61b, fontFamily: _f);
  static const whatsapp = IconData(0xf232, fontFamily: _f);
  static const pinterest = IconData(0xf231, fontFamily: _f);
}

class _SiteTile extends StatelessWidget {
  const _SiteTile({required this.source, required this.onTap});
  final Source source;
  final VoidCallback onTap;

  static (IconData, Gradient) _look(Source s) {
    LinearGradient g(List<int> c, {Alignment begin = Alignment.topCenter, Alignment end = Alignment.bottomCenter}) =>
        LinearGradient(begin: begin, end: end, colors: [for (final v in c) Color(v)]);
    return switch (s) {
      Source.facebook => (Brand.facebook, g([0xFF18ACFE, 0xFF0163E0])),
      Source.instagram => (
          Brand.instagram,
          g([0xFF5B51D8, 0xFFC13584, 0xFFE1306C, 0xFFFD1D1D, 0xFFF77737, 0xFFFCAF45],
              begin: Alignment.topRight, end: Alignment.bottomLeft)
        ),
      Source.vimeo => (Brand.vimeo, g([0xFF1AB7EA, 0xFF0F9FD1])),
      Source.dailymotion => (Brand.dailymotion, g([0xFF1E6DF5, 0xFF0A4BC7])),
      Source.youtube => (Brand.youtube, g([0xFFFF2A2A, 0xFFE00000])),
      Source.tiktok => (Brand.tiktok, g([0xFF111111, 0xFF000000])),
      Source.twitter => (Brand.x, g([0xFF111111, 0xFF000000])),
      Source.whatsapp => (Brand.whatsapp, g([0xFF5FFC7B, 0xFF28D146])),
      Source.pinterest => (Brand.pinterest, g([0xFFF0213A, 0xFFC8001A])),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (icon, gradient) = _look(source);
    return Pressable(
      onTap: onTap,
      child: Column(children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: gradient),
            child: Icon(icon, color: Colors.white, size: 38),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          source == Source.twitter ? 'Twitter' : source.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Palette.muted, fontSize: 15),
        ),
      ]),
    );
  }
}

class _EntryList extends StatelessWidget {
  const _EntryList({required this.entries, required this.empty, required this.onOpen, required this.onDelete});
  final List<WebEntry> entries;
  final String empty;
  final ValueChanged<String> onOpen;
  final ValueChanged<WebEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
        child: Text(empty, style: const TextStyle(color: Palette.faint, fontSize: 15, height: 1.4)),
      );
    }
    return Column(children: [
      for (final e in entries) ...[
        InkWell(
          onTap: () => onOpen(e.url),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 0, 12),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, color: Palette.text)),
                  const SizedBox(height: 4),
                  Text(e.url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, color: Palette.faint)),
                ]),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Palette.muted),
                color: Colors.white,
                onSelected: (v) {
                  switch (v) {
                    case 'open':
                      onOpen(e.url);
                    case 'tab':
                      context.read<TabsController>().newTab(url: e.url);
                    case 'copy':
                      Clipboard.setData(ClipboardData(text: e.url));
                      toast(context, 'Link copied');
                    case 'delete':
                      onDelete(e);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'open', child: Text('Open')),
                  PopupMenuItem(value: 'tab', child: Text('Open in new tab')),
                  PopupMenuItem(value: 'copy', child: Text('Copy link')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ]),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Palette.line),
      ],
    ]);
  }
}

class _DownloadFab extends StatelessWidget {
  const _DownloadFab({required this.busy, required this.onTap});
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Download',
      child: Pressable(
      onTap: busy ? null : onTap,
      enabled: true,
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: Palette.fab,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x55000000), blurRadius: 14, offset: Offset(0, 6))],
        ),
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
            : const Icon(Icons.download_rounded, color: Colors.white, size: 34, semanticLabel: 'Download video'),
      ),
    ),
    );
  }
}
