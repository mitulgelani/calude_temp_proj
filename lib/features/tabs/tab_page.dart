import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app.dart';
import '../../core/config.dart';
import '../../core/sources.dart';
import '../../core/tokens.dart';
import '../../data/models.dart';
import '../../data/native_bridge.dart';
import '../../data/web_store.dart';
import '../../widgets/brand.dart';
import '../../widgets/ui.dart';
import '../result/result_sheet.dart';
import '../settings/settings_screen.dart';
import '../source/source_screen.dart';
import '../status/status_screen.dart';
import 'tab_switcher.dart';
import 'tabs_controller.dart';

/// The Browser tab: search bar on top, then either the start page or a live website.
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
    shellTab.value = 1;
  }

  /// Opens an Instagram post/reel in the browser, then pops the download sheet as soon as the page has it.
  void _openAndCapture(String url, String code) {
    debugPrint('[pluck] open-and-capture $url code=$code');
    final tab = tabs.current;
    shellTab.value = 1;
    tab.pendingCode = code;
    final ig = code != '*';
    // Instagram: the Reels route plays logged-out for any video (even /p/ links); photo posts fall back to the public embed page.
    tab.load(!ig ? url : 'https://www.instagram.com/reels/$code/');
    var stage = 0;
    setState(() => _resolving = true);
    final started = DateTime.now();
    _pendingTimer?.cancel();
    _pendingTimer = Timer.periodic(Duration(milliseconds: 500), (t) async {
      if (!mounted || tab.pendingCode != code) {
        t.cancel();
        return;
      }
      final ready = ig ? tab.codes.contains(code) : tab.mediaSrc != null;
      final elapsed = DateTime.now().difference(started);
      if (ig && !ready && stage == 0 && elapsed > const Duration(seconds: 8)) {
        stage = 1;
        tab.load('https://www.instagram.com/p/$code/embed/captioned/');
        return;
      }
      final waited = elapsed > Duration(seconds: ig ? 18 : 20);
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
    debugPrint('[pluck] download url=$url retried=$retried resolving=$_resolving page=${tabs.current.url}');
    if (!retried) _pendingTimer?.cancel();
    final src = Source.detect(url);
    if (src == Source.youtube && !Config.youtubeEnabled) {
      toast(context, 'YouTube saving isn’t available in this version.', error: true);
      return;
    }
    final bridge = context.read<NativeBridge>();
    final tab = tabs.current;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Getting video…'), duration: Duration(seconds: 2)));
    HapticFeedback.mediumImpact();
    setState(() => _resolving = true);
    try {
      MediaInfo? info;
      final key = _igCode.firstMatch(url)?.group(1) ?? _igStory.firstMatch(url)?.group(1);
      if (key != null && !tab.isStart) {
        final payload = await tab.captured(key);
        debugPrint('[pluck] key=$key captured=${payload == null ? 'no' : '${payload.length} chars'} codes=${tab.codes.length}');
        if (payload != null) info = await bridge.fromPage(payload, url);
      }
      if (info == null && key != null && src == Source.instagram && !retried && tab.isStart) {
        _openAndCapture(url, key); // pasted link: open it via the route that plays logged-out
        return;
      }
      if (info == null) {
        try {
          info = await bridge.resolve(url).timeout(Duration(seconds: 25),
              onTimeout: () => throw PluckException('This is taking too long. Check your internet and try again.'));
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
      if (found.items.isEmpty) throw PluckException('Nothing downloadable found here.');
      setState(() => _resolving = false);
      await showResultSheet(context, found);
    } on PluckException catch (e) {
      debugPrint('[pluck] error ${e.message} | ${e.detail}');
      if (mounted) _showError(e);
    } catch (e, st) {
      debugPrint('[pluck] crash $e\n$st');
      if (mounted) _showError(PluckException('Something went wrong.', '$e'));
    } finally {
      if (mounted && tabs.current.pendingCode == null) setState(() => _resolving = false);
    }
  }

  Future<void> _fromPlayer(String url) async {
    final tab = tabs.current;
    final media = tab.mediaSrc;
    if (media == null) {
      _showError(PluckException('This video didn’t start playing, so there was nothing to save. Tap play, then the red download button.'));
      return;
    }
    try {
      final info = await context.read<NativeBridge>().fromPage(jsonEncode({'video_url': media, '_title': tab.title}), tab.url ?? url);
      if (mounted) await showResultSheet(context, info);
    } on PluckException catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<void> _tapFab(BrowserTab tab) async {
    final t = tab.target;
    if (t != null) return _download(t);
    // No specific post detected yet: try what the page has for the current address.
    final payload = await tab.captured('');
    if (payload != null && mounted) {
      try {
        final info = await context.read<NativeBridge>().fromPage(payload, tab.url ?? '');
        if (mounted) await showResultSheet(context, info);
        return;
      } on PluckException catch (_) {}
    }
    if (mounted) toast(context, 'Open a reel, post or video first, let it play, then tap download.', error: true);
  }

  void _showError(PluckException e) {
    showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: Palette.surface,
        title: Text('Couldn’t download'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.message, style: TextStyle(fontSize: 15, height: 1.4)),
            if (e.detail != null && e.detail!.isNotEmpty)
              Theme(
                data: Theme.of(d).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('Details', style: TextStyle(fontSize: 14, color: Palette.muted)),
                  children: [SelectableText(e.detail!, style: TextStyle(fontSize: 12, color: Palette.muted))],
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
              child: Text('Copy details'),
            ),
          TextButton(onPressed: () => Navigator.pop(d), child: Text('OK')),
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
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(body: StatusScreen())));
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
            onTabs: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TabSwitcher())),
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
                  bottom: 110, // clear of snackbars and the site's own bottom bars
                  child: AnimatedScale(
                    // Always there on supported sites (like the reference app); brighter once a post is on screen.
                    scale: Source.detect(tab.url ?? '') == null || Source.detect(tab.url ?? '') == Source.whatsapp ? 0 : 1,
                    duration: Motion.base,
                    curve: Motion.curve,
                    child: AnimatedOpacity(
                      opacity: tab.target == null ? 0.75 : 1,
                      duration: Motion.base,
                      child: _DownloadFab(busy: _resolving, onTap: () => _tapFab(tab)),
                    ),
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
        shellTab.value = 0;
      case 'start':
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
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsScreen()));
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

// ── Top bar ──────────────────────────────────────────────────────────────────
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
    final src = Source.detect(tab.url ?? '');
    return Container(
      decoration: BoxDecoration(color: Palette.surface, border: Border(bottom: BorderSide(color: Palette.line))),
      padding: EdgeInsets.fromLTRB(12, top + 8, 4, 10),
      child: Row(children: [
        Pressable(
          onTap: onTabs,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: Palette.ink, width: 2), borderRadius: BorderRadius.circular(7)),
              child: Text('$count', style: TextStyle(fontFamily: Fonts.body, color: Palette.ink, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
        ),
        SizedBox(width: 6),
        Expanded(
          child: AnimatedContainer(
            duration: Motion.base,
            height: 44,
            padding: EdgeInsets.only(left: 12, right: 2),
            decoration: BoxDecoration(
              color: focus.hasFocus ? Palette.surface : Palette.surfaceHi,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: focus.hasFocus ? Palette.accent : Colors.transparent, width: 1.4),
            ),
            child: Row(children: [
              if (src != null && !focus.hasFocus)
                SiteBubble(src, size: 22)
              else
                Icon(tab.isStart || focus.hasFocus ? Icons.search_rounded : Icons.lock_rounded, size: 18, color: Palette.muted),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: search,
                  focusNode: focus,
                  onSubmitted: onSubmit,
                  textInputAction: TextInputAction.go,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  maxLines: 1,
                  style: TextStyles.title.copyWith(fontSize: 14.5, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Search or paste a link',
                    hintStyle: TextStyles.title.copyWith(fontSize: 14.5, fontWeight: FontWeight.w500, color: Palette.faint),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(focus.hasFocus || tab.isStart ? Icons.content_paste_rounded : Icons.refresh_rounded, size: 20, color: Palette.muted),
                tooltip: focus.hasFocus || tab.isStart ? 'Paste' : 'Reload',
                onPressed: focus.hasFocus || tab.isStart ? onPaste : () => tab.web.reload(),
              ),
            ]),
          ),
        ),
        if (tab.isStart) ThemeSwitch(plain: true),
        if (!tab.isStart)
          IconButton(
            icon: Icon(bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: bookmarked ? Palette.accent : Palette.ink, size: 23),
            tooltip: 'Bookmark',
            onPressed: () => onMenu('bookmark'),
          ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: Palette.ink, size: 23),
          color: Palette.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: onMenu,
          itemBuilder: (_) => [
            _item('home', Icons.home_rounded, 'Home'),
            _item('new', Icons.add_rounded, 'New tab'),
            if (!tab.isStart) _item('start', Icons.apps_rounded, 'Start page'),
            if (!tab.isStart) _item('bookmark', bookmarked ? Icons.bookmark_remove_rounded : Icons.bookmark_add_rounded, bookmarked ? 'Remove bookmark' : 'Add bookmark'),
            if (!tab.isStart) _item('copy', Icons.link_rounded, 'Copy link'),
            _item('paste', Icons.content_paste_go_rounded, 'Download copied link'),
            _item('status', Icons.blur_circular_rounded, 'Status saver'),
            _item('howto', Icons.help_outline_rounded, 'How to download'),
            _item('settings', Icons.tune_rounded, 'Settings'),
          ],
        ),
      ]),
    );
  }

  static PopupMenuItem<String> _item(String v, IconData i, String t) => PopupMenuItem(
        value: v,
        height: 44,
        child: Row(children: [
          Icon(i, size: 19, color: Palette.muted),
          SizedBox(width: 12),
          Text(t, style: TextStyles.title.copyWith(fontSize: 14.5, fontWeight: FontWeight.w500)),
        ]),
      );
}

