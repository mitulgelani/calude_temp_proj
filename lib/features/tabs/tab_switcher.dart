import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/sources.dart';
import '../../core/tokens.dart';
import 'tabs_controller.dart';

class TabSwitcher extends StatelessWidget {
  const TabSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = context.read<TabsController>();
    return ListenableBuilder(
      listenable: tabs,
      builder: (context, _) => Scaffold(
        backgroundColor: Palette.bg,
        appBar: AppBar(
          backgroundColor: Palette.brand,
          foregroundColor: Colors.white,
          title: Text('${tabs.tabs.length} ${tabs.tabs.length == 1 ? 'tab' : 'tabs'}'),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Palette.brand,
          foregroundColor: Colors.white,
          onPressed: () {
            tabs.newTab();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('New tab'),
        ),
        body: ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          itemCount: tabs.tabs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final t = tabs.tabs[i];
            final src = Source.detect(t.url ?? '');
            final on = i == tabs.index;
            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  tabs.select(i);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: on ? Palette.brand : Palette.line, width: on ? 2 : 1),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: src?.color ?? Palette.brand, borderRadius: BorderRadius.circular(10)),
                      child: src == null
                          ? const Icon(Icons.home_rounded, color: Colors.white)
                          : Text(src.mono, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t.isStart ? 'Start page' : t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        if (t.url != null)
                          Text(t.url!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Palette.faint)),
                      ]),
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded, color: Palette.muted), onPressed: () => tabs.close(t)),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
