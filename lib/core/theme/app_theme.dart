// lib/core/theme/app_theme.dart

import "package:flutter/material.dart";
import "package:valoqui/core/theme/app_colors.dart";
import "package:valoqui/core/theme/app_spacing.dart";
import "package:valoqui/core/theme/app_typography.dart";

class AppTheme {
  static ThemeData get dark {
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
      fontFamily: AppTypography.dmSans,
      textTheme: const TextTheme(
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
      // Material 2's BottomNavigationBar ignores the app fontFamily entirely
      // unless selectedLabelStyle / unselectedLabelStyle are set explicitly.
      // Without these, nav bar labels render in the system default font even
      // though every other text widget in the app uses DMSans / Fraunces.
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgSurface,
        selectedItemColor: AppColors.accentPrimary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        // Color is driven by selectedItemColor / unselectedItemColor above;
        // these styles only need to carry the font metadata.
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
