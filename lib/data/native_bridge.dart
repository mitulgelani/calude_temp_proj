import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'models.dart';

/// Talks to MainActivity.kt, which runs the on-device engine (yt-dlp inside the app via
/// Chaquopy), merges HD video+audio with Android's MediaMuxer, and reads WhatsApp statuses.
/// No server, no API keys.
class NativeBridge {
  NativeBridge() {
    _ch.setMethodCallHandler(_onCall);
  }

  static const _ch = MethodChannel('pluck/native');
  final _shared = StreamController<String>.broadcast();
  final _progress = <String, void Function(int done, int total)>{};

  bool get supported => Platform.isAndroid;
  Stream<String> get sharedText => _shared.stream;

  Future<dynamic> _onCall(MethodCall call) async {
    switch (call.method) {
      case 'sharedText':
        if (call.arguments is String) _shared.add(call.arguments as String);
      case 'progress':
        final m = Map<String, dynamic>.from(call.arguments as Map);
        _progress[m['id']]?.call((m['done'] as num).toInt(), (m['total'] as num).toInt());
    }
    return null;
  }

  Never _rethrow(PlatformException e) => throw PluckException(e.message ?? 'Something went wrong. Try again.', e.details?.toString());

  // ── Engine ────────────────────────────────────────────────────────────────
  Future<MediaInfo> resolve(String url) async {
    _ensureAndroid();
    try {
      final raw = await _ch.invokeMethod<String>('resolve', {'url': url});
      return MediaInfo.fromJson(Map<String, dynamic>.from(jsonDecode(raw!) as Map), url);
    } on PlatformException catch (e) {
      _rethrow(e);
    }
  }

  /// Media captured from the page open in Pluck's browser.
  Future<MediaInfo> fromPage(String payloadJson, String url) async {
    _ensureAndroid();
    try {
      final raw = await _ch.invokeMethod<String>('fromPage', {'payload': payloadJson, 'url': url});
      return MediaInfo.fromJson(Map<String, dynamic>.from(jsonDecode(raw!) as Map), url);
    } on PlatformException catch (e) {
      _rethrow(e);
    }
  }

  Future<String> download({
    required String id,
    required String url,
    required Map<String, dynamic> spec,
    required String outDir,
    required String baseName,
    required void Function(int done, int total) onProgress,
  }) async {
    _ensureAndroid();
    _progress[id] = onProgress;
    try {
      final path = await _ch.invokeMethod<String>('download', {
        'id': id,
        'url': url,
        'spec': jsonEncode(spec),
        'outDir': outDir,
        'baseName': baseName,
      });
      return path!;
    } on PlatformException catch (e) {
      _rethrow(e);
    } finally {
      _progress.remove(id);
    }
  }

  Future<void> cancel(String id) => _ch.invokeMethod('cancel', {'id': id});
  Future<String> engineVersion() async => (await _ch.invokeMethod<String>('engineVersion')) ?? '—';

  /// Pulls the newest yt-dlp release from GitHub (free). Applied on next launch.
  Future<String> updateEngine() async {
    try {
      return (await _ch.invokeMethod<String>('updateEngine')) ?? '';
    } on PlatformException catch (e) {
      _rethrow(e);
    }
  }

  /// Logs out of every site opened in Pluck's browser.
  Future<void> clearBrowserData() => _ch.invokeMethod('clearBrowserData');

  // ── Share-to-Pluck ────────────────────────────────────────────────────────
  Future<String?> takeSharedText() async => supported ? _ch.invokeMethod<String>('takeSharedText') : null;

  // ── WhatsApp statuses (Storage Access Framework) ─────────────────────────
  Future<String?> pickStatusTree(String variant) async {
    try {
      return await _ch.invokeMethod<String>('pickStatusTree', {'variant': variant});
    } on PlatformException catch (e) {
      _rethrow(e);
    }
  }

  Future<List<StatusItem>> listStatuses(String tree) async {
    final raw = await _ch.invokeListMethod<Map>('listStatuses', {'tree': tree}) ?? [];
    return raw.map((m) => StatusItem.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  final _copyCache = <String, Future<String>>{};
  Future<String> copyToCache(StatusItem item) => _copyCache.putIfAbsent(
        item.uri,
        () async => (await _ch.invokeMethod<String>('copyToCache', {'uri': item.uri, 'name': item.name}))!,
      );

  final _thumbCache = <String, Future<Uint8List?>>{};
  Future<Uint8List?> videoThumb(StatusItem item) =>
      _thumbCache.putIfAbsent(item.uri, () => _ch.invokeMethod<Uint8List>('videoThumb', {'uri': item.uri}));

  void _ensureAndroid() {
    if (!supported) throw PluckException('Pluck’s download engine runs on Android.');
  }
}
