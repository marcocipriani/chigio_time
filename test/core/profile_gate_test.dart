import 'dart:io';

import 'package:chigio_time/features/profile/domain/profile_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolving = ProfileGateResult(
    status: ProfileGateStatus.resolving,
    hasUsableProfile: false,
  );

  test('cache incomplete remains resolving and never becomes onboarding', () {
    final result = reduceProfileGateSnapshot(
      previous: resolving,
      data: const {'photoURL': 'https://example.test/photo.png'},
      isFromCache: true,
    );
    expect(result.status, ProfileGateStatus.resolving);
    expect(result.hasUsableProfile, isFalse);
    expect(result.requiresOnboarding, isFalse);
  });

  test('cache complete permits Home without server authority', () {
    final result = reduceProfileGateSnapshot(
      previous: resolving,
      data: const {'hasCompletedOnboarding': true},
      isFromCache: true,
    );
    expect(result.status, ProfileGateStatus.completeCached);
    expect(result.hasUsableProfile, isTrue);
  });

  test('server incomplete is the only snapshot that requires onboarding', () {
    final result = reduceProfileGateSnapshot(
      previous: resolving,
      data: null,
      isFromCache: false,
    );
    expect(result.status, ProfileGateStatus.incompleteServer);
    expect(result.requiresOnboarding, isTrue);
  });

  test('error preserves a previously usable cached profile', () {
    const cached = ProfileGateResult(
      status: ProfileGateStatus.completeCached,
      hasUsableProfile: true,
    );
    final error = StateError('network unavailable');
    final result = reduceProfileGateError(previous: cached, error: error);
    expect(result.status, ProfileGateStatus.failure);
    expect(result.hasUsableProfile, isTrue);
    expect(result.error, same(error));
    expect(result.requiresOnboarding, isFalse);
  });

  test('profile stream includes metadata and maintains the local marker', () {
    final source = File(
      'lib/features/profile/data/profile_repository.dart',
    ).readAsStringSync();
    expect(
      source,
      matches(RegExp(r'snapshots\(\s*includeMetadataChanges: true')),
    );
    expect(source, contains(r"'hasProfile_${user.uid}'"));
    expect(source, contains('preferences.setBool(markerKey, true)'));
    expect(source, contains('preferences.remove(markerKey)'));
  });
}
