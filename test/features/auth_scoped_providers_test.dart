import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// I repository che leggono `_auth.currentUser` in modo sincrono devono
/// dipendere da `currentUidProvider`: creati mentre l'auth sta ancora
/// risolvendo (all'avvio il router monta /dashboard prima della prima
/// emissione) restituirebbero uno `Stream.empty()` mai sostituito e la Home
/// resterebbe bloccata sullo skeleton dopo il login.
void main() {
  for (final path in const [
    'lib/features/timesheet/data/timesheet_repository.dart',
    'lib/features/dashboard/data/active_timer_repository.dart',
    'lib/features/profile/data/profile_repository.dart',
    'lib/features/social/data/social_repository.dart',
    'lib/features/projects/data/pomodoro_repository.dart',
  ]) {
    test('$path: il provider del repository osserva lo stato di auth', () {
      expect(
        File(path).readAsStringSync(),
        contains('ref.watch(currentUidProvider)'),
      );
    });
  }

  test('WorkTimer osserva activeTimerRepositoryProvider (non read)', () {
    expect(
      File(
        'lib/features/dashboard/presentation/timer_provider.dart',
      ).readAsStringSync(),
      contains('ref.watch(activeTimerRepositoryProvider).watch()'),
    );
  });
}
