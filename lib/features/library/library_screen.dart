import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../app.dart';
import '../../core/sources.dart';
import '../../core/tokens.dart';
import '../../data/models.dart';
import '../../widgets/enter.dart';
import '../../widgets/ui.dart';
import 'library_cubit.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return BlocBuilder<LibraryCubit, LibraryState>(builder: (context, s) {
      final cubit = context.read<LibraryCubit>();
      final items = s.visible;
      return CustomScrollView(slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(Space.page, top + Space.xxl + Space.md, Space.page, 0),
          sliver: SliverToBoxAdapter(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Library', style: TextStyles.hero).enter(context, 0),
              const SizedBox(height: Space.sm),
              MonoLabel('${s.records.length} files · ${formatBytes(s.totalBytes)}').enter(context, 1),
            ]),
          ),
        ),
        if (s.records.isEmpty)
          SliverToBoxAdapter(child: const _Empty().enter(context, 2))
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: Space.xl, bottom: Space.md),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Space.page),
                  children: [
                    for (final k in KindFilter.values) ...[
                      _FilterChip(
                        label: switch (k) {
                          KindFilter.all => 'All',
                          KindFilter.video => 'Videos',
                          KindFilter.image => 'Photos',
                          KindFilter.audio => 'Audio',
                        },
                        on: s.kind == k,
                        onTap: () => cubit.setKind(k),
                      ),
                      const SizedBox(width: Space.sm),
                    ],
                    Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8), color: Palette.line),
                    for (final src in Source.visible.where((x) => s.records.any((r) => r.source == x))) ...[
                      const SizedBox(width: Space.sm),
                      Pressable(
                        onTap: () => cubit.setSource(src),
                        child: AnimatedOpacity(
                          duration: Motion.fast,
                          opacity: s.source == null || s.source == src ? 1 : 0.35,
                          child: MonogramTile(src, size: 40, filled: s.source == src),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (items.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(Space.page),
                child: Text('Nothing matches this filter.', style: TextStyles.body),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Space.page),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((_, i) => _Tile(items[i]), childCount: items.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: Space.md,
                  crossAxisSpacing: Space.md,
                  childAspectRatio: 0.74,
                ),
              ),
            ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 150)),
      ]);
    });
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.base,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? Palette.text : Palette.surface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: on ? Palette.text : Palette.line),
          ),
          child: Text(label, style: TextStyles.button.copyWith(fontSize: 14, color: on ? Palette.bg : Palette.text)),
        ),
      );
}

class _Tile extends StatelessWidget {
  const _Tile(this.r);
  final DownloadRecord r;

  void _actions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Palette.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl))),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, Space.lg),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyles.h2),
            const SizedBox(height: 6),
            MonoLabel('${r.source.label} · ${r.ext} · ${formatBytes(r.bytes)}'),
            const SizedBox(height: Space.xl),
            GhostButton(label: 'Share', icon: Icons.ios_share_rounded, onTap: () {
              Navigator.pop(sheet);
              Share.shareXFiles([XFile(r.path)]);
            }),
            const SizedBox(height: Space.sm),
            GhostButton(label: 'Delete from Pluck', icon: Icons.delete_outline_rounded, color: Palette.danger, onTap: () {
              Navigator.pop(sheet);
              context.read<LibraryCubit>().remove(r);
            }),
            const SizedBox(height: Space.sm),
            Text('Copies in your gallery are kept.', style: TextStyles.small.copyWith(color: Palette.faint)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.97,
      onTap: () => OpenFilex.open(r.path),
      onLongPress: () => _actions(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.lg),
        child: Stack(fit: StackFit.expand, children: [
          if (r.kind == 'audio')
            Container(
              color: Color.alphaBlend(r.source.color.withValues(alpha: 0.10), Palette.surface),
              alignment: const Alignment(0, -0.25),
              child: Icon(Icons.graphic_eq_rounded, size: 64, color: r.source.color),
            )
          else
            Thumb(file: r.thumb, source: r.source, radius: 0),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.4, 1],
                colors: [Color(0x000B0A0F), Color(0xE60B0A0F)],
              ),
            ),
          ),
          Positioned(left: 10, top: 10, child: MonogramTile(r.source, size: 28, filled: true)),
          if (r.kind == 'video')
            const Positioned(right: 10, top: 12, child: Icon(Icons.play_arrow_rounded, color: Palette.text, size: 22)),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyles.title.copyWith(fontSize: 14, height: 1.25)),
              const SizedBox(height: 4),
              MonoLabel('${r.ext} · ${formatBytes(r.bytes)}', color: Palette.text.withValues(alpha: 0.6)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.page, Space.section, Space.page, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Nothing plucked yet.', style: TextStyles.h1.copyWith(color: Palette.faint)),
        const SizedBox(height: Space.sm),
        Text('Everything you save shows up here, ready to open, share or post again.', style: TextStyles.body),
        const SizedBox(height: Space.xl),
        SizedBox(
          width: 200,
          child: VoltButton(label: 'Paste a link', icon: Icons.arrow_forward_rounded, onTap: () => ShellScope.of(context).go(0)),
        ),
      ]),
    );
  }
}
