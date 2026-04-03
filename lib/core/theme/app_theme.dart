// lib/core/theme/app_theme.dart

import "package:flutter/material.dart";
import "package:valoqui/core/theme/app_colors.dart";
import "package:valoqui/core/theme/app_spacing.dart";
import "package:valoqui/core/theme/app_typography.dart";

class AppTheme {
  static ThemeData get dark {
    // 1. Create a base text theme using DMSans for all default/fallback styles
    final baseTextTheme = ThemeData.dark().textTheme.apply(
      fontFamily: AppTypography.dmSans,
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.accentPrimary,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentPrimary,
        secondary: AppColors.accentSecondary,
        surface: AppColors.bgSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),

      // FIX: Removed global fontFamily declaration here so it doesn't
      // overwrite the Fraunces styles inside the textTheme below.

      // 2. Overlay your explicit typography onto the base theme
      textTheme: baseTextTheme.copyWith(
        displayLarge: AppTypography.displayXL,
        headlineLarge: AppTypography.headingLG,
        headlineMedium: AppTypography.headingMD,
        bodyLarge: AppTypography.bodyLG,
        bodyMedium: AppTypography.bodyMD,
        labelLarge: AppTypography.labelLG,
        labelMedium: AppTypography.labelMD,
        labelSmall: AppTypography.labelSM,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgElevated,
        hintStyle: AppTypography.bodyMD.copyWith(
          color: AppColors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(
            color: AppColors.accentPrimary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppTypography.labelLG,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.labelLG,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgSurface,
        selectedItemColor: AppColors.accentPrimary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontFamily: AppTypography.dmSans,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppTypography.dmSans,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerColor: AppColors.border,
      cardTheme: CardThemeData(
        color: AppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border),
        ),
        elevation: 0,
      ),
    );
  }
}
