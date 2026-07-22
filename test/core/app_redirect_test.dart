import 'package:chigio_time/app/routes/app_redirect.dart';
import 'package:chigio_time/features/profile/domain/profile_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolving = ProfileGateResult(
    status: ProfileGateStatus.resolving,
    hasUsableProfile: false,
  );
  const cached = ProfileGateResult(
    status: ProfileGateStatus.completeCached,
    hasUsableProfile: true,
  );
  const incomplete = ProfileGateResult(
    status: ProfileGateStatus.incompleteServer,
    hasUsableProfile: false,
  );
  const failed = ProfileGateResult(
    status: ProfileGateStatus.failure,
    hasUsableProfile: false,
    error: 'offline',
  );
  const failedWithCache = ProfileGateResult(
    status: ProfileGateStatus.failure,
    hasUsableProfile: true,
    error: 'offline',
  );

  test('unauthenticated users go only to login', () {
    expect(
      resolveAppRedirect(
        authLoading: false,
        isAuthenticated: false,
        gate: resolving,
        location: '/dashboard',
      ),
      '/login',
    );
    expect(
      resolveAppRedirect(
        authLoading: false,
        isAuthenticated: false,
        gate: resolving,
        location: '/login',
      ),
      isNull,
    );
  });

  test('resolving and failure never select onboarding', () {
    for (final gate in [resolving, failed]) {
      expect(
        resolveAppRedirect(
          authLoading: false,
          isAuthenticated: true,
          gate: gate,
          location: '/dashboard',
        ),
        isNull,
      );
    }
  });

  test('only incompleteServer selects onboarding', () {
    expect(
      resolveAppRedirect(
        authLoading: false,
        isAuthenticated: true,
        gate: incomplete,
        location: '/dashboard',
      ),
      '/onboarding',
    );
  });

  test('usable cache exits login or onboarding to dashboard', () {
    for (final gate in [cached, failedWithCache]) {
      for (final location in ['/login', '/onboarding']) {
        expect(
          resolveAppRedirect(
            authLoading: false,
            isAuthenticated: true,
            gate: gate,
            location: location,
          ),
          '/dashboard',
        );
      }
    }
  });
}
