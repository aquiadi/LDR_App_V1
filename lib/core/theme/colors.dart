import 'package:flutter/material.dart';

/// Design tokens.
///
/// Warm paper and ink, one ember accent for "you" and a dusk blue for
/// "them". The only gradients in the app are the [SkyPalette] ones, and they
/// mean something: the colour of the sky where each partner is right now.
class AppColors {
  AppColors._();

  // Paper
  static const Color background = Color(0xffF7F2EA);
  static const Color surface = Color(0xffF7F2EA);
  static const Color surfaceContainer = Color(0xffFFFDF9);
  static const Color surfaceContainerLow = Color(0xffFBF7F1);
  static const Color surfaceContainerHigh = Color(0xffF0E9DF);
  static const Color surfaceContainerHighest = Color(0xffE8DFD2);
  static const Color surfaceVariant = Color(0xffEFE8DD);

  // Ember: you, primary actions
  static const Color primary = Color(0xffC24B3E);
  static const Color onPrimary = Color(0xffFFFFFF);
  static const Color primaryContainer = Color(0xffF7DDD5);
  static const Color onPrimaryContainer = Color(0xff6E2118);
  static const Color inversePrimary = Color(0xffE8846F);

  // Dusk: your partner
  static const Color secondary = Color(0xff2F3A66);
  static const Color onSecondary = Color(0xffFFFFFF);
  static const Color secondaryContainer = Color(0xffDFE3F2);
  static const Color onSecondaryContainer = Color(0xff1E2547);

  static const Color tertiary = Color(0xff8A6A3D);
  static const Color onTertiary = Color(0xffFFFFFF);
  static const Color tertiaryContainer = Color(0xffF1E4CF);
  static const Color onTertiaryContainer = Color(0xff3D2C12);

  // Status
  static const Color error = Color(0xffB3261E);
  static const Color onError = Color(0xffFFFFFF);
  static const Color errorContainer = Color(0xffF9DEDC);
  static const Color onErrorContainer = Color(0xff410E0B);

  // Ink and lines
  static const Color outline = Color(0xff8E857A);
  static const Color outlineVariant = Color(0xffE3DACC);

  static const Color onBackground = Color(0xff221C17);
  static const Color onSurface = Color(0xff221C17);
  static const Color onSurfaceVariant = Color(0xff5E554C);
  static const Color inverseSurface = Color(0xff2B2520);
  static const Color inverseOnSurface = Color(0xffF7F2EA);

  // Older names, still used across the screens
  static const Color surfaceElevated = surfaceContainer;
  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textMuted = outline;
  static const Color border = outlineVariant;
  static const Color success = Color(0xff3E7B5B);
  static const Color warning = Color(0xffB7791F);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [primary, Color(0xffA93D31)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Soft shadow for raised paper.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0F221C17), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A221C17), blurRadius: 2, offset: Offset(0, 1)),
  ];
}

/// The sky at a given local hour. Used for the partner card, so you can see
/// at a glance whether it is morning or the middle of the night for them.
class SkyPalette {
  SkyPalette._();

  static LinearGradient forHour(int hour) {
    final colors = switch (hour) {
      >= 5 && < 8 => const [Color(0xffF4C7A1), Color(0xffE9A6A1)], // dawn
      >= 8 && < 17 => const [Color(0xffBFD8EC), Color(0xffE6EEF3)], // day
      >= 17 && < 20 => const [Color(0xffF2B279), Color(0xffD9776A)], // dusk
      _ => const [Color(0xff2F3A66), Color(0xff1B2140)], // night
    };
    return LinearGradient(
      colors: colors,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  /// Whether text on [forHour] needs to be light.
  static bool isDark(int hour) => hour < 5 || hour >= 20;

  static String label(int hour) => switch (hour) {
        >= 5 && < 8 => 'Early morning',
        >= 8 && < 12 => 'Morning',
        >= 12 && < 17 => 'Afternoon',
        >= 17 && < 20 => 'Evening',
        >= 20 && < 23 => 'Night',
        _ => 'Late night',
      };
}
