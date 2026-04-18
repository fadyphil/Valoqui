// lib/core/theme/app_typography.dart

import "package:flutter/material.dart";
import 'package:valoqui/core/theme/app_colors.dart';

abstract class AppTypography {
  static const String fraunces = "Fraunces";
  static const String dmSans = "DMSans";
  static const String jetBrainsMono = "JetBrainsMono";

  // ── Display ───────────────────────────────────────
  static const TextStyle displayXL = TextStyle(
    fontFamily: fraunces,
    fontWeight: FontWeight.w700,
    fontSize: 48,
    color: AppColors.textPrimary,
    height: 1.1,
    letterSpacing: -0.5,
  );

  // ── Headings ──────────────────────────────────────
  static const TextStyle headingLG = TextStyle(
    fontFamily: fraunces,
    fontWeight: FontWeight.w600,
    fontSize: 28,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle headingMD = TextStyle(
    fontFamily: fraunces,
    fontWeight: FontWeight.w600,
    fontSize: 24,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // ── Body ──────────────────────────────────────────
  static const TextStyle bodyLG = TextStyle(
    fontFamily: dmSans,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMD = TextStyle(
    fontFamily: dmSans,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // ── Labels ────────────────────────────────────────
  static const TextStyle labelLG = TextStyle(
    fontFamily: dmSans,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle labelMD = TextStyle(
    fontFamily: dmSans,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle labelSM = TextStyle(
    fontFamily: dmSans,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    color: AppColors.textSecondary,
    letterSpacing: 0.8,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: dmSans,
    fontWeight: FontWeight.w400,
    fontSize: 11,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // ── Transcript ────────────────────────────────────
  static const TextStyle transcript = TextStyle(
    fontFamily: jetBrainsMono,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.textPrimary,
    height: 1.6,
  );
}
