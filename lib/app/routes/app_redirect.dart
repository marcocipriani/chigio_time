import '../../features/profile/domain/profile_gate.dart';

String? resolveAppRedirect({
  required bool authLoading,
  required bool isAuthenticated,
  required ProfileGateResult gate,
  required String location,
}) {
  if (authLoading) return null;
  final goingToLogin = location == '/login';
  final goingToOnboarding = location == '/onboarding';

  if (!isAuthenticated) return goingToLogin ? null : '/login';
  if (gate.requiresOnboarding) {
    return goingToOnboarding ? null : '/onboarding';
  }
  if (gate.allowsHome && (goingToLogin || goingToOnboarding)) {
    return '/dashboard';
  }
  return null;
}
