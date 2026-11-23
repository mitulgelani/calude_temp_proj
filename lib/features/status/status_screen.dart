import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/sources.dart';
import '../../core/tokens.dart';
import '../../data/downloader.dart';
import '../../data/models.dart';
import '../../data/native_bridge.dart';
import '../../widgets/enter.dart';
import '../../widgets/ui.dart';
import '../library/library_cubit.dart';
import 'status_cubit.dart';
import 'status_viewer.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});
  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<StatusCubit>().load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) context.read<StatusCubit>().load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return BlocBuilder<StatusCubit, StatusState>(builder: (context, s) {
      final cubit = context.read<StatusCubit>();
      return RefreshIndicator(
        color: Palette.volt,
        backgroundColor: Palette.surface,
        onRefresh: cubit.load,
        child: CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(Space.page, top + Space.md, Space.page, 0),
            sliver: SliverToBoxAdapter(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (Navigator.of(context).canPop())
                    IconCircle(icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).pop(), tooltip: 'Back')
                  else
                    const MonogramTile(Source.whatsapp, size: 44),
                  const Spacer(),
                  if (s.phase == StatusPhase.ready) IconCircle(icon: Icons.refresh_rounded, onTap: cubit.load, tooltip: 'Refresh'),
                ]),
                const SizedBox(height: Space.xl),
                const Text('Statuses', style: TextStyles.hero).enter(context, 0),
                const SizedBox(height: Space.sm),
                Text('They disappear after 24 hours. Keep the good ones.', style: TextStyles.body).enter(context, 1),
                const SizedBox(height: Space.xl),
                _Segmented(
                  value: s.variant,
                  onChanged: cubit.setVariant,
                ).enter(context, 2),
              ]),
            ),
          ),
          ..._body(context, s),
          const SliverToBoxAdapter(child: SizedBox(height: 150)),
        ]),
      );
    });
  }

  List<Widget> _body(BuildContext context, StatusState s) {
    switch (s.phase) {
      case StatusPhase.checking:
      case StatusPhase.loading:
        return [_grid(context, 9, (_, __) => Container(decoration: BoxDecoration(color: Palette.surface, borderRadius: BorderRadius.circular(Radii.sm))))];
      case StatusPhase.needsAccess:
        return [SliverToBoxAdapter(child: _AccessCard(variant: s.variant, onGrant: context.read<StatusCubit>().grant).enter(context, 3))];
      case StatusPhase.error:
        return [SliverToBoxAdapter(child: _Message(title: 'Can’t open statuses', body: s.error ?? 'Something went wrong.'))];
      case StatusPhase.ready:
        if (s.items.isEmpty) {
          return const [
            SliverToBoxAdapter(
              child: _Message(
                title: 'Nothing new yet.',
                body: 'Watch a few statuses in WhatsApp, then come back. They’ll be waiting here.',
              ),
            ),
          ];
        }
        final videos = s.items.where((i) => i.isVideo).length;
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, Space.md),
              child: Row(children: [
                _Chip('All ${s.items.length}', s.videosOnly == null, () => context.read<StatusCubit>().setFilter(null)),
                const SizedBox(width: Space.sm),
                _Chip('Videos $videos', s.videosOnly == true, () => context.read<StatusCubit>().setFilter(true)),
                const SizedBox(width: Space.sm),
                _Chip('Photos ${s.items.length - videos}', s.videosOnly == false, () => context.read<StatusCubit>().setFilter(false)),
              ]),
            ),
          ),
          _grid(context, s.visible.length, (ctx, i) => _StatusTile(item: s.visible[i], items: s.visible, index: i)),
        ];
    }
  }

  Widget _grid(BuildContext context, int count, IndexedWidgetBuilder builder) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, 0),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(builder, childCount: count),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 9 / 15,
          ),
        ),
      );
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.value, required this.onChanged});
  final StatusVariant value;
  final ValueChanged<StatusVariant> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Palette.surface, borderRadius: BorderRadius.circular(100), border: Border.all(color: Palette.line)),
      child: LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth) / 2;
        return Stack(children: [
          AnimatedPositioned(
            duration: Motion.base,
            curve: Motion.curve,
            left: value == StatusVariant.whatsapp ? 0 : w,
            top: 0,
            bottom: 0,
            width: w,
            child: Container(decoration: BoxDecoration(color: Palette.text, borderRadius: BorderRadius.circular(100))),
          ),
          Row(children: [
            for (final v in StatusVariant.values)
              Expanded(
                child: Pressable(
                  onTap: () => onChanged(v),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: Motion.base,
                      style: TextStyles.button.copyWith(fontSize: 14, color: v == value ? Palette.bg : Palette.muted),
                      child: Text(v == StatusVariant.whatsapp ? 'WhatsApp' : 'Business'),
                    ),
                  ),
                ),
              ),
          ]),
        ]);
      }),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.on, this.onTap);
  final String label;
  final bool on;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.base,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: on ? Palette.volt.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: on ? Palette.volt : Palette.line),
          ),
          child: Text(label, style: TextStyles.label.copyWith(color: on ? Palette.volt : Palette.muted, letterSpacing: 0.4, fontSize: 12)),
        ),
      );
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({required this.variant, required this.onGrant});
  final StatusVariant variant;
  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    final app = variant == StatusVariant.whatsapp ? 'WhatsApp' : 'WhatsApp Business';
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, 0),
      child: Container(
        padding: const EdgeInsets.all(Space.xl),
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.circular(Radii.xl),
          border: Border.all(color: Palette.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('One tap, then every status shows up here.', style: TextStyles.h2.copyWith(fontSize: 24)),
          const SizedBox(height: Space.md),
          Text('Android keeps $app’s status folder private. Allow Pluck to read it once. Nothing leaves your phone.', style: TextStyles.body),
          const SizedBox(height: Space.xl),
          for (final (i, step) in const ['Tap the button below', 'The .Statuses folder opens', 'Tap “Use this folder”, then Allow'].indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: Row(children: [
                SizedBox(width: 32, child: Text('0${i + 1}', style: TextStyles.number.copyWith(color: Source.whatsapp.color, fontSize: 13))),
                Expanded(child: Text(step, style: TextStyles.title.copyWith(fontSize: 15, fontWeight: FontWeight.w500))),
              ]),
            ),
          const SizedBox(height: Space.md),
          VoltButton(label: 'Allow folder access', icon: Icons.folder_open_rounded, onTap: onGrant),
        ]),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.section, Space.page, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyles.h1),
          const SizedBox(height: Space.sm),
          Text(body, style: TextStyles.body),
        ]),
      );
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.item, required this.items, required this.index});
  final StatusItem item;
  final List<StatusItem> items;
  final int index;

  Future<void> _quickSave(BuildContext context) async {
    try {
      await context.read<Downloader>().saveStatus(item);
      if (!context.mounted) return;
      context.read<LibraryCubit>().load();
      toast(context, item.isVideo ? 'Video saved to your gallery' : 'Photo saved to your gallery');
    } catch (e) {
      if (context.mounted) toast(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bridge = context.read<NativeBridge>();
    return Pressable(
      scale: 0.97,
      onTap: () => Navigator.of(context).push(PageRouteBuilder(
        opaque: false,
        transitionDuration: Motion.base,
        pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: StatusViewer(items: items, initial: index)),
      )),
      onLongPress: () => _quickSave(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.sm),
        child: Stack(fit: StackFit.expand, children: [
          Container(color: Palette.surface),
          if (item.isVideo)
            FutureBuilder(
              future: bridge.videoThumb(item),
              builder: (_, snap) => snap.data == null
                  ? const SizedBox.shrink()
                  : Image.memory(snap.data!, fit: BoxFit.cover, gaplessPlayback: true),
            )
          else
            FutureBuilder(
              future: bridge.copyToCache(item),
              builder: (_, snap) => snap.data == null
                  ? const SizedBox.shrink()
                  : Image.file(File(snap.data!), fit: BoxFit.cover, cacheWidth: 360, gaplessPlayback: true),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.55, 1],
                colors: [Color(0x000B0A0F), Color(0xAA0B0A0F)],
              ),
            ),
          ),
          if (item.isVideo)
            const Positioned(left: 8, top: 8, child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20)),
          Positioned(
            left: 8,
            bottom: 9,
            child: Text(_ago(item.modified), style: TextStyles.label.copyWith(color: Colors.white, letterSpacing: 0.4, fontSize: 11)),
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Pressable(
              onTap: () => _quickSave(context),
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(color: Palette.volt, shape: BoxShape.circle),
                child: const Icon(Icons.south_rounded, size: 17, color: Palette.voltInk),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  return '${d.inHours}h';
}

String statusAgo(DateTime t) => _ago(t);
