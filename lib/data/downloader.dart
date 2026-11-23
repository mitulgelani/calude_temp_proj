import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';
import '../core/sources.dart';
import 'history_repo.dart';
import 'models.dart';
import 'native_bridge.dart';

/// Orchestrates a save: engine download → (HD merge happens natively) → thumbnail → gallery → history.
class Downloader {
  Downloader({required this.bridge, required this.history, required this.prefs});
  final NativeBridge bridge;
  final HistoryRepo history;
  final SharedPreferences prefs;
  final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15)));

  bool get saveToGalleryEnabled => prefs.getBool('save_to_gallery') ?? true;
  Future<void> setSaveToGallery(bool v) => prefs.setBool('save_to_gallery', v);

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/Pluck');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static String _slug(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').replaceAll(RegExp(r'-+'), '-');
    final trimmed = cleaned.length > 40 ? cleaned.substring(0, 40) : cleaned;
    return trimmed.replaceAll(RegExp(r'^-|-$'), '').toLowerCase();
  }

  Future<DownloadRecord> download(
    MediaInfo info,
    MediaItem item, {
    required String jobId,
    required void Function(double progress) onProgress,
  }) async {
    final dir = await _dir();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final baseName = '${info.source.name}_${_slug(info.title).isEmpty ? 'media' : _slug(info.title)}_$stamp';

    final path = await bridge.download(
      id: jobId,
      url: info.sourceUrl,
      spec: item.spec,
      outDir: dir.path,
      baseName: baseName,
      onProgress: (done, total) {
        final t = total > 0 ? total : (item.bytes ?? 0);
        onProgress(t > 0 ? (done / t).clamp(0.0, 1.0).toDouble() : -1.0);
      },
    );

    String? thumb;
    if (item.isImage) {
      thumb = path;
    } else {
      final src = item.thumb ?? info.thumbnail;
      if (src != null) {
        try {
          final thumbs = Directory('${dir.path}/.thumbs');
          if (!await thumbs.exists()) await thumbs.create();
          final t = '${thumbs.path}/$baseName.jpg';
          await _dio.download(src, t);
          thumb = t;
        } catch (_) {
          thumb = null; // a missing thumbnail never fails a save
        }
      }
    }

    if (saveToGalleryEnabled) await saveToGallery(path, item.kind);

    final record = DownloadRecord(
      id: '$stamp',
      title: item.isImage && info.isGallery ? '${info.title} · ${item.label}' : info.title,
      source: info.source,
      kind: item.kind,
      ext: path.split('.').last,
      path: path,
      thumb: thumb,
      bytes: await File(path).length(),
      createdAt: DateTime.now(),
    );
    await history.add(record);
    return record;
  }

  /// WhatsApp statuses are already on the phone: copy out of the hidden folder, then gallery + history.
  Future<DownloadRecord> saveStatus(StatusItem item) async {
    final cached = await bridge.copyToCache(item);
    final dir = await _dir();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final ext = item.name.contains('.') ? item.name.split('.').last : (item.isVideo ? 'mp4' : 'jpg');
    final path = '${dir.path}/whatsapp_status_$stamp.$ext';
    await File(cached).copy(path);
    final kind = item.isVideo ? 'video' : 'image';
    await saveToGallery(path, kind);
    final record = DownloadRecord(
      id: '$stamp',
      title: item.isVideo ? 'WhatsApp status video' : 'WhatsApp status photo',
      source: Source.whatsapp,
      kind: kind,
      ext: ext,
      path: path,
      thumb: item.isVideo ? null : path,
      bytes: item.size,
      createdAt: DateTime.now(),
    );
    await history.add(record);
    return record;
  }

  static Future<void> saveToGallery(String path, String kind) async {
    if (kind == 'audio') return; // audio stays in the Library; share it from there
    if (!await Gal.hasAccess(toAlbum: true)) {
      final ok = await Gal.requestAccess(toAlbum: true);
      if (!ok) throw const PluckException('Allow photo access so Pluck can save to your gallery.');
    }
    if (kind == 'image') {
      await Gal.putImage(path, album: Config.albumName);
    } else {
      await Gal.putVideo(path, album: Config.albumName);
    }
  }
}
