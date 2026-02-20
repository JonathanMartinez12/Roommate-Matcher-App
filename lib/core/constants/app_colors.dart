import 'package:flutter/material.dart';

class AppColors {
  // Primary gradient
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryPurple = Color(0xFF8B5CF6);

  // Action colors
  static const Color like = Color(0xFF10B981);   // green
  static const Color pass = Color(0xFFEF4444);   // red
  static const Color superLike = Color(0xFFF59E0B); // amber

  // Background
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color surface = Color(0xFFF1F5F9);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  // Border
  static const Color border = Color(0xFFE2E8F0);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    colors: [primaryBlue, primaryPurple],
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
