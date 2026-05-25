import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../network/supabase_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/current_user_provider.dart';
import '../../features/auth/providers/auth_state_provider.dart';
import '../../features/auth/providers/current_couple_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/onboarding/screens/invite_screen.dart';
import '../../features/onboarding/screens/solo_onboarding_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/checkin/screens/checkin_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../shared/widgets/bottom_nav_shell.dart';

part 'app_router.g.dart';

class AppRoutes {
  AppRoutes._();
  
  static const String splash = '/';
  static const String login = '/login';
  static const String onboarding = '/onboarding';
  static const String invite = '/invite';
  static const String dashboard = '/dashboard';
  static const String checkin = '/checkin';
  static const String history = '/history';
  static const String settings = '/settings';
}

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
    _ref.listen(currentUserProvider, (_, __) => notifyListeners());
    _ref.listen(currentCoupleStreamProvider, (_, __) => notifyListeners());
  }
}

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = supabase.auth.currentSession != null;
      final isGoingToLogin = state.matchedLocation == AppRoutes.login;
      
      if (!isLoggedIn) {
        return isGoingToLogin ? null : AppRoutes.login;
      }

      // Read instead of watch so we don't recreate the GoRouter
      final currentUserAsync = ref.read(currentUserProvider);
      final coupleAsync = ref.read(currentCoupleStreamProvider);

      // If logged in, wait for profile to load
      if (currentUserAsync is AsyncLoading) {
        return AppRoutes.splash;
      }

      final profile = currentUserAsync.value;
      final couple = coupleAsync.value;
      final hasCoupleId = profile?.coupleId != null;
      final isGoingToInvite = state.matchedLocation == AppRoutes.invite;
      final isGoingToOnboarding = state.matchedLocation == AppRoutes.onboarding;

      if (!hasCoupleId) {
        if (isGoingToInvite || isGoingToOnboarding) return null;
        return AppRoutes.invite;
      }

      // Has couple ID. Check if couple is fully formed.
      final isCoupleComplete = couple != null && couple.partner1Id != null && couple.partner2Id != null;

      if (!isCoupleComplete) {
        // Pending partner. Must stay on Invite screen to see the code or go to onboarding to recreate.
        if (isGoingToInvite || isGoingToOnboarding) return null;
        return AppRoutes.invite;
      }

      if (isGoingToLogin || isGoingToInvite || state.matchedLocation == AppRoutes.splash) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const SoloOnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.invite,
        builder: (context, state) => const InviteScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkin,
        builder: (context, state) => const CheckinScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return BottomNavShell(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) => const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.history,
            pageBuilder: (context, state) => const NoTransitionPage(child: HistoryScreen()),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
}
