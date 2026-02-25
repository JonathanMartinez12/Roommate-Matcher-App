
import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF7C3AED);      // Vibrant purple
  static const Color secondary = Color(0xFFFF4757);    // Hot coral
  static const Color accent = Color(0xFF00C9A7);       // Mint green
  static const Color highlight = Color(0xFFFFB700);    // Amber

  // Backward-compat aliases (primaryBlue now = purple)
  static const Color primaryBlue = Color(0xFF7C3AED);
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color coral = Color(0xFFFF4757);
  static const Color mint = Color(0xFF00C9A7);
  static const Color amber = Color(0xFFFFB700);

  // Action colors
  static const Color like = Color(0xFF10B981);         // green
  static const Color pass = Color(0xFFEF4444);         // red
  static const Color superLike = Color(0xFFFFB700);    // amber

  // Background
  static const Color background = Color(0xFFFAFAF8);   // Warm white
  static const Color cardBackground = Colors.white;
  static const Color surface = Color(0xFFF3F0FF);      // Light purple tint

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  // Border
  static const Color border = Color(0xFFE8E4F0);       // Warmer border

  // Category colors for quiz/profile chips
  static const Color sleepColor = Color(0xFF7C3AED);   // purple
  static const Color socialColor = Color(0xFFFF4757);  // coral
  static const Color lifestyleColor = Color(0xFF00C9A7); // mint
  static const Color kitchenColor = Color(0xFFFFB700); // amber

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],   // purple → coral
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient cardOverlayLike = LinearGradient(
    colors: [like.withValues(alpha: 0.0), like.withValues(alpha: 0.6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient cardOverlayPass = LinearGradient(
    colors: [pass.withValues(alpha: 0.0), pass.withValues(alpha: 0.6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient cardOverlayInfo = LinearGradient(
    colors: [Colors.transparent, Colors.black87],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
