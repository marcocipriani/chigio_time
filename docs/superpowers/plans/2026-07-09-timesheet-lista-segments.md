# Timesheet Lista + Segments Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Multi-entry giornaliero via `segments[]`, ricalcolo automatico totali, riga vista Lista ridisegnata, widget contatori con scorporo maggior presenza.

**Architecture:** Il doc Firestore `timesheets/{dateId}` resta uno per giorno; nuovo campo array `segments[]` (voci work/leave). Totali giorno sempre derivati dai segments da una funzione pura unica. UI: `MonthlySummaryCard` semplificato (no espansione/barre), righe Lista con enfasi orari + colonna contatori destra, `_EntrySheet` diventa editor segments per Presenza.

**Tech Stack:** Flutter 3 / Dart 3.10+, Riverpod 3, Firestore, Drift (schema v5).

**Spec:** `docs/superpowers/specs/2026-07-09-timesheet-lista-segments-design.md`

## Global Constraints

- Lingua UI: italiano (stringhe in `lib/core/constants/app_strings.dart`); codice/commenti inglese.
- Niente `FirebaseFirestore.instance` fuori dal layer `data/`.
- Non modificare file `*.g.dart` a mano; dopo modifiche a tabelle Drift eseguire `dart run build_runner build --delete-conflicting-outputs`.
- `flutter analyze` + `flutter test` verdi prima di ogni commit.
- Docs aggiornati nello stesso commit del codice che cambia comportamento (regola CLAUDE.md §2).
- Nota: `docs/entita/daily-timesheet.md` dice "Drift schema v3" ma il codice è già v4 (campi absence) — la migrazione segments è la **v5**.

---

### Task 1: `DaySegment` + campo `segments` in `DailyTimesheet`

**Files:**
- Create: `lib/features/timesheet/domain/day_segment.dart`
- Modify: `lib/features/timesheet/domain/daily_timesheet.dart`
- Test: `test/features/timesheet/day_segment_test.dart`

**Interfaces:**
- Produces: `DaySegment{type:'work'|'leave', start:DateTime?, end:DateTime?, mins:int, absenceKind:String?}` con `toMap()`/`fromMap()`, getter `workMins`; `DailyTimesheet.segments: List<DaySegment>` (default `const []`), serializzato in `toMap()['segments']`, parse in `fromMap` con **derive lazy** se assente.

- [ ] **Step 1: Write failing test**

```dart
// test/features/timesheet/day_segment_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/features/timesheet/domain/daily_timesheet.dart';
import 'package:chigio_time/features/timesheet/domain/day_segment.dart';

void main() {
  group('DaySegment', () {
    test('work segment roundtrip + workMins', () {
      final s = DaySegment(
        type: DaySegment.work,
        start: DateTime(2026, 7, 9, 9, 2),
        end: DateTime(2026, 7, 9, 13, 0),
      );
      expect(s.workMins, 238);
      final back = DaySegment.fromMap(s.toMap());
      expect(back.type, DaySegment.work);
      expect(back.start, DateTime(2026, 7, 9, 9, 2));
      expect(back.workMins, 238);
    });

    test('leave segment roundtrip', () {
      final s = DaySegment(
        type: DaySegment.leave,
        mins: 96,
        absenceKind: 'short_leave',
      );
      final back = DaySegment.fromMap(s.toMap());
      expect(back.mins, 96);
      expect(back.absenceKind, 'short_leave');
      expect(back.workMins, 0);
    });

    test('fromMap tolerant on garbage', () {
      final s = DaySegment.fromMap({'type': 'work'});
      expect(s.workMins, 0); // no start/end → 0, no throw
    });
  });

  group('DailyTimesheet.segments', () {
    test('toMap writes segments, fromMap reads them', () {
      final e = DailyTimesheet(
        dateId: '2026-07-09',
        startTime: DateTime(2026, 7, 9, 9),
        endTime: DateTime(2026, 7, 9, 17),
        standardPauseMins: 0,
        lunchPauseMins: 0,
        netWorkedMins: 480,
        extraMins: 24,
        segments: [
          DaySegment(
            type: DaySegment.work,
            start: DateTime(2026, 7, 9, 9),
            end: DateTime(2026, 7, 9, 17),
          ),
        ],
      );
      final back = DailyTimesheet.fromMap(e.toMap());
      expect(back.segments, hasLength(1));
      expect(back.segments.first.workMins, 480);
    });

    test('legacy doc without segments derives work segment lazily', () {
      final back = DailyTimesheet.fromMap({
        'dateId': '2026-07-09',
        'startTime': '2026-07-09T09:00:00.000',
        'endTime': '2026-07-09T17:36:00.000',
        'netWorkedMins': 456,
        'extraMins': 0,
        'workType': 'presence',
      });
      expect(back.segments, hasLength(1));
      expect(back.segments.first.type, DaySegment.work);
      expect(back.segments.first.start, DateTime(2026, 7, 9, 9));
    });

    test('legacy doc with leavePauseMins derives extra leave segment', () {
      final back = DailyTimesheet.fromMap({
        'dateId': '2026-07-09',
        'startTime': '2026-07-09T09:00:00.000',
        'endTime': '2026-07-09T17:36:00.000',
        'leavePauseMins': 60,
        'netWorkedMins': 396,
        'extraMins': -60,
        'workType': 'presence',
      });
      expect(back.segments, hasLength(2));
      expect(back.segments.last.type, DaySegment.leave);
      expect(back.segments.last.mins, 60);
    });

    test('leave/holiday full-day docs derive NO segments', () {
      final back = DailyTimesheet.fromMap({
        'dateId': '2026-07-09',
        'startTime': '2026-07-09T09:00:00.000',
        'endTime': '2026-07-09T17:36:00.000',
        'netWorkedMins': 0,
        'extraMins': 0,
        'workType': 'holiday',
      });
      expect(back.segments, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test, verify FAIL**

Run: `flutter test test/features/timesheet/day_segment_test.dart`
Expected: FAIL — `day_segment.dart` non esiste.

- [ ] **Step 3: Implement**

```dart
// lib/features/timesheet/domain/day_segment.dart
// A slice of a day: a work interval or an hourly leave (permesso).
// Lunch/coffee pauses stay as day-level fields on DailyTimesheet.
class DaySegment {
  static const work = 'work';
  static const leave = 'leave';

