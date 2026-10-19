import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Brand ---
  // Lime is a *fill* colour (buttons, selected chips, active nav). It is too light
  // to read as text on a light background, so text/icons use `colorScheme.secondary`.
  static const Color lime = Color(0xFFD6F26A);
  static const Color ink = Color(0xFF111111);
  static const Color errorRed = Color(0xFFE5484D);

  // --- Colors for Light Theme ---
  static const Color lightBackground = Color(0xFFF1F1EA);
  static const Color lightSurface = Colors.white;
  static const Color textDark = Color(0xFF111111);
  static const Color textGreyLight = Color(0xFF6F6F69);
  static const Color lightAccentInk = Color(0xFF3B7A1A); // readable green on light backgrounds

  // --- Colors for Dark Theme ---
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E20);
  static const Color textLight = Colors.white;
  static const Color textGrey = Color(0xFFA0A0A0);

  // Kept for the few screens that still reference the old names.
  static const Color primaryGreen = lime;

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        background: darkBackground,
        surface: darkSurface,
        onSurface: textLight,
        onSurfaceVariant: textGrey,
        accentInk: lime,
      );

  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        background: lightBackground,
        surface: lightSurface,
        onSurface: textDark,
        onSurfaceVariant: textGreyLight,
        accentInk: lightAccentInk,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color accentInk,
  }) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark() : ThemeData.light();

    return ThemeData(
      fontFamily: GoogleFonts.manrope().fontFamily,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: lime,
      colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
        primary: lime,
        onPrimary: ink,
        secondary: accentInk,
        surface: surface,
        error: errorRed,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
      ),
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, color: onSurface),
        displayMedium: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: onSurface),
        headlineSmall: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: onSurface),
        titleLarge: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700, color: onSurface),
        bodyLarge: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500, color: onSurface),
        bodyMedium: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: onSurfaceVariant),
        labelLarge: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: ink),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lime,
          foregroundColor: ink,
          // A disabled lime button would vanish on the light background, so it turns neutral grey.
          disabledBackgroundColor: onSurface.withValues(alpha: 0.1),
          disabledForegroundColor: onSurface.withValues(alpha: 0.4),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
          textStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          minimumSize: const Size(double.infinity, 56),
          side: BorderSide(color: onSurface.withValues(alpha: 0.2), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      // Anything that would default to the lime primary (spinners, cursor, pickers) uses the readable accent.
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accentInk, circularTrackColor: Colors.transparent),
      textSelectionTheme: TextSelectionThemeData(cursorColor: accentInk, selectionHandleColor: accentInk, selectionColor: lime.withValues(alpha: 0.4)),
      datePickerTheme: DatePickerThemeData(
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: accentInk),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: accentInk),
        todayForegroundColor: WidgetStatePropertyAll(accentInk),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentInk,
          textStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? ink : (isDark ? textGrey : Colors.white)),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? lime : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD5D5CD))),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? lime : Colors.transparent),
        checkColor: WidgetStateProperty.all(ink),
        side: BorderSide(color: onSurfaceVariant, width: 1.5),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: isDark ? lime : ink, width: 1.5)),
        hintStyle: GoogleFonts.manrope(color: onSurfaceVariant, fontWeight: FontWeight.w500),
        floatingLabelStyle: GoogleFonts.manrope(color: accentInk, fontWeight: FontWeight.w700),
      ),
    );
  }
}
