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

  // Finds the video nearest the centre of the screen and the post link it belongs to.
  static const _scanner = r'''
(function(){
  if (window.__pluck) { window.__pluck(); return; }
  function dist(el){ var r=el.getBoundingClientRect(); if(r.bottom<0||r.top>innerHeight||r.width<40) return 1e9;
    return Math.abs((r.top+r.bottom)/2 - innerHeight/2); }
  var SEL='a[href*="/reel/"],a[href*="/p/"],a[href*="/video/"],a[href*="/status/"],a[href*="/pin/"],a[href*="/shorts/"],a[href*="watch?v="],a[href*="/videos/"]';
  function scan(){
    var best=null,bd=1e9;
    document.querySelectorAll('video').forEach(function(v){var d=dist(v); if(d<bd){bd=d;best=v;}});
    var post=null;
    if(best){ var n=best; for(var i=0;i<30&&n&&!post;i++){ if(n.querySelector){ var a=n.querySelector(SEL); if(a) post=a.href; } n=n.parentElement; } }
    if(!post){ var pd=1e9; document.querySelectorAll(SEL).forEach(function(a){var d=dist(a); if(d<pd){pd=d;post=a.href;}}); if(pd>innerHeight*0.6) post=null; }
    try { Pluck.postMessage(JSON.stringify({url:location.href, post:post})); } catch(e) {}
  }
  window.__pluck=scan; setInterval(scan,1000);
  document.addEventListener('scroll',function(){clearTimeout(window.__pt);window.__pt=setTimeout(scan,150);},true); scan();
})();
''';

  WebViewController _create() {
    final c = WebViewController();
    c
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..addJavaScriptChannel('Pluck', onMessageReceived: (m) {
        try {
          final j = jsonDecode(m.message) as Map<String, dynamic>;
          _pick(j['url'] as String? ?? url ?? '', j['post'] as String?);
        } catch (_) {}
      })
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) {
          progress = p;
          notifyListeners();
        },
        onPageStarted: (u) => _setUrl(u),
        onPageFinished: (u) async {
          _setUrl(u);
          c.runJavaScript(_scanner);
          final t = await c.getTitle();
          if (t != null && t.isNotEmpty) title = t;
          _store.addHistory(title, u);
          notifyListeners();
        },
        onUrlChange: (ch) {
          if (ch.url != null) _setUrl(ch.url!);
          c.runJavaScript(_scanner);
        },
        // Stay inside Pluck: block "open in app" / app-store intents.
        onNavigationRequest: (req) => req.url.startsWith('http') ? NavigationDecision.navigate : NavigationDecision.prevent,
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

  void load(String u) {
    url = u;
    title = Uri.tryParse(u)?.host ?? u;
    target = null;
    web.loadRequest(Uri.parse(u));
    notifyListeners();
  }

  void goStart() {
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
