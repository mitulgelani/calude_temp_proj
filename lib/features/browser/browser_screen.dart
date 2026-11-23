import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/sources.dart';
import '../../core/tokens.dart';
import '../../data/models.dart';
import '../../data/native_bridge.dart';
import '../../widgets/ui.dart';
import '../result/result_sheet.dart';
import '../source/source_screen.dart';

/// Pluck's built-in browser. Browse any supported site (log in if you like — it stays on this phone),
/// and a download button floats over whatever Reel, post or video is on screen.
class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key, required this.url, this.source});
  final String url;
  final Source? source;

  static Future<void> open(BuildContext context, String url, {Source? source}) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => BrowserScreen(url: url, source: source)));

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _Target {
  const _Target(this.url, this.source);
  final String url;
  final Source source;
  @override
  bool operator ==(Object o) => o is _Target && o.url == url;
  @override
  int get hashCode => url.hashCode;
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final WebViewController _web;
  String _url = '';
  int _progress = 0;
  bool _canBack = false;
  bool _canForward = false;
  _Target? _target;
  bool _busy = false;

  // Watches the page: finds the video nearest the centre of the screen and the post link it belongs to.
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
    var media=null; if(best){ var s=best.currentSrc||best.src; if(s&&s.indexOf('http')===0) media=s; }
    try { Pluck.postMessage(JSON.stringify({url:location.href, post:post, media:media, video:!!best})); } catch(e) {}
  }
  window.__pluck=scan; setInterval(scan,1000); document.addEventListener('scroll',function(){clearTimeout(window.__pt);window.__pt=setTimeout(scan,150);},true); scan();
})();
''';

  @override
  void initState() {
    super.initState();
    _url = widget.url;
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Palette.bg)
      ..addJavaScriptChannel('Pluck', onMessageReceived: (m) => _onScan(m.message))
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
        onPageStarted: (u) => _onUrl(u),
        onPageFinished: (u) {
          _onUrl(u);
          _web.runJavaScript(_scanner);
        },
        onUrlChange: (c) {
          if (c.url != null) _onUrl(c.url!);
          _web.runJavaScript(_scanner);
        },
        onNavigationRequest: (req) {
          // Keep users inside Pluck: block "open in app" intents and app-store redirects.
          final u = req.url;
          if (u.startsWith('http')) return NavigationDecision.navigate;
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _onUrl(String u) async {
    final back = await _web.canGoBack();
    final fwd = await _web.canGoForward();
    if (!mounted) return;
    setState(() {
      _url = u;
      _canBack = back;
      _canForward = fwd;
    });
    _pickTarget(page: u);
  }

  void _onScan(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      _pickTarget(page: m['url'] as String? ?? _url, post: m['post'] as String?);
    } catch (_) {}
  }

  /// The download button appears only when there's one specific thing to download.
  void _pickTarget({required String page, String? post}) {
    _Target? t;
    final pageSrc = Source.detect(page);
    if (pageSrc != null && Source.isItem(page)) {
      t = _Target(page, pageSrc);
    } else if (post != null && Source.isItem(post)) {
      t = _Target(post, Source.detect(post)!);
    }
    if (t != _target && mounted) setState(() => _target = t);
  }

  Future<void> _download() async {
    final t = _target;
    if (t == null || _busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final info = await context.read<NativeBridge>().resolve(LinkParser.normalize(t.url));
      if (!mounted) return;
      if (info.items.isEmpty) throw const PluckException('Nothing downloadable found here.');
      await showResultSheet(context, info);
    } on PluckException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _back() async {
    if (await _web.canGoBack()) {
      await _web.goBack();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final src = Source.detect(_url) ?? widget.source;
    final host = Uri.tryParse(_url)?.host.replaceFirst('www.', '') ?? '';
    final accent = _target?.source.color ?? Palette.volt;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: Palette.bg,
        body: Column(children: [
          // ── Address bar ──
          Container(
            padding: EdgeInsets.fromLTRB(Space.md, pad.top + Space.sm, Space.md, Space.sm),
            color: Palette.bg,
            child: Row(children: [
              IconCircle(icon: Icons.close_rounded, size: 40, onTap: () => Navigator.of(context).pop(), tooltip: 'Close'),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Pressable(
                  scale: 0.98,
                  onTap: () => _editUrl(context),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: Space.md),
                    decoration: BoxDecoration(
                      color: Palette.surface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Palette.line),
                    ),
                    child: Row(children: [
                      if (src != null) MonogramTile(src, size: 24, filled: true) else const Icon(Icons.lock_outline_rounded, size: 16, color: Palette.muted),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: Text(host, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyles.title.copyWith(fontSize: 14)),
                      ),
                      Pressable(onTap: () => _web.reload(), child: const Icon(Icons.refresh_rounded, size: 20, color: Palette.muted)),
                    ]),
                  ),
                ),
              ),
              if (src != null && src != Source.whatsapp) ...[
                const SizedBox(width: Space.sm),
                IconCircle(
                  icon: Icons.help_outline_rounded,
                  size: 40,
                  tooltip: 'How to',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SourceScreen(source: src))),
                ),
              ],
            ]),
          ),
          SizedBox(
            height: 2,
            child: _progress < 100
                ? LinearProgressIndicator(value: _progress / 100, color: accent, backgroundColor: Palette.bg)
                : const SizedBox.shrink(),
          ),
          // ── Page ──
          Expanded(
            child: Stack(children: [
              WebViewWidget(controller: _web),
              Positioned(
                right: Space.page,
                bottom: Space.xl,
                child: AnimatedSwitcher(
                  duration: Motion.base,
                  switchInCurve: Motion.curve,
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
                  child: _target == null ? const SizedBox.shrink(key: ValueKey('none')) : _Fab(key: ValueKey(_target!.url), target: _target!, busy: _busy, onTap: _download),
                ),
              ),
            ]),
          ),
          // ── Toolbar ──
          Container(
            padding: EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, pad.bottom + Space.sm),
            decoration: const BoxDecoration(color: Palette.bg, border: Border(top: BorderSide(color: Palette.line))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _ToolIcon(Icons.arrow_back_rounded, enabled: _canBack, onTap: _back),
              _ToolIcon(Icons.arrow_forward_rounded, enabled: _canForward, onTap: () => _web.goForward()),
              _ToolIcon(Icons.home_rounded, onTap: () => _web.loadRequest(Uri.parse((src ?? widget.source)?.home ?? widget.url))),
              _ToolIcon(Icons.ios_share_rounded, onTap: () => Clipboard.setData(ClipboardData(text: _url)).then((_) {
                    if (context.mounted) toast(context, 'Link copied');
                  })),
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _editUrl(BuildContext context) async {
    final c = TextEditingController(text: _url);
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Palette.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl))),
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, MediaQuery.viewInsetsOf(sheet).bottom + Space.xl),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const MonoLabel('Go to or search'),
          const SizedBox(height: Space.md),
          TextField(
            controller: c,
            autofocus: true,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onSubmitted: (v) => Navigator.pop(sheet, v),
            style: TextStyles.title,
            decoration: InputDecoration(
              filled: true,
              fillColor: Palette.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: BorderSide.none),
            ),
          ),
        ]),
      ),
    );
    if (value != null && value.trim().isNotEmpty) await _web.loadRequest(Uri.parse(webAddress(value)));
  }
}

/// Turns typed text into a URL: links stay links, anything else becomes a Google search.
String webAddress(String input) {
  final t = input.trim();
  final found = LinkParser.extract(t);
  if (found != null) return found;
  if (!t.contains(' ') && t.contains('.')) return 'https://$t';
  return 'https://www.google.com/search?q=${Uri.encodeQueryComponent(t)}';
}

class _Fab extends StatelessWidget {
  const _Fab({super.key, required this.target, required this.busy, required this.onTap});
  final _Target target;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: busy ? null : onTap,
      enabled: true,
      child: Container(
        height: 60,
        padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
        decoration: BoxDecoration(
          color: Palette.volt,
          borderRadius: BorderRadius.circular(100),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: Palette.voltInk, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Palette.volt))
                : const Icon(Icons.south_rounded, color: Palette.volt, size: 22),
          ),
          const SizedBox(width: 10),
          Text(busy ? 'Reading…' : 'Save ${target.source.kindOf(target.url).toLowerCase()}',
              style: TextStyles.button.copyWith(color: Palette.voltInk, fontSize: 15)),
        ]),
      ),
    );
  }
}

class _ToolIcon extends StatelessWidget {
  const _ToolIcon(this.icon, {required this.onTap, this.enabled = true});
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: enabled ? onTap : null,
        enabled: enabled,
        child: SizedBox(width: 52, height: 44, child: Icon(icon, color: Palette.text, size: 22)),
      );
}
