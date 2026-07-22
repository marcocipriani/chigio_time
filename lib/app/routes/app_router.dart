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
import '../../features/profile/domain/profile_gate.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/social/presentation/notifications_screen.dart';
import '../../features/chigio/presentation/chigio_screen.dart';
import '../../features/profile/presentation/sau_screen.dart';
import '../../features/profile/presentation/stats_screen.dart';
import 'app_redirect.dart';

part 'app_router.g.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

Widget _withPcmAssignmentGate(Widget child) => PcmAssignmentGate(child: child);

// Notifies GoRouter to re-evaluate redirects when auth state OR profile-gate
// state changes. Created once, kept alive alongside the router.
//
// Listening to profileGateProvider here is what makes the gate reactive:
// the keepAlive router holds a permanent subscription, so the (auto-dispose)
// stream is never torn down mid-flight, and every emission re-runs the
// (now synchronous) redirect. This replaces the old async Firestore get()
// inside redirect, which raced against concurrent auth emissions.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authStateChangesProvider, (_, _) => notifyListeners());
    ref.listen(profileGateProvider, (_, _) => notifyListeners());
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
    // gate). No async/await and no Firestore get(), so it cannot race against
    // concurrent auth emissions or treat a cache-only miss as a new user.
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);
      final user = authState.asData?.value;
      final gateAsync = ref.read(profileGateProvider);
      final gate =
          gateAsync.asData?.value ??
          ProfileGateResult(
            status: gateAsync.hasError
                ? ProfileGateStatus.failure
                : ProfileGateStatus.resolving,
            hasUsableProfile: false,
            error: gateAsync.error,
          );

      return resolveAppRedirect(
        authLoading: authState.isLoading,
        isAuthenticated: user != null,
        gate: gate,
        location: state.matchedLocation,
      );
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
        builder: (context, state) => _withPcmAssignmentGate(const SauScreen()),
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
