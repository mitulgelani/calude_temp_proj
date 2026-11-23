import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class HistoryRepo {
  HistoryRepo(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'history_v1';

  List<DownloadRecord> all() {
    final raw = _prefs.getStringList(_key) ?? const [];
    return raw
        .map((s) {
          try {
            return DownloadRecord.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map));
          } catch (_) {
            return null;
          }
        })
        .whereType<DownloadRecord>()
        .where((r) => File(r.path).existsSync())
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> add(DownloadRecord r) async {
    final list = _prefs.getStringList(_key) ?? <String>[];
    list.add(jsonEncode(r.toJson()));
    await _prefs.setStringList(_key, list);
  }

  Future<void> remove(DownloadRecord r) async {
    final list = (_prefs.getStringList(_key) ?? <String>[])
        .where((s) => !s.contains('"id":"${r.id}"'))
        .toList();
    await _prefs.setStringList(_key, list);
    for (final p in [r.path, if (r.thumb != null && r.thumb != r.path) r.thumb!]) {
      final f = File(p);
      if (await f.exists()) await f.delete();
    }
  }

  Future<void> clear() async {
    for (final r in all()) {
      await remove(r);
    }
    await _prefs.remove(_key);
  }
}
