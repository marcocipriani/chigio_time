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

  test('review segmenti: l\'editor di giornata scrive un segmento work', () {
    // ADR-0018: timer, editor e import scrivono segmenti. L'editor scriveva
    // i soli campi di giornata; poiche' `toMap` ometteva `segments` vuota e
    // il repository salva in merge, su Firestore restavano i segmenti
    // precedenti e il primo tocco sulla timeline riportava gli orari vecchi.
    // Il salvataggio passa da un repository che nessun test puo' istanziare
    // senza Firebase, quindi il contratto e' verificato sul sorgente.
    final source = File(
      'lib/features/timesheet/presentation/timesheet_screen.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('[DaySegment(type: DaySegment.work, start: start, end: end)]'),
    );
    expect(
      source,
      contains('isPresence ? entry.recomputedFromSegments(stdMins: stdMins)'),
    );
    // La condizione della timeline vive nel widget, non nella schermata.
    expect(source, contains('if (DayTimeline.showsFor(entry))'));
  });

  test('slide affordance nudges once and does not repeat forever', () {
    final source = File(
      'lib/features/dashboard/widgets/timbratura_hero.dart',
    ).readAsStringSync();
    expect(source, contains('_nudgeCtrl.forward()'));
    expect(source, isNot(contains(')..repeat();')));
  });
}
