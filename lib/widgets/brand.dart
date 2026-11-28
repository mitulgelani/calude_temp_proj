import 'package:flutter/material.dart';

import '../core/sources.dart';
import '../core/tokens.dart';

/// Font Awesome Free brand icons (CC BY 4.0), bundled as assets/fonts/fa-brands-400.ttf.
abstract final class Brand {
  static const _f = 'FABrands';
  static const facebook = IconData(0xf39e, fontFamily: _f);
  static const instagram = IconData(0xf16d, fontFamily: _f);
  static const vimeo = IconData(0xf27d, fontFamily: _f);
  static const dailymotion = IconData(0xe052, fontFamily: _f);
  static const youtube = IconData(0xf167, fontFamily: _f);
  static const tiktok = IconData(0xe07b, fontFamily: _f);
  static const x = IconData(0xe61b, fontFamily: _f);
  static const whatsapp = IconData(0xf232, fontFamily: _f);
  static const pinterest = IconData(0xf231, fontFamily: _f);
}

(IconData, LinearGradient) brandLook(Source s) {
  LinearGradient g(List<int> c, {Alignment begin = Alignment.topCenter, Alignment end = Alignment.bottomCenter}) =>
      LinearGradient(begin: begin, end: end, colors: [for (final v in c) Color(v)]);
  return switch (s) {
    Source.facebook => (Brand.facebook, g([0xFF18ACFE, 0xFF0163E0])),
    Source.instagram => (
        Brand.instagram,
        g([0xFF5B51D8, 0xFFC13584, 0xFFE1306C, 0xFFFD1D1D, 0xFFF77737, 0xFFFCAF45], begin: Alignment.topRight, end: Alignment.bottomLeft)
      ),
    Source.vimeo => (Brand.vimeo, g([0xFF1AB7EA, 0xFF0F9FD1])),
    Source.dailymotion => (Brand.dailymotion, g([0xFF2A7BFF, 0xFF0A4BC7])),
    Source.youtube => (Brand.youtube, g([0xFFFF2A2A, 0xFFD90000])),
    Source.tiktok => (Brand.tiktok, g([0xFF2A2A2E, 0xFF000000])),
    Source.twitter => (Brand.x, g([0xFF2A2A2E, 0xFF000000])),
    Source.whatsapp => (Brand.whatsapp, g([0xFF5FFC7B, 0xFF22C340])),
    Source.pinterest => (Brand.pinterest, g([0xFFF0213A, 0xFFC8001A])),
  };
}

String appName(Source s) => s == Source.twitter ? 'X' : s.label;

/// App icon tile: a glossy 3D squircle — brand gradient, top sheen, bottom shade, rim light, lifted shadow.
class AppIcon extends StatelessWidget {
  const AppIcon(this.source, {super.key, this.size = 60, this.shadow = true});
  final Source source;
  final double size;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final (icon, gradient) = brandLook(source);
    final r = BorderRadius.circular(size * 0.3);
    final base = gradient.colors.last;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: shadow
            ? [
                BoxShadow(color: base.withValues(alpha: 0.38), blurRadius: size * 0.32, offset: Offset(0, size * 0.14)),
                BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: size * 0.06, offset: Offset(0, size * 0.03)),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(fit: StackFit.expand, children: [
          DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
          // bottom shade: gives the tile depth
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.45, 1],
                colors: [Colors.black.withValues(alpha: 0), Colors.black.withValues(alpha: 0.22)],
              ),
            ),
          ),
          // glossy sheen across the top half
          Positioned(
            left: -size * 0.15,
            right: -size * 0.15,
            top: -size * 0.55,
            height: size * 1.0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withValues(alpha: 0.42), Colors.white.withValues(alpha: 0.04)],
                ),
              ),
            ),
          ),
          // rim light
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: r,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: size * 0.018),
            ),
          ),
          Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: size * 0.46,
              shadows: [
                Shadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: size * 0.08, offset: Offset(0, size * 0.035)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// Small round site badge used in lists.
class SiteBubble extends StatelessWidget {
  const SiteBubble(this.source, {super.key, this.size = 36});
  final Source? source;
  final double size;
  @override
  Widget build(BuildContext context) {
    final s = source;
    if (s == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: Palette.surfaceHi, shape: BoxShape.circle),
        child: Icon(Icons.public_rounded, size: size * 0.52, color: Palette.muted),
      );
    }
    final (icon, gradient) = brandLook(s);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: gradient.colors.last.withValues(alpha: 0.30), blurRadius: size * 0.25, offset: Offset(0, size * 0.08))],
      ),
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.30), Colors.white.withValues(alpha: 0), Colors.black.withValues(alpha: 0.15)],
        ),
      ),
      child: Icon(icon, size: size * 0.44, color: Colors.white,
          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: size * 0.08, offset: Offset(0, size * 0.03))]),
    );
  }
}
