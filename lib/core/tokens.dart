import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Single source of truth for every visual decision in Pluck.
/// Nothing in the UI uses a raw colour, size or duration — only these.
abstract final class Palette {
  static const ink = Color(0xFF111113); // headlines, dark surfaces
  static const accent = Color(0xFFFF5A1F); // ember: the one action colour
  static const accentSoft = Color(0xFFFFEEE7);
  static const brand = accent;
  static const brandDark = Color(0xFFE84A12);
  static const fab = accent;
  static const bg = Color(0xFFF5F4F0); // warm paper
  static const surface = Color(0xFFFFFFFF);
  static const surfaceHi = Color(0xFFEFEEE9);
  static const line = Color(0xFFE7E5DF);
  static const text = Color(0xFF111113);
  static const muted = Color(0xFF6E6D73);
  static const faint = Color(0xFFA6A5AB);
  static const volt = accent;
  static const voltInk = Color(0xFFFFFFFF);
  static const danger = Color(0xFFE5484D);
  static const success = Color(0xFF16A34A);
}

/// One shadow family for the whole app.
abstract final class Shadows {
  static const soft = [BoxShadow(color: Color(0x0D111113), blurRadius: 24, offset: Offset(0, 8))];
  static const lift = [BoxShadow(color: Color(0x1A111113), blurRadius: 30, offset: Offset(0, 12))];
}

abstract final class Fonts {
  static const display = 'Bricolage';
  static const body = 'DMSans';
  static const mono = 'DMSans';
}

abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double section = 44;
  static const double page = 20; // horizontal page gutter
}

abstract final class Radii {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 26;
  static const double xl = 34;
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 560);
  static const curve = Cubic(0.16, 1, 0.3, 1); // expo-out: quick start, soft landing
}

abstract final class TextStyles {
  static const hero = TextStyle(
    fontFamily: Fonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 46,
    height: 0.95,
    letterSpacing: -1.8,
    color: Palette.text,
  );
  static const h1 = TextStyle(
    fontFamily: Fonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 30,
    height: 1.0,
    letterSpacing: -1.0,
    color: Palette.text,
  );
  static const h2 = TextStyle(
    fontFamily: Fonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 21,
    height: 1.1,
    letterSpacing: -0.5,
    color: Palette.text,
  );
  static const title = TextStyle(
    fontFamily: Fonts.body,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.3,
    color: Palette.text,
  );
  static const body = TextStyle(
    fontFamily: Fonts.body,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.45,
    color: Palette.muted,
  );
  static const small = TextStyle(
    fontFamily: Fonts.body,
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 1.35,
    color: Palette.muted,
  );
  static const label = TextStyle(
    fontFamily: Fonts.body,
    fontWeight: FontWeight.w700,
    fontSize: 11.5,
    letterSpacing: 1.0,
    color: Palette.muted,
  );
  static const number = TextStyle(
    fontFamily: Fonts.mono,
    fontWeight: FontWeight.w700,
    fontSize: 15,
    fontFeatures: [FontFeature.tabularFigures()],
    color: Palette.text,
  );
  static const button = TextStyle(
    fontFamily: Fonts.body,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    letterSpacing: -0.1,
  );
}

ThemeData buildTheme() {
  const scheme = ColorScheme.light(
    surface: Palette.surface,
    primary: Palette.brand,
    onPrimary: Colors.white,
    secondary: Palette.brand,
    error: Palette.danger,
    onSurface: Palette.text,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.bg,
    dividerColor: Palette.line,
    fontFamily: Fonts.body,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Palette.volt,
      selectionColor: Color(0x55FF6A00),
      selectionHandleColor: Palette.volt,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF2B2B2B),
      contentTextStyle: TextStyles.title.copyWith(fontSize: 14, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}