  final String type; // work | leave
  final DateTime? start; // work only
  final DateTime? end; // work only
  final int mins; // leave duration; ignored for work (derived)
  final String? absenceKind; // CCNL causale for leave

  const DaySegment({
    required this.type,
    this.start,
    this.end,
    this.mins = 0,
    this.absenceKind,
  });

  /// Worked minutes contributed by this segment (0 for leave/invalid).
  int get workMins {
    if (type != work || start == null || end == null) return 0;
    final d = end!.difference(start!).inMinutes;
    return d > 0 ? d : 0;
  }

  /// Leave minutes contributed by this segment (0 for work).
  int get leaveMins => type == leave ? mins : 0;

  Map<String, dynamic> toMap() => {
    'type': type,
    if (start != null) 'start': start!.toIso8601String(),
    if (end != null) 'end': end!.toIso8601String(),
    if (mins > 0) 'mins': mins,
    if (absenceKind != null) 'absenceKind': absenceKind,
  };

  // Tolerant: garbage fields degrade to an inert segment, never throw.
  factory DaySegment.fromMap(Map<String, dynamic> map) => DaySegment(
    type: map['type'] as String? ?? work,
    start: map['start'] is String ? DateTime.tryParse(map['start'] as String) : null,
    end: map['end'] is String ? DateTime.tryParse(map['end'] as String) : null,
    mins: (map['mins'] as num?)?.toInt() ?? 0,
    absenceKind: map['absenceKind'] as String?,
  );
}
```

In `daily_timesheet.dart`:
1. `import 'day_segment.dart';`
2. Campo dopo `hasDocumentation`:

```dart
  /// Day slices (work intervals + hourly leaves). Empty for full-day
  /// leave/holiday and for legacy docs whose fields couldn't be derived.
  final List<DaySegment> segments;
```

3. Costruttore: `this.segments = const [],`
4. In `toMap()`, prima di `'updatedAt'`:

```dart
    if (segments.isNotEmpty)
      'segments': segments.map((s) => s.toMap()).toList(),
