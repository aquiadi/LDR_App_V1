import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../services/auth_service.dart';
import 'current_user_provider.dart';

part 'auth_provider.g.dart';

// Kept alive on purpose. Every action here navigates away from the screen
// that started it (login -> invite, settings -> login), which disposed an
// auto-dispose controller mid-call; assigning `state` after the await then
// threw "Future already completed" as an uncaught error.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(email: email, password: password);
      ref.invalidate(currentUserProvider);
    });
  }

  Future<void> signUp({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      await authService.signUpWithEmail(email: email, password: password);
      // Wait a moment for the DB trigger to create the user profile
      await Future.delayed(const Duration(seconds: 1));
      ref.invalidate(currentUserProvider);
    });
  }

  /// Always ends signed out with a clean controller.
  ///
  /// gotrue clears the local session and emits `signedOut` *before* it calls
  /// the server's /logout, so by the time that request finishes the router
  /// has already shown the login screen. Because this controller is kept
  /// alive, putting it in a loading or error state here would leave the next
  /// person a disabled Log In button, or a logout network error in red. A
  /// failed server-side logout only matters to the server (the token expires
  /// on its own), so it is logged and otherwise ignored.
  Future<void> signOut() async {
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (e) {
      debugPrint('Server-side sign-out failed: $e');
    }
    ref.invalidate(currentUserProvider);
    state = const AsyncValue.data(null);
  }
}
