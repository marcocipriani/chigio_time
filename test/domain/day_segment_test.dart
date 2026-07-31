import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/features/timesheet/domain/day_segment.dart';

DateTime _t(int h, int m) => DateTime(2026, 7, 23, h, m);

void main() {
  group('DaySegment — comportamento dei tipi', () {
    test('solo work conta come lavorato', () {
      expect(DaySegment.isWork(DaySegment.work), isTrue);
      for (final t in [
        DaySegment.leave,
        DaySegment.bancaOre,
        DaySegment.lunch,
        DaySegment.pause,
      ]) {
        expect(DaySegment.isWork(t), isFalse, reason: t);
      }
    });

    test('leave e bancaOre coprono l\'orario dovuto, lunch e pause no', () {
      expect(DaySegment.coversDuty(DaySegment.leave), isTrue);
      expect(DaySegment.coversDuty(DaySegment.bancaOre), isTrue);
      expect(DaySegment.coversDuty(DaySegment.lunch), isFalse);
      expect(DaySegment.coversDuty(DaySegment.pause), isFalse);
      expect(DaySegment.coversDuty(DaySegment.work), isFalse);
    });

    test('senza orari: lunch, pause e leave stanno dentro lo span, bancaOre fuori', () {
      // Una pausa o un permesso senza posizione interrompono il lavoro; la
      // banca ore e' un credito, non tempo trascorso nella giornata.
      expect(DaySegment.insideSpanWhenUnpositioned(DaySegment.lunch), isTrue);
      expect(DaySegment.insideSpanWhenUnpositioned(DaySegment.pause), isTrue);
      expect(DaySegment.insideSpanWhenUnpositioned(DaySegment.leave), isTrue);
      expect(DaySegment.insideSpanWhenUnpositioned(DaySegment.bancaOre), isFalse);
    });

    test('tipo sconosciuto degrada a inerte, non lancia', () {
      expect(DaySegment.isWork('pippo'), isFalse);
      expect(DaySegment.coversDuty('pippo'), isFalse);
      expect(DaySegment.insideSpanWhenUnpositioned('pippo'), isFalse);
    });
  });

  group('DaySegment — durata e sovrapposizione', () {
    test('durationMins dagli orari quando ci sono', () {
      final s = DaySegment(
        type: DaySegment.leave,
        start: _t(12, 52),
        end: _t(15, 8),
      );
      expect(s.durationMins, 136);
    });

    test('durationMins dai minuti quando gli orari mancano', () {
      const s = DaySegment(type: DaySegment.pause, mins: 7);
      expect(s.durationMins, 7);
    });

    test('durationMins non e\' mai negativa', () {
      final s = DaySegment(
        type: DaySegment.work,
        start: _t(15, 0),
        end: _t(14, 0),
      );
      expect(s.durationMins, 0);
    });

    test('overlapMins misura l\'intersezione con lo span', () {
      final dentro = DaySegment(
        type: DaySegment.leave,
        start: _t(12, 52),
        end: _t(15, 8),
      );
      expect(dentro.overlapMins(_t(10, 25), _t(18, 2)), 136);

      final fuori = DaySegment(
        type: DaySegment.leave,
        start: _t(8, 45),
        end: _t(10, 31),
      );
      expect(fuori.overlapMins(_t(10, 31), _t(17, 5)), 0);

      final parziale = DaySegment(
        type: DaySegment.leave,
        start: _t(10, 0),
        end: _t(11, 0),
      );
      expect(parziale.overlapMins(_t(10, 30), _t(18, 0)), 30);
    });

    test('overlapMins usa la regola del tipo quando manca la posizione', () {
      const pausa = DaySegment(type: DaySegment.pause, mins: 7);
      expect(pausa.overlapMins(_t(10, 23), _t(16, 23)), 7);

      const boe = DaySegment(type: DaySegment.bancaOre, mins: 103);
      expect(boe.overlapMins(_t(10, 23), _t(16, 23)), 0);
    });
  });
}
