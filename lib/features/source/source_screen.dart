import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/sources.dart';
import '../../core/tokens.dart';
import '../../widgets/enter.dart';
import '../../widgets/ui.dart';
import '../home/link_cubit.dart';
import '../result/result_sheet.dart';
import '../settings/settings_screen.dart';

class SourceScreen extends StatefulWidget {
  const SourceScreen({super.key, required this.source});
  final Source source;
  @override
  State<SourceScreen> createState() => _SourceScreenState();
}

class _SourceScreenState extends State<SourceScreen> {
  int _kind = 0;
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  Source get src => widget.source;
  KindGuide get guide => src.guides[_kind];

  Future<void> _pluck() async {
    FocusScope.of(context).unfocus();
    var text = _controller.text.trim();
    if (guide.usernameMode && text.isNotEmpty && !text.contains('/') && !text.startsWith('@')) text = '@$text';
    setState(() {
      _busy = true;
      _error = null;
    });
    final cubit = context.read<LinkCubit>();
    final info = await cubit.resolve(text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = info == null ? cubit.state.error : null;
    });
    if (info != null) await showResultSheet(context, info);
  }

  Future<void> _paste() async {
    final t = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    final url = LinkParser.extract(t) ?? t.trim();
    if (url.isNotEmpty) setState(() => _controller.text = url);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(padding: EdgeInsets.fromLTRB(0, top + Space.md, 0, 60), children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: Row(children: [
              IconCircle(icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).pop(), tooltip: 'Back'),
              const Spacer(),
              MonoLabel('Save from ${src.label}'),
            ]),
          ),
          // Header: the app's monogram as architecture, not decoration.
          SizedBox(
            height: 210,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                right: -20,
                top: -6,
                child: Text(
                  src.mono,
                  style: TextStyle(
                    fontFamily: Fonts.display,
                    fontWeight: FontWeight.w800,
                    fontSize: 230,
                    height: 1,
                    letterSpacing: -12,
                    color: src.color.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Positioned(
                left: Space.page,
                right: Space.page,
                bottom: Space.md,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  MonogramTile(src, size: 48, filled: true),
                  const SizedBox(height: Space.lg),
                  Text(src.label, style: TextStyles.hero.copyWith(fontSize: 40)),
                  const SizedBox(height: Space.sm),
                  Text(src.pitch, style: TextStyles.body),
                ]),
              ),
            ]),
          ).enter(context, 0),
          const SizedBox(height: Space.xl),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.page),
              itemCount: src.guides.length,
              separatorBuilder: (_, __) => const SizedBox(width: Space.sm),
              itemBuilder: (_, i) {
                final on = i == _kind;
                return Pressable(
                  onTap: () => setState(() {
                    _kind = i;
                    _error = null;
                  }),
                  child: AnimatedContainer(
                    duration: Motion.base,
                    curve: Motion.curve,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: on ? Palette.text : Palette.surface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: on ? Palette.text : Palette.line),
                    ),
                    child: Text(src.guides[i].name,
                        style: TextStyles.button.copyWith(fontSize: 14, color: on ? Palette.bg : Palette.text)),
                  ),
                );
              },
            ),
          ).enter(context, 1),
          const SizedBox(height: Space.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: AnimatedSwitcher(
              duration: Motion.base,
              child: _GuideCard(key: ValueKey(_kind), guide: guide, source: src),
            ),
          ).enter(context, 2),
          const SizedBox(height: Space.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: Container(
              padding: const EdgeInsets.fromLTRB(Space.lg + 2, Space.sm, Space.sm, Space.sm),
              decoration: BoxDecoration(
                color: Palette.surface,
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(color: _error != null ? Palette.danger.withValues(alpha: 0.6) : Palette.line),
              ),
              child: Row(children: [
                if (guide.usernameMode) Text('@', style: TextStyles.h2.copyWith(color: src.color)),
                if (guide.usernameMode) const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _pluck(),
                    textInputAction: TextInputAction.go,
                    autocorrect: false,
                    keyboardType: guide.usernameMode ? TextInputType.text : TextInputType.url,
                    style: TextStyles.title.copyWith(fontSize: 16),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: guide.usernameMode ? 'username' : 'Paste ${src.label} link',
                      hintStyle: TextStyles.title.copyWith(fontSize: 16, color: Palette.faint),
                    ),
                  ),
                ),
                if (!guide.usernameMode)
                  Pressable(
                    onTap: _paste,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.content_paste_rounded, color: Palette.muted, size: 20),
                    ),
                  ),
                const SizedBox(width: 4),
                SizedBox(width: 108, child: VoltButton(label: 'Pluck', loading: _busy, height: 50, onTap: _pluck)),
              ]),
            ),
          ).enter(context, 3),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.page + 4, Space.md, Space.page, 0),
              child: Text(_error!, style: TextStyles.small.copyWith(color: Palette.danger)),
            ),
        ]),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({super.key, required this.guide, required this.source});
  final KindGuide guide;
  final Source source;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.xl - 4),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: Palette.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const MonoLabel('How to'),
        const SizedBox(height: Space.lg),
        for (var i = 0; i < guide.steps.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == guide.steps.length - 1 ? 0 : Space.lg),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 34,
                child: Text('0${i + 1}', style: TextStyles.number.copyWith(color: source.color, fontSize: 14)),
              ),
              Expanded(child: Text(guide.steps[i], style: TextStyles.title.copyWith(fontWeight: FontWeight.w500))),
            ]),
          ),
        if (guide.note != null) ...[
          const SizedBox(height: Space.lg),
          Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(color: Palette.surfaceHi, borderRadius: BorderRadius.circular(Radii.sm)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lock_outline_rounded, size: 18, color: Palette.muted),
              const SizedBox(width: Space.sm),
              Expanded(child: Text(guide.note!, style: TextStyles.small)),
            ]),
          ),
          const SizedBox(height: Space.md),
          Pressable(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            child: MonoLabel('Connect in Settings  →', color: Palette.text),
          ),
        ],
      ]),
    );
  }
}
