import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/tokens.dart';
import '../../data/native_bridge.dart';
import '../../widgets/ui.dart';

/// Instagram's own login page in a WebView. After login, the session cookie is written to a
/// private file inside the app so the on-device engine can open stories. Nothing is uploaded anywhere.
class ConnectInstagramScreen extends StatefulWidget {
  const ConnectInstagramScreen({super.key});
  @override
  State<ConnectInstagramScreen> createState() => _ConnectInstagramScreenState();
}

class _ConnectInstagramScreenState extends State<ConnectInstagramScreen> {
  late final WebViewController _web;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Palette.bg)
      ..setNavigationDelegate(NavigationDelegate(onProgress: (p) => setState(() => _progress = p)))
      ..loadRequest(Uri.parse('https://www.instagram.com/accounts/login/'));
  }

  Future<void> _done() async {
    final ok = await context.read<NativeBridge>().exportInstagramCookies();
    if (!mounted) return;
    if (ok) {
      toast(context, 'Instagram connected');
      Navigator.pop(context, true);
    } else {
      toast(context, 'Log in first, then tap Done.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: Column(children: [
        Container(
          padding: EdgeInsets.fromLTRB(Space.page, top + Space.sm, Space.page, Space.md),
          color: Palette.bg,
          child: Row(children: [
            IconCircle(icon: Icons.close_rounded, onTap: () => Navigator.pop(context), tooltip: 'Close'),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Connect Instagram', style: TextStyles.title),
                Text('Stays on this phone', style: TextStyles.small.copyWith(fontSize: 12)),
              ]),
            ),
            SizedBox(width: 96, child: VoltButton(label: 'Done', height: 44, onTap: _done)),
          ]),
        ),
        if (_progress < 100) LinearProgressIndicator(value: _progress / 100, minHeight: 2, color: Palette.volt, backgroundColor: Palette.bg),
        Expanded(child: WebViewWidget(controller: _web)),
      ]),
    );
  }
}
