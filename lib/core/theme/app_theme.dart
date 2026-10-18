import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static const double radius = 16;

  static ThemeData get light => _build(AppPalette.light);
  static ThemeData get dark => _build(AppPalette.dark);

  // Built from an explicit palette rather than AppColors, because both
  // themes are created up front while only one palette is active.
  static ThemeData _build(AppPalette c) {
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: c.outlineVariant),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      primaryColor: c.primary,
      scaffoldBackgroundColor: c.background,
      splashFactory: InkSparkle.splashFactory,

      colorScheme: ColorScheme(
        brightness: c.brightness,
        primary: c.primary,
        onPrimary: c.onPrimary,
        primaryContainer: c.primaryContainer,
        onPrimaryContainer: c.onPrimaryContainer,
        secondary: c.secondary,
        onSecondary: c.onSecondary,
        secondaryContainer: c.secondaryContainer,
        onSecondaryContainer: c.onSecondaryContainer,
        tertiary: c.tertiary,
        onTertiary: c.onTertiary,
        tertiaryContainer: c.tertiaryContainer,
        onTertiaryContainer: c.onTertiaryContainer,
        error: c.error,
        onError: c.onError,
        errorContainer: c.errorContainer,
        onErrorContainer: c.onErrorContainer,
        surface: c.background,
        onSurface: c.onSurface,
        onSurfaceVariant: c.onSurfaceVariant,
        surfaceContainerLowest: c.surfaceContainer,
        surfaceContainerLow: c.surfaceContainerLow,
        surfaceContainer: c.surfaceContainer,
        surfaceContainerHigh: c.surfaceContainerHigh,
        surfaceContainerHighest: c.surfaceContainerHighest,
        outline: c.outline,
        outlineVariant: c.outlineVariant,
        inverseSurface: c.inverseSurface,
        onInverseSurface: c.inverseOnSurface,
      ),

      textTheme: TextTheme(
        displayLarge: AppTypography.display,
        headlineLarge: AppTypography.headlineLg,
        headlineMedium: AppTypography.headlineMd,
        titleMedium: AppTypography.cardTitle,
        bodyLarge: AppTypography.bodyLg,
        bodyMedium: AppTypography.bodyMd,
        bodySmall: AppTypography.bodySm,
        labelLarge: AppTypography.buttonText,
        labelMedium: AppTypography.labelMd,
      ).apply(bodyColor: c.onSurface, displayColor: c.onSurface),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: c.onSurface,
        titleTextStyle: AppTypography.cardTitle.copyWith(color: c.onSurface),
      ),

      cardTheme: CardThemeData(
        color: c.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius + 4),
          side: BorderSide(color: c.outlineVariant),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceContainer,
        hintStyle: AppTypography.bodyMd.copyWith(color: c.outline),
        labelStyle: AppTypography.bodySm.copyWith(color: c.onSurfaceVariant),
        floatingLabelStyle: AppTypography.bodySm.copyWith(color: c.primary),
        prefixIconColor: c.outline,
        suffixIconColor: c.outline,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        disabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: c.error),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: c.error, width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.surfaceContainerHighest,
          disabledForegroundColor: c.outline,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: AppTypography.buttonText,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.onSurface,
          minimumSize: const Size(0, 52),
          side: BorderSide(color: c.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: AppTypography.buttonText,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: AppTypography.buttonText.copyWith(fontSize: 15),
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: c.primary,
        inactiveTrackColor: c.surfaceContainerHighest,
        thumbColor: c.primary,
        overlayColor: c.primary.withValues(alpha: 0.12),
        valueIndicatorColor: c.inverseSurface,
        valueIndicatorTextStyle: AppTypography.bodySm.copyWith(color: c.inverseOnSurface),
        showValueIndicator: ShowValueIndicator.onDrag,
        valueIndicatorShape: const RectangularSliderValueIndicatorShape(),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onPrimary : c.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.primaryContainer : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.onPrimaryContainer : c.onSurfaceVariant,
          ),
          side: WidgetStateProperty.all(BorderSide(color: c.outlineVariant)),
          textStyle: WidgetStateProperty.all(AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600)),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          minimumSize: WidgetStateProperty.all(const Size(0, 44)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.inverseSurface,
        contentTextStyle: AppTypography.bodyMd.copyWith(color: c.inverseOnSurface),
        actionTextColor: c.inversePrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius + 8)),
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.surfaceContainer,
        surfaceTintColor: Colors.transparent,
      ),

      dividerTheme: DividerThemeData(color: c.outlineVariant, space: 1),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
    );
  }
}
