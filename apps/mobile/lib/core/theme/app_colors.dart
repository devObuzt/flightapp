import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color brand       = Color(0xFF2563EB);
  static const Color brandDark   = Color(0xFF1D4ED8);
  static const Color brandLight  = Color(0xFFEFF6FF);

  // Header gradient
  static const Color navyDark    = Color(0xFF0A0F2E);
  static const Color navyMid     = Color(0xFF0F2070);
  static const Color navyBlue    = Color(0xFF1A3A8F);

  static const Color accent      = Color(0xFF38BDF8);
  static const Color accentGold  = Color(0xFFF59E0B);
  static const Color success     = Color(0xFF10B981);
  static const Color error       = Color(0xFFEF4444);

  static const Color white       = Color(0xFFFFFFFF);
  static const Color surface     = Color(0xFFF8FAFC);
  static const Color surfaceAlt  = Color(0xFFF1F5F9);
  static const Color border      = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted     = Color(0xFF94A3B8);

  static const gradientHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyDark, navyMid, navyBlue],
  );

  static const gradientBrand = LinearGradient(
    colors: [brand, Color(0xFF06B6D4)],
  );

  static const gradientCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
  );
}
