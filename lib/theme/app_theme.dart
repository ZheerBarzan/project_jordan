import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color nbaBlue = Color(0xFF0254A6);
  static const Color courtBlue = Color(0xFF144490);
  static const Color accentRed = Color(0xFFD62828);
  static const Color softBackground = Color(0xFFF3F6FB);
  static const Color cardBackground = Color(0xFFFFFFFF);

  static ThemeData light() {
    final ColorScheme colorScheme = const ColorScheme.light(
      primary: nbaBlue,
      onPrimary: Colors.white,
      secondary: accentRed,
      onSecondary: Colors.white,
      surface: cardBackground,
      onSurface: Color(0xFF142033),
      error: Color(0xFF9C1C1C),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: softBackground,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: accentRed,
        secondarySelectedColor: accentRed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: GoogleFonts.oswald(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: courtBlue,
        ),
        secondaryLabelStyle: GoogleFonts.oswald(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentRed,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.oswald(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: nbaBlue,
          textStyle: GoogleFonts.oswald(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: TextTheme(
        displaySmall: GoogleFonts.bebasNeue(
          fontSize: 46,
          letterSpacing: 0.3,
          color: colorScheme.onSurface,
        ),
        headlineMedium: GoogleFonts.bebasNeue(
          fontSize: 30,
          letterSpacing: 0.2,
          color: colorScheme.onSurface,
        ),
        titleLarge: GoogleFonts.bebasNeue(
          fontSize: 26,
          letterSpacing: 0.2,
          color: colorScheme.onSurface,
        ),
        titleMedium: GoogleFonts.bebasNeue(
          fontSize: 22,
          letterSpacing: 0.2,
          color: colorScheme.onSurface,
        ),
        bodyLarge: GoogleFonts.oswald(
          fontSize: 16,
          height: 1.35,
          color: colorScheme.onSurface,
        ),
        bodyMedium: GoogleFonts.oswald(
          fontSize: 14,
          height: 1.35,
          color: colorScheme.onSurface.withValues(alpha: 0.84),
        ),
        bodySmall: GoogleFonts.oswald(
          fontSize: 12,
          height: 1.25,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        labelLarge: GoogleFonts.oswald(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}
