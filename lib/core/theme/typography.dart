import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {
  AppTypography._();

  // Primary Font Family: Sora
  static TextStyle get _displayFamily => GoogleFonts.sora(
        color: AppColors.onSurface,
      );

  // Secondary Font Family: Inter
  static TextStyle get _bodyFamily => GoogleFonts.inter(
        color: AppColors.onSurface,
      );

  // --- Display & Headings (Sora) ---
  
  static TextStyle get display => _displayFamily.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w600,
        height: 48 / 40,
        letterSpacing: -0.02 * 40,
      );

  static TextStyle get headlineLg => _displayFamily.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 40 / 32,
        letterSpacing: -0.01 * 32,
      );

  static TextStyle get headlineLgMobile => _displayFamily.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
      );

  static TextStyle get headlineMd => _displayFamily.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 32 / 24,
      );

  // --- Body Copy (Inter) ---
  
  static TextStyle get bodyLg => _bodyFamily.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 28 / 18,
      );

  static TextStyle get bodyMd => _bodyFamily.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
      );

  static TextStyle get bodySm => _bodyFamily.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
      );

  // --- UI Elements (Inter) ---
  
  static TextStyle get labelMd => _bodyFamily.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.05 * 12,
      );

  // Legacy mappings to keep existing code compiling before it's updated
  static TextStyle get h1 => headlineLg;
  static TextStyle get h2 => headlineMd;
  static TextStyle get h3 => headlineMd.copyWith(fontSize: 20);
  static TextStyle get subtitle => bodyLg.copyWith(color: AppColors.onSurfaceVariant);
  static TextStyle get bodyLarge => bodyLg;
  static TextStyle get bodyMedium => bodyMd;
  static TextStyle get bodySmall => bodySm.copyWith(color: AppColors.outline);
  static TextStyle get buttonText => headlineMd.copyWith(fontSize: 16);
  static TextStyle get labelText => labelMd;
  static TextStyle get cardTitle => headlineMd.copyWith(fontSize: 18);
  static TextStyle get statsNumber => display;
}
