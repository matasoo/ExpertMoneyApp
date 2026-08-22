import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Colors for Dark Theme ---
  static const Color darkBackground = Color(0xFF202022);
  static const Color darkSurface = Color(0xFF2C2C2E);
  static const Color primaryGreen = Color(0xFF2ECC71);
  static const Color textLight = Colors.white;
  static const Color textGrey = Color(0xFFA0A0A0);
  static const Color errorRed = Color(0xFFE74C3C);

  // --- Colors for Light Theme ---
  static const Color lightBackground = Color(0xFFF4F6F8);
  static const Color lightSurface = Colors.white;
  static const Color textDark = Color(0xFF1E1E1E);
  static const Color textGreyLight = Color(0xFF757575);

  static ThemeData get darkTheme {
    return ThemeData(
      fontFamily: GoogleFonts.manrope().fontFamily,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryGreen,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        surface: darkSurface,
        error: errorRed,
        onSurface: textLight,
        onSurfaceVariant: textGrey,
      ),
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, color: textLight),
        displayMedium: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: textLight),
        headlineSmall: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: textLight),
        titleLarge: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700, color: textLight),
        bodyLarge: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500, color: textLight),
        bodyMedium: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: textGrey),
        labelLarge: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: darkBackground),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: darkBackground,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          textStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          textStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
        hintStyle: GoogleFonts.manrope(color: textGrey, fontWeight: FontWeight.w500),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: GoogleFonts.manrope().fontFamily,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: primaryGreen,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        surface: lightSurface,
        error: errorRed,
        onSurface: textDark,
        onSurfaceVariant: textGreyLight,
      ),
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, color: textDark),
        displayMedium: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: textDark),
        headlineSmall: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: textDark),
        titleLarge: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700, color: textDark),
        bodyLarge: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500, color: textDark),
        bodyMedium: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: textGreyLight),
        labelLarge: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: lightSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: lightSurface,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          textStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          textStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
        hintStyle: GoogleFonts.manrope(color: textGreyLight, fontWeight: FontWeight.w500),
      ),
    );
  }
}
