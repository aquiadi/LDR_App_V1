import 'package:flutter/material.dart';

/// One full set of colours. There is a light and a dark one; [AppColors]
/// reads from whichever is active.
///
/// Cool mist (light) or midnight (dark) surfaces, iris violet for you, rose
/// for your partner, teal for the daily question. The only gradients in the
/// app are the [SkyPalette] ones, and they mean something.
class AppPalette {
  final Brightness brightness;
  final Color background;
  final Color surfaceContainer;
  final Color surfaceContainerLow;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color surfaceVariant;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color inversePrimary;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color outline;
  final Color outlineVariant;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color inverseSurface;
  final Color inverseOnSurface;
  final Color success;
  final Color warning;
  final List<BoxShadow> cardShadow;

  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surfaceContainer,
    required this.surfaceContainerLow,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.surfaceVariant,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.inversePrimary,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.outline,
    required this.outlineVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.success,
    required this.warning,
    required this.cardShadow,
  });

  static const light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xffF4F5FA),
    surfaceContainer: Color(0xffFFFFFF),
    surfaceContainerLow: Color(0xffF9FAFD),
    surfaceContainerHigh: Color(0xffECEEF5),
    surfaceContainerHighest: Color(0xffE3E6F0),
    surfaceVariant: Color(0xffEEF0F6),
    primary: Color(0xff5B4CF0),
    onPrimary: Color(0xffFFFFFF),
    primaryContainer: Color(0xffE7E4FF),
    onPrimaryContainer: Color(0xff23178A),
    inversePrimary: Color(0xffA79BFF),
    secondary: Color(0xffD23C6E),
    onSecondary: Color(0xffFFFFFF),
    secondaryContainer: Color(0xffFCE4EC),
    onSecondaryContainer: Color(0xff6B0F33),
    tertiary: Color(0xff0E8F86),
    onTertiary: Color(0xffFFFFFF),
    tertiaryContainer: Color(0xffDDF4F1),
    onTertiaryContainer: Color(0xff063F3B),
    error: Color(0xffC62828),
    onError: Color(0xffFFFFFF),
    errorContainer: Color(0xffFDE2E1),
    onErrorContainer: Color(0xff5F1412),
    outline: Color(0xff6B7089),
    outlineVariant: Color(0xffE2E4EE),
    onSurface: Color(0xff0E1020),
    onSurfaceVariant: Color(0xff4B5068),
    inverseSurface: Color(0xff1A1D2E),
    inverseOnSurface: Color(0xffECEDF5),
    success: Color(0xff138A5B),
    warning: Color(0xffB26B00),
    cardShadow: [
      BoxShadow(color: Color(0x0F0E1020), blurRadius: 24, offset: Offset(0, 8)),
      BoxShadow(color: Color(0x0A0E1020), blurRadius: 2, offset: Offset(0, 1)),
    ],
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xff0B0D17),
    surfaceContainer: Color(0xff151827),
    surfaceContainerLow: Color(0xff10121E),
    surfaceContainerHigh: Color(0xff1D2133),
    surfaceContainerHighest: Color(0xff262A3F),
    surfaceVariant: Color(0xff1A1D2E),
    primary: Color(0xffA79BFF),
    onPrimary: Color(0xff160E5C),
    primaryContainer: Color(0xff2D2670),
    onPrimaryContainer: Color(0xffE2DEFF),
    inversePrimary: Color(0xff5B4CF0),
    secondary: Color(0xffFF7FA8),
    onSecondary: Color(0xff4A0A23),
    secondaryContainer: Color(0xff4A1730),
    onSecondaryContainer: Color(0xffFFD9E4),
    tertiary: Color(0xff4FD1C5),
    onTertiary: Color(0xff062B28),
    tertiaryContainer: Color(0xff0F3A37),
    onTertiaryContainer: Color(0xffC9F5EF),
    error: Color(0xffFF8A80),
    onError: Color(0xff5C1A16),
    errorContainer: Color(0xff5C1A16),
    onErrorContainer: Color(0xffFFDAD5),
    outline: Color(0xff8A8FA8),
    outlineVariant: Color(0xff262A3D),
    onSurface: Color(0xffECEDF5),
    onSurfaceVariant: Color(0xffA8ACC2),
    inverseSurface: Color(0xffECEDF5),
    inverseOnSurface: Color(0xff151827),
    success: Color(0xff4ADE9B),
    warning: Color(0xffF5B453),
    cardShadow: [],
  );
}

