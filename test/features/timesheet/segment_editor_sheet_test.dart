import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/core/constants/app_strings.dart';
import 'package:chigio_time/features/timesheet/domain/absence_kind.dart';
import 'package:chigio_time/features/timesheet/domain/daily_timesheet.dart';
import 'package:chigio_time/features/timesheet/domain/day_segment.dart';
import 'package:chigio_time/features/timesheet/presentation/day_timeline.dart';
import 'package:chigio_time/features/timesheet/presentation/segment_editor_sheet.dart';

DateTime _at(int h, int m) => DateTime(2026, 7, 23, h, m);
final _day = DateTime(2026, 7, 23);

/// Viewport alto: lo sheet costruisce tutte le causali, ma per toccarle
/// devono anche essere visibili.
void _tallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Apre l'editor e resta in ascolto sul risultato. [closed] diventa true solo
/// quando lo sheet si chiude davvero: un `false` significa che la validazione
/// ha trattenuto il segmento.
Future<void> _openEditor(
  WidgetTester tester, {
  DaySegment? initial,
  required void Function(DaySegment?) onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showSegmentEditor(context, initial: initial, day: _day)
                    .then(onResult),
            child: const Text('apri'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('apri'));
  await tester.pumpAndSettle();
}

/// Conferma il TimePicker sull'ora proposta di default.
Future<void> _pickTime(WidgetTester tester, String field) async {
  await tester.tap(find.text(field));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

DailyTimesheet _entry(List<DaySegment> segments) => DailyTimesheet(
  dateId: '2026-07-23',
  startTime: _at(10, 0),
  endTime: _at(18, 0),
  standardPauseMins: 0,
  lunchPauseMins: 0,
  netWorkedMins: 0,
  extraMins: 0,
  workType: WorkType.presence,
  segments: segments,
).recomputedFromSegments(stdMins: 456);

Future<void> _pumpTimeline(
  WidgetTester tester,
  DailyTimesheet entry,
  ValueChanged<List<DaySegment>> onChanged,
) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: DayTimeline(entry: entry, onChanged: onChanged)),
  ),
);

