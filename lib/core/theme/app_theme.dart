import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),

      // Card Design
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),

      // Custom Input Decoration for Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.transparent,
        hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.outline.withValues(alpha: 0.5)),
        labelStyle: AppTypography.labelMd,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.headlineMd.copyWith(fontSize: 16),
        ),
      ),

      // Slider Styling
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.2),
        valueIndicatorColor: AppColors.surfaceContainerHigh,
        valueIndicatorTextStyle: AppTypography.bodySm,
        showValueIndicator: ShowValueIndicator.onDrag,
        valueIndicatorShape: const RectangularSliderValueIndicatorShape(),
        trackHeight: 8,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
    );
  }
}