```

5. In `fromMap`, sostituire il `return DailyTimesheet(` con parse + derive:

```dart
  factory DailyTimesheet.fromMap(Map<String, dynamic> map) {
    final dateId = map['dateId'] as String? ?? '';
    final startTime = _parseDt(map['startTime'], dateId);
    final endTime = _parseDt(map['endTime'], dateId);
    final workType = map['workType'] as String?;
    final leavePauseMins = (map['leavePauseMins'] as num?)?.toInt() ?? 0;

    // Parse segments; legacy docs (no field) derive them lazily so the
    // whole app can assume segments exist for presence/remote days.
    var segments = (map['segments'] as List?)
            ?.whereType<Map>()
            .map((m) => DaySegment.fromMap(Map<String, dynamic>.from(m)))
            .toList() ??
        const <DaySegment>[];
    final isFullDayAbsence =
        workType == WorkType.leave || workType == WorkType.holiday;
    if (segments.isEmpty && !isFullDayAbsence && endTime.isAfter(startTime)) {
      segments = [
        DaySegment(type: DaySegment.work, start: startTime, end: endTime),
        if (leavePauseMins > 0)
          DaySegment(type: DaySegment.leave, mins: leavePauseMins),
      ];
    }

    return DailyTimesheet(
      dateId: dateId,
      startTime: startTime,
      endTime: endTime,
      // ... (tutti i campi esistenti invariati, leavePauseMins: leavePauseMins)
      segments: segments,
    );
  }
```

- [ ] **Step 4: Run test, verify PASS**

Run: `flutter test test/features/timesheet/day_segment_test.dart`
Expected: PASS (tutti).

- [ ] **Step 5: Commit**

```bash
git add lib/features/timesheet/domain/ test/features/timesheet/day_segment_test.dart
git commit -m "feat(timesheet): DaySegment model + segments field with lazy legacy derive"
```

---

### Task 2: Ricalcolo totali da segments (`recomputeFromSegments`)

**Files:**
- Modify: `lib/features/timesheet/domain/daily_timesheet.dart`
- Test: `test/features/timesheet/recompute_test.dart`

**Interfaces:**
- Consumes: `DaySegment` (Task 1), `AppConstants.forcedLunchMins`.
- Produces: metodo `DailyTimesheet recomputedFromSegments({required int stdMins})` — ritorna copia con `startTime`/`endTime` (min/max work), `leavePauseMins` (somma leave), `lunchPauseMins` (regola 9h 3-zone, mai sotto il già preso), `netWorkedMins`, `extraMins = net + bancaOreMins − stdMins` (può essere negativo). Getter statico `int uncoveredDeficitMins(DailyTimesheet e)` = deficit non coperto da permessi.

- [ ] **Step 1: Write failing test**

```dart
// test/features/timesheet/recompute_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/features/timesheet/domain/daily_timesheet.dart';
import 'package:chigio_time/features/timesheet/domain/day_segment.dart';

DailyTimesheet _day(List<DaySegment> segs, {int standardPause = 0, int bancaOre = 0, int lunchTaken = 0}) =>
    DailyTimesheet(
      dateId: '2026-07-09',
      startTime: DateTime(2026, 7, 9),
      endTime: DateTime(2026, 7, 9),
      standardPauseMins: standardPause,
      lunchPauseMins: lunchTaken,
      netWorkedMins: 0,
      extraMins: 0,
      bancaOreMins: bancaOre,
      segments: segs,
    );

DaySegment _w(int h1, int m1, int h2, int m2) => DaySegment(
  type: DaySegment.work,
  start: DateTime(2026, 7, 9, h1, m1),
  end: DateTime(2026, 7, 9, h2, m2),
);

void main() {
  test('single work segment 9:00-17:36, std 456 → net 456, extra 0, no lunch', () {
    final r = _day([_w(9, 0, 17, 36)]).recomputedFromSegments(stdMins: 456);
    expect(r.netWorkedMins, 456);
    expect(r.lunchPauseMins, 0); // elapsed 516 < 540 → zone 1
    expect(r.extraMins, 0);
    expect(r.startTime, DateTime(2026, 7, 9, 9));
    expect(r.endTime, DateTime(2026, 7, 9, 17, 36));
  });

  test('9h+ elapsed triggers 3-zone forced lunch on work total', () {
    // two work segments totalling 570m elapsed-worked → forced 30
    final r = _day([_w(8, 0, 13, 0), _w(13, 30, 18, 0)])
        .recomputedFromSegments(stdMins: 456);
    // workSum = 300 + 270 = 570 → zone 3 → lunch 30, net 540
    expect(r.lunchPauseMins, 30);
    expect(r.netWorkedMins, 540);
    expect(r.extraMins, 84);
  });

  test('leave segments sum into leavePauseMins, not net', () {
    final r = _day([
      _w(9, 0, 13, 0), // 240
      DaySegment(type: DaySegment.leave, mins: 96, absenceKind: 'short_leave'),
      _w(14, 30, 17, 30), // 180
    ]).recomputedFromSegments(stdMins: 456);
    expect(r.netWorkedMins, 420);
    expect(r.leavePauseMins, 96);
    expect(r.extraMins, -36); // negative deficit preserved
  });

  test('standard pauses subtract from net', () {
    final r = _day([_w(9, 0, 17, 36)], standardPause: 20)
        .recomputedFromSegments(stdMins: 456);
    expect(r.netWorkedMins, 436);
    expect(r.extraMins, -20);
  });

  test('banca ore counts toward extra', () {
    final r = _day([_w(9, 0, 16, 36)], bancaOre: 60)
        .recomputedFromSegments(stdMins: 456);
    expect(r.netWorkedMins, 456); // 456 elapsed... wait: 9:00→16:36 = 456
    expect(r.extraMins, 60);
  });

  test('lunch already taken never reduced by rule', () {
    final r = _day([_w(9, 0, 17, 0)], lunchTaken: 45)
        .recomputedFromSegments(stdMins: 456);
    expect(r.lunchPauseMins, 45);
    expect(r.netWorkedMins, 480 - 45);
  });

  test('uncoveredDeficitMins: permesso covers deficit', () {
    final covered = _day([
      _w(9, 0, 15, 0), // 360, std 456 → deficit 96
      DaySegment(type: DaySegment.leave, mins: 96),
    ]).recomputedFromSegments(stdMins: 456);
    expect(covered.extraMins, -96);
    expect(DailyTimesheet.uncoveredDeficitMins(covered), 0);

    final partial = _day([
      _w(9, 0, 15, 0),
      DaySegment(type: DaySegment.leave, mins: 30),
    ]).recomputedFromSegments(stdMins: 456);
    expect(DailyTimesheet.uncoveredDeficitMins(partial), 66);
  });

  test('empty segments → unchanged copy', () {
    final e = _day(const []);
    expect(e.recomputedFromSegments(stdMins: 456).netWorkedMins, 0);
  });
}
```

- [ ] **Step 2: Run test, verify FAIL**

Run: `flutter test test/features/timesheet/recompute_test.dart`
Expected: FAIL — metodo non definito.

- [ ] **Step 3: Implement in `daily_timesheet.dart`**

```dart
  /// Recomputes day totals from [segments]: start/end = min/max of work
  /// segments, leavePauseMins = sum of leave segments, lunch via the 9h
  /// 3-zone rule (never below what was already taken), extra may be
  /// negative (deficit). No-op copy when segments is empty.
  DailyTimesheet recomputedFromSegments({required int stdMins}) {
    if (segments.isEmpty) return this;

    final workSegs = segments.where((s) => s.workMins > 0).toList();
    final workSum = workSegs.fold<int>(0, (t, s) => t + s.workMins);
    final leaveSum = segments.fold<int>(0, (t, s) => t + s.leaveMins);

    // 9h rule applies to effective worked time (pauses already excluded
    // because gaps between work segments are simply not counted).
    final effective = workSum - standardPauseMins;
    final lunch = AppConstants.forcedLunchMins(
      effective,
      alreadyTakenMins: lunchPauseMins,
    );
    final net = (workSum - standardPauseMins - lunch).clamp(0, 9999).toInt();

    DateTime? minStart, maxEnd;
    for (final s in workSegs) {
      if (minStart == null || s.start!.isBefore(minStart)) minStart = s.start;
      if (maxEnd == null || s.end!.isAfter(maxEnd)) maxEnd = s.end;
    }

    return copyWith(
      startTime: minStart ?? startTime,
      endTime: maxEnd ?? endTime,
      leavePauseMins: leaveSum,
      lunchPauseMins: lunch,
      netWorkedMins: net,
      extraMins: net + bancaOreMins - stdMins,
    );
  }

  /// Deficit minutes NOT covered by hourly leave (permessi). 0 when the
  /// day is at/over schedule or fully covered.
  static int uncoveredDeficitMins(DailyTimesheet e) {
    if (e.extraMins >= 0) return 0;
    return (-e.extraMins - e.leavePauseMins).clamp(0, 9999);
  }
```

`copyWith` non esiste: aggiungerlo (tutti i campi, pattern standard `Type? param` → `param ?? this.field`; per i nullable usare parametri `Object? = _sentinel` **solo se serve azzerarli** — qui non serve, basta il pattern semplice). Import `../../../core/constants/app_constants.dart`.

- [ ] **Step 4: Run test, verify PASS**

Run: `flutter test test/features/timesheet/recompute_test.dart`
Expected: PASS.

- [ ] **Step 5: Full check + commit**

Run: `flutter analyze && flutter test`

```bash
git add lib/features/timesheet/domain/daily_timesheet.dart test/features/timesheet/recompute_test.dart
git commit -m "feat(timesheet): recomputedFromSegments + uncoveredDeficitMins"
```

---

### Task 3: Persistenza segments — Drift v5 + repository

**Files:**
- Modify: `lib/core/database/app_database.dart`
- Modify: `lib/features/timesheet/data/timesheet_repository.dart`
- Test: già coperto dai roundtrip Task 1 (la colonna è JSON passthrough); nessun test Drift nuovo (il repo non ha harness Drift oggi).

**Interfaces:**
- Consumes: `DaySegment.toMap/fromMap` (Task 1).
- Produces: colonna `segments TEXT NULL` (JSON array) in `TimesheetEntries`; `_toCompanion`/`_fromRow` la serializzano/parsano.

- [ ] **Step 1: Schema v5**

In `app_database.dart`, dentro `TimesheetEntries` dopo `countsAsSicknessPeriod`:

```dart
  // ── Segments (schema v5) — JSON array of DaySegment maps ────────────────
  TextColumn get segments => text().nullable()();
```

`schemaVersion` → `5`. In `onUpgrade`:

```dart
      if (from < 5) {
        await m.database.customStatement(
          'ALTER TABLE timesheet_entries ADD COLUMN segments TEXT',
        );
      }
```

- [ ] **Step 2: Code-gen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: exit 0, `app_database.g.dart` rigenerato.

- [ ] **Step 3: Repository serialization**

In `timesheet_repository.dart` (`import 'dart:convert';`, `import '../domain/day_segment.dart';`):

In `_toCompanion`, dopo `boeSlot`:

```dart
        segments: Value(
          e.segments.isEmpty
              ? null
              : jsonEncode(e.segments.map((s) => s.toMap()).toList()),
        ),
```

In `_fromRow`, dopo `boeSlot`:

```dart
    segments: _segmentsFromJson(r.segments),
```

Helper privato nella classe:

```dart
  static List<DaySegment> _segmentsFromJson(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      return (jsonDecode(json) as List)
          .whereType<Map>()
          .map((m) => DaySegment.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return const []; // corrupt cache row must not break the list
    }
  }
```

- [ ] **Step 4: Verify + commit**

Run: `flutter analyze && flutter test`
Expected: verdi.

```bash
git add lib/core/database/app_database.dart lib/core/database/app_database.g.dart lib/features/timesheet/data/timesheet_repository.dart
git commit -m "feat(timesheet): persist segments in Drift cache (schema v5)"
```

---

### Task 4: Produttori scrivono segments (timer, sheet base, import CSV)

**Files:**
- Modify: `lib/features/dashboard/presentation/timer_provider.dart:494-514`
- Modify: `lib/features/timesheet/data/csv_import_service.dart` (punto dove costruisce `DailyTimesheet` presence)
- Test: `test/features/timesheet/recompute_test.dart` già copre la matematica; qui si aggiornano solo i costruttori.

**Interfaces:**
- Consumes: `DaySegment`, `recomputedFromSegments` (Task 1-2).
- Produces: ogni nuovo salvataggio presence contiene `segments[]` coerenti.

- [ ] **Step 1: Timer `endTurn`**

In `timer_provider.dart`, nel costruttore `record = DailyTimesheet(...)` (riga ~497) aggiungere:

```dart
      segments: [
        DaySegment(
          type: DaySegment.work,
          start: state.startTime!,
          end: endTime,
        ),
        if (state.totalLeavePauseMins > 0)
          DaySegment(type: DaySegment.leave, mins: state.totalLeavePauseMins),
      ],
```

(import `day_segment.dart`). La matematica esistente del timer resta com'è: già equivalente alla regola (il segment è uno solo; pause tracciate nei campi giorno).

- [ ] **Step 2: CSV import**

In `csv_import_service.dart`, dove costruisce l'entry presence, aggiungere lo stesso pattern e poi ricalcolare:

```dart
      entry = DailyTimesheet(
        // ... campi esistenti ...
        segments: [
          DaySegment(type: DaySegment.work, start: start, end: end),
        ],
      ).recomputedFromSegments(stdMins: stdMins);
```

`stdMins` è già disponibile nel parser (usato per extraMins); se il codice attuale calcola lunch/net a mano per la riga, sostituire quel calcolo con `recomputedFromSegments` mantenendo il caso "pausa esplicita nella nota" (passa come `lunchPauseMins` iniziale: la regola non scende mai sotto il già preso). Giorni remote/leave/holiday: nessun segment.

- [ ] **Step 3: Verify + commit**

Run: `flutter analyze && flutter test`

```bash
git add lib/features/dashboard/presentation/timer_provider.dart lib/features/timesheet/data/csv_import_service.dart
git commit -m "feat(timesheet): timer + CSV import write day segments"
```

---

### Task 5: `MonthlySummaryCard` ridisegnato + rimozione prefs

**Files:**
- Modify: `lib/shared/widgets/monthly_summary_card.dart` (riscrittura)
- Modify: `lib/features/timesheet/presentation/timesheet_screen.dart:262-302` (call site)
- Modify: `lib/features/profile/presentation/stats_screen.dart:44-48,245` (call site)
- Modify: `lib/features/profile/presentation/profile_screen.dart:398-402,1981-2010` (rimuovere `showCountersCustomizer` + entry point)
- Modify: `lib/core/constants/app_strings.dart` (nuove label)

**Interfaces:**
- Produces: nuova API `MonthlySummaryCard` — rimossi `visibleItems`, `showProgressBars`, `onEditTap`, `initiallyExpanded`, `art9Cap`, `sliCap`, `sboCap`, `overtimeCap`, `art9Mins`; aggiunti `opMins:int`. Parametri restanti invariati. Il widget calcola internamente niente: riceve `art9`/`sli`/`sbo`/`op` già scorporati? No — riceve `totalOtMins`, `sliMins`, `sboMins`, `opMins` e **art9Mins resta** come parametro (già calcolato waterfall dal caller). Firma finale:

```dart
const MonthlySummaryCard({
  required int year, month, totalNetMins, totalOtMins, totalMeal,
  required int art9Mins, sliMins, sboMins, opMins, deficitMins,
  int swCount = 0, int swYearCount = 0,
  VoidCallback? onPrevMonth, onNextMonth, onMonthTap,
  bool showMonthNav = true,
});
```

- [ ] **Step 1: Stringhe**

In `app_strings.dart` vicino a `art9Label` (riga ~181):

```dart
  static const maggiorPresenzaShort = 'Magg. presenza';
  static const buoniPastoLabel = 'Buoni pasto';
  static const opLabel = 'OP';
```

(`deficitLabel`, `totalHours`, `art9Label`, `sliLabel`, `sboLabel` esistono già.)

- [ ] **Step 2: Riscrivere il widget**

`monthly_summary_card.dart` diventa `StatelessWidget`. Struttura (riusa `_NavCircle`, `_BigStat`, `_hm` esistenti; elimina `_SecStat`, `_ProgressRow`, stato `_expanded`, `AnimatedSize`, freccia):

```dart
class MonthlySummaryCard extends StatelessWidget {
  // ... campi + costruttore come da firma sopra ...

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // textMain/textSub/badge identici a oggi
    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        children: [
          // Month nav row: INVARIATA (copia il blocco attuale righe 171-256)
          if (showMonthNav) ...[ /* blocco esistente */ ],

          // Riga principale: Ore tot · Magg. presenza · Buoni pasto
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BigStat(label: AppStrings.totalHours, value: '${totalNetMins ~/ 60}h', isDark: isDark),
              _BigStat(label: AppStrings.maggiorPresenzaShort, value: totalOtMins == 0 ? '—' : _hm(totalOtMins), isDark: isDark),
              _BigStat(label: AppStrings.buoniPastoLabel, value: '$totalMeal 🍽️', isDark: isDark),
            ],
          ),

          // Scorporo maggior presenza — visivamente legato (indent + dot)
          if (totalOtMins > 0) ...[
            const SizedBox(height: 10),
            _BreakdownRow(isDark: isDark, entries: [
              (AppStrings.art9Label, art9Mins),
              (AppStrings.sliLabel, sliMins),
              (AppStrings.sboLabel, sboMins),
              (AppStrings.opLabel, opMins),
            ]),
          ],

          // Deficit — riga separata rossa, solo se > 0
          if (deficitMins > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${AppStrings.deficitLabel} −${_hm(deficitMins)}',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFFF9B9B) : AppColors.red700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Indented breakdown: "└ Art.9 8:00 · SLI 2:00 · SBO 1:30 · OP 0:54".
/// Zero entries render as "—" to keep the sum readable at a glance.
class _BreakdownRow extends StatelessWidget {
  final bool isDark;
  final List<(String, int)> entries;
  const _BreakdownRow({required this.isDark, required this.entries});

  @override
  Widget build(BuildContext context) {
    final sub = isDark ? Colors.white.withValues(alpha: 0.55) : AppColors.neutral600;
    final val = isDark ? Colors.white.withValues(alpha: 0.85) : AppColors.neutral900;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.blue600.withValues(alpha: isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        children: [
          for (final (label, mins) in entries)
            Text.rich(TextSpan(children: [
              TextSpan(text: '$label ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sub)),
              TextSpan(
                text: mins == 0 ? '—' : _MonthlySummaryFmt.hm(mins),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: val,
                  fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ])),
        ],
      ),
    );
  }
}
```

(`_MonthlySummaryFmt.hm` = spostare l'attuale `_hm` statico in un helper top-level privato del file, usato da entrambe le classi. Import `dart:ui` per `FontFeature` se non già presente via material.)

- [ ] **Step 3: Call site timesheet_screen**

Righe 262-302: eliminare `visibleItems`/`showProgressBars` (269-273) e calcolare lo scorporo waterfall completo:

```dart
    final art9Cap = (profileData?['monthlyArt9Hours'] as int? ?? 0) * 60;
    final sliCap = (profileData?['monthlySliHours'] as int? ?? 0) * 60;
    final sboCap = (profileData?['monthlySboHours'] as int? ?? 0) * 60;
    final art9Mins = totalOT.clamp(0, art9Cap);
    final opMins = (totalOT - art9Cap - sliCap - sboCap).clamp(0, 1 << 31);
```

`summaryCard = MonthlySummaryCard(` → nuova firma (togliere `art9Cap/sliCap/sboCap/overtimeCap/visibleItems/showProgressBars/onEditTap`, aggiungere `opMins: opMins`). Togliere l'import `show showCountersCustomizer` (riga 23). **Nota deficit**: sostituire il calcolo `deficitMins` (righe 247-250) con la somma dei deficit non coperti:

```dart
    final deficitMins = map.values.fold<int>(
      0,
      (s, e) => s + DailyTimesheet.uncoveredDeficitMins(e),
    );
```

- [ ] **Step 4: Call site stats_screen + profile_screen**

`stats_screen.dart`: rimuovere lettura prefs (righe 44-48), aggiornare la chiamata `MonthlySummaryCard(` (riga 245) alla nuova firma con lo stesso calcolo `opMins` (il waterfall è già calcolato lì per art9 — riusarlo). `profile_screen.dart`: eliminare la funzione `showCountersCustomizer` (righe 1981-fine funzione) e il suo entry point (riga ~400, rimuovere la tile/voce che la invoca). Le chiavi Firestore `summaryItems`/`summaryShowProgress` restano nei doc esistenti ma nessuno le legge più — nessuna migrazione.

- [ ] **Step 5: Verify + commit**

Run: `flutter analyze && flutter test`
Poi run app o `flutter build` rapido non richiesto qui (verifica visiva in Task 8).

```bash
git add lib/shared/widgets/monthly_summary_card.dart lib/features/timesheet/presentation/timesheet_screen.dart lib/features/profile/presentation/stats_screen.dart lib/features/profile/presentation/profile_screen.dart lib/core/constants/app_strings.dart
git commit -m "feat(ui): monthly summary redesign — maggior presenza breakdown, no bars/expansion"
```

---

### Task 6: Riga vista Lista ridisegnata

**Files:**
- Modify: `lib/features/timesheet/presentation/timesheet_screen.dart` — `_buildListView` (1126-1201), `_buildListRow` (1203-1348), `_buildEntryInfo` (1350-1465)
- Modify: `lib/core/constants/app_strings.dart`

**Interfaces:**
- Consumes: `AppConstants.stdMinsForDate`, `DailyTimesheet.uncoveredDeficitMins`, `profileData` (già disponibile nello State).
- Produces: `_buildListRow` accetta nuovo param `int stdMins` (0 per weekend/festivi); helper `double _estimatedRowHeight(int day)` per l'auto-scroll.

- [ ] **Step 1: Stringhe**

```dart
  static const lavorateLabel = 'lavorate';
  static const maggPresRowLabel = 'magg.pres.';
```

- [ ] **Step 2: `_buildListView` — stdMins + auto-scroll cumulativo**

Passare `profileData` a `_buildListView` (aggiungere param) e per ogni giorno: `final stdMins = (isWeekend || _holidayLabel(day) != null) ? 0 : (profileData != null ? AppConstants.stdMinsForDate(profileData, date) : 456);` → passarlo a `_buildListRow`.

Auto-scroll: sostituire `const rowH = 62.0; final offset = ((now.day - 1) * rowH)...` con somma di altezze stimate:

```dart
        // Variable row heights: weekend/holiday rows are compact.
        double offset = 0;
        for (var d = 1; d < now.day; d++) {
          final dt = DateTime(_year, _month, d);
          final compact = dt.weekday >= 6 || _holidayLabel(d) != null;
          offset += compact ? 38.0 : 72.0; // ponytail: estimates, not measured
        }
        final clamped = offset.clamp(0.0, _listScrollController.position.maxScrollExtent);
```

- [ ] **Step 3: `_buildListRow` — layout nuovo**

Riscrittura del body. Struttura:

```dart
    final missing = entry != null
        ? DailyTimesheet.uncoveredDeficitMins(entry)
        : (showWarning ? stdMins : 0);
    final compact = (isWeekend || isPublicHoliday) && entry == null;

    // Row container: identico a oggi nei colori/bordi, ma
    // vertical padding 10 → 4 quando compact.
    child: Row(children: [
      // ── Colonna sinistra: giorno + nome + ore default ──
      SizedBox(
        width: 48,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // numero + nome giorno: INVARIATI (blocco attuale)
          if (stdMins > 0)
            Text(_fmtNet(stdMins), // es. '7:36'
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: textSub)),
        ]),
      ),
      const SizedBox(width: 10),
      // ── Centro + destra: per stato ──
      if (entry != null)
        _buildEntryInfo(entry, textMain, textSub, mealThreshold, missing)
      else if (isPublicHoliday)
        // blocco 🌴 attuale INVARIATO
      else if (!isWeekend) ...[
        Expanded(child: Wrap(spacing: 6, runSpacing: 4, children: [
          _QuickAddChip(emoji: '🏢', label: AppStrings.wtPresence, isDark: isDark,
            onTap: () => _showEntrySheet(context, isDark, preselectedDay: day)),
          _QuickAddChip(emoji: '🏠', label: AppStrings.swShort, isDark: isDark,
            onTap: () => _showEntrySheet(context, isDark, preselectedDay: day, preselectedType: WorkType.remote)),
          if (isPast) ...[
            _QuickAddChip(emoji: '🌴', label: AppStrings.wtHoliday, isDark: isDark,
              onTap: () => _showEntrySheet(context, isDark, preselectedDay: day, preselectedType: WorkType.holiday)),
            _QuickAddChip(emoji: '📄', label: AppStrings.wtLeave, isDark: isDark,
              onTap: () => _showEntrySheet(context, isDark, preselectedDay: day, preselectedType: WorkType.leave)),
          ],
        ])),
        if (showWarning) _DeficitBadge(mins: missing),
      ] else
        Text('—', style: TextStyle(color: textSub, fontSize: 12)),
    ]),
```

`_DeficitBadge` — nuovo widget privato in fondo al file:

```dart
class _DeficitBadge extends StatelessWidget {
  final int mins;
  const _DeficitBadge({required this.mins});

  static String _hm(int m) => '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.red700.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      '⚠ −${_hm(mins)}',
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.red700),
    ),
  );
}
```

- [ ] **Step 4: `_buildEntryInfo` — enfasi orari + colonna destra**

Riscrittura (firma: aggiunge `int missing`):

```dart
  Widget _buildEntryInfo(DailyTimesheet entry, Color textMain, Color textSub,
      int mealThreshold, int missing) {
    final info = _typeInfo(entry.workType);
    final hasNote = entry.note != null && entry.note!.isNotEmpty;
    final isFullDayAbsence = entry.isLeave || entry.isHoliday;

    // Pause line pieces (only non-zero ones)
    final pauses = <String>[
      if (entry.standardPauseMins > 0) '☕ ${entry.standardPauseMins}m',
      if (entry.lunchPauseMins > 0) '🍽 ${entry.lunchPauseMins}m',
      if (entry.leavePauseMins > 0) '📄 ${_fmtNet(entry.leavePauseMins)}',
    ];

    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Centro: orari in evidenza + pause + nota ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isFullDayAbsence)
                  Text(
                    '${info.emoji} ${_fmtTime(entry.startTime)} → ${_fmtTime(entry.endTime)}',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: textMain,
                      letterSpacing: -0.3,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  )
                else
                  Text('${info.emoji} ${info.label}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: info.color)),
                if (pauses.isNotEmpty)
                  Text(pauses.join('  '),
                    style: TextStyle(fontSize: 10, color: textSub)),
                if (hasNote)
                  Text(entry.note!, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: textSub, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          // ── Destra: colonna contatori allineata ──
          if (!isFullDayAbsence)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_fmtNet(entry.netWorkedMins)} ${AppStrings.lavorateLabel}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: info.color)),
                if (entry.extraMins > 0)
                  Text('+${_fmtNet(entry.extraMins)} ${AppStrings.maggPresRowLabel}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.orange600))
                else if (missing > 0)
                  _DeficitBadge(mins: missing),
                if (entry.netWorkedMins >= mealThreshold)
                  const Text('🍽️', style: TextStyle(fontSize: 11)),
              ],
            ),
        ],
      ),
    );
  }
