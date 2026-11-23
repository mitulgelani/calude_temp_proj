import 'package:equatable/equatable.dart';

import '../core/sources.dart';

class PluckException implements Exception {
  const PluckException(this.message, [this.detail]);
  final String message;
  final String? detail; // technical reason, shown under "Details" so users can report it
  @override
  String toString() => message;
}

/// One downloadable option: a quality, the audio track, or one photo of a carousel.
class MediaItem extends Equatable {
  const MediaItem({
    required this.id,
    required this.kind,
    required this.label,
    required this.ext,
    required this.spec,
    this.bytes,
    this.thumb,
    this.detail,
  });

  final String id;
  final String kind; // video | image | audio
  final String label; // "1080p", "Audio", "Photo 2"
  final String ext;
  final int? bytes;
  final String? thumb;
  final String? detail; // "No watermark", "HD"
  final Map<String, dynamic> spec; // opaque recipe handed back to the engine

  bool get isVideo => kind == 'video';
  bool get isImage => kind == 'image';
  bool get isAudio => kind == 'audio';

  factory MediaItem.fromJson(Map<String, dynamic> j) => MediaItem(
        id: j['id'] as String,
        kind: j['kind'] as String,
        label: j['label'] as String,
        ext: j['ext'] as String,
        bytes: (j['bytes'] as num?)?.toInt(),
        thumb: j['thumb'] as String?,
        detail: j['detail'] as String?,
        spec: Map<String, dynamic>.from(j['spec'] as Map),
      );

  @override
  List<Object?> get props => [id, label];
}

class MediaInfo {
  const MediaInfo({
    required this.source,
    required this.sourceUrl,
    required this.title,
    required this.kindLabel,
    required this.items,
    this.author,
    this.thumbnail,
    this.duration,
    this.vertical = false,
  });

  final Source source;
  final String sourceUrl;
  final String title;
  final String kindLabel;
  final String? author;
  final String? thumbnail;
  final Duration? duration;
  final bool vertical;
  final List<MediaItem> items;

  bool get isGallery => items.where((i) => i.isImage).length > 1;

  factory MediaInfo.fromJson(Map<String, dynamic> j, String url) {
    final source = Source.byName(j['source'] as String?) ?? Source.detect(url) ?? Source.instagram;
    final secs = (j['duration'] as num?)?.toDouble();
    return MediaInfo(
      source: source,
      sourceUrl: url,
      title: ((j['title'] as String?)?.trim().isNotEmpty ?? false) ? (j['title'] as String).trim() : '${source.label} ${source.kindOf(url)}',
      kindLabel: (j['kind_label'] as String?) ?? source.kindOf(url),
      author: j['author'] as String?,
      thumbnail: j['thumbnail'] as String?,
      duration: secs == null ? null : Duration(milliseconds: (secs * 1000).round()),
      vertical: j['vertical'] == true,
      items: (j['items'] as List).map((e) => MediaItem.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }
}

class DownloadRecord extends Equatable {
  const DownloadRecord({
    required this.id,
    required this.title,
    required this.source,
    required this.kind,
    required this.ext,
    required this.path,
    required this.createdAt,
    this.thumb,
    this.bytes,
  });

  final String id;
  final String title;
  final Source source;
  final String kind;
  final String ext;
  final String path;
  final String? thumb;
  final int? bytes;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'source': source.name,
        'kind': kind,
        'ext': ext,
        'path': path,
        'thumb': thumb,
        'bytes': bytes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DownloadRecord.fromJson(Map<String, dynamic> j) => DownloadRecord(
        id: j['id'] as String,
        title: j['title'] as String,
        source: Source.byName(j['source'] as String?) ?? Source.instagram,
        kind: j['kind'] as String,
        ext: j['ext'] as String,
        path: j['path'] as String,
        thumb: j['thumb'] as String?,
        bytes: (j['bytes'] as num?)?.toInt(),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  @override
  List<Object?> get props => [id];
}

class StatusItem extends Equatable {
  const StatusItem({required this.uri, required this.name, required this.mime, required this.modified, required this.size});
  final String uri;
  final String name;
  final String mime;
  final DateTime modified;
  final int size;

  bool get isVideo => mime.startsWith('video') || name.toLowerCase().endsWith('.mp4');

  factory StatusItem.fromMap(Map<String, dynamic> m) => StatusItem(
        uri: m['uri'] as String,
        name: m['name'] as String,
        mime: (m['mime'] as String?) ?? '',
        modified: DateTime.fromMillisecondsSinceEpoch((m['modified'] as num?)?.toInt() ?? 0),
        size: (m['size'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [uri, modified];
}

String formatBytes(int? b) {
  if (b == null || b <= 0) return '—';
  if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
  if (b < 1024 * 1024 * 1024) return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(b / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

String formatDuration(Duration? d) {
  if (d == null) return '';
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$m:$s' : '${d.inMinutes}:$s';
}
