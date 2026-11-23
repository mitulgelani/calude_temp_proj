import 'package:flutter/material.dart';

/// Single source of truth for every visual decision in Pluck.
/// Nothing in the UI uses a raw colour, size or duration — only these.
abstract final class Palette {
  static const bg = Color(0xFF0B0A0F); // warm near-black ink
  static const surface = Color(0xFF15131B);
  static const surfaceHi = Color(0xFF1E1B26);
  static const line = Color(0xFF2A2633);
  static const text = Color(0xFFF4EFE7); // cream, never pure white
  static const muted = Color(0xFF8B8496);
  static const faint = Color(0xFF5A5466);
  static const volt = Color(0xFFD6FF3D); // the one accent: action + success
  static const voltInk = Color(0xFF0B0A0F);
  static const danger = Color(0xFFFF6B5E);
}

abstract final class Fonts {
  static const display = 'Bricolage';
  static const body = 'DMSans';
  static const mono = 'JetBrainsMono';
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
    fontFamily: Fonts.mono,
    fontWeight: FontWeight.w500,
    fontSize: 11,
    letterSpacing: 1.4,
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
  const scheme = ColorScheme.dark(
    surface: Palette.surface,
    primary: Palette.volt,
    onPrimary: Palette.voltInk,
    secondary: Palette.volt,
    error: Palette.danger,
    onSurface: Palette.text,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.bg,
    fontFamily: Fonts.body,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Palette.volt,
      selectionColor: Color(0x55D6FF3D),
      selectionHandleColor: Palette.volt,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Palette.surfaceHi,
      contentTextStyle: TextStyles.title.copyWith(fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}