```

Il vecchio badge rosso "orari sospetti" (righe 1424-1449, net>600 o net<120) si conserva? No: sostituito dal badge deficit (più informativo); il caso net>600 è già visibile dall'orario in evidenza. Rimuoverlo.

- [ ] **Step 5: Verify + commit**

Run: `flutter analyze && flutter test`

```bash
git add lib/features/timesheet/presentation/timesheet_screen.dart lib/core/constants/app_strings.dart
git commit -m "feat(ui): timesheet list rows — time emphasis, right counters, 4 quick-add, deficit badge"
```

---

### Task 7: `_EntrySheet` editor segments + "Copri con permesso"

**Files:**
- Modify: `lib/features/timesheet/presentation/timesheet_screen.dart` — `_EntrySheetState` (3019-3720)
- Modify: `lib/core/constants/app_strings.dart`

**Interfaces:**
- Consumes: `DaySegment`, `recomputedFromSegments`, `AbsenceKind.groups` (picker esistente), `_TimeTile` (4030).
- Produces: per `_workType == presence` lo sheet edita `List<_SegmentDraft>` e salva `DailyTimesheet` con `segments` + totali ricalcolati.

- [ ] **Step 1: Stringhe**

```dart
  static const segmentiGiornata = 'Segmenti giornata';
  static const aggiungiLavoro = '+ Lavoro';
  static const aggiungiPermesso = '+ Permesso';
  static String copriConPermesso(String hm) => 'Copri con permesso $hm';
  static String mancanoAllOrario(String hm, String std) =>
      'Mancano $hm all\'orario ($std)';
  static const segmentiSovrapposti = 'Segmenti di lavoro sovrapposti';