/// The active palette, read by every screen.
///
/// The app calls [use] from `MaterialApp.builder` with the resolved
/// brightness and rebuilds the tree under a brightness key, so switching
/// between light and dark repaints everything without each widget having to
/// look the colour up through `Theme.of`.
class AppColors {
  AppColors._();

  static AppPalette _p = AppPalette.light;

  static void use(Brightness brightness) =>
      _p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;

  static bool get isDark => _p.brightness == Brightness.dark;

  static Color get background => _p.background;
  static Color get surface => _p.background;
  static Color get surfaceContainer => _p.surfaceContainer;
  static Color get surfaceContainerLow => _p.surfaceContainerLow;
  static Color get surfaceContainerHigh => _p.surfaceContainerHigh;
  static Color get surfaceContainerHighest => _p.surfaceContainerHighest;
  static Color get surfaceVariant => _p.surfaceVariant;

  static Color get primary => _p.primary;
  static Color get onPrimary => _p.onPrimary;
  static Color get primaryContainer => _p.primaryContainer;
  static Color get onPrimaryContainer => _p.onPrimaryContainer;
  static Color get inversePrimary => _p.inversePrimary;

  static Color get secondary => _p.secondary;
  static Color get onSecondary => _p.onSecondary;
  static Color get secondaryContainer => _p.secondaryContainer;
  static Color get onSecondaryContainer => _p.onSecondaryContainer;

  static Color get tertiary => _p.tertiary;
  static Color get onTertiary => _p.onTertiary;
  static Color get tertiaryContainer => _p.tertiaryContainer;
  static Color get onTertiaryContainer => _p.onTertiaryContainer;

  static Color get error => _p.error;
  static Color get onError => _p.onError;
  static Color get errorContainer => _p.errorContainer;
  static Color get onErrorContainer => _p.onErrorContainer;

  static Color get outline => _p.outline;
  static Color get outlineVariant => _p.outlineVariant;

  static Color get onBackground => _p.onSurface;
  static Color get onSurface => _p.onSurface;
  static Color get onSurfaceVariant => _p.onSurfaceVariant;
  static Color get inverseSurface => _p.inverseSurface;
  static Color get inverseOnSurface => _p.inverseOnSurface;

  // Older names, still used across the screens
  static Color get surfaceElevated => _p.surfaceContainer;
  static Color get textPrimary => _p.onSurface;
  static Color get textSecondary => _p.onSurfaceVariant;
  static Color get textMuted => _p.outline;
  static Color get border => _p.outlineVariant;
  static Color get success => _p.success;
  static Color get warning => _p.warning;

  static List<BoxShadow> get cardShadow => _p.cardShadow;
}

/// The sky at a given local hour. Used for the partner card, so you can see
/// at a glance whether it is morning or the middle of the night for them.
class SkyPalette {
  SkyPalette._();

  /// With [dim], the sky is pulled a little toward the night background, so
  /// a bright daytime card doesn't glare in dark mode.
  static LinearGradient forHour(int hour, {bool dim = false}) {
    final base = switch (hour) {
      >= 5 && < 8 => const [Color(0xffF6C9A8), Color(0xffE7A3B5)], // dawn
      >= 8 && < 17 => const [Color(0xffBCD6F5), Color(0xffE5EEFA)], // day
      >= 17 && < 20 => const [Color(0xffF4AE7E), Color(0xffC86A9A)], // dusk
      _ => const [Color(0xff2A2F6B), Color(0xff121534)], // night
    };
    final colors = dim
        ? [for (final c in base) Color.lerp(c, const Color(0xff0B0D17), 0.15)!]
        : base;
    return LinearGradient(
      colors: colors,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  /// Whether text on [forHour] needs to be light.
  static bool isDark(int hour) => hour < 5 || hour >= 20;

  /// Text colours for a sky card. Fixed, because the sky is the same colour
  /// whichever theme the app is in.
  static const Color inkOnLight = Color(0xff0E1020);
  static const Color inkOnDark = Color(0xffF4F5FA);

  static String label(int hour) => switch (hour) {
        >= 5 && < 8 => 'Early morning',
        >= 8 && < 12 => 'Morning',
        >= 12 && < 17 => 'Afternoon',
        >= 17 && < 20 => 'Evening',
        >= 20 && < 23 => 'Night',
        _ => 'Late night',
      };
}