// ── Start page (new tab) ─────────────────────────────────────────────────────
class _StartPage extends StatefulWidget {
  const _StartPage({required this.onSite, required this.onOpen, required this.resolving});
  final ValueChanged<Source> onSite;
  final ValueChanged<String> onOpen;
  final bool resolving;
  @override
  State<_StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<_StartPage> {
  int _section = 0; // 0 history, 1 bookmarks

  static const _order = [
    Source.instagram,
    Source.tiktok,
    Source.youtube,
    Source.facebook,
    Source.pinterest,
    Source.twitter,
    Source.vimeo,
    Source.dailymotion,
  ];

  @override
  Widget build(BuildContext context) {
    final store = context.read<WebStore>();
    final sites = _order.where((s) => s != Source.youtube || Config.youtubeEnabled).toList();
    return ListView(padding: EdgeInsets.only(bottom: 24), children: [
      if (widget.resolving) LinearProgressIndicator(minHeight: 2, color: Palette.accent, backgroundColor: Colors.transparent),
      Padding(
        padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
        child: Text('Browse & download', style: TextStyles.h1.copyWith(fontSize: 26)),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
        child: Text('Open a site, play a video, tap the orange button.', style: TextStyles.small),
      ),
      SizedBox(height: 18),
      SizedBox(
        height: 92,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 18),
          itemCount: sites.length,
          separatorBuilder: (_, __) => SizedBox(width: 6),
          itemBuilder: (_, i) => Pressable(
            onTap: () => widget.onSite(sites[i]),
            child: SizedBox(
              width: 70,
              child: Column(children: [
                AppIcon(sites[i], size: 52),
                SizedBox(height: 7),
                Text(appName(sites[i]), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyles.small.copyWith(fontSize: 12, color: Palette.text, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      ),
      SizedBox(height: 18),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(color: Palette.surface, borderRadius: BorderRadius.circular(24), boxShadow: Shadows.soft),
          child: Column(children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8, 8, 4, 0),
              child: Row(children: [
                for (final (i, label) in ['History', 'Bookmarks'].indexed)
                  Pressable(
                    onTap: () => setState(() => _section = i),
                    child: AnimatedContainer(
                      duration: Motion.base,
                      margin: EdgeInsets.only(right: 6),
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: _section == i ? Palette.ink : Colors.transparent, borderRadius: BorderRadius.circular(100)),
                      child: Text(label, style: TextStyles.button.copyWith(fontSize: 13.5, color: _section == i ? Palette.onInk : Palette.muted)),
                    ),
                  ),
                Spacer(),
                if (_section == 0 && store.history.isNotEmpty)
                  TextButton(onPressed: store.clearHistory, child: Text('Clear', style: TextStyles.button.copyWith(fontSize: 13, color: Palette.muted))),
              ]),
            ),
            _EntryList(
              entries: _section == 0 ? store.history.take(30).toList() : store.bookmarks,
              empty: _section == 0 ? 'Sites you open will show up here.' : 'No bookmarks yet. Open a site and tap the bookmark icon.',
              onOpen: widget.onOpen,
              onDelete: _section == 0 ? store.removeHistory : store.removeBookmark,
            ),
            SizedBox(height: 6),
          ]),
        ),
      ),
    ]);
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
        padding: EdgeInsets.fromLTRB(18, 10, 18, 8),
        child: Text(empty, style: TextStyle(color: Palette.faint, fontSize: 14, height: 1.4)),
      );
    }
    return Column(children: [
      for (final e in entries) ...[
        InkWell(
          onTap: () => onOpen(e.url),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 0, 10),
            child: Row(children: [
              SiteBubble(Source.detect(e.url)),
              SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Palette.text)),
                  SizedBox(height: 2),
                  Text(e.url.replaceFirst(RegExp(r'^https?://(www\.)?'), ''), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Palette.faint)),
                ]),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: Palette.muted),
                color: Palette.surface,
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
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'open', child: Text('Open')),
                  PopupMenuItem(value: 'tab', child: Text('Open in new tab')),
                  PopupMenuItem(value: 'copy', child: Text('Copy link')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ]),
          ),
        ),
        Divider(height: 1, thickness: 1, indent: 66, endIndent: 16, color: Palette.line),
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
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Palette.fab,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x55000000), blurRadius: 14, offset: Offset(0, 6))],
        ),
        alignment: Alignment.center,
        child: busy
            ? SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
            : Icon(Icons.download_rounded, color: Colors.white, size: 34, semanticLabel: 'Download video'),
      ),
    ),
    );
  }
}