```

- [ ] **Step 2: Stato sheet**

In `_EntrySheetState` aggiungere:

```dart
  // Segment drafts (presence only). Legacy single-interval days load as
  // one work draft, preserving today's simple UX for the common case.
  late List<_SegmentDraft> _segments;
```

```dart
class _SegmentDraft {
  String type; // DaySegment.work | DaySegment.leave
  TimeOfDay start, end; // work
  int leaveMins; // leave
  String? absenceKind; // leave
  _SegmentDraft.work(this.start, this.end)
      : type = DaySegment.work, leaveMins = 0;
  _SegmentDraft.leave(this.leaveMins, {this.absenceKind})
      : type = DaySegment.leave,
        start = const TimeOfDay(hour: 0, minute: 0),
        end = const TimeOfDay(hour: 0, minute: 0);
}
```

In `initState`: se `existing != null && !existing.isLeave && !existing.isHoliday && !existing.isRemote` → `_segments` da `existing.segments` (work → `_SegmentDraft.work(TimeOfDay.fromDateTime(s.start!), ...)`, leave → `_SegmentDraft.leave(s.mins, absenceKind: s.absenceKind)`); altrimenti `_segments = [_SegmentDraft.work(_entry, _exit)]`.

- [ ] **Step 3: UI sezione Presenza**

Sostituire i due `_TimeTile` Entrata/Uscita (sezione presence del `build`) con:

```dart
            if (_workType == WorkType.presence) ...[
              Text(AppStrings.segmentiGiornata, style: TextStyle(fontSize: 13, color: textSub)),
              const SizedBox(height: 8),
              for (var i = 0; i < _segments.length; i++)
                _segmentTile(i, isDark, textMain, textSub),
              Row(children: [
                _QuickAddChip(emoji: '🏢', label: AppStrings.aggiungiLavoro, isDark: isDark,
                  onTap: () => setState(() {
                    final last = _segments.lastWhere((s) => s.type == DaySegment.work,
                        orElse: () => _SegmentDraft.work(const TimeOfDay(hour: 9, minute: 0), const TimeOfDay(hour: 13, minute: 0)));
                    _segments.add(_SegmentDraft.work(last.end, TimeOfDay(hour: (last.end.hour + 2).clamp(0, 23), minute: last.end.minute)));
                  })),
                const SizedBox(width: 6),
                _QuickAddChip(emoji: '📄', label: AppStrings.aggiungiPermesso, isDark: isDark,
                  onTap: () => setState(() => _segments.add(_SegmentDraft.leave(60)))),
              ]),
              const SizedBox(height: 10),
              _liveTotalsFooter(textSub), // totale + delta + Copri
            ],
