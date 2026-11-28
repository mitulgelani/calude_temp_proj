import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';

import '../../app.dart';
import '../../core/config.dart';
import '../../core/sources.dart';
import '../../core/tokens.dart';
import '../../data/models.dart';
import '../../widgets/brand.dart';
import '../../widgets/enter.dart';
import '../../widgets/ui.dart';
import '../library/library_cubit.dart';
import '../settings/settings_screen.dart';
import '../tabs/tabs_controller.dart';
import 'guide_sheet.dart';

/// Home: paste a link and download, or pick an app to see how.
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _link = TextEditingController();
  final _focus = FocusNode();
  String? _clip;
  final _dismissed = <String>{};

  static const _apps = [
    Source.instagram,
    Source.tiktok,
    Source.youtube,
    Source.facebook,
    Source.whatsapp,
    Source.pinterest,
    Source.twitter,
    Source.vimeo,
    Source.dailymotion,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkClipboard());
    _link.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkClipboard();
  }

  Future<void> _checkClipboard() async {
    if (!(await Clipboard.hasStrings())) return;
    final url = LinkParser.extract((await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '');
    if (!mounted || url == null || _dismissed.contains(url) || url == _link.text.trim()) return;
    if (Source.isItem(url)) setState(() => _clip = url);
  }

  Future<void> _download([String? given]) async {
    _focus.unfocus();
    var text = (given ?? _link.text).trim();
    if (text.isEmpty) {
      text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '';
      if (text.isEmpty) {
        if (mounted) toast(context, 'Copy a video link first, then tap Paste.', error: true);
        return;
      }
      _link.text = LinkParser.extract(text) ?? text;
    }
    if (!mounted) return;
    setState(() => _clip = null);
    context.read<TabsController>().incoming.value = text; // same engine as the browser's search bar
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _link.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final compact = MediaQuery.sizeOf(context).height < 760;
    final apps = _apps.where((s) => s != Source.youtube || Config.youtubeEnabled).toList();
    return GestureDetector(
      onTap: () => _focus.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: ListView(
        padding: EdgeInsets.fromLTRB(0, top + 14, 0, 32),
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(children: [
              Text.rich(
                const TextSpan(children: [TextSpan(text: 'pluck'), TextSpan(text: '.', style: TextStyle(color: Palette.accent))]),
                style: TextStyles.h2.copyWith(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -1),
              ),
              const Spacer(),
              IconCircle(
                icon: Icons.tune_rounded,
                tooltip: 'Settings',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ]),
          ).enter(context, 0),
          SizedBox(height: compact ? 14 : 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Save any video,\nin one tap.', style: TextStyles.hero.copyWith(fontSize: compact ? 32 : 40, height: 1.02, letterSpacing: compact ? -1.2 : -1.6)),
              SizedBox(height: compact ? 6 : 10),
              Text('Reels, Shorts, posts, stories and statuses — straight to your gallery.', style: TextStyles.body),
            ]),
          ).enter(context, 1),
          SizedBox(height: compact ? 16 : 22),

          // ── Clipboard catch ──
          AnimatedSize(
            duration: Motion.base,
            curve: Motion.curve,
            child: _clip == null
                ? const SizedBox(width: double.infinity)
                : Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: _ClipCard(url: _clip!, onUse: () => _download(_clip), onClose: () => setState(() {
                    _dismissed.add(_clip!);
                    _clip = null;
                  }))),
          ),

          // ── Paste card ──
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _PasteCard(controller: _link, focus: _focus, onDownload: _download))
              .enter(context, 2),
          const SizedBox(height: 14),
          const _TrustRow().enter(context, 3),
          SizedBox(height: compact ? 22 : 30),

          // ── Apps ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: Text('Download from', style: TextStyles.h2.copyWith(fontSize: 20))),
              Text('Tap for a quick guide', style: TextStyles.small.copyWith(fontSize: 12.5)),
            ]),
          ).enter(context, 4),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
              decoration: BoxDecoration(color: Palette.surface, borderRadius: BorderRadius.circular(26), boxShadow: Shadows.soft),
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                childAspectRatio: 0.82,
                children: [
                  for (final s in apps)
                    Pressable(
                      onTap: () => showGuideSheet(context, s),
                      child: Column(children: [
                        AppIcon(s, size: 56),
                        const SizedBox(height: 8),
                        Text(appName(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyles.small.copyWith(color: Palette.text, fontWeight: FontWeight.w600, fontSize: 12.5)),
                      ]),
                    ),
                ],
              ),
            ),
          ).enter(context, 5),
          const SizedBox(height: 14),

          // ── Status saver spotlight ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Pressable(
              scale: 0.98,
              onTap: () => showGuideSheet(context, Source.whatsapp),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                decoration: BoxDecoration(color: Palette.ink, borderRadius: BorderRadius.circular(24)),
                child: Row(children: [
                  const AppIcon(Source.whatsapp, size: 44, shadow: false),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Status saver', style: TextStyles.title.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Keep WhatsApp statuses before they vanish', style: TextStyles.small.copyWith(color: Colors.white70, fontSize: 12.5)),
                    ]),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 19),
                  ),
                ]),
              ),
            ),
          ).enter(context, 6),

          // ── Recent ──
          const _Recent(),
        ],
      ),
    );
  }
}

