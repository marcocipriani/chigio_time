import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/features/timesheet/domain/daily_timesheet.dart';
import 'package:chigio_time/features/timesheet/domain/absence_kind.dart';
import 'package:chigio_time/features/timesheet/domain/day_segment.dart';

void main() {
  group('DailyTimesheet', () {
    test('getter tipo giornata', () {
      DailyTimesheet base(String? t) => DailyTimesheet(
        dateId: '2026-06-01',
        startTime: DateTime(2026, 6, 1, 9),
        endTime: DateTime(2026, 6, 1, 17),
        standardPauseMins: 0,
        lunchPauseMins: 30,
        netWorkedMins: 450,
        extraMins: 0,
        workType: t,
      );
      expect(base(WorkType.remote).isRemote, isTrue);
      expect(base(WorkType.leave).isLeave, isTrue);
      expect(base(WorkType.holiday).isHoliday, isTrue);
      expect(base(WorkType.presence).isRemote, isFalse);
      expect(base(null).isLeave, isFalse); // null = presence backward-compat
    });

    test('toMap/fromMap round-trip conserva i campi chiave', () {
      final entry = DailyTimesheet(
        dateId: '2026-06-02',
        startTime: DateTime(2026, 6, 2, 9, 0),
        endTime: DateTime(2026, 6, 2, 17, 36),
        standardPauseMins: 0,
        lunchPauseMins: 30,
        netWorkedMins: 456,
        extraMins: 20,
        sliMins: 12,
        sboMins: 8,
        workType: WorkType.presence,
        note: 'Meeting',
      );
      final back = DailyTimesheet.fromMap(entry.toMap());
      expect(back.dateId, entry.dateId);
      expect(back.netWorkedMins, 456);
      expect(back.extraMins, 20);
      expect(back.sliMins, 12);
      expect(back.sboMins, 8);
      expect(back.workType, WorkType.presence);
      expect(back.note, 'Meeting');
    });

    test('toMap scrive sempre segments, anche vuota', () {
      // Le scritture usano merge: omettere il campo lascerebbe su Firestore i
      // segmenti della versione precedente della giornata.
      final ferie = DailyTimesheet(
        dateId: '2026-06-07',
        startTime: DateTime(2026, 6, 7, 9),
        endTime: DateTime(2026, 6, 7, 9),
        standardPauseMins: 0,
        lunchPauseMins: 0,
        netWorkedMins: 0,
        extraMins: 0,
        workType: WorkType.holiday,
      );
      expect(ferie.toMap()['segments'], isEmpty);
      expect(ferie.toMap().containsKey('segments'), isTrue);
    });

    test('fromMap tollera start/end mancanti o corrotti (no throw)', () {
      // Un doc legacy/corrotto non deve far crashare l'intero stream timesheet.
      DailyTimesheet parse(Map<String, dynamic> m) => DailyTimesheet.fromMap(m);

      // startTime/endTime assenti → fallback alla mezzanotte del dateId.
      final missing = parse({'dateId': '2026-06-04', 'netWorkedMins': 100});
      expect(missing.startTime, DateTime(2026, 6, 4));
      expect(missing.endTime, DateTime(2026, 6, 4));
      expect(missing.netWorkedMins, 100);

      // Valori non-stringa / non parsabili → nessuna eccezione.
      expect(
        () => parse({'dateId': '2026-06-05', 'startTime': 12345}),
        returnsNormally,
      );
      expect(
        () => parse({'dateId': 'corrotto', 'startTime': 'non-una-data'}),
        returnsNormally,
      );

      // dateId valido + start valido → parsing normale preservato.
      final ok = parse({
        'dateId': '2026-06-06',
        'startTime': DateTime(2026, 6, 6, 9).toIso8601String(),
        'endTime': DateTime(2026, 6, 6, 17).toIso8601String(),
      });
      expect(ok.startTime, DateTime(2026, 6, 6, 9));
      expect(ok.endTime, DateTime(2026, 6, 6, 17));
    });

    test('giornata legacy: il deficit non conta due volte il permesso', () {
      // Documento salvato prima di ADR-0018: nessun campo `segments` e
      // `extraMins` nella convenzione vecchia (netto − dovuto), che non
      // contiene la copertura del permesso. Span 9:00–15:00 = 360, netto 300,
      // dovuti 456 → salvato −156. Il deficit scoperto e' pero' 96: 60 minuti
      // sono coperti dal permesso.
      final legacy = DailyTimesheet.fromMap({
        'dateId': '2026-02-10',
        'startTime': DateTime(2026, 2, 10, 9).toIso8601String(),
        'endTime': DateTime(2026, 2, 10, 15).toIso8601String(),
        'leavePauseMins': 60,
        'netWorkedMins': 300,
        'extraMins': -156,
        'workType': WorkType.presence,
      });

      expect(DailyTimesheet.uncoveredDeficitMins(legacy), 96);
      // La lettura e il ricalcolo devono dare lo stesso numero: nessun
      // percorso ricalcola in lettura, quindi la giornata storica deve gia'
      // essere coerente.
      final recomputed = legacy.recomputedFromSegments(stdMins: 456);
      expect(recomputed.extraMins, legacy.extraMins);
      expect(DailyTimesheet.uncoveredDeficitMins(recomputed), 96);
    });

    test('giornata legacy: la causale di giornata scende sul segmento', () {
      final legacy = DailyTimesheet.fromMap({
        'dateId': '2026-02-11',
        'startTime': DateTime(2026, 2, 11, 9).toIso8601String(),
        'endTime': DateTime(2026, 2, 11, 17).toIso8601String(),
        'leavePauseMins': 60,
        'workType': WorkType.presence,
        'absenceKind': AbsenceKind.specialistVisit,
        'absenceUnit': AbsenceUnit.hourly,
        'absenceMins': 60,
      });

      final leave = legacy.segments.singleWhere(
        (s) => s.type == DaySegment.leave,
      );
      expect(leave.absenceKind, AbsenceKind.specialistVisit);
      expect(leave.durationMins, 60);
    });

    test('convenzione vecchia con segments scritti: convertita lo stesso', () {
      // La popolazione che conta: l'app in produzione dal 10 luglio 2026
      // scrive `segments` su ogni giornata del timer ma calcola ancora
      // `extraMins` con la formula precedente. Dedurre la convenzione
      // dall'assenza di `segments` lasciava proprio questi documenti non
      // convertiti. Span 9:00–15:00 = 360, netto 300, dovuti 456 → −156
      // salvati; il deficit scoperto e' 96, non 156.
      final doc = DailyTimesheet.fromMap({
        'dateId': '2026-02-12',
        'startTime': DateTime(2026, 2, 12, 9).toIso8601String(),
        'endTime': DateTime(2026, 2, 12, 15).toIso8601String(),
        'leavePauseMins': 60,
        'netWorkedMins': 300,
        'extraMins': -156,
        'workType': WorkType.presence,
        'segments': [
          {
            'type': DaySegment.work,
            'start': DateTime(2026, 2, 12, 9).toIso8601String(),
            'end': DateTime(2026, 2, 12, 15).toIso8601String(),
          },
          {'type': DaySegment.leave, 'mins': 60},
        ],
      });

      expect(doc.extraMins, -96);
      expect(DailyTimesheet.uncoveredDeficitMins(doc), 96);
      expect(doc.recomputedFromSegments(stdMins: 456).extraMins, -96);
    });

    test('il marcatore converte una volta sola', () {
      // Senza marcatore la conversione si riapplicava a ogni lettura: una
      // presenza con `segments` vuota (assenza convertita in presenza, cache
      // pre-migrazione) e `leavePauseMins > 0` guadagnava 60 minuti a ogni
      // round-trip.
      final saved = DailyTimesheet(
        dateId: '2026-02-13',
        startTime: DateTime(2026, 2, 13, 9),
        endTime: DateTime(2026, 2, 13, 15),
        standardPauseMins: 0,
        leavePauseMins: 60,
        lunchPauseMins: 0,
        netWorkedMins: 300,
        extraMins: -96,
        workType: WorkType.presence,
      );
      var back = DailyTimesheet.fromMap(saved.toMap());
      expect(back.extraMins, -96);
      back = DailyTimesheet.fromMap(back.toMap());
      expect(back.extraMins, -96);

      // E una giornata legacy convertita non si riconverte al salvataggio.
      final legacy = DailyTimesheet.fromMap({
        'dateId': '2026-02-14',
        'startTime': DateTime(2026, 2, 14, 9).toIso8601String(),
        'endTime': DateTime(2026, 2, 14, 15).toIso8601String(),
        'leavePauseMins': 60,
        'extraMins': -156,
        'workType': WorkType.presence,
      });
      expect(legacy.extraMins, -96);
      expect(DailyTimesheet.fromMap(legacy.toMap()).extraMins, -96);
    });

    test('causale di giornata sul segmento leave gia presente', () {
      // Stesso buco di I3 sui documenti con `segments`: il timer scrive il
      // segmento senza causale quando la pausa non ne aveva una, e il
      // livello di giornata la porta.
      final doc = DailyTimesheet.fromMap({
        'dateId': '2026-02-15',
        'startTime': DateTime(2026, 2, 15, 9).toIso8601String(),
        'endTime': DateTime(2026, 2, 15, 17).toIso8601String(),
        'workType': WorkType.presence,
        'absenceKind': AbsenceKind.specialistVisit,
        'extraConvention': DailyTimesheet.extraConvention,
        'segments': [
          {
            'type': DaySegment.work,
            'start': DateTime(2026, 2, 15, 9).toIso8601String(),
            'end': DateTime(2026, 2, 15, 17).toIso8601String(),
          },
          {'type': DaySegment.leave, 'mins': 60},
        ],
      });

      final leave = doc.segments.singleWhere((s) => s.type == DaySegment.leave);
      expect(leave.absenceKind, AbsenceKind.specialistVisit);
      expect(leave.durationMins, 60);
    });

    test('round-trip di una giornata di permesso con causale', () {
      final entry = DailyTimesheet(
        dateId: '2026-06-03',
        startTime: DateTime(2026, 6, 3, 9),
        endTime: DateTime(2026, 6, 3, 12),
        standardPauseMins: 0,
        lunchPauseMins: 0,
        netWorkedMins: 0,
        extraMins: 0,
        workType: WorkType.leave,
        absenceKind: AbsenceKind.specialistVisit,
        absenceUnit: AbsenceUnit.hourly,
        absenceMins: 180,
      );
      final back = DailyTimesheet.fromMap(entry.toMap());
      expect(back.workType, WorkType.leave);
      expect(back.absenceKind, AbsenceKind.specialistVisit);
      expect(back.absenceMins, 180);
    });
  });

  group('recomputedFromSegments — casi reali del portale', () {
    DailyTimesheet base(String dateId, List<DaySegment> segments) =>
        DailyTimesheet(
          dateId: dateId,
          startTime: DateTime.parse('${dateId}T00:00:00'),
          endTime: DateTime.parse('${dateId}T00:00:00'),
          standardPauseMins: 0,
          lunchPauseMins: 0,
          netWorkedMins: 0,
          extraMins: 0,
          segments: segments,
        ).recomputedFromSegments(stdMins: 456);

    DateTime at(String dateId, int h, int m) =>
        DateTime(int.parse(dateId.substring(0, 4)),
            int.parse(dateId.substring(5, 7)),
            int.parse(dateId.substring(8, 10)), h, m);

    test('permesso dentro lo span: copre il dovuto senza doppio conteggio', () {
      const d = '2026-07-23';
      final e = base(d, [
        DaySegment(type: DaySegment.work, start: at(d, 10, 25), end: at(d, 12, 52)),
        DaySegment(
          type: DaySegment.leave,
          start: at(d, 12, 52),
          end: at(d, 15, 8),
          absenceKind: 'specialist_visit',
        ),
        DaySegment(type: DaySegment.work, start: at(d, 15, 8), end: at(d, 18, 2)),
      ]);
      expect(e.netWorkedMins, 321);
      expect(e.leavePauseMins, 136);
      expect(e.extraMins, 1);
      expect(DailyTimesheet.uncoveredDeficitMins(e), 0);
    });

    test('permesso fuori dallo span: si somma alla copertura', () {
      const d = '2026-07-07';
      final e = base(d, [
        DaySegment(
          type: DaySegment.leave,
          start: at(d, 8, 45),
          end: at(d, 10, 31),
          absenceKind: 'specialist_visit',
        ),
        DaySegment(type: DaySegment.work, start: at(d, 10, 31), end: at(d, 15, 13)),
        DaySegment(type: DaySegment.work, start: at(d, 15, 16), end: at(d, 16, 3)),
        DaySegment(type: DaySegment.work, start: at(d, 16, 6), end: at(d, 17, 5)),
      ]);
      // I buchi fra le timbrature restano lavorati: work collassa nello span.
      expect(e.netWorkedMins, 394);
      expect(e.extraMins, 44);
    });

    test('esonero banca ore fuori span piu\' pausa senza orario', () {
      const d = '2026-03-04';
      final e = base(d, [
        DaySegment(type: DaySegment.bancaOre, start: at(d, 8, 40), end: at(d, 10, 23)),
        DaySegment(type: DaySegment.work, start: at(d, 10, 23), end: at(d, 13, 34)),
        DaySegment(type: DaySegment.work, start: at(d, 13, 41), end: at(d, 16, 23)),
        const DaySegment(type: DaySegment.pause, mins: 7),
      ]);
      expect(e.standardPauseMins, 7);
      expect(e.bancaOreMins, 103);
      expect(e.netWorkedMins, 353);
      expect(e.extraMins, 0);
    });

    test('pausa pranzo dichiarata e regola delle 9 ore', () {
      const d = '2026-07-29';
      final e = base(d, [
        DaySegment(type: DaySegment.work, start: at(d, 8, 17), end: at(d, 9, 30)),
        DaySegment(type: DaySegment.lunch, start: at(d, 9, 30), end: at(d, 10, 3)),
        DaySegment(type: DaySegment.work, start: at(d, 10, 3), end: at(d, 10, 30)),
        DaySegment(type: DaySegment.work, start: at(d, 10, 37), end: at(d, 12, 21)),
        DaySegment(type: DaySegment.work, start: at(d, 12, 36), end: at(d, 19, 59)),
      ]);
      expect(e.lunchPauseMins, 33); // dichiarata 33 > forzata 30
      expect(e.netWorkedMins, 669);
      expect(e.extraMins, 213);
    });

    test('estremi della giornata dai soli segmenti work', () {
      const d = '2026-07-07';
      final e = base(d, [
        DaySegment(
          type: DaySegment.leave,
          start: at(d, 8, 45),
          end: at(d, 10, 31),
          absenceKind: 'specialist_visit',
        ),
        DaySegment(type: DaySegment.work, start: at(d, 10, 31), end: at(d, 17, 5)),
      ]);
      expect(e.startTime, at(d, 10, 31));
      expect(e.endTime, at(d, 17, 5));
    });

    test('deficit scoperto solo per la parte non coperta', () {
      const d = '2026-06-04';
      final e = base(d, [
        DaySegment(
          type: DaySegment.leave,
          start: at(d, 8, 30),
          end: at(d, 9, 0),
          absenceKind: 'short_leave',
        ),
        DaySegment(type: DaySegment.work, start: at(d, 9, 0), end: at(d, 15, 0)),
      ]);
      // Span 360 tutto lavorato, piu' 30 di permesso fuori span che coprono:
      // 390 su 456 dovuti, quindi 66 scoperti e non 96. La copertura
      // parziale riduce il deficit, non lo azzera.
      expect(e.netWorkedMins, 360);
      expect(e.leavePauseMins, 30);
      expect(e.extraMins, -66);
      expect(DailyTimesheet.uncoveredDeficitMins(e), 66);
    });
  });
}