```

`_segmentTile(i, ...)`: riga con emoji tipo; work → due `_TimeTile` compatti (start/end, `onChanged` → setState); leave → tap apre il picker causale esistente (`AbsenceKind.groups`, riusare il widget/dialog già usato per il tipo Permesso) + `_TimeTile`-style durata (TimePicker come già fatto per `_absenceDuration`); IconButton ✕ (`Icons.close_rounded`, size 16) → `setState(() => _segments.removeAt(i))` (min 1 segment work: nascondere ✕ se è l'unico work).

`_liveTotalsFooter`: calcola preview con la stessa funzione di dominio —

```dart
  DailyTimesheet _previewEntry(DateTime base, int stdMins) {
    final segs = _segments.map((d) => d.type == DaySegment.work
        ? DaySegment(type: DaySegment.work,
            start: DateTime(base.year, base.month, base.day, d.start.hour, d.start.minute),
            end: DateTime(base.year, base.month, base.day, d.end.hour, d.end.minute))
        : DaySegment(type: DaySegment.leave, mins: d.leaveMins, absenceKind: d.absenceKind))
        .toList();
    return DailyTimesheet(
      dateId: '', startTime: base, endTime: base,
      standardPauseMins: widget.existingEntry?.standardPauseMins ?? 0,
      lunchPauseMins: 0, netWorkedMins: 0, extraMins: 0,
      bancaOreMins: widget.existingEntry?.bancaOreMins ?? 0,
      segments: segs,
    ).recomputedFromSegments(stdMins: stdMins);
  }
