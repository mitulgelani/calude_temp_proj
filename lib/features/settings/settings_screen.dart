import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config.dart';
import '../../core/tokens.dart';
import '../../data/downloader.dart';
import '../../data/native_bridge.dart';
import '../../widgets/ui.dart';
import '../library/library_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _engine = '…';
  bool _updating = false;

  NativeBridge get bridge => context.read<NativeBridge>();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!bridge.supported) return;
    final v = await bridge.engineVersion();
    if (mounted) setState(() => _engine = v);
  }

  Future<void> _update() async {
    setState(() => _updating = true);
    try {
      final v = await bridge.updateEngine();
      if (mounted) toast(context, 'Engine $v downloaded. Restart Pluck to use it.');
    } catch (e) {
      if (mounted) toast(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final downloader = context.read<Downloader>();
    return Scaffold(
      body: ListView(padding: EdgeInsets.fromLTRB(Space.page, pad.top + Space.md, Space.page, pad.bottom + Space.xxl), children: [
        Row(children: [IconCircle(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context), tooltip: 'Back')]),
        const SizedBox(height: Space.xl),
        const Text('Settings', style: TextStyles.hero),
        const SizedBox(height: Space.section - Space.md),
        const MonoLabel('Saving'),
        const SizedBox(height: Space.md),
        _Group(children: [
          _Row(
            title: 'Save to gallery',
            subtitle: 'Photos and videos also go to the “${Config.albumName}” album.',
            trailing: _VoltSwitch(
              value: downloader.saveToGalleryEnabled,
              onChanged: (v) async {
                await downloader.setSaveToGallery(v);
                setState(() {});
              },
            ),
          ),
        ]),
        const SizedBox(height: Space.xl),
        const MonoLabel('Download engine'),
        const SizedBox(height: Space.md),
        _Group(children: [
          _Row(
            title: 'yt-dlp $_engine',
            subtitle: 'Open-source, runs on your phone. When a site changes, update here. It’s free.',
            trailing: _updating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Palette.volt))
                : Pressable(onTap: _update, child: const MonoLabel('Update', color: Palette.volt)),
          ),
        ]),
        const SizedBox(height: Space.xl),
        const MonoLabel('Storage'),
        const SizedBox(height: Space.md),
        _Group(children: [
          _Row(
            title: 'Clear library',
            subtitle: 'Removes Pluck’s copies. Your gallery isn’t touched.',
            trailing: Pressable(
              onTap: () async {
                await context.read<LibraryCubit>().clear();
                if (context.mounted) toast(context, 'Library cleared');
              },
              child: const MonoLabel('Clear', color: Palette.danger),
            ),
          ),
        ]),
        const SizedBox(height: Space.section),
        Text('Pluck ${Config.version}', style: TextStyles.h2.copyWith(color: Palette.faint)),
        const SizedBox(height: Space.sm),
        Text(
          'Runs entirely on your phone. No login, no account, no servers, no tracking. Pluck isn’t affiliated with Instagram, YouTube, TikTok, Facebook, Pinterest or WhatsApp. Save only content you own or have permission to use.',
          style: TextStyles.small.copyWith(color: Palette.faint),
        ),
      ]),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: Palette.line),
        ),
        child: Column(children: children),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.title, this.subtitle, this.trailing, this.leading});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(Space.lg + 2),
        child: Row(children: [
          if (leading != null) ...[leading!, const SizedBox(width: Space.md + 2)],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyles.title),
              if (subtitle != null) ...[const SizedBox(height: 3), Text(subtitle!, style: TextStyles.small)],
            ]),
          ),
          if (trailing != null) ...[const SizedBox(width: Space.md), trailing!],
        ]),
      );
}

class _VoltSwitch extends StatelessWidget {
  const _VoltSwitch({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: Motion.base,
          curve: Motion.curve,
          width: 52,
          height: 32,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: value ? Palette.volt : Palette.surfaceHi, borderRadius: BorderRadius.circular(100), border: Border.all(color: value ? Palette.volt : Palette.line)),
          child: AnimatedAlign(
            duration: Motion.base,
            curve: Motion.curve,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(width: 24, height: 24, decoration: BoxDecoration(color: value ? Palette.voltInk : Palette.muted, shape: BoxShape.circle)),
          ),
        ),
      );
}