class _PasteCard extends StatelessWidget {
  const _PasteCard({required this.controller, required this.focus, required this.onDownload});
  final TextEditingController controller;
  final FocusNode focus;
  final Future<void> Function([String?]) onDownload;

  @override
  Widget build(BuildContext context) {
    final text = controller.text.trim();
    final src = text.isEmpty ? null : Source.detect(text);
    return AnimatedContainer(
      duration: Motion.base,
      curve: Motion.curve,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: Shadows.lift,
        border: Border.all(color: focus.hasFocus ? Palette.accent.withValues(alpha: 0.5) : Colors.transparent, width: 1.4),
      ),
      child: Column(children: [
        Container(
          height: 56,
          padding: const EdgeInsets.only(left: 14, right: 6),
          decoration: BoxDecoration(color: Palette.bg, borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            AnimatedSwitcher(
              duration: Motion.base,
              child: src == null
                  ? const Icon(Icons.link_rounded, key: ValueKey('l'), color: Palette.muted, size: 22)
                  : SiteBubble(src, key: ValueKey(src), size: 26),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focus,
                keyboardType: TextInputType.url,
                autocorrect: false,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => onDownload(),
                style: TextStyles.title.copyWith(fontSize: 15.5, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Paste a video link…',
                  hintStyle: TextStyles.title.copyWith(fontSize: 15.5, fontWeight: FontWeight.w500, color: Palette.faint),
                ),
              ),
            ),
            if (text.isNotEmpty)
              IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close_rounded, size: 20, color: Palette.muted),
                onPressed: controller.clear,
              )
            else
              Pressable(
                onTap: () async {
                  final t = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '';
                  if (t.isNotEmpty) controller.text = LinkParser.extract(t) ?? t;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(color: Palette.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Palette.line)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.content_paste_rounded, size: 16, color: Palette.text),
                    const SizedBox(width: 6),
                    Text('Paste', style: TextStyles.button.copyWith(fontSize: 13.5, color: Palette.text)),
                  ]),
                ),
              ),
          ]),
        ),
        AnimatedSize(
          duration: Motion.base,
          curve: Motion.curve,
          child: src == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: Palette.success),
                    const SizedBox(width: 6),
                    Text('${appName(src)} ${src.kindOf(text).toLowerCase()} detected', style: TextStyles.small.copyWith(color: Palette.text, fontWeight: FontWeight.w600)),
                  ]),
                ),
        ),
        const SizedBox(height: 12),
        VoltButton(label: text.isEmpty ? 'Paste & download' : 'Download', icon: Icons.south_rounded, height: 56, onTap: onDownload),
      ]),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();
  @override
  Widget build(BuildContext context) {
    Widget item(IconData i, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 15, color: Palette.muted),
          const SizedBox(width: 5),
          Text(t, style: TextStyles.small.copyWith(fontSize: 12.5)),
        ]);
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      item(Icons.lock_open_rounded, 'No login'),
      const SizedBox(width: 16),
      item(Icons.hd_rounded, 'Full quality'),
      const SizedBox(width: 16),
      item(Icons.water_drop_outlined, 'No watermark'),
    ]);
  }
}

class _ClipCard extends StatelessWidget {
  const _ClipCard({required this.url, required this.onUse, required this.onClose});
  final String url;
  final VoidCallback onUse;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) {
    final s = Source.detect(url)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(color: Palette.accentSoft, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        SiteBubble(s, size: 34),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${appName(s)} link copied', style: TextStyles.title.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
            Text(url.replaceFirst(RegExp(r'^https?://(www\.)?'), ''), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyles.small.copyWith(fontSize: 12)),
          ]),
        ),
        Pressable(
          onTap: onUse,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: Palette.accent, borderRadius: BorderRadius.circular(100)),
            child: Text('Download', style: TextStyles.button.copyWith(fontSize: 13, color: Colors.white)),
          ),
        ),
        IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded, size: 18, color: Palette.muted)),
      ]),
    );
  }
}

class _Recent extends StatelessWidget {
  const _Recent();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(builder: (context, s) {
      if (s.records.isEmpty) return const SizedBox.shrink();
      final items = s.records.take(8).toList();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(children: [
            Expanded(child: Text('Recent downloads', style: TextStyles.h2.copyWith(fontSize: 20))),
            Pressable(onTap: () => shellTab.value = 3, child: Text('See all', style: TextStyles.button.copyWith(fontSize: 14, color: Palette.accent))),
          ]),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _RecentCard(items[i]),
          ),
        ),
      ]);
    });
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard(this.r);
  final DownloadRecord r;
  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.97,
      onTap: () => OpenFilex.open(r.path),
      child: SizedBox(
        width: 124,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(fit: StackFit.expand, children: [
            if (r.kind == 'audio')
              Container(color: Palette.surfaceHi, child: const Icon(Icons.graphic_eq_rounded, size: 40, color: Palette.muted))
            else
              MediaThumb(file: r.thumb, source: r.source, radius: 0),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.5, 1], colors: [Color(0x00000000), Color(0xB3000000)]),
              ),
            ),
            Positioned(left: 8, top: 8, child: SiteBubble(r.source, size: 24)),
            if (r.kind == 'video') const Positioned(right: 8, top: 8, child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 22)),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: Fonts.body, color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, height: 1.25)),
            ),
          ]),
        ),
      ),
    );
  }
}