```

Footer: `Text('${_fmtNet(p.netWorkedMins)} / ${_fmtNet(stdMins)}')`; se `uncoveredDeficitMins(p) > 0` → warning `AppStrings.mancanoAllOrario(...)` + bottone `AppStrings.copriConPermesso(hm)` che fa `setState(() => _segments.add(_SegmentDraft.leave(missing)))`.

(`stdMins` nel build: leggere `profileData` via `ref.watch(userProfileStreamProvider)` come già fa `_save`.)

- [ ] **Step 4: `_save` per presence**

Sostituire il ramo presence (righe 3118-3152 circa) con:

```dart
        // Validate: work segments must not overlap.
        final works = _segments.where((s) => s.type == DaySegment.work).toList()
          ..sort((a, b) => (a.start.hour * 60 + a.start.minute)
              .compareTo(b.start.hour * 60 + b.start.minute));
        for (var i = 0; i < works.length; i++) {
          final sMin = works[i].start.hour * 60 + works[i].start.minute;
          final eMin = works[i].end.hour * 60 + works[i].end.minute;
          if (eMin <= sMin ||
              (i > 0 && sMin < works[i - 1].end.hour * 60 + works[i - 1].end.minute)) {
            throw Exception(AppStrings.segmentiSovrapposti);
          }
        }

        final entry = _previewEntry(base, stdMins); // same builder as footer
        await repo.saveDailyTimesheet(
          entry.copyWith(dateId: dateId, workType: WorkType.presence),
          fullOverwrite: widget.existingEntry != null, // no stale absence fields
        );
