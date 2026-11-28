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

/// App icon tile: brand gradient squircle with the app's glyph.
class AppIcon extends StatelessWidget {
  const AppIcon(this.source, {super.key, this.size = 60, this.shadow = true});
  final Source source;
  final double size;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final (icon, gradient) = brandLook(source);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: shadow
            ? [BoxShadow(color: gradient.colors.last.withValues(alpha: 0.30), blurRadius: size * 0.28, offset: Offset(0, size * 0.1))]
            : null,
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.46),
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
      decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.44, color: Colors.white),
    );
  }
}
