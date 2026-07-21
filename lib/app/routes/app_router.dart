import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../shared/widgets/main_shell_screen.dart';
import '../../shared/widgets/pcm_assignment_gate.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/timesheet/presentation/timesheet_screen.dart';
import '../../features/social/presentation/social_screen.dart';
import '../../features/salary/presentation/salary_screen.dart';
import '../../features/projects/presentation/projects_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/onboarding_screen.dart';
import '../../features/authentication/data/auth_repository.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/social/presentation/notifications_screen.dart';
import '../../features/chigio/presentation/chigio_screen.dart';
import '../../features/profile/presentation/sau_screen.dart';
import '../../features/profile/presentation/stats_screen.dart';

part 'app_router.g.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

Widget _withPcmAssignmentGate(Widget child) =>
    PcmAssignmentGate(child: child);

// Notifies GoRouter to re-evaluate redirects when auth state OR profile-gate
// state changes. Created once, kept alive alongside the router.
//
// Listening to hasProfileStreamProvider here is what makes the gate reactive:
// the keepAlive router holds a permanent subscription, so the (auto-dispose)
// stream is never torn down mid-flight, and every emission re-runs the
// (now synchronous) redirect. This replaces the old async Firestore get()
// inside redirect, which raced against concurrent auth emissions.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authStateChangesProvider, (_, _) => notifyListeners());
    ref.listen(hasProfileStreamProvider, (_, _) => notifyListeners());
  }
}

// keepAlive: GoRouter must NOT be recreated on every auth-state emission.
// Recreating it would reset the navigation stack and trigger multiple
// concurrent redirects that race against each other.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: notifier,

    // Synchronous redirect: reads two reactive providers (auth + profile
    // gate). No async/await, no Firestore get(), no SharedPreferences — so it
    // can't race against concurrent auth emissions and can't bounce a
    // just-onboarded user back to /onboarding. hasProfileStreamProvider is the
    // single source of truth for completeness (see profileDocIsComplete); it
    // reads Firestore's offline cache first, so it still works offline.
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);
      if (authState.isLoading) return null;

      final user = authState.asData?.value;
      final isAuth = user != null;

      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToOnboarding = state.matchedLocation == '/onboarding';

      if (!isAuth) {
        return isGoingToLogin ? null : '/login';
      }

      final profile = ref.read(hasProfileStreamProvider);
      // Still resolving: don't force any redirect yet (avoids flashing
      // onboarding before the cache/server answers). The provider emission
      // re-runs this redirect via _RouterNotifier.
      if (profile.isLoading) return null;
      // Network/permission error: don't force onboarding — the user may
      // already have a profile. Wait for the next emission.
      if (profile.hasError) return null;

      final hasProfile = profile.value ?? false;

      if (!hasProfile) {
        return isGoingToOnboarding ? null : '/onboarding';
      }

      if (isGoingToLogin || isGoingToOnboarding) {
        return '/dashboard';
      }

      return null;
    },

    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Profile pushes above the shell — no bottom nav visible
      GoRoute(
        path: '/profile',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            _withPcmAssignmentGate(const ProfileScreen()),
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            _withPcmAssignmentGate(const ProfileEditScreen()),
      ),
      // Notifications pushes above the shell — no bottom nav visible
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            _withPcmAssignmentGate(const NotificationsScreen()),
      ),
      GoRoute(
        path: '/chigio',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            _withPcmAssignmentGate(const ChigioScreen()),
      ),
      GoRoute(
        path: '/stats',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            _withPcmAssignmentGate(const StatsScreen()),
      ),
      // Andamento straordinario autorizzato (SAU) mese per mese
      GoRoute(
        path: '/sau',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            _withPcmAssignmentGate(const SauScreen()),
      ),

      // Main shell — 3 branches (profile is a top-level push)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _withPcmAssignmentGate(
          MainShellScreen(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/timesheet',
                builder: (context, state) => const TimesheetScreen(),
              ),
            ],
          ),
          // Progetti (3ª voce navbar) — ADR-0011 / F4.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects',
                builder: (context, state) => const ProjectsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/social',
                builder: (context, state) => const SocialScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/salary',
                builder: (context, state) => const SalaryScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