```

Ramo `leave`/`holiday` giornata intera: INVARIATO (nessun segment). Ramo `remote`: INVARIATO.

- [ ] **Step 5: Verify + commit**

Run: `flutter analyze && flutter test`

```bash
git add lib/features/timesheet/presentation/timesheet_screen.dart lib/core/constants/app_strings.dart
git commit -m "feat(timesheet): entry sheet segment editor + cover-with-leave action"
```

---

### Task 8: Verifica visiva, docs, ADR, changelog

**Files:**
- Modify: `docs/entita/daily-timesheet.md`, `docs/funzionalita/timesheet.md`, `docs/CHANGELOG.md`
- Create: `docs/decisioni/00NN-day-segments.md` (numero successivo al più alto esistente in `docs/decisioni/`)

- [ ] **Step 1: Run app + verifica flussi**

Run: `flutter run -d macos` (o device disponibile). Verificare: vista Lista (righe nuove, weekend compatti, quick-add 4 chip su giorno passato vuoto, badge deficit), widget contatori (scorporo, no barre), sheet segments (aggiungi permesso, Copri, salva), riapertura giorno salvato mostra segments, giorno legacy si apre senza errori.

- [ ] **Step 2: Docs**

- `daily-timesheet.md`: sezione nuova "Segments" (modello, derive lazy, recompute, `uncoveredDeficitMins`), correggere "schema v3" → v5, aggiornare glossario `deficit` (ora = somma deficit **non coperti**).
- `timesheet.md`: vista Lista (layout nuovo, 4 chip, badge, ore default), widget contatori (nuova struttura, prefs rimosse), `_EntrySheet` (editor segments, Copri con permesso).
- ADR: contesto (permessi parziali su giorno lavorato), opzioni (multi-doc, subcollection, array nel doc), decisione (array `segments[]`, derive lazy, totali sempre ricalcolati), conseguenze (cache Drift v5, campi legacy restano fonte per aggregati mensili).
- `CHANGELOG.md`: riga nuova in cima.

- [ ] **Step 3: Final check + commit**

Run: `flutter analyze && flutter test`

```bash
git add docs/
git commit -m "docs: segments model, list redesign, summary card — wiki + ADR + changelog"
```

---

## Self-Review (fatta)

- Spec coverage: §1→Task 1-4, §2→Task 6, §3→Task 5, §4→Task 7, §5→Task 1-2 (test) + Task 8 (docs). Ore default vicino data→Task 6 Step 3. Ricalcolo automatico→Task 2+4+7.
- Tipi coerenti: `recomputedFromSegments({required int stdMins})` ovunque; `uncoveredDeficitMins` statico su `DailyTimesheet`; `copyWith` introdotto in Task 2 e usato in Task 7.
- Nessun placeholder TBD; i blocchi "INVARIATO" indicano codice esistente da non toccare, con righe esatte.
