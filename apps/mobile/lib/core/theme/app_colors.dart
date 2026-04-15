import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand — vibrant indigo-violet
  static const Color brand       = Color(0xFF6366F1);
  static const Color brandDark   = Color(0xFF4F46E5);
  static const Color brandLight  = Color(0xFFEEF2FF);

  // Header gradient — deep space feel
  static const Color navyDark    = Color(0xFF0D0B2B);
  static const Color navyMid     = Color(0xFF1A1050);
  static const Color navyBlue    = Color(0xFF2D1F8A);

  static const Color accent      = Color(0xFF38BDF8);
  static const Color accentGold  = Color(0xFFF59E0B);
  static const Color success     = Color(0xFF10B981);
  static const Color error       = Color(0xFFEF4444);

  static const Color white       = Color(0xFFFFFFFF);
  static const Color surface     = Color(0xFFF7F7FB);
  static const Color surfaceAlt  = Color(0xFFF1F1F8);
  static const Color border      = Color(0xFFE8E8F0);
  static const Color borderLight = Color(0xFFF3F3F9);

  static const Color textPrimary   = Color(0xFF0F0E2A);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted     = Color(0xFF9CA3AF);

  static const gradientHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyDark, navyMid, Color(0xFF3730A3)],
  );

  static const gradientBrand = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [brand, Color(0xFF818CF8)],
  );

  static const gradientCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
  );
}
