import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App text styles using Inter font family
class AppTextStyles {
  AppTextStyles._();

  // Headings
  static TextStyle heading1(BuildContext context) => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static TextStyle heading2(BuildContext context) => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static TextStyle heading3(BuildContext context) => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static TextStyle heading4(BuildContext context) =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700);

  // Body Text
  static TextStyle bodyLarge(BuildContext context) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400);

  static TextStyle bodyMedium(BuildContext context) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400);

  static TextStyle bodySmall(BuildContext context) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400);

  // Labels
  static TextStyle labelLarge(BuildContext context) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600);

  static TextStyle labelMedium(BuildContext context) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600);

  static TextStyle labelSmall(BuildContext context) => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  // Button Text
  static TextStyle buttonLarge(BuildContext context) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700);

  static TextStyle buttonMedium(BuildContext context) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600);

  // Caption
  static TextStyle caption(BuildContext context) => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  // Uppercase Labels (like "SANGAM GHAT LIVE")
  static TextStyle uppercaseLabel(BuildContext context) => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
  );
}
