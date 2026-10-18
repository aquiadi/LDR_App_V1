import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {
  AppTypography._();

  // Display: Instrument Serif. It only comes in one weight, so hierarchy
  // comes from size, not boldness.
  static TextStyle get _displayFamily => GoogleFonts.instrumentSerif(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w400,
      );

  // Everything else: Inter
  static TextStyle get _bodyFamily => GoogleFonts.inter(
        color: AppColors.onSurface,
      );

  // --- Display & Headings (Instrument Serif) ---

  static TextStyle get display => _displayFamily.copyWith(
        fontSize: 48,
        height: 52 / 48,
        letterSpacing: -0.01 * 48,
      );

  static TextStyle get headlineLg => _displayFamily.copyWith(
        fontSize: 36,
        height: 42 / 36,
        letterSpacing: -0.01 * 36,
      );

  static TextStyle get headlineLgMobile => _displayFamily.copyWith(
        fontSize: 32,
        height: 38 / 32,
      );

  static TextStyle get headlineMd => _displayFamily.copyWith(
        fontSize: 28,
        height: 34 / 28,
      );

  /// Serif italic, for the one emotional word in a heading.
  static TextStyle get accentItalic => GoogleFonts.instrumentSerif(
        color: AppColors.primary,
        fontStyle: FontStyle.italic,
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
  static TextStyle get h3 => headlineMd.copyWith(fontSize: 22);
  static TextStyle get subtitle => bodyLg.copyWith(color: AppColors.onSurfaceVariant);
  static TextStyle get bodyLarge => bodyLg;
  static TextStyle get bodyMedium => bodyMd;
  static TextStyle get bodySmall => bodySm.copyWith(color: AppColors.outline);
  static TextStyle get buttonText => _bodyFamily.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 24 / 16,
      );
  static TextStyle get labelText => labelMd;
  static TextStyle get cardTitle => _bodyFamily.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 24 / 17,
      );
  static TextStyle get statsNumber => display;
}
