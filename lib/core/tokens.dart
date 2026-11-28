import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Single source of truth for every visual decision in Pluck.
/// Nothing in the UI uses a raw colour, size or duration — only these.
abstract final class Palette {
  /// Flipped by the theme toggle (see ThemeSwitch); the whole tree is rebuilt afterwards.
  static bool dark = false;
  static Color _p(int light, int night) => Color(dark ? night : light);

  static Color get ink => _p(0xFF111113, 0xFFF2F1EE); // headlines; "inverted" surfaces
  static Color get onInk => _p(0xFFFFFFFF, 0xFF111113); // text on ink
  static Color get feature => _p(0xFF111113, 0xFF24232A); // dark spotlight card (white text in both themes)
  static Color get accent => _p(0xFFFF5A1F, 0xFFFF6A33); // ember: the one action colour
  static Color get accentSoft => _p(0xFFFFEEE7, 0xFF3A2017);
  static Color get brand => accent;
  static Color get brandDark => _p(0xFFE84A12, 0xFFFF5A1F);
  static Color get fab => accent;
  static Color get bg => _p(0xFFF5F4F0, 0xFF0D0D10);
  static Color get surface => _p(0xFFFFFFFF, 0xFF17171B);
  static Color get surfaceHi => _p(0xFFEFEEE9, 0xFF222227);
  static Color get line => _p(0xFFE7E5DF, 0xFF2C2C33);
  static Color get text => _p(0xFF111113, 0xFFF2F1EE);
  static Color get muted => _p(0xFF6E6D73, 0xFFA3A2AB);
  static Color get faint => _p(0xFFA6A5AB, 0xFF6C6B75);
  static Color get volt => accent;
  static const voltInk = Color(0xFFFFFFFF);
  static Color get danger => _p(0xFFE5484D, 0xFFFF6B6B);
  static Color get success => _p(0xFF16A34A, 0xFF22C55E);
}

/// One shadow family for the whole app.
abstract final class Shadows {
  static List<BoxShadow> get soft => [BoxShadow(color: Color(Palette.dark ? 0x40000000 : 0x0D111113), blurRadius: 24, offset: Offset(0, 8))];
  static List<BoxShadow> get lift => [BoxShadow(color: Color(Palette.dark ? 0x66000000 : 0x1A111113), blurRadius: 30, offset: Offset(0, 12))];
}

/// One shadow family for the whole app.

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
  static TextStyle get hero => TextStyle(
    fontFamily: Fonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 46,
    height: 0.95,
    letterSpacing: -1.8,
    color: Palette.text,
  );
  static TextStyle get h1 => TextStyle(
    fontFamily: Fonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 30,
    height: 1.0,
    letterSpacing: -1.0,
    color: Palette.text,
  );
  static TextStyle get h2 => TextStyle(
    fontFamily: Fonts.display,
    fontWeight: FontWeight.w700,
    fontSize: 21,
    height: 1.1,
    letterSpacing: -0.5,
    color: Palette.text,
  );
  static TextStyle get title => TextStyle(
    fontFamily: Fonts.body,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.3,
    color: Palette.text,
  );
  static TextStyle get body => TextStyle(
    fontFamily: Fonts.body,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.45,
    color: Palette.muted,
  );
  static TextStyle get small => TextStyle(
    fontFamily: Fonts.body,
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 1.35,
    color: Palette.muted,
  );
  static TextStyle get label => TextStyle(
    fontFamily: Fonts.body,
    fontWeight: FontWeight.w700,
    fontSize: 11.5,
    letterSpacing: 1.0,
    color: Palette.muted,
  );
  static TextStyle get number => TextStyle(
    fontFamily: Fonts.mono,
    fontWeight: FontWeight.w700,
    fontSize: 15,
    fontFeatures: [FontFeature.tabularFigures()],
    color: Palette.text,
  );
  static TextStyle get button => TextStyle(
    fontFamily: Fonts.body,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    letterSpacing: -0.1,
  );
}

ThemeData buildTheme() {
  final scheme = Palette.dark
      ? ColorScheme.dark(surface: Palette.surface, primary: Palette.brand, onPrimary: Colors.white, secondary: Palette.brand, error: Palette.danger, onSurface: Palette.text)
      : ColorScheme.light(surface: Palette.surface, primary: Palette.brand, onPrimary: Colors.white, secondary: Palette.brand, error: Palette.danger, onSurface: Palette.text);
  return ThemeData(
    useMaterial3: true,
    brightness: Palette.dark ? Brightness.dark : Brightness.light,
    dialogTheme: DialogThemeData(backgroundColor: Palette.surface, surfaceTintColor: Colors.transparent),
    popupMenuTheme: PopupMenuThemeData(color: Palette.surface, surfaceTintColor: Colors.transparent),
    bottomSheetTheme: const BottomSheetThemeData(surfaceTintColor: Colors.transparent),
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.bg,
    dividerColor: Palette.line,
    fontFamily: Fonts.body,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Palette.volt,
      selectionColor: Color(0x55FF6A00),
      selectionHandleColor: Palette.volt,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Color(Palette.dark ? 0xFF2C2C33 : 0xFF2B2B2B),
      contentTextStyle: TextStyles.title.copyWith(fontSize: 14, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
    ),
    pageTransitionsTheme: PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}

/// Light / dark switch. Lives in the top bars; remembers the choice.
class ThemeController {
  ThemeController._();
  static final mode = ValueNotifier<bool>(false);
  static void Function(bool dark)? _save;

  static void init({required bool dark, required void Function(bool) save}) {
    Palette.dark = dark;
    mode.value = dark;
    _save = save;
  }

  static void toggle() {
    Palette.dark = !Palette.dark;
    _save?.call(Palette.dark);
    mode.value = Palette.dark; // root rebuilds every widget (see ThemeRebuilder)
  }
}

/// Rebuilds the entire tree when the theme flips, so every Palette read picks up the new colours.
class ThemeRebuilder extends StatefulWidget {
  const ThemeRebuilder({super.key, required this.builder});
  final WidgetBuilder builder;
  @override
  State<ThemeRebuilder> createState() => _ThemeRebuilderState();
}

class _ThemeRebuilderState extends State<ThemeRebuilder> {
  void _rebuildAll(Element e) {
    e.markNeedsBuild();
    e.visitChildren(_rebuildAll);
  }

  void _onChange() {
    setState(() {});
    (context as Element).visitChildren(_rebuildAll);
  }

  @override
  void initState() {
    super.initState();
    ThemeController.mode.addListener(_onChange);
  }

  @override
  void dispose() {
    ThemeController.mode.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
