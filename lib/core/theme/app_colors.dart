// lib/core/theme/app_colors.dart

import "package:flutter/material.dart";

abstract class AppColors {
  // ── Backgrounds ───────────────────────────────────
  static const Color bgPrimary = Color(0xFF0D0F1A);
  static const Color bgSurface = Color(0xFF161928);
  static const Color bgElevated = Color(0xFF1E2235);

  // ── Accent ────────────────────────────────────────
  static const Color accentPrimary = Color(0xFFF5A623);
  static const Color accentSecondary = Color(0xFF4A90E2);
  static const Color accentGradientEnd = Color(0xFFE8940A);

  // ── Semantic ──────────────────────────────────────
  static const Color success = Color(0xFF52C97D);
  static const Color error = Color(0xFFE05C5C);

  // ── Text ──────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F2FF);
  static const Color textSecondary = Color(0xFF8B93B4);

  // ── Chrome ────────────────────────────────────────
  static const Color border = Color(0xFF2A2F4A);
  static const Color micGlow = Color(0x59F5A623); // rgba(245,166,35,0.35)

  // ── Gradients ─────────────────────────────────────
  static const LinearGradient micButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [accentPrimary, accentGradientEnd],
  );

  static const LinearGradient xpBarGradient = LinearGradient(
    colors: [accentPrimary, success],
  );

  static const LinearGradient luciaBubbleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B3A5C), Color(0xFF1E2B4A)],
  );
}
