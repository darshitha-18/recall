import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colour with the given opacity (avoids version-specific withOpacity/withValues).
Color tint(Color c, double opacity) => c.withAlpha((opacity * 255).round());

/// Colour palette. Ivory + near-black navy ink + one cobalt accent.
class Pal {
  const Pal({
    required this.bg,
    required this.surface,
    required this.sunken,
    required this.ink,
    required this.muted,
    required this.border,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.good,
    required this.bad,
    required this.shadow,
  });

  final Color bg, surface, sunken, ink, muted, border;
  final Color accent, onAccent, accentSoft, good, bad, shadow;

  static const light = Pal(
    bg: Color(0xFFF7F4EC),
    surface: Color(0xFFFFFDF8),
    sunken: Color(0xFFEFEADC),
    ink: Color(0xFF0E1525),
    muted: Color(0xFF626A7C),
    border: Color(0xFFE4DDCB),
    accent: Color(0xFF2347C8),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFE6EAF8),
    good: Color(0xFF2F7D57),
    bad: Color(0xFFB4492F),
    shadow: Color(0x140E1525),
  );

  static const dark = Pal(
    bg: Color(0xFF0C101B),
    surface: Color(0xFF141A28),
    sunken: Color(0xFF090C14),
    ink: Color(0xFFEDE9DD),
    muted: Color(0xFF9199AD),
    border: Color(0xFF262E42),
    accent: Color(0xFF7C97FF),
    onAccent: Color(0xFF0C101B),
    accentSoft: Color(0xFF1C2542),
    good: Color(0xFF5BBE8C),
    bad: Color(0xFFE58769),
    shadow: Color(0x66000000),
  );

  /// Muted colours used to colour-code decks.
  static const deckColors = [
    Color(0xFF2347C8), // cobalt
    Color(0xFFB7791F), // ochre
    Color(0xFF2F7D57), // sage
    Color(0xFFB4492F), // terracotta
    Color(0xFF2F7F86), // teal
  ];

  static Pal of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Typography: Fraunces (editorial serif) for display, Inter for interface text.
class T {
  static TextStyle serif(double size, Color color,
          {FontWeight w = FontWeight.w600,
          double h = 1.2,
          double ls = -0.3,
          FontStyle? style}) =>
      GoogleFonts.fraunces(
          fontSize: size,
          color: color,
          fontWeight: w,
          height: h,
          letterSpacing: ls,
          fontStyle: style);

  static TextStyle sans(double size, Color color,
          {FontWeight w = FontWeight.w400, double h = 1.5, double ls = 0}) =>
      GoogleFonts.inter(
          fontSize: size,
          color: color,
          fontWeight: w,
          height: h,
          letterSpacing: ls);

  /// Small uppercase label.
  static TextStyle label(Color color) =>
      sans(11, color, w: FontWeight.w600, ls: 1.1, h: 1.3);
}

ThemeData buildTheme(Brightness b) {
  final p = b == Brightness.dark ? Pal.dark : Pal.light;
  final base = ThemeData(brightness: b, useMaterial3: true);
  final scheme = ColorScheme(
    brightness: b,
    primary: p.accent,
    onPrimary: p.onAccent,
    secondary: p.accent,
    onSecondary: p.onAccent,
    error: p.bad,
    onError: Colors.white,
    surface: p.surface,
    onSurface: p.ink,
  );
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c, width: w),
      );
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    textTheme: GoogleFonts.interTextTheme(base.textTheme)
        .apply(bodyColor: p.ink, displayColor: p.ink),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.accent,
      selectionColor: tint(p.accent, .25),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: T.sans(15, p.muted),
      errorStyle: T.sans(12.5, p.bad, h: 1.4),
      border: border(p.border),
      enabledBorder: border(p.border),
      focusedBorder: border(p.accent, 1.6),
      errorBorder: border(p.bad),
      focusedErrorBorder: border(p.bad, 1.6),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.ink,
      contentTextStyle: T.sans(14, p.bg),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