void main() {
  group('showSegmentEditor — selettore di causale', () {
    testWidgets('mostra solo le causali orarie', (tester) async {
      _tallSurface(tester);
      await _openEditor(
        tester,
        initial: DaySegment(
          type: DaySegment.leave,
          start: _at(12, 0),
          end: _at(13, 0),
          absenceKind: AbsenceKind.shortLeave,
        ),
        onResult: (_) {},
      );

      // Orarie: plafond in ore, compatibili con un segmento di giornata.
      expect(find.text('Permesso breve (Art. 35)'), findsOneWidget);
      expect(find.text('Motivi personali/familiari'), findsOneWidget);
      expect(find.text('Visita specialistica'), findsOneWidget);
      expect(find.text('Assemblea sindacale'), findsOneWidget);
      // Non orarie: fuori dal selettore.
      expect(find.text('Legge 104'), findsNothing);
      expect(find.text('Lutto'), findsNothing);
      expect(find.text('Sciopero'), findsNothing);
    });

    testWidgets('la causale gia\' impostata resta selezionabile anche se non '
        'e\' oraria', (tester) async {
      _tallSurface(tester);
      await _openEditor(
        tester,
        initial: DaySegment(
          type: DaySegment.leave,
          start: _at(12, 0),
          end: _at(13, 0),
          absenceKind: AbsenceKind.law104,
        ),
        onResult: (_) {},
      );

      expect(find.text('Legge 104'), findsOneWidget);
      // Le altre non orarie restano fuori: e' un'eccezione per non perdere
      // la causale di un segmento importato, non un allargamento del filtro.
      expect(find.text('Lutto'), findsNothing);
    });

    testWidgets('nessuna causale per i segmenti che non sono permessi',
        (tester) async {
      _tallSurface(tester);
      await _openEditor(
        tester,
        initial: DaySegment(
          type: DaySegment.work,
          start: _at(10, 0),
          end: _at(12, 0),
        ),
        onResult: (_) {},
      );

      expect(find.text(AppStrings.causale), findsNothing);
      expect(find.text('Permesso breve (Art. 35)'), findsNothing);
    });
  });

  group('showSegmentEditor — validazione', () {
    testWidgets('intervallo incompleto: non emette e mostra il motivo',
        (tester) async {
      _tallSurface(tester);
      var closed = false;
      await _openEditor(tester, onResult: (_) => closed = true);

      await _pickTime(tester, AppStrings.segmentoDalle); // solo "dalle"
      await tester.tap(find.text(AppStrings.save));
      await tester.pumpAndSettle();

      expect(closed, isFalse);
      expect(find.text(AppStrings.segmentoOrariIncompleti), findsOneWidget);
    });

    testWidgets('senza orari e senza durata: non emette e mostra il motivo',
        (tester) async {
      _tallSurface(tester);
      var closed = false;
      await _openEditor(tester, onResult: (_) => closed = true);

      await tester.tap(find.text(AppStrings.save));
      await tester.pumpAndSettle();

      expect(closed, isFalse);
      expect(find.text(AppStrings.segmentoDurataMancante), findsOneWidget);
    });

    testWidgets('fine non successiva all\'inizio: non emette e mostra il '
        'motivo', (tester) async {
      _tallSurface(tester);
      var closed = false;
      await _openEditor(tester, onResult: (_) => closed = true);

      // Entrambi i picker confermano l'ora di default: da == a.
      await _pickTime(tester, AppStrings.segmentoDalle);
      await _pickTime(tester, AppStrings.segmentoAlle);
      await tester.tap(find.text(AppStrings.save));
      await tester.pumpAndSettle();

      expect(closed, isFalse);
      expect(find.text(AppStrings.segmentoFinePrimaDiInizio), findsOneWidget);
    });

    testWidgets('senza orari con durata valida: emette il segmento',
        (tester) async {
      _tallSurface(tester);
      DaySegment? result;
      await _openEditor(tester, onResult: (s) => result = s);

      await tester.enterText(find.byType(TextField), '25');
      await tester.tap(find.text(AppStrings.save));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.type, DaySegment.work);
      expect(result!.start, isNull);
      expect(result!.mins, 25);
    });

    testWidgets('annullare non emette nulla', (tester) async {
      _tallSurface(tester);
      DaySegment? result;
      var closed = false;
      await _openEditor(tester, onResult: (s) {
        result = s;
        closed = true;
      });

      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(result, isNull);
    });
  });

  group('DayTimeline — modifica di un segmento', () {
    testWidgets('tap sul segmento, modifica e conferma: onChanged riceve la '
        'lista aggiornata', (tester) async {
      _tallSurface(tester);
      List<DaySegment>? updated;
      await _pumpTimeline(
        tester,
        _entry([
          DaySegment(type: DaySegment.work, start: _at(10, 0), end: _at(12, 0)),
          DaySegment(
            type: DaySegment.leave,
            start: _at(12, 0),
            end: _at(13, 0),
            absenceKind: AbsenceKind.shortLeave,
          ),
          DaySegment(type: DaySegment.work, start: _at(13, 0), end: _at(18, 0)),
        ]),
        (s) => updated = s,
      );

      // La riga del permesso porta la causale come sottotitolo.
      await tester.tap(find.text('Permesso breve (Art. 35)'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.modificaSegmento), findsOneWidget);

      await tester.tap(find.text('Visita specialistica'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.save));
      await tester.pumpAndSettle();

      expect(updated, isNotNull);
      expect(updated!.length, 3);
      final leave = updated!.singleWhere((s) => s.type == DaySegment.leave);
      expect(leave.absenceKind, AbsenceKind.specialistVisit);
      expect(leave.start, _at(12, 0));
      expect(leave.end, _at(13, 0));
      // Gli altri segmenti passano intatti: la modifica e' puntuale.
      expect(updated!.where((s) => s.type == DaySegment.work).length, 2);
    });

    testWidgets('una sovrapposizione non viene emessa e il motivo compare a '
        'schermo', (tester) async {
      _tallSurface(tester);
      List<DaySegment>? updated;
      // Giornata gia' sovrapposta (documento legacy, scritto prima che la
      // regola esistesse): riconfermare un segmento non deve salvarla.
      await _pumpTimeline(
        tester,
        _entry([
          DaySegment(type: DaySegment.work, start: _at(10, 0), end: _at(13, 0)),
          DaySegment(
            type: DaySegment.leave,
            start: _at(12, 0),
            end: _at(14, 0),
            absenceKind: AbsenceKind.shortLeave,
          ),
        ]),
        (s) => updated = s,
      );

      await tester.tap(find.text('10:00 – 13:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.save));
      await tester.pumpAndSettle();

      expect(updated, isNull);
      expect(find.text('Segmenti sovrapposti'), findsOneWidget);
    });

    testWidgets('eliminare l\'ultimo segmento di lavoro e\' rifiutato',
        (tester) async {
      _tallSurface(tester);
      List<DaySegment>? updated;
      await _pumpTimeline(
        tester,
        _entry([
          DaySegment(type: DaySegment.work, start: _at(10, 0), end: _at(12, 0)),
          DaySegment(
            type: DaySegment.leave,
            start: _at(12, 0),
            end: _at(13, 0),
            absenceKind: AbsenceKind.shortLeave,
          ),
        ]),
        (s) => updated = s,
      );

      await tester.tap(find.byTooltip(AppStrings.eliminaSegmento).first);
      await tester.pumpAndSettle();

      expect(updated, isNull);
      expect(
        find.text('La giornata non ha segmenti di lavoro con orari'),
        findsOneWidget,
      );
    });
  });
}
