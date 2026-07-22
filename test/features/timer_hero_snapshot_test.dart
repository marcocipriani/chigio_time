import 'dart:io';

import 'package:chigio_time/features/dashboard/presentation/timer_provider.dart';
import 'package:chigio_time/features/dashboard/widgets/timbratura_hero.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 7, 22, 9);

  TimerState state(DateTime now, {WorkState status = WorkState.working}) =>
      TimerState(
        status: status,
        startTime: start,
        currentTime: now,
        standardWorkMins: 456,
      );

  test('hero snapshot ignores seconds inside one minute', () {
    final first = TimerHeroSnapshot(state(DateTime(2026, 7, 22, 9, 15, 1)));
    final second = TimerHeroSnapshot(state(DateTime(2026, 7, 22, 9, 15, 59)));
    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('hero snapshot changes at the next minute or structural transition', () {
    final base = TimerHeroSnapshot(state(DateTime(2026, 7, 22, 9, 15, 59)));
    final nextMinute = TimerHeroSnapshot(state(DateTime(2026, 7, 22, 9, 16)));
    final paused = TimerHeroSnapshot(
      state(DateTime(2026, 7, 22, 9, 15, 59), status: WorkState.paused),
    );
    expect(base, isNot(nextMinute));
    expect(base, isNot(paused));
  });

  test('live pause formatter retains second precision', () {
    expect(formatLivePause(5), '00:05');
    expect(formatLivePause(65), '01:05');
    expect(formatLivePause(3661), '01:01:01');
  });

  test(
    'hero wiring selects the minute snapshot and isolates pause seconds',
    () {
      final source = File(
        'lib/features/dashboard/widgets/timbratura_hero.dart',
      ).readAsStringSync();
      expect(source, contains('TimerHeroSnapshot(value)'));
      expect(source, contains("key: const Key('live-pause-duration')"));
      expect(
        source,
        isNot(contains('final state = ref.watch(workTimerProvider);')),
      );
    },
  );
}
