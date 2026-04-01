import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_radius.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onSurface: AppColors.onSurface,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.onSecondary,
        onError: AppColors.onError,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        titleTextStyle: GoogleFonts.manrope(
          color: AppColors.primary,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.0,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: AppColors.onSurface),
        displayMedium: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: AppColors.onSurface),
        displaySmall: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: AppColors.onSurface),
        headlineLarge: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: AppColors.onSurface),
        headlineMedium: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.onSurface),
        headlineSmall: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.onSurface),
        titleLarge: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.onSurface),
        titleMedium: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.circularMd,
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circularLg,
        ),
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
    );
  }
}
