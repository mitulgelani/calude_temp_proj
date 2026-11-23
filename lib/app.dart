import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/tokens.dart';
import 'data/native_bridge.dart';
import 'features/home/home_screen.dart';
import 'features/home/link_cubit.dart';
import 'features/library/library_screen.dart';
import 'features/status/status_screen.dart';
import 'widgets/ui.dart';

/// Tab controller for the whole app. Screens call [ShellScope.of(context).go(i)].
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.go, required this.index, required super.child});
  final void Function(int) go;
  final int index;
  static ShellScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ShellScope>()!;
  @override
  bool updateShouldNotify(ShellScope old) => old.index != index;
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;
  StreamSubscription<String>? _shareSub;

  @override
  void initState() {
    super.initState();
    final bridge = context.read<NativeBridge>();
    // Links shared into Pluck from Instagram/TikTok/etc. land straight in the Portal and auto-resolve.
    bridge.takeSharedText().then((t) {
      if (t != null && mounted) _receive(t);
    });
    _shareSub = bridge.sharedText.listen(_receive);
  }

  void _receive(String text) {
    setState(() => _index = 0);
    context.read<LinkCubit>().setInput(text, auto: true);
  }

  @override
  void dispose() {
    _shareSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return ShellScope(
      index: _index,
      go: (i) => setState(() => _index = i),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(children: [
          IndexedStack(index: _index, children: const [HomeScreen(), StatusScreen(), LibraryScreen()]),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 120 + bottomInset,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x000B0A0F), Palette.bg],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: Space.page,
            right: Space.page,
            bottom: bottomInset + Space.md,
            child: _NavBar(index: _index, onTap: (i) => setState(() => _index = i)),
          ),
        ]),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.south_rounded, 'Pluck'),
    (Icons.blur_circular_rounded, 'Statuses'),
    (Icons.grid_view_rounded, 'Library'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Palette.line),
        boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 30, offset: Offset(0, 12))],
      ),
      child: Row(children: [
        for (var i = 0; i < _items.length; i++)
          Expanded(
            flex: i == index ? 14 : 10,
            child: Pressable(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: Motion.base,
                curve: Motion.curve,
                decoration: BoxDecoration(
                  color: i == index ? Palette.text : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                alignment: Alignment.center,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_items[i].$1, size: 20, color: i == index ? Palette.bg : Palette.muted),
                  AnimatedSize(
                    duration: Motion.base,
                    curve: Motion.curve,
                    child: i == index
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(_items[i].$2, style: TextStyles.button.copyWith(color: Palette.bg, fontSize: 14)),
                          )
                        : const SizedBox.shrink(),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}
