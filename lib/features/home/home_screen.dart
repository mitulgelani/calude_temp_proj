import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';

import '../../app.dart';
import '../../core/sources.dart';
import '../../core/tokens.dart';
import '../../data/models.dart';
import '../../widgets/enter.dart';
import '../../widgets/ui.dart';
import '../library/library_cubit.dart';
import '../result/result_sheet.dart';
import '../settings/settings_screen.dart';
import '../source/source_screen.dart';
import 'link_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String? _clip; // a supported link sitting on the clipboard
  final _dismissedClips = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkClipboard());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkClipboard();
  }

  Future<void> _checkClipboard() async {
    if (!(await Clipboard.hasStrings())) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final url = LinkParser.extract(data?.text ?? '');
    if (!mounted || url == null) return;
    final current = context.read<LinkCubit>().state.input;
    if (Source.detect(url) != null && url != current && !_dismissedClips.contains(url)) {
      setState(() => _clip = url);
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.trim().isEmpty) {
      if (mounted) toast(context, 'Your clipboard is empty. Copy a link first.', error: true);
      return;
    }
    if (!mounted) return;
    context.read<LinkCubit>().setInput(text);
    setState(() => _clip = null);
  }

  Future<void> _pluck() async {
    _focus.unfocus();
    final info = await context.read<LinkCubit>().resolve(_controller.text);
    if (!mounted || info == null) return;
    HapticFeedback.lightImpact();
    await showResultSheet(context, info);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return MultiBlocListener(
      listeners: [
        BlocListener<LinkCubit, LinkState>(
          listenWhen: (a, b) => a.input != b.input,
          listener: (_, s) {
            if (_controller.text != s.input) {
              _controller.value = TextEditingValue(text: s.input, selection: TextSelection.collapsed(offset: s.input.length));
            }
          },
        ),
        BlocListener<LinkCubit, LinkState>(
          listenWhen: (a, b) => a.autoToken != b.autoToken,
          listener: (_, __) => _pluck(),
        ),
      ],
      child: GestureDetector(
        onTap: () => _focus.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ListView(
          padding: EdgeInsets.fromLTRB(0, top + Space.md, 0, 150),
          children: [
            _TopBar(onSettings: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()))).enter(context, 0),
            const SizedBox(height: Space.xxl),
            const _Hero().enter(context, 1),
            const SizedBox(height: Space.xl),
            AnimatedSize(
              duration: Motion.base,
              curve: Motion.curve,
              child: _clip == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.md),
                      child: _ClipboardBanner(
                        url: _clip!,
                        onUse: () {
                          context.read<LinkCubit>().setInput(_clip!);
                          setState(() => _clip = null);
                          _pluck();
                        },
                        onDismiss: () => setState(() {
                          _dismissedClips.add(_clip!);
                          _clip = null;
                        }),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.page),
              child: _Portal(controller: _controller, focus: _focus, onPaste: _paste, onPluck: _pluck),
            ).enter(context, 2),
            const SizedBox(height: Space.section),
            const SectionHeader('Save from').enter(context, 3),
            const SizedBox(height: Space.lg),
            const _SourceRail().enter(context, 4),
            const _Recent(),
            const SizedBox(height: Space.section),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.page),
              child: Text(
                'Save only what you made or have permission to use. Pluck isn’t affiliated with any of these apps.',
                style: TextStyles.small.copyWith(color: Palette.faint, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.page),
      child: Row(children: [
        Text.rich(
          const TextSpan(children: [
            TextSpan(text: 'pluck'),
            TextSpan(text: '.', style: TextStyle(color: Palette.volt)),
          ]),
          style: TextStyles.h2.copyWith(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -1),
        ),
        const Spacer(),
        IconCircle(icon: Icons.tune_rounded, onTap: onSettings, tooltip: 'Settings'),
      ]),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.page),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(
          const TextSpan(children: [
            TextSpan(text: 'Paste it.\n'),
            TextSpan(text: 'Pluck it.', style: TextStyle(color: Palette.volt)),
          ]),
          style: TextStyles.hero,
        ),
        const SizedBox(height: Space.md),
        Text(
          'Reels, Shorts, pins, stories and statuses. Straight to your gallery, full quality, no watermark.',
          style: TextStyles.body,
        ),
      ]),
    );
  }
}

class _ClipboardBanner extends StatelessWidget {
  const _ClipboardBanner({required this.url, required this.onUse, required this.onDismiss});
  final String url;
  final VoidCallback onUse;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final src = Source.detect(url)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: src.color.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        MonogramTile(src, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${src.kindOf(url)} link copied', style: TextStyles.title.copyWith(fontSize: 14)),
            const SizedBox(height: 2),
            Text(url.replaceFirst(RegExp(r'^https?://(www\.)?'), ''),
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyles.label.copyWith(letterSpacing: 0.2)),
          ]),
        ),
        Pressable(
          onTap: onUse,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: Palette.volt, borderRadius: BorderRadius.circular(100)),
            child: Text('Pluck', style: TextStyles.button.copyWith(fontSize: 13, color: Palette.voltInk)),
          ),
        ),
        Pressable(
          onTap: onDismiss,
          child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.close_rounded, size: 18, color: Palette.muted)),
        ),
      ]),
    );
  }
}

