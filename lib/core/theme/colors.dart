import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core Backgrounds
  static const Color background = Color(0xff131316);
  static const Color surface = Color(0xff131316);
  static const Color surfaceContainer = Color(0xff1f1f22);
  static const Color surfaceContainerLow = Color(0xff1b1b1e);
  static const Color surfaceContainerHigh = Color(0xff2a2a2d);
  static const Color surfaceContainerHighest = Color(0xff353438);
  static const Color surfaceVariant = Color(0xff353438);

  // Core Brand Colors
  static const Color primary = Color(0xffffb1c0);
  static const Color onPrimary = Color(0xff660029);
  static const Color primaryContainer = Color(0xffff7597);
  static const Color onPrimaryContainer = Color(0xff740430);
  static const Color inversePrimary = Color(0xffa83255);

  static const Color secondary = Color(0xffcdbdff);
  static const Color onSecondary = Color(0xff370096);
  static const Color secondaryContainer = Color(0xff5203d5);
  static const Color onSecondaryContainer = Color(0xffc0acff);

  static const Color tertiary = Color(0xfffab4c2);
  static const Color onTertiary = Color(0xff4f212d);
  static const Color tertiaryContainer = Color(0xffd2909e);
  static const Color onTertiaryContainer = Color(0xff592935);

  // Status Colors
  static const Color error = Color(0xffffb4ab);
  static const Color onError = Color(0xff690005);
  static const Color errorContainer = Color(0xff93000a);
  static const Color onErrorContainer = Color(0xffffdad6);

  // Outline and Text
  static const Color outline = Color(0xffa58a8e);
  static const Color outlineVariant = Color(0xff564145);
  
  static const Color onBackground = Color(0xffe4e1e6);
  static const Color onSurface = Color(0xffe4e1e6);
  static const Color onSurfaceVariant = Color(0xffddbfc3);
  static const Color inverseSurface = Color(0xffe4e1e6);
  static const Color inverseOnSurface = Color(0xff303033);

  // Legacy mappings for existing code compatibility (to be phased out if possible)
  static const Color surfaceElevated = Color(0xff1f1f22);
  static const Color textPrimary = Color(0xffe4e1e6);
  static const Color textSecondary = Color(0xffddbfc3);
  static const Color textMuted = Color(0xffa58a8e);
  static const Color border = Color(0xff564145);
  static const Color success = Color(0xff4ADE80);
  static const Color warning = Color(0xffFBBF24);

  // Gradients
  static const LinearGradient accentGradient = LinearGradient(
    colors: [primaryContainer, inversePrimary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x0affffff), // Very thin semi-transparent white
      Color(0x05ffffff),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
