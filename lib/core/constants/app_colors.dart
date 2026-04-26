import 'package:flutter/material.dart';

class AppColors {
  // Primary palette from prototype
  static const Color navy = Color(0xFF16192A);
  static const Color navyLight = Color(0xFF1E2235);
  static const Color navySoft = Color(0xFF252A40);
  static const Color navyDeep = Color(0xFF0E1020);
  static const Color cream = Color(0xFFD9DDD9);
  static const Color creamLight = Color(0xFFE8EBE8);
  static const Color creamDark = Color(0xFFC8CCC8);
  static const Color terracotta = Color(0xFFC3543A);
  static const Color terracottaLight = Color(0xFFD4654B);
  static const Color terracottaGlow = Color(0xFFD9684E);
  static const Color terracottaSoft = Color(0x26C3543A);
  static const Color terracottaTint = Color(0xFFF4E2DD);
  static const Color bg = Color(0xFFD9DDD9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF4F4F2);
  static const Color border = Color(0xFFC8CCC8);
  static const Color borderLight = Color(0xFFE0E3E0);
  static const Color text = Color(0xFF16192A);
  static const Color textSoft = Color(0xFF3D4156);
  static const Color textMuted = Color(0xFF6B7080);
  static const Color textLight = Color(0xFF9A9FAB);
  static const Color success = Color(0xFF2D8A5F);

  // Glass surface tokens (used by GlassContainer)
  static const Color glassFill = Color(0xA6FFFFFF); // white @ 65%
  static const Color glassFillDark = Color(0x66000000); // black @ 40%
  static const Color glassStroke = Color(0x33FFFFFF);

  // Legacy aliases
  static const Color primaryBlue = terracotta;
  static const Color primaryPurple = terracottaLight;
  static const Color like = Color(0xFF10B981);
  static const Color pass = Color(0xFFEF4444);
  static const Color superLike = Color(0xFFF59E0B);
  static const Color background = bg;
  static const Color cardBackground = surface;
  static const Color textPrimary = text;
  static const Color textSecondary = textSoft;
  static const Color textHint = textMuted;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [terracotta, terracottaGlow],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    colors: [terracotta, terracottaGlow],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient navyGradient = LinearGradient(
    colors: [navy, navyDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [navy, Color(0xFF221E36), terracotta],
    stops: [0.0, 0.6, 1.4],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient celebrationGradient = LinearGradient(
    colors: [navyDeep, navy, terracotta],
    stops: [0.0, 0.5, 1.0],
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

  static const LinearGradient cardOverlayInfo = LinearGradient(
    colors: [Colors.transparent, Color(0xE516192A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
