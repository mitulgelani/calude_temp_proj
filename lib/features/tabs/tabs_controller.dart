import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/sources.dart';
import '../../data/web_store.dart';

/// One browser tab. Null [url] = the start page (favourite sites, bookmarks, history).
class BrowserTab extends ChangeNotifier {
  BrowserTab(this._store, {String? url}) {
    if (url != null) load(url);
  }

  final WebStore _store;
  final id = '${DateTime.now().microsecondsSinceEpoch}';
  String? url;
  String title = 'New tab';
  int progress = 100;

  /// The one post / video on screen that the download button would save.
  String? target;
  WebViewController? _web;

  bool get isStart => url == null;
  WebViewController get web => _web ??= _create();

  /// Pluck's page script (assets/pluck_page.js): captures media from the site's own data,
  /// hides "open app" prompts, and reports what's on screen.
  static String script = '';
  static const userAgent =
      'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36';

  /// Media keys (Instagram shortcodes / ids) the page has captured so far.
  Set<String> codes = {};

  /// Direct http(s) video URL of the player on screen (TikTok, Facebook…), if any.
  String? mediaSrc;

  /// Set when a pasted link should download as soon as the page has captured it.
  String? pendingCode;

  void _inject() {
    if (script.isNotEmpty) _web?.runJavaScript(script);
  }

  WebViewController _create() {
    final c = WebViewController();
    c
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(userAgent)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..addJavaScriptChannel('Pluck', onMessageReceived: (m) {
        try {
          final j = jsonDecode(m.message) as Map<String, dynamic>;
          codes = ((j['codes'] as List?) ?? const []).map((e) => '$e').toSet();
          mediaSrc = j['media'] as String?;
          _pick(j['url'] as String? ?? url ?? '', j['post'] as String?);
          if (pendingCode != null && codes.contains(pendingCode)) notifyListeners();
        } catch (_) {}
      })
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) {
          progress = p;
          notifyListeners();
        },
        onPageStarted: (u) {
          _setUrl(u);
          _inject();
        },
        onPageFinished: (u) async {
          _setUrl(u);
          _inject();
          final t = await c.getTitle();
          if (t != null && t.isNotEmpty) title = t;
          _store.addHistory(title, u);
          notifyListeners();
        },
        onUrlChange: (ch) {
          if (ch.url != null) _setUrl(ch.url!);
          _inject();
        },
        // Stay inside Pluck: block "open in app" / app-store intents.
        onNavigationRequest: (req) {
          if (!req.url.startsWith('http')) return NavigationDecision.prevent; // intent://, market:// → stay here
          final m = RegExp(r'^https?://(?:www\.|m\.)?instagram\.com/(?:[A-Za-z0-9._]+/)?reel/([A-Za-z0-9_-]{5,})').firstMatch(req.url);
          if (m != null && req.isMainFrame) {
            c.loadRequest(Uri.parse('https://www.instagram.com/reels/${m.group(1)}/'));
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));
    return c;
  }

  void _setUrl(String u) {
    if (url == null) return; // user went back to the start page
    url = u;
    _pick(u, null);
    notifyListeners();
  }

  void _pick(String page, String? post) {
    String? t;
    if (Source.isItem(page)) {
      t = page;
    } else if (post != null && Source.isItem(post)) {
      t = post;
    }
    if (t != target) {
      target = t;
      notifyListeners();
    }
  }

  /// Asks the page for the media it captured under [key] (JSON) — null if not captured.
  Future<String?> captured(String key) async {
    if (_web == null) return null;
    try {
      final r = await _web!.runJavaScriptReturningResult("window.__pluckCurrent ? window.__pluckCurrent('$key') : 'null'");
      Object? v = r;
      if (v is String) {
        try {
          final d = jsonDecode(v);
          v = d is String ? d : jsonEncode(d); // Android returns the JS string JSON-encoded
        } catch (_) {}
      }
      final text = v?.toString();
      if (text == null || text == 'null' || text.isEmpty) return null;
      return text;
    } catch (_) {
      return null;
    }
  }

  void load(String u) {
    url = u;
    title = Uri.tryParse(u)?.host ?? u;
    target = null;
    codes = {};
    mediaSrc = null;
    web.loadRequest(Uri.parse(u));
    notifyListeners();
  }

  void goStart() {
    pendingCode = null;
    url = null;
    title = 'New tab';
    target = null;
    notifyListeners();
  }

  /// Returns false when there's nowhere left to go back to.
  Future<bool> back() async {
    if (isStart) return false;
    if (await web.canGoBack()) {
      await web.goBack();
    } else {
      goStart();
    }
    return true;
  }
}

class TabsController extends ChangeNotifier {
  TabsController(this.store) {
    tabs.add(BrowserTab(store));
  }
  final WebStore store;
  final tabs = <BrowserTab>[];
  int index = 0;

  /// Links shared into Pluck from other apps.
  final incoming = ValueNotifier<String?>(null);

  BrowserTab get current => tabs[index];

  BrowserTab newTab({String? url}) {
    final t = BrowserTab(store, url: url);
    tabs.add(t);
    index = tabs.length - 1;
    notifyListeners();
    return t;
  }

  void select(int i) {
    index = i;
    notifyListeners();
  }

  void close(BrowserTab t) {
    final i = tabs.indexOf(t);
    tabs.remove(t);
    t.dispose();
    if (tabs.isEmpty) tabs.add(BrowserTab(store));
    if (index >= tabs.length || i <= index) index = (index - 1).clamp(0, tabs.length - 1);
    notifyListeners();
  }
}
