import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/features/projects/domain/project.dart';
import 'package:chigio_time/features/projects/domain/pomodoro_session.dart';
import 'package:chigio_time/features/projects/data/pomodoro_repository.dart';

void main() {
  group('Project', () {
    final p = Project.fromDoc('p1', {
      'name': 'Progetto X',
      'ownerUid': 'u1',
      'ownerName': 'Capo',
      'shared': true,
      'memberUids': ['u1', 'u2'],
      'colorValue': 0xFF0055A5,
    });
    test('ruoli e membership', () {
      expect(p.isOwner('u1'), isTrue);
      expect(p.isOwner('u2'), isFalse);
      expect(p.isMember('u2'), isTrue);
      expect(p.isMember('u3'), isFalse);
      expect(p.shared, isTrue);
    });
  });

  group('PomodoroSession', () {
    test('fromDoc', () {
      final s = PomodoroSession.fromDoc('s1', {
        'uid': 'u1',
        'focusMins': 45,
        'breakMins': 15,
        'confirmed': true,
        'dateId': '2026-06-01',
      });
      expect(s.uid, 'u1');
      expect(s.focusMins, 45);
      expect(s.confirmed, isTrue);
    });
  });

  group('ActivePomodoro — calcolo fase/pausa', () {
    final t0 = DateTime(2026, 1, 1, 9, 0, 0);

    test('elapsed sottrae le pause accumulate e quella in corso', () {
      final running = ActivePomodoro(
        projectId: 'p',
        projectName: 'X',
        focusMins: 25,
        breakMins: 5,
        startedAt: t0,
        pausedAccumSecs: 30,
      );
      final now = t0.add(const Duration(seconds: 90));
      expect(running.elapsedSecs(now), 60); // 90 - 30
      expect(running.remainingSecs(now), 25 * 60 - 60);
      expect(running.isPaused, isFalse);

      final paused = ActivePomodoro(
        projectId: 'p',
        projectName: 'X',
        focusMins: 25,
        breakMins: 5,
        startedAt: t0,
        pausedAt: t0.add(const Duration(seconds: 90)),
      );
      final now2 = t0.add(const Duration(seconds: 120));
      expect(paused.isPaused, isTrue);
      expect(paused.elapsedSecs(now2), 90); // 120 - 30 in pausa
    });

    test('fase pausa usa breakMins', () {
      final brk = ActivePomodoro(
        projectId: 'p',
        projectName: 'X',
        focusMins: 25,
        breakMins: 5,
        startedAt: t0,
        onBreak: true,
      );
      expect(brk.phaseSecs, 5 * 60);
    });
  });
}
