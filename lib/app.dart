import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/tokens.dart';
import 'data/native_bridge.dart';
import 'features/downloads/download_manager.dart';
import 'features/downloads/downloads_screens.dart';
import 'features/home/home_page.dart';
import 'features/tabs/tab_page.dart';
import 'features/tabs/tabs_controller.dart';
import 'widgets/ui.dart';

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

  void _receive(String text) => context.read<TabsController>().incoming.value = text;

  Future<void> _onBack() async {
    if (_index == 1) {
      final handled = await context.read<TabsController>().current.back();
      if (!handled) shellTab.value = 0;
      return;
    }
    if (_index != 0) {
      shellTab.value = 0;
      return;
    }
    SystemNavigator.pop();
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
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Palette.dark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: Palette.surface,
            systemNavigationBarIconBrightness: Palette.dark ? Brightness.light : Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: Palette.bg,
            resizeToAvoidBottomInset: true,
            body: IndexedStack(index: _index, children: [HomePage(), TabPage(), ProgressScreen(), FinishedScreen()]),
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
      (Icons.home_outlined, Icons.home_rounded, 'Home'),
      (Icons.explore_outlined, Icons.explore_rounded, 'Browser'),
      (Icons.downloading_outlined, Icons.downloading_rounded, 'Downloads'),
      (Icons.video_library_outlined, Icons.video_library_rounded, 'Saved'),
    ];
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(color: Palette.surface, border: Border(top: BorderSide(color: Palette.line))),
      padding: EdgeInsets.fromLTRB(8, 8, 8, bottom + 8),
      child: Row(children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
            child: Pressable(
              onTap: () => onTap(i),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AnimatedContainer(
                  duration: Motion.base,
                  curve: Motion.curve,
                  width: 60,
                  height: 32,
                  decoration: BoxDecoration(
                    color: i == index ? Palette.accentSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Badge(
                    isLabelVisible: i == 2 && running > 0,
                    backgroundColor: Palette.accent,
                    label: Text('$running'),
                    child: Icon(i == index ? items[i].$2 : items[i].$1, size: 23, color: i == index ? Palette.accent : Palette.muted),
                  ),
                ),
                SizedBox(height: 4),
                Text(items[i].$3,
                    style: TextStyle(
                      fontFamily: Fonts.body,
                      fontSize: 12,
                      fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                      color: i == index ? Palette.ink : Palette.muted,
                    )),
              ]),
            ),
          ),
      ]),
    );
  }
}
