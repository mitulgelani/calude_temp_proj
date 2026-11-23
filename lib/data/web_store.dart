import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebEntry {
  const WebEntry(this.title, this.url, this.time);
  final String title;
  final String url;
  final DateTime time;

  Map<String, dynamic> toJson() => {'t': title, 'u': url, 'at': time.millisecondsSinceEpoch};
  factory WebEntry.fromJson(Map<String, dynamic> j) =>
      WebEntry(j['t'] as String? ?? '', j['u'] as String, DateTime.fromMillisecondsSinceEpoch(j['at'] as int? ?? 0));
}

/// Browser history + bookmarks, kept on the phone.
class WebStore extends ChangeNotifier {
  WebStore(this._prefs) {
    history = _read('web_history');
    bookmarks = _read('web_bookmarks');
  }
  final SharedPreferences _prefs;
  late List<WebEntry> history;
  late List<WebEntry> bookmarks;

  List<WebEntry> _read(String key) {
    try {
      return (_prefs.getStringList(key) ?? const [])
          .map((s) => WebEntry.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(String key, List<WebEntry> list) =>
      _prefs.setStringList(key, list.map((e) => jsonEncode(e.toJson())).toList());

  void addHistory(String title, String url) {
    if (!url.startsWith('http')) return;
    history.removeWhere((e) => e.url == url);
    history.insert(0, WebEntry(title.trim().isEmpty ? Uri.parse(url).host : title.trim(), url, DateTime.now()));
    if (history.length > 150) history = history.sublist(0, 150);
    _write('web_history', history);
    notifyListeners();
  }

  void removeHistory(WebEntry e) {
    history.remove(e);
    _write('web_history', history);
    notifyListeners();
  }

  void clearHistory() {
    history = [];
    _write('web_history', history);
    notifyListeners();
  }

  bool isBookmarked(String? url) => url != null && bookmarks.any((b) => b.url == url);

  void toggleBookmark(String title, String url) {
    if (isBookmarked(url)) {
      bookmarks.removeWhere((b) => b.url == url);
    } else {
      bookmarks.insert(0, WebEntry(title.trim().isEmpty ? Uri.parse(url).host : title.trim(), url, DateTime.now()));
    }
    _write('web_bookmarks', bookmarks);
    notifyListeners();
  }

  void removeBookmark(WebEntry e) {
    bookmarks.remove(e);
    _write('web_bookmarks', bookmarks);
    notifyListeners();
  }
}
