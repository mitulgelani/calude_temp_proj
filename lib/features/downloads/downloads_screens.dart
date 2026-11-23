import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/sources.dart';
import '../../core/tokens.dart';
import '../../data/models.dart';
import '../../widgets/ui.dart';
import '../library/library_cubit.dart';
import 'download_manager.dart';

class _Header extends StatelessWidget {
  const _Header(this.title, {this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      color: Palette.brand,
      padding: EdgeInsets.fromLTRB(20, top + 14, 8, 14),
      child: Row(children: [
        Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700))),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 72, color: Palette.line),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Palette.muted)),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Palette.faint, height: 1.4)),
          ]),
        ),
      );
}

Widget _thumb(String? file, String? url, Source? source) => SizedBox(
      width: 72,
      height: 72,
      child: MediaThumb(file: file, url: url, source: source, radius: 10),
    );

// ── Progress ─────────────────────────────────────────────────────────────────
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.read<DownloadManager>();
    return ListenableBuilder(
      listenable: m,
      builder: (context, _) => Column(children: [
        const _Header('Progress'),
        Expanded(
          child: m.jobs.isEmpty
              ? const _Empty(Icons.download_rounded, 'No downloads in progress', 'Open a site from the Tab page and tap the red download button, or paste a link in the search bar.')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: m.jobs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Palette.line),
                  itemBuilder: (_, i) => _JobRow(m.jobs[i]),
                ),
        ),
      ]),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow(this.job);
  final DownloadJob job;

  @override
  Widget build(BuildContext context) {
    final m = context.read<DownloadManager>();
    final failed = job.status == JobStatus.failed;
    final p = job.progress;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      child: Row(children: [
        _thumb(null, job.thumb, job.source),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(job.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (!failed)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: p < 0 ? null : p,
                  minHeight: 6,
                  color: Palette.brand,
                  backgroundColor: Palette.surfaceHi,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              failed ? job.error ?? 'Failed' : '${p < 0 ? 'Starting…' : '${(p * 100).floor()}%'}  ·  ${job.item.label} · ${job.item.ext.toUpperCase()}',
              maxLines: 2,
              style: TextStyle(fontSize: 13, color: failed ? Palette.danger : Palette.muted),
            ),
          ]),
        ),
        if (failed)
          IconButton(tooltip: 'Retry', icon: const Icon(Icons.refresh_rounded, color: Palette.brand), onPressed: () => m.retry(job)),
        IconButton(tooltip: 'Cancel', icon: const Icon(Icons.close_rounded, color: Palette.muted), onPressed: () => m.cancel(job)),
      ]),
    );
  }
}

// ── Finished ─────────────────────────────────────────────────────────────────
class FinishedScreen extends StatelessWidget {
  const FinishedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(builder: (context, s) {
      final cubit = context.read<LibraryCubit>();
      return Column(children: [
        _Header('Finished',
            trailing: PopupMenuButton<KindFilter>(
              icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
              color: Colors.white,
              initialValue: s.kind,
              onSelected: cubit.setKind,
              itemBuilder: (_) => const [
                PopupMenuItem(value: KindFilter.all, child: Text('All')),
                PopupMenuItem(value: KindFilter.video, child: Text('Videos')),
                PopupMenuItem(value: KindFilter.image, child: Text('Photos')),
                PopupMenuItem(value: KindFilter.audio, child: Text('Audio')),
              ],
            )),
        Expanded(
          child: s.visible.isEmpty
              ? const _Empty(Icons.folder_rounded, 'Nothing here yet', 'Finished downloads are saved to your gallery and listed here.')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: s.visible.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Palette.line),
                  itemBuilder: (_, i) => _FinishedRow(s.visible[i]),
                ),
        ),
      ]);
    });
  }
}

class _FinishedRow extends StatelessWidget {
  const _FinishedRow(this.r);
  final DownloadRecord r;

  @override
  Widget build(BuildContext context) {
    final d = r.createdAt;
    final date = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: () => OpenFilex.open(r.path),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(children: [
          Stack(children: [
            _thumb(r.thumb, null, r.source),
            if (r.kind == 'video')
              const Positioned.fill(child: Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 30))),
            if (r.kind == 'audio')
              const Positioned.fill(child: Center(child: Icon(Icons.music_note_rounded, color: Palette.brand, size: 30))),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('${r.source.label} · ${r.ext.toUpperCase()} · ${formatBytes(r.bytes)}', style: const TextStyle(fontSize: 13, color: Palette.muted)),
              Text(date, style: const TextStyle(fontSize: 12, color: Palette.faint)),
            ]),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Palette.muted),
            color: Colors.white,
            onSelected: (v) {
              switch (v) {
                case 'open':
                  OpenFilex.open(r.path);
                case 'share':
                  Share.shareXFiles([XFile(r.path)]);
                case 'delete':
                  context.read<LibraryCubit>().remove(r);
                  toast(context, 'Deleted from Pluck (gallery copy kept)');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'open', child: Text('Open')),
              PopupMenuItem(value: 'share', child: Text('Share')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ]),
      ),
    );
  }
}
