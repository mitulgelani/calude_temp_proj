import 'package:flutter/foundation.dart';

import '../../core/sources.dart';
import '../../data/downloader.dart';
import '../../data/models.dart';
import '../../data/native_bridge.dart';

enum JobStatus { running, failed }

class DownloadJob {
  DownloadJob({required this.id, required this.info, required this.item});
  final String id;
  final MediaInfo info;
  final MediaItem item;
  double progress = -1; // -1 = starting / unknown size
  JobStatus status = JobStatus.running;
  String? error;

  String get title => item.isImage && info.isGallery ? '${info.title} · ${item.label}' : info.title;
  Source get source => info.source;
  String? get thumb => item.thumb ?? info.thumbnail;
}

/// Runs downloads in the background. Active ones show in the Progress tab; finished ones move to Finished.
class DownloadManager extends ChangeNotifier {
  DownloadManager(this._downloader, this._bridge, this._onFinished);
  final Downloader _downloader;
  final NativeBridge _bridge;
  final VoidCallback _onFinished;

  final jobs = <DownloadJob>[];
  int get runningCount => jobs.where((j) => j.status == JobStatus.running).length;

  void enqueue(MediaInfo info, List<MediaItem> items) {
    for (final item in items) {
      final job = DownloadJob(id: '${DateTime.now().microsecondsSinceEpoch}${item.id}', info: info, item: item);
      jobs.insert(0, job);
      _run(job);
    }
    notifyListeners();
  }

  Future<void> _run(DownloadJob job) async {
    job
      ..status = JobStatus.running
      ..progress = -1
      ..error = null;
    notifyListeners();
    try {
      await _downloader.download(job.info, job.item, jobId: job.id, onProgress: (p) {
        job.progress = p;
        notifyListeners();
      });
      jobs.remove(job);
      _onFinished();
    } on PluckException catch (e) {
      job
        ..status = JobStatus.failed
        ..error = e.message;
    } catch (_) {
      job
        ..status = JobStatus.failed
        ..error = 'Download failed. Tap retry.';
    }
    notifyListeners();
  }

  void retry(DownloadJob job) => _run(job);

  void cancel(DownloadJob job) {
    if (job.status == JobStatus.running) _bridge.cancel(job.id);
    jobs.remove(job);
    notifyListeners();
  }
}
