import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/widgets/main_shell_screen.dart';
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
import '../../features/profile/presentation/stats_screen.dart';

part 'app_router.g.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// Notifies GoRouter to re-evaluate redirects when auth state changes.
// Created once, kept alive alongside the router.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authStateChangesProvider, (_, _) => notifyListeners());
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

    redirect: (context, state) async {
      // Read auth state at redirect time, not at router-creation time.
      final authState = ref.read(authStateChangesProvider);
      if (authState.isLoading) return null;

      final user = authState.asData?.value;
      final isAuth = user != null;

      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToOnboarding = state.matchedLocation == '/onboarding';

      if (!isAuth) {
        return isGoingToLogin ? null : '/login';
      }

      // Fast path: SharedPreferences local cache.
      final prefs = await SharedPreferences.getInstance();
      bool hasProfile = prefs.getBool('hasProfile_${user.uid}') ?? false;

      if (!hasProfile) {
        // Slow path: direct one-shot Firestore get().
        // Do NOT use a StreamProvider here — auto-disposed providers are
        // torn down by Riverpod's scheduler before Firestore emits its first
        // snapshot, causing "disposed during loading state" Bad state errors.
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          hasProfile = doc.exists && profileDocIsComplete(doc.data());
          if (hasProfile) {
            await prefs.setBool('hasProfile_${user.uid}', true);
            // Back-fill the explicit flag for legacy docs (completed via the
            // name/employmentType fallback) so every device takes the fast
            // path and never re-triggers onboarding.
            if (doc.data()?['hasCompletedOnboarding'] != true) {
              doc.reference.update({'hasCompletedOnboarding': true}).ignore();
            }
          } else if (doc.metadata.isFromCache) {
            // Incomplete result came from the offline cache (e.g. first launch
            // on a fresh device with no synced data yet). Don't force a user
            // who may already have a profile through onboarding — wait for the
            // server snapshot, which re-triggers this redirect via auth state.
            return null;
          }
        } catch (e, st) {
          debugPrint('[appRouter] hasProfile check failed: $e\n$st');
          // Network/permission error: don't force onboarding — the user may
          // already have a profile. Return null (no redirect) and let the
          // next auth-state change trigger a fresh check.
          return null;
        }
      }

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
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ProfileEditScreen(),
      ),
      // Notifications pushes above the shell — no bottom nav visible
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/chigio',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ChigioScreen(),
      ),
      GoRoute(
        path: '/stats',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const StatsScreen(),
      ),

      // Main shell — 3 branches (profile is a top-level push)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShellScreen(navigationShell: navigationShell),
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
