import 'package:flutter/material.dart';

/// App color palette extracted from the HTML designs
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primaryOrange = Color(0xFFFF9933);
  static const Color primaryBlue = Color(0xFF137FEC);

  // Emergency & Status Colors
  static const Color emergency = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color crowdHigh = Color(0xFFEF4444);
  static const Color crowdMedium = Color(0xFFF59E0B);
  static const Color crowdLow = Color(0xFF10B981);

  // Light Theme Colors
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF9FAFB);
  static const Color cardLight = Color(0xFFF8F9FA);
  static const Color cardSecondaryLight = Color(0xFFF1F3F5);
  static const Color textDarkLight = Color(0xFF1F2937);
  static const Color textMutedLight = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color dividerLight = Color(0xFFF3F4F6);

  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF0A0F14);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color cardDark = Color(0xFF1F2937);
  static const Color cardSecondaryDark = Color(0xFF374151);
  static const Color textDarkDark = Color(0xFFFFFFFF);
  static const Color textMutedDark = Color(0xFF9CA3AF);
  static const Color borderDark = Color(0xFF374151);
  static const Color dividerDark = Color(0xFF1F2937);

  // Crowd Level Backgrounds
  static const Color crowdHighBg = Color(0xFFFEE2E2);
  static const Color crowdMediumBg = Color(0xFFFEF3C7);
  static const Color crowdLowBg = Color(0xFFD1FAE5);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryOrange, Color(0xFFFFB366)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    colors: [emergency, Color(0xFFFF6B6B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
