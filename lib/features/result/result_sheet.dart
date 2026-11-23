import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/tokens.dart';
import '../../data/models.dart';
import '../../widgets/ui.dart';
import '../../app.dart';
import '../downloads/download_manager.dart';

Future<void> showResultSheet(BuildContext context, MediaInfo info) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (_) => ResultSheet(info: info),
  );
}

class ResultSheet extends StatefulWidget {
  const ResultSheet({super.key, required this.info});
  final MediaInfo info;
  @override
  State<ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<ResultSheet> {
  late final Set<MediaItem> _selected;

  MediaInfo get info => widget.info;

  @override
  void initState() {
    super.initState();
    _selected = info.isGallery ? info.items.where((i) => i.isImage || i.isVideo).toSet() : {info.items.first};
  }

  void _toggle(MediaItem item) {
    setState(() {
      if (info.isGallery) {
        _selected.contains(item) ? _selected.remove(item) : _selected.add(item);
      } else {
        _selected
          ..clear()
          ..add(item);
      }
    });
  }

  void _save() {
    if (_selected.isEmpty) return;
    final items = info.items.where(_selected.contains).toList(); // keep carousel order
    context.read<DownloadManager>().enqueue(info, items);
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(items.length > 1 ? 'Downloading ${items.length} items' : 'Download started'),
        action: SnackBarAction(label: 'VIEW', textColor: Palette.brand, onPressed: () => shellTab.value = 1),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final accent = info.source.color;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
      decoration: const BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Palette.line, borderRadius: BorderRadius.circular(4))),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, Space.lg),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Preview(info: info),
              const SizedBox(height: Space.lg + 2),
              Text(info.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyles.h2),
              if (info.author != null) ...[
                const SizedBox(height: 6),
                Text(info.author!, style: TextStyles.small.copyWith(color: accent)),
              ],
              const SizedBox(height: Space.xl),
              Row(children: [
                MonoLabel(info.isGallery ? '${info.items.length} items · tap to pick' : 'Choose format'),
                const Spacer(),
                if (info.isGallery)
                  Pressable(
                    onTap: () => setState(() {
                      if (_selected.length == info.items.length) {
                        _selected.clear();
                      } else {
                        _selected.addAll(info.items);
                      }
                    }),
                    child: MonoLabel(_selected.length == info.items.length ? 'None' : 'All', color: Palette.text),
                  ),
              ]),
              const SizedBox(height: Space.md),
              if (info.isGallery)
                _GalleryGrid(items: info.items, selected: _selected, onToggle: _toggle, accent: accent)
              else
                for (final item in info.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.sm),
                    child: _FormatRow(item: item, selected: _selected.contains(item), onTap: () => _toggle(item)),
                  ),
            ]),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, bottom + Space.lg),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Palette.line))),
          child: Column(children: [
            VoltButton(
              label: _selected.length > 1
                  ? 'Download ${_selected.length} items'
                  : (_selected.isNotEmpty && _selected.first.isAudio ? 'Download audio' : 'Download'),
              icon: Icons.download_rounded,
              onTap: _selected.isEmpty ? null : _save,
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.info});
  final MediaInfo info;

  @override
  Widget build(BuildContext context) {
    final h = info.vertical ? 300.0 : 200.0;
    return SizedBox(
      height: h,
      width: double.infinity,
      child: Stack(fit: StackFit.expand, children: [
        MediaThumb(url: info.thumbnail ?? info.items.first.thumb, radius: Radii.lg, source: info.source),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.lg),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.45, 1],
              colors: [Color(0x000B0A0F), Color(0xCC0B0A0F)],
            ),
          ),
        ),
        Positioned(left: 12, top: 12, child: SourcePill(info.source, kind: info.kindLabel, onMedia: true)),
        if (info.duration != null)
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Palette.bg.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(100)),
              child: Text(formatDuration(info.duration), style: TextStyles.number.copyWith(fontSize: 12)),
            ),
          ),
      ]),
    );
  }
}

class _FormatRow extends StatelessWidget {
  const _FormatRow({required this.item, required this.selected, required this.onTap});
  final MediaItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = item.isAudio ? Icons.graphic_eq_rounded : (item.isImage ? Icons.photo_outlined : Icons.play_arrow_rounded);
    final meta = [item.ext.toUpperCase(), if (item.bytes != null) formatBytes(item.bytes), if (item.detail != null) item.detail!].join(' · ');
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.base,
        curve: Motion.curve,
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: selected ? Palette.volt.withValues(alpha: 0.07) : Palette.bg,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: selected ? Palette.volt : Palette.line, width: selected ? 1.4 : 1),
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: Palette.surfaceHi, borderRadius: BorderRadius.circular(Radii.sm)),
            child: Icon(icon, color: selected ? Palette.volt : Palette.muted, size: 22),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.label, style: TextStyles.title.copyWith(fontFamily: Fonts.display, fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 2),
              MonoLabel(meta),
            ]),
          ),
          AnimatedContainer(
            duration: Motion.base,
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? Palette.volt : Colors.transparent,
              border: Border.all(color: selected ? Palette.volt : Palette.faint, width: 1.6),
            ),
            child: selected ? const Icon(Icons.check_rounded, size: 16, color: Palette.voltInk) : null,
          ),
        ]),
      ),
    );
  }
}

class _GalleryGrid extends StatelessWidget {
  const _GalleryGrid({required this.items, required this.selected, required this.onToggle, required this.accent});
  final List<MediaItem> items;
  final Set<MediaItem> selected;
  final ValueChanged<MediaItem> onToggle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.8),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final it = items[i];
        final on = selected.contains(it);
        return Pressable(
          onTap: () => onToggle(it),
          child: Stack(fit: StackFit.expand, children: [
            MediaThumb(url: it.thumb, radius: Radii.sm),
            AnimatedContainer(
              duration: Motion.fast,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.sm),
                border: Border.all(color: on ? Palette.volt : Colors.transparent, width: 2.4),
                color: on ? Colors.transparent : Palette.bg.withValues(alpha: 0.5),
              ),
            ),
            if (it.isVideo) const Positioned(left: 6, bottom: 6, child: Icon(Icons.play_circle_fill_rounded, color: Palette.text, size: 20)),
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(shape: BoxShape.circle, color: on ? Palette.volt : Palette.bg.withValues(alpha: 0.6), border: Border.all(color: Palette.text, width: on ? 0 : 1.4)),
                child: on ? const Icon(Icons.check_rounded, size: 15, color: Palette.voltInk) : null,
              ),
            ),
          ]),
        );
      },
    );
  }
}
