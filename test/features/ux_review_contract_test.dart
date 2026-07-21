import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('review P1: dashboard non trasforma il primo errore in dati vuoti', () {
    final source = File(
      'lib/features/dashboard/presentation/dashboard_screen.dart',
    ).readAsStringSync();

    expect(source, contains('monthlyAsync.hasError && !monthlyAsync.hasValue'));
    expect(source, contains('monthlyAsync.value ?? const <DailyTimesheet>[]'));
    expect(source, isNot(contains('monthlyAsync.asData?.value ?? []')));
  });

  test(
    'review P1: gruppi social distinguono errore, loading e lista vuota',
    () {
      final source = File(
        'lib/features/social/presentation/social_screen.dart',
      ).readAsStringSync();

      expect(source, contains('groupsAsync.hasError && !groupsAsync.hasValue'));
      expect(
        source,
        contains('groupsAsync.isLoading && !groupsAsync.hasValue'),
      );
      expect(source, isNot(contains('groupsAsync.asData?.value ?? []')));
    },
  );

  test('review desktop: uscita prevista resta fuori dallo scroll hero', () {
    final source = File(
      'lib/features/dashboard/presentation/dashboard_screen.dart',
    ).readAsStringSync();

    expect(source, contains('_DesktopExitPill(exitTime: expectedExitTime)'));
    expect(source, contains('if (expectedExitTime != null)'));
  });

  test('review performance: Aurora non mantiene un ticker continuo', () {
    final source = File(
      'lib/features/dashboard/presentation/dashboard_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('late final AnimationController _t')));
    expect(source, contains('painter: const _AuroraPainter()'));
  });
}
