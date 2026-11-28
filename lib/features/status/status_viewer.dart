import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../core/tokens.dart';
import '../../data/downloader.dart';
import '../../data/models.dart';
import '../../data/native_bridge.dart';
import '../../widgets/ui.dart';
import '../library/library_cubit.dart';
import 'status_screen.dart';

class StatusViewer extends StatefulWidget {
  const StatusViewer({super.key, required this.items, required this.initial});
  final List<StatusItem> items;
  final int initial;
  @override
  State<StatusViewer> createState() => _StatusViewerState();
}

class _StatusViewerState extends State<StatusViewer> {
  late final PageController _pages = PageController(initialPage: widget.initial);
  late int _index = widget.initial;
  final _saved = <String>{};
  bool _saving = false;

  StatusItem get current => widget.items[_index];

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<Downloader>().saveStatus(current);
      if (!mounted) return;
      context.read<LibraryCubit>().load();
      setState(() => _saved.add(current.uri));
      toast(context, 'Saved to your gallery');
    } catch (e) {
      if (mounted) toast(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share() async {
    final path = await context.read<NativeBridge>().copyToCache(current);
    await Share.shareXFiles([XFile(path)]);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final saved = _saved.contains(current.uri);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _pages,
          itemCount: widget.items.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => _StatusPage(item: widget.items[i], active: i == _index),
        ),
        Positioned(
          left: Space.page,
          right: Space.page,
          top: pad.top + Space.sm,
          child: Row(children: [
            IconCircle(icon: Icons.close_rounded, onTap: () => Navigator.of(context).pop(), tooltip: 'Close'),
            Spacer(),
            MonoLabel('${_index + 1} / ${widget.items.length} · ${statusAgo(current.modified)} ago', color: Colors.white),
          ]),
        ),
        Positioned(
          left: Space.page,
          right: Space.page,
          bottom: pad.bottom + Space.lg,
          child: Row(children: [
            IconCircle(icon: Icons.ios_share_rounded, onTap: _share, size: 60, tooltip: 'Share'),
            SizedBox(width: Space.md),
            Expanded(
              child: AnimatedSwitcher(
                duration: Motion.base,
                child: saved
                    ? GhostButton(key: ValueKey('saved'), label: 'Saved to gallery', icon: Icons.check_rounded, color: Palette.volt)
                    : VoltButton(key: ValueKey('save'), label: 'Save to gallery', icon: Icons.south_rounded, loading: _saving, onTap: _save),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _StatusPage extends StatefulWidget {
  const _StatusPage({required this.item, required this.active});
  final StatusItem item;
  final bool active;
  @override
  State<_StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<_StatusPage> {
  String? _path;
  VideoPlayerController? _video;

  @override
  void initState() {
    super.initState();
    context.read<NativeBridge>().copyToCache(widget.item).then((p) async {
      if (!mounted) return;
      if (widget.item.isVideo) {
        final c = VideoPlayerController.file(File(p));
        await c.initialize();
        await c.setLooping(true);
        if (!mounted) {
          c.dispose();
          return;
        }
        if (widget.active) c.play();
        setState(() => _video = c);
      }
      setState(() => _path = p);
    });
  }

  @override
  void didUpdateWidget(covariant _StatusPage old) {
    super.didUpdateWidget(old);
    if (_video != null && old.active != widget.active) {
      widget.active ? _video!.play() : _video!.pause();
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_path == null) {
      return Center(child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.4, color: Palette.volt)));
    }
    if (widget.item.isVideo && _video != null) {
      return GestureDetector(
        onTap: () async {
          _video!.value.isPlaying ? await _video!.pause() : await _video!.play();
          if (mounted) setState(() {});
        },
        child: Center(
          child: AspectRatio(
            aspectRatio: _video!.value.aspectRatio,
            child: Stack(fit: StackFit.expand, children: [
              VideoPlayer(_video!),
              if (!_video!.value.isPlaying)
                Center(child: Icon(Icons.play_arrow_rounded, size: 72, color: Color(0xCCF4EFE7))),
            ]),
          ),
        ),
      );
    }
    return InteractiveViewer(child: Center(child: Image.file(File(_path!), fit: BoxFit.contain)));
  }
}
