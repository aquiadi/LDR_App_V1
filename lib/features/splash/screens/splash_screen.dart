import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/current_user_provider.dart';

/// Shown while the signed-in user's profile loads, and when that load fails.
///
/// The router parks the app here in both cases, so this is the only place a
/// failed first fetch can be retried from.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    // A retry keeps the old error while it reloads (isLoading is true), so
    // show the spinner then rather than an error card with a live button.
    final failed = userAsync.hasError && !userAsync.hasValue && !userAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: failed
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: AppColors.outline, size: 40),
                    const SizedBox(height: 16),
                    Text(
                      "Couldn't load your profile.",
                      style: AppTypography.bodyLg,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check your connection and try again.',
                      style: AppTypography.bodySm.copyWith(color: AppColors.outline),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(currentUserProvider),
                      child: const Text('Retry'),
                    ),
                    TextButton(
                      onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
