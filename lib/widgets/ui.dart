import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sources.dart';
import '../core/tokens.dart';

/// Every tappable thing in Pluck goes through this: a soft scale-down and a light haptic.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.onLongPress, this.scale = 0.96, this.enabled = true});
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && (widget.onTap != null || widget.onLongPress != null);
    return Semantics(
      button: true,
      enabled: active,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: active ? (_) => _set(true) : null,
        onTapUp: active ? (_) => _set(false) : null,
        onTapCancel: active ? () => _set(false) : null,
        onTap: active
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap?.call();
              }
            : null,
        onLongPress: active && widget.onLongPress != null
            ? () {
                HapticFeedback.mediumImpact();
                widget.onLongPress!.call();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: Motion.fast,
          curve: Motion.curve,
          child: AnimatedOpacity(
            opacity: widget.enabled ? 1 : 0.4,
            duration: Motion.fast,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Typographic stand-in for each app: a tinted square with its two-letter monogram.
class MonogramTile extends StatelessWidget {
  const MonogramTile(this.source, {super.key, this.size = 44, this.filled = false});
  final Source source;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Motion.base,
      curve: Motion.curve,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? source.color : source.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Text(
        source.mono,
        style: TextStyle(
          fontFamily: Fonts.display,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.38,
          letterSpacing: -0.5,
          height: 1,
          color: filled ? Palette.voltInk : source.color,
        ),
      ),
    );
  }
}

class SourcePill extends StatelessWidget {
  const SourcePill(this.source, {super.key, this.kind, this.onMedia = false});
  final Source source;
  final String? kind;
  final bool onMedia; // sitting on a photo: solid dark backing so the label stays readable

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(
        color: onMedia ? Palette.bg.withValues(alpha: 0.82) : source.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        MonogramTile(source, size: 22, filled: true),
        const SizedBox(width: 8),
        Text(
          kind == null ? source.label : '${source.label} · $kind',
          style: TextStyles.small.copyWith(color: onMedia ? Palette.text : source.color, fontWeight: FontWeight.w700),
        ),
      ]),
    );
  }
}

class MonoLabel extends StatelessWidget {
  const MonoLabel(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: TextStyles.label.copyWith(color: color ?? Palette.muted));
}

/// The primary action. Volt is reserved for this and for success.
class VoltButton extends StatelessWidget {
  const VoltButton({super.key, required this.label, this.icon, this.onTap, this.loading = false, this.height = 60});
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool loading;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: loading ? null : onTap,
      enabled: onTap != null || loading,
      child: AnimatedContainer(
        duration: Motion.base,
        height: height,
        decoration: BoxDecoration(color: Palette.volt, borderRadius: BorderRadius.circular(Radii.md)),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: Motion.fast,
          child: loading
              ? const SizedBox(
                  key: ValueKey('l'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.6, color: Palette.voltInk),
                )
              : Row(key: const ValueKey('t'), mainAxisSize: MainAxisSize.min, children: [
                  Text(label, style: TextStyles.button.copyWith(color: Palette.voltInk)),
                  if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 20, color: Palette.voltInk)],
                ]),
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, this.icon, this.onTap, this.height = 60, this.color});
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Palette.text;
    return Pressable(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: Space.lg),
        decoration: BoxDecoration(
          color: Palette.surfaceHi,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: Palette.line),
        ),
        alignment: Alignment.center,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 19, color: c), const SizedBox(width: 8)],
          Text(label, style: TextStyles.button.copyWith(color: c, fontSize: 15)),
        ]),
      ),
    );
  }
}

class IconCircle extends StatelessWidget {
  const IconCircle({super.key, required this.icon, this.onTap, this.size = 44, this.tooltip});
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Pressable(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Palette.surface,
            shape: BoxShape.circle,
            border: Border.all(color: Palette.line),
          ),
          child: Icon(icon, size: size * 0.45, color: Palette.text),
        ),
      ),
    );
  }
}

/// The download button that fills like liquid. Text flips colour exactly where the fill passes it.
class LiquidButton extends StatelessWidget {
  const LiquidButton({
    super.key,
    required this.progress,
    required this.idleLabel,
    required this.onTap,
    this.done = false,
    this.error = false,
    this.accent = Palette.volt,
  });

  /// null = idle, -1 = indeterminate, 0..1 = progress
  final double? progress;
  final String idleLabel;
  final VoidCallback? onTap;
  final bool done;
  final bool error;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final pv = p ?? 0.0;
    final working = p != null && !done;
    final label = done
        ? 'Saved'
        : error
            ? 'Try again'
            : !working
                ? idleLabel
                : pv < 0
                    ? 'Plucking…'
                    : '${(pv * 100).floor()}%';

    Widget content(Color fg) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (done) ...[Icon(Icons.check_rounded, color: fg, size: 22), const SizedBox(width: 8)],
          Text(
            label,
            style: (working && pv >= 0 ? TextStyles.number.copyWith(fontSize: 20) : TextStyles.button.copyWith(fontSize: 17))
                .copyWith(color: fg),
          ),
          if (!working && !done && !error) ...[const SizedBox(width: 8), Icon(Icons.south_rounded, color: fg, size: 20)],
        ]);

    return Pressable(
      onTap: working || done ? null : onTap,
      enabled: true,
      scale: 0.97,
      child: SizedBox(
        height: 64,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.md),
          child: LayoutBuilder(builder: (context, c) {
            final fill = done || (!working && !error) ? 1.0 : (p == null || p < 0 ? 0.0 : p);
            return TweenAnimationBuilder<double>(
              tween: Tween(end: fill),
              duration: Motion.slow,
              curve: Motion.curve,
              builder: (context, v, _) => Stack(fit: StackFit.expand, children: [
                Container(color: error ? Palette.danger.withValues(alpha: 0.16) : Palette.surfaceHi, child: content(error ? Palette.danger : Palette.text)),
                if (working && pv < 0) LinearProgressIndicator(color: accent.withValues(alpha: 0.35), backgroundColor: Colors.transparent),
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: v,
                    child: SizedBox(width: c.maxWidth, child: Container(color: accent, child: content(Palette.voltInk))),
                  ),
                ),
              ]),
            );
          }),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.onTrailing});
  final String title;
  final String? trailing;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.page),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: Text(title, style: TextStyles.h2)),
        if (trailing != null)
          Pressable(onTap: onTrailing, child: MonoLabel(trailing!, color: Palette.text)),
      ]),
    );
  }
}

/// Rounded media thumbnail that never shows a broken image.
class Thumb extends StatelessWidget {
  const Thumb({super.key, this.file, this.url, this.radius = Radii.sm, this.source, this.fit = BoxFit.cover});
  final String? file;
  final String? url;
  final double radius;
  final Source? source;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Container(
          color: (source?.color ?? Palette.muted).withValues(alpha: 0.10),
          alignment: Alignment.center,
          child: source == null
              ? const Icon(Icons.image_outlined, color: Palette.faint)
              : Text(source!.mono,
                  style: TextStyle(fontFamily: Fonts.display, fontWeight: FontWeight.w800, fontSize: 22, color: source!.color.withValues(alpha: 0.7))),
        );
    Widget child;
    if (file != null && File(file!).existsSync()) {
      child = Image.file(File(file!), fit: fit, errorBuilder: (_, __, ___) => fallback(), cacheWidth: 600);
    } else if (url != null) {
      child = Image.network(url!, fit: fit, errorBuilder: (_, __, ___) => fallback(), cacheWidth: 800);
    } else {
      child = fallback();
    }
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
  }
}

void toast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: error ? Palette.danger : Palette.volt, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
      margin: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, 100),
    ));
}
