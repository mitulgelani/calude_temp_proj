import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app.dart';
import '../../core/sources.dart';
import '../../core/tokens.dart';
import '../../widgets/brand.dart';
import '../../widgets/ui.dart';
import '../status/status_screen.dart';
import '../tabs/tabs_controller.dart';

/// "How to download from <app>" — shown when an app icon is tapped, before opening the site.
Future<void> showGuideSheet(BuildContext context, Source source) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Color(0x66111113),
      builder: (_) => _GuideSheet(source: source),
    );

class _GuideSheet extends StatefulWidget {
  const _GuideSheet({required this.source});
  final Source source;
  @override
  State<_GuideSheet> createState() => _GuideSheetState();
}

class _GuideSheetState extends State<_GuideSheet> {
  int _kind = 0;
  final _user = TextEditingController();

  Source get s => widget.source;
  KindGuide get g => s.guides[_kind];
  bool get isStatus => s == Source.whatsapp;

  void _open() {
    final nav = Navigator.of(context);
    nav.pop();
    if (isStatus) {
      nav.push(MaterialPageRoute(builder: (_) => Scaffold(body: StatusScreen())));
      return;
    }
    final tabs = context.read<TabsController>();
    if (tabs.current.isStart) {
      tabs.current.load(s.home);
    } else {
      tabs.newTab(url: s.home);
    }
    shellTab.value = 1;
  }

  Future<void> _pasteLink() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '';
    if (!mounted) return;
    if (text.isEmpty) {
      toast(context, 'Copy a ${appName(s)} link first, then tap here.', error: true);
      return;
    }
    Navigator.of(context).pop();
    context.read<TabsController>().incoming.value = text;
  }

  void _profile() {
    final name = _user.text.trim().replaceAll('@', '');
    if (name.isEmpty) return;
    Navigator.of(context).pop();
    context.read<TabsController>().incoming.value = '@$name';
  }

  @override
  void dispose() {
    _user.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(22, 10, 22, bottom + 18),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: Palette.line, borderRadius: BorderRadius.circular(4)))),
        SizedBox(height: 22),
        Row(children: [
          AppIcon(s, size: 54),
          SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isStatus ? 'Status saver' : 'Download from ${appName(s)}', style: TextStyles.h2.copyWith(fontSize: 22)),
              SizedBox(height: 3),
              Text(s.pitch, maxLines: 2, style: TextStyles.small),
            ]),
          ),
        ]),
        if (s.guides.length > 1) ...[
          SizedBox(height: 20),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: s.guides.length,
              separatorBuilder: (_, __) => SizedBox(width: 8),
              itemBuilder: (_, i) {
                final on = i == _kind;
                return Pressable(
                  onTap: () => setState(() => _kind = i),
                  child: AnimatedContainer(
                    duration: Motion.base,
                    curve: Motion.curve,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: on ? Palette.ink : Palette.surfaceHi,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(s.guides[i].name,
                        style: TextStyles.button.copyWith(fontSize: 13.5, color: on ? Palette.onInk : Palette.text)),
                  ),
                );
              },
            ),
          ),
        ],
        SizedBox(height: 18),
        AnimatedSwitcher(
          duration: Motion.base,
          child: Container(
            key: ValueKey(_kind),
            width: double.infinity,
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(color: Palette.bg, borderRadius: BorderRadius.circular(22)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var i = 0; i < g.steps.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i == g.steps.length - 1 ? 0 : 14),
                  child: Row(children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Palette.ink, shape: BoxShape.circle),
                      child: Text('${i + 1}', style: TextStyle(fontFamily: Fonts.body, fontWeight: FontWeight.w700, fontSize: 13, color: Palette.onInk)),
                    ),
                    SizedBox(width: 12),
                    Expanded(child: Text(g.steps[i], style: TextStyles.title.copyWith(fontSize: 15, fontWeight: FontWeight.w500))),
                  ]),
                ),
              if (g.note != null) ...[
                SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline_rounded, size: 17, color: Palette.muted),
                  SizedBox(width: 8),
                  Expanded(child: Text(g.note!, style: TextStyles.small.copyWith(fontSize: 12.5))),
                ]),
              ],
            ]),
          ),
        ),
        SizedBox(height: 18),
        if (g.usernameMode) ...[
          Container(
            height: 56,
            padding: EdgeInsets.only(left: 16, right: 6),
            decoration: BoxDecoration(color: Palette.surfaceHi, borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              Text('@', style: TextStyles.h2.copyWith(color: Palette.muted, fontSize: 19)),
              SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _user,
                  autocorrect: false,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _profile(),
                  style: TextStyles.title,
                  decoration: InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: 'username', hintStyle: TextStyles.title.copyWith(color: Palette.faint)),
                ),
              ),
              SizedBox(width: 120, child: VoltButton(label: 'Get photo', height: 44, onTap: _profile)),
            ]),
          ),
        ] else ...[
          VoltButton(
            label: isStatus ? 'Open status saver' : 'Open ${appName(s)}',
            icon: Icons.arrow_forward_rounded,
            onTap: _open,
          ),
          if (!isStatus) ...[
            SizedBox(height: 10),
            GhostButton(label: 'I already copied a link', icon: Icons.content_paste_rounded, height: 52, onTap: _pasteLink),
          ],
        ],
      ]),
    );
  }
}
