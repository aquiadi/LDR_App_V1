import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {
  AppTypography._();

  // Display: Archivo at its expanded width. Wide letterforms carry the
  // headings, so they can stay a size smaller than a narrow face would need.
  static TextStyle get _displayFamily => TextStyle(
        fontFamily: 'ArchivoExpanded',
        color: AppColors.onSurface,
        fontWeight: FontWeight.w600,
      );

  // Everything else: Inter
  static TextStyle get _bodyFamily => GoogleFonts.inter(
        color: AppColors.onSurface,
      );

  // --- Display & Headings (Archivo Expanded) ---

  static TextStyle get display => _displayFamily.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.08,
        letterSpacing: -0.8,
      );

  static TextStyle get headlineLg => _displayFamily.copyWith(
        fontSize: 28,
        height: 1.15,
        letterSpacing: -0.4,
      );

  static TextStyle get headlineLgMobile => _displayFamily.copyWith(
        fontSize: 26,
        height: 1.15,
        letterSpacing: -0.3,
      );

  static TextStyle get headlineMd => _displayFamily.copyWith(
        fontSize: 21,
        height: 1.2,
        letterSpacing: -0.2,
      );

  /// The display face in the accent colour, for the one word in a heading
  /// that should stand out.
  static TextStyle get accent => _displayFamily.copyWith(color: AppColors.primary);

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
