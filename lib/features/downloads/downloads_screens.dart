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
  const _Header(this.title, {this.trailing, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(22, top + 18, 10, 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyles.h1.copyWith(fontSize: 30)),
            if (subtitle != null) ...[SizedBox(height: 4), Text(subtitle!, style: TextStyles.small)],
          ]),
        ),
        ThemeSwitch(size: 40),
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
          padding: EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: Palette.brand.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(icon, size: 44, color: Palette.brand),
            ),
            SizedBox(height: 16),
            Text(title, style: TextStyles.h2.copyWith(fontSize: 19)),
            SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Palette.faint, height: 1.4)),
          ]),
        ),
      );
}

Widget _thumb(String? file, String? url, Source? source) => SizedBox(
      width: 64,
      height: 64,
      child: MediaThumb(file: file, url: url, source: source, radius: 12),
    );

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}

// ── Progress ─────────────────────────────────────────────────────────────────
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.read<DownloadManager>();
    return ListenableBuilder(
      listenable: m,
      builder: (context, _) => Column(children: [
        _Header('Downloads', subtitle: m.jobs.isEmpty ? 'Nothing downloading right now' : '${m.runningCount} in progress'),
        Expanded(
          child: m.jobs.isEmpty
              ? _Empty(Icons.download_rounded, 'No downloads yet', 'Paste a link on Home, or open an app in the Browser and tap the orange download button.')
              : ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: m.jobs.length,
                  separatorBuilder: (_, __) => Divider(height: 1, indent: 94, color: Palette.line),
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
      padding: EdgeInsets.fromLTRB(12, 12, 4, 12),
      child: Row(children: [
        _thumb(null, job.thumb, job.source),
        SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(job.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyles.title.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
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
            SizedBox(height: 6),
            Text(
              failed ? job.error ?? 'Failed' : '${p < 0 ? 'Starting…' : '${(p * 100).floor()}%'}  ·  ${job.item.label} · ${job.item.ext.toUpperCase()}',
              maxLines: 2,
              style: TextStyle(fontSize: 13, color: failed ? Palette.danger : Palette.muted),
            ),
          ]),
        ),
        if (failed)
          IconButton(tooltip: 'Retry', icon: Icon(Icons.refresh_rounded, color: Palette.brand), onPressed: () => m.retry(job)),
        IconButton(tooltip: 'Cancel', icon: Icon(Icons.close_rounded, color: Palette.muted), onPressed: () => m.cancel(job)),
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
        _Header('Saved',
            subtitle: '${s.records.length} ${s.records.length == 1 ? 'file' : 'files'} · ${formatBytes(s.totalBytes)}',
            trailing: PopupMenuButton<KindFilter>(
              icon: Icon(Icons.tune_rounded, color: Palette.ink),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Palette.surface,
              initialValue: s.kind,
              onSelected: cubit.setKind,
              itemBuilder: (_) => [
                PopupMenuItem(value: KindFilter.all, child: Text('All')),
                PopupMenuItem(value: KindFilter.video, child: Text('Videos')),
                PopupMenuItem(value: KindFilter.image, child: Text('Photos')),
                PopupMenuItem(value: KindFilter.audio, child: Text('Audio')),
              ],
            )),
        Expanded(
          child: s.visible.isEmpty
              ? _Empty(Icons.video_library_rounded, 'Nothing saved yet', 'Everything you download lands here and in your gallery.')
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: s.visible.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10),
                  itemBuilder: (_, i) => _Card(child: _FinishedRow(s.visible[i])),
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
        padding: EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Row(children: [
          Stack(children: [
            _thumb(r.thumb, null, r.source),
            if (r.kind == 'video')
              Positioned.fill(child: Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 30))),
            if (r.kind == 'audio')
              Positioned.fill(child: Center(child: Icon(Icons.music_note_rounded, color: Palette.brand, size: 30))),
          ]),
          SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyles.title.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text('${r.source.label} · ${r.ext.toUpperCase()} · ${formatBytes(r.bytes)}', style: TextStyle(fontSize: 13, color: Palette.muted)),
              Text(date, style: TextStyle(fontSize: 12, color: Palette.faint)),
            ]),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: Palette.muted),
            color: Palette.surface,
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
            itemBuilder: (_) => [
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