/// The signature: a link card that takes on the identity of whatever app the link is from.
class _Portal extends StatelessWidget {
  const _Portal({required this.controller, required this.focus, required this.onPaste, required this.onPluck});
  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onPaste;
  final VoidCallback onPluck;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LinkCubit, LinkState>(builder: (context, s) {
      final src = s.source;
      final tint = src?.color ?? Palette.line;
      return AnimatedContainer(
        duration: Motion.slow,
        curve: Motion.curve,
        decoration: BoxDecoration(
          color: src == null ? Palette.surface : Color.alphaBlend(src.color.withValues(alpha: 0.07), Palette.surface),
          borderRadius: BorderRadius.circular(Radii.xl),
          border: Border.all(color: src == null ? Palette.line : tint.withValues(alpha: 0.55), width: 1.2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.xl),
          child: Stack(children: [
            // The stamp: an oversized monogram that drops into the corner when a link is recognised.
            Positioned(
              right: -14,
              bottom: -46,
              child: AnimatedSwitcher(
                duration: Motion.slow,
                switchInCurve: Motion.curve,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(scale: Tween(begin: 1.35, end: 1.0).animate(a), child: child),
                ),
                child: src == null
                    ? const SizedBox(key: ValueKey('none'), width: 10, height: 10)
                    : Text(
                        src.mono,
                        key: ValueKey(src),
                        style: TextStyle(
                          fontFamily: Fonts.display,
                          fontWeight: FontWeight.w800,
                          fontSize: 172,
                          height: 1,
                          letterSpacing: -8,
                          color: src.color.withValues(alpha: 0.13),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.xl - 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  height: 30,
                  child: Row(children: [
                    MonoLabel(src == null ? 'Link or @username' : 'Detected'),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: Motion.base,
                      child: src == null ? const SizedBox.shrink() : SourcePill(src, kind: s.kind, key: ValueKey('${src.name}${s.kind}')),
                    ),
                  ]),
                ),
                const SizedBox(height: Space.md),
                TextField(
                  controller: controller,
                  focusNode: focus,
                  onChanged: context.read<LinkCubit>().setInput,
                  onSubmitted: (_) => onPluck(),
                  textInputAction: TextInputAction.go,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  minLines: 1,
                  maxLines: 3,
                  style: const TextStyle(
                    fontFamily: Fonts.display,
                    fontWeight: FontWeight.w600,
                    fontSize: 21,
                    height: 1.25,
                    letterSpacing: -0.4,
                    color: Palette.text,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'instagram.com/reel/…',
                    hintStyle: TextStyle(
                      fontFamily: Fonts.display,
                      fontWeight: FontWeight.w600,
                      fontSize: 21,
                      letterSpacing: -0.4,
                      color: Palette.faint.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: Motion.base,
                  curve: Motion.curve,
                  child: s.phase == LinkPhase.error && s.error != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: Space.md),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Icon(Icons.error_outline_rounded, size: 16, color: Palette.danger),
                            const SizedBox(width: 6),
                            Expanded(child: Text(s.error!, style: TextStyles.small.copyWith(color: Palette.danger))),
                          ]),
                        )
                      : s.resolving
                          ? Padding(
                              padding: const EdgeInsets.only(top: Space.md),
                              child: MonoLabel('Reading ${src?.label ?? 'link'}…', color: src?.color),
                            )
                          : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: Space.xl),
                Row(children: [
                  Expanded(
                    flex: 5,
                    child: s.input.isEmpty
                        ? GhostButton(label: 'Paste', icon: Icons.content_paste_rounded, onTap: onPaste)
                        : GhostButton(label: 'Clear', icon: Icons.close_rounded, onTap: context.read<LinkCubit>().clear),
                  ),
                  const SizedBox(width: Space.sm + 2),
                  Expanded(
                    flex: 7,
                    child: VoltButton(label: 'Pluck', icon: Icons.south_rounded, loading: s.resolving, onTap: onPluck),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      );
    });
  }
}

class _SourceRail extends StatelessWidget {
  const _SourceRail();
  @override
  Widget build(BuildContext context) {
    final sources = Source.visible;
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.page),
        itemCount: sources.length,
        separatorBuilder: (_, __) => const SizedBox(width: Space.md - 2),
        itemBuilder: (context, i) {
          final s = sources[i];
          return Pressable(
            onTap: () {
              if (s == Source.whatsapp) {
                ShellScope.of(context).go(1);
              } else {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => SourceScreen(source: s)));
              }
            },
            child: Container(
              width: 118,
              padding: const EdgeInsets.all(Space.lg - 2),
              decoration: BoxDecoration(
                color: Palette.surface,
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(color: Palette.line),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                MonogramTile(s, size: 42),
                const Spacer(),
                Text(s.label, style: TextStyles.title.copyWith(fontSize: 15)),
                const SizedBox(height: 3),
                MonoLabel('${s.guides.length} ${s.guides.length == 1 ? 'type' : 'types'}'),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _Recent extends StatelessWidget {
  const _Recent();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(builder: (context, s) {
      if (s.records.isEmpty) return const SizedBox.shrink();
      final recent = s.records.take(3).toList();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: Space.section),
        SectionHeader('Just plucked', trailing: 'See all', onTrailing: () => ShellScope.of(context).go(2)),
        const SizedBox(height: Space.md),
        for (final r in recent) _RecentRow(r),
      ]);
    });
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow(this.r);
  final DownloadRecord r;
  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      onTap: () => OpenFilex.open(r.path),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.page, vertical: 7),
        child: Row(children: [
          SizedBox(width: 56, height: 56, child: Thumb(file: r.thumb, source: r.source)),
          const SizedBox(width: Space.md + 2),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyles.title.copyWith(fontSize: 15)),
              const SizedBox(height: 4),
              Row(children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: r.source.color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                MonoLabel('${r.source.label} · ${r.ext} · ${formatBytes(r.bytes)}'),
              ]),
            ]),
          ),
          const Icon(Icons.north_east_rounded, size: 18, color: Palette.faint),
        ]),
      ),
    );
  }
}
