import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/typography.dart';
import 'core/theme/colors.dart';
import 'core/navigation/app_router.dart';
import 'features/settings/providers/appearance_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inter ships in assets/google_fonts/ (and Archivo Expanded in assets/fonts/). Without this the package
  // fetches them from fonts.gstatic.com on first paint, so a cold start with
  // no network renders the entire UI without any text.
  GoogleFonts.config.allowRuntimeFetching = false;

  try {
    Appearance.prefs = await SharedPreferences.getInstance();
  } catch (_) {
    // No storage available: the app just follows the system theme.
  }

  // Retrieve environment variables
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  bool isSupabaseInitialized = false;
  String? initializationError;

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      isSupabaseInitialized = true;
    } catch (e) {
      initializationError = e.toString();
    }
  } else {
    initializationError = 
        'Supabase configuration keys are missing. '
        'Please pass them via Dart defines at compile time:\n'
        '--dart-define=SUPABASE_URL=YOUR_URL\n'
        '--dart-define=SUPABASE_ANON_KEY=YOUR_KEY';
  }

  runApp(
    ProviderScope(
      child: LdrApp(
        isConfigured: isSupabaseInitialized,
        configErrorMessage: initializationError,
      ),
    ),
  );
}

class LdrApp extends ConsumerWidget {
  final bool isConfigured;
  final String? configErrorMessage;

  const LdrApp({
    super.key,
    required this.isConfigured,
    this.configErrorMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Without the Supabase keys there is nothing to connect to, so explain how to set them
    if (!isConfigured) {
      return MaterialApp(
        title: 'LDR Sync',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeAnimationDuration: Duration.zero,
        debugShowCheckedModeBanner: false,
        builder: _withPalette,
        home: ConfigurationErrorScreen(message: configErrorMessage),
      );
    }

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'LDR Sync',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(appearanceProvider),
      themeAnimationDuration: Duration.zero,
      debugShowCheckedModeBanner: false,
      builder: _withPalette,
      routerConfig: router,
    );
  }

  static Brightness? _appliedBrightness;

  /// Points [AppColors] at the palette for the theme MaterialApp resolved
  /// (system, light or dark).
  ///
  /// Widgets read AppColors directly rather than through `Theme.of`, so they
  /// don't rebuild by themselves when it changes, and `const` widgets under
  /// GoRouter's keyed navigators would keep the old colours. So after a
  /// switch, every element below is marked for rebuild once.
  static Widget _withPalette(BuildContext context, Widget? child) {
    final brightness = Theme.of(context).brightness;
    if (brightness != _appliedBrightness) {
      final isSwitch = _appliedBrightness != null;
      _appliedBrightness = brightness;
      AppColors.use(brightness);
      if (isSwitch) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          void rebuild(Element e) {
            e.markNeedsBuild();
            e.visitChildren(rebuild);
          }
          (context as Element).visitChildren(rebuild);
        });
      }
    }
    return child ?? const SizedBox.shrink();
  }
}

/// Shown instead of the app when the Supabase keys were not compiled in.
class ConfigurationErrorScreen extends StatelessWidget {
  final String? message;

  const ConfigurationErrorScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Glowing heart visual helper
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Sync Setting Required',
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message ?? 'Unable to connect to database.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to run locally:',
                      style: AppTypography.subtitle.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. Create a Supabase project at supabase.com\n'
                      '2. Fetch your project API URL & anon key\n'
                      '3. Launch using the command:\n'
                      '   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
                      style: AppTypography.bodySmall.copyWith(height: 1.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
