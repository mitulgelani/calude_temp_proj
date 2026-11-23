import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/tokens.dart';
import 'data/native_bridge.dart';
import 'features/downloads/download_manager.dart';
import 'features/downloads/downloads_screens.dart';
import 'features/tabs/tab_page.dart';
import 'features/tabs/tabs_controller.dart';

/// Which bottom tab is showing. Any screen (including sheets and pushed pages) can switch it.
final shellTab = ValueNotifier<int>(0);

/// Bottom bar: Tab (browser + start page) · Progress · Finished.
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  StreamSubscription<String>? _shareSub;
  int get _index => shellTab.value;

  @override
  void initState() {
    super.initState();
    final bridge = context.read<NativeBridge>();
    bridge.takeSharedText().then((t) {
      if (t != null && mounted) _receive(t);
    });
    _shareSub = bridge.sharedText.listen(_receive);
    shellTab.addListener(_onTab);
  }

  void _onTab() => setState(() {});

  void _receive(String text) {
    shellTab.value = 0;
    context.read<TabsController>().incoming.value = text;
  }

  Future<void> _onBack() async {
    if (_index != 0) {
      shellTab.value = 0;
      return;
    }
    final handled = await context.read<TabsController>().current.back();
    if (!handled) SystemNavigator.pop();
  }

  @override
  void dispose() {
    _shareSub?.cancel();
    shellTab.removeListener(_onTab);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.read<DownloadManager>();
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onBack();
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: Colors.white,
            resizeToAvoidBottomInset: true,
            body: IndexedStack(index: _index, children: const [TabPage(), ProgressScreen(), FinishedScreen()]),
            bottomNavigationBar: ListenableBuilder(
              listenable: manager,
              builder: (context, _) => _BottomBar(
                index: _index,
                running: manager.runningCount,
                onTap: (i) => shellTab.value = i,
              ),
            ),
          ),
        ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.running, required this.onTap});
  final int index;
  final int running;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.filter_none_rounded, 'Tab'),
      (Icons.download_rounded, 'Progress'),
      (Icons.folder_rounded, 'Finished'),
    ];
    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Palette.line))),
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      height: 68 + MediaQuery.paddingOf(context).bottom,
      child: Row(children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
            child: InkWell(
              onTap: () => onTap(i),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Badge(
                  isLabelVisible: i == 1 && running > 0,
                  backgroundColor: Palette.fab,
                  label: Text('$running'),
                  child: Icon(items[i].$1, size: 28, color: i == index ? Palette.brand : Palette.faint),
                ),
                const SizedBox(height: 3),
                Text(items[i].$2,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                      color: i == index ? Palette.brand : Palette.faint,
                    )),
              ]),
            ),
          ),
      ]),
    );
  }
}
