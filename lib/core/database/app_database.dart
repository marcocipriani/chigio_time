import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/pcm_locations.dart';
import 'connection_native.dart' if (dart.library.html) 'connection_web.dart';

part 'app_database.g.dart';

// ── Table ────────────────────────────────────────────────────────────────────

class TimesheetEntries extends Table {
  TextColumn get uid => text()();
  TextColumn get dateId => text()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  IntColumn get standardPauseMins => integer().withDefault(const Constant(0))();
  IntColumn get leavePauseMins => integer().withDefault(const Constant(0))();
  IntColumn get lunchPauseMins => integer().withDefault(const Constant(0))();
  IntColumn get netWorkedMins => integer()();
  IntColumn get extraMins => integer()();
  IntColumn get sliMins => integer().withDefault(const Constant(0))();
  IntColumn get sboMins => integer().withDefault(const Constant(0))();
  TextColumn get workType => text().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get bancaOreMins => integer().withDefault(const Constant(0))();
  TextColumn get boeSlot => text().nullable()();
  TextColumn get updatedAt => text()();
  // ── Absence fields (schema v4) ──────────────────────────────────────────
  TextColumn get absenceKind => text().nullable()();
  TextColumn get absenceUnit => text().nullable()();
  IntColumn get absenceMins => integer().nullable()();
  RealColumn get absenceDays => real().nullable()();
  TextColumn get periodFrom => text().nullable()();
  TextColumn get periodTo => text().nullable()();
  RealColumn get quotaYear => real().nullable()();
  BoolColumn get sensitive =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get hasDocumentation =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get countsAsSicknessPeriod =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uid, dateId};
}

class PcmOfficeLocations extends Table {
  TextColumn get id => text()();
  TextColumn get locationName => text()();
  TextColumn get structureName => text()();
  TextColumn get address => text()();
  TextColumn get city => text().withDefault(const Constant('Roma'))();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get sortOrder => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [TimesheetEntries, PcmOfficeLocations])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? nativeConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.database.customStatement(
          'ALTER TABLE timesheet_entries ADD COLUMN banca_ore_mins INTEGER NOT NULL DEFAULT 0',
        );
        await m.database.customStatement(
          'ALTER TABLE timesheet_entries ADD COLUMN boe_slot TEXT',
        );
      }
      if (from < 3) {
        await m.createTable(pcmOfficeLocations);
      }
      if (from < 4) {
        const add = 'ALTER TABLE timesheet_entries ADD COLUMN';
        await m.database.customStatement('$add absence_kind TEXT');
        await m.database.customStatement('$add absence_unit TEXT');
        await m.database.customStatement('$add absence_mins INTEGER');
        await m.database.customStatement('$add absence_days REAL');
        await m.database.customStatement('$add period_from TEXT');
        await m.database.customStatement('$add period_to TEXT');
        await m.database.customStatement('$add quota_year REAL');
        await m.database.customStatement(
          '$add sensitive INTEGER NOT NULL DEFAULT 0',
        );
        await m.database.customStatement(
          '$add has_documentation INTEGER NOT NULL DEFAULT 0',
        );
        await m.database.customStatement(
          '$add counts_as_sickness_period INTEGER NOT NULL DEFAULT 0',
        );
      }
    },
  );

  Future<List<TimesheetEntry>> getMonthlyEntries(
    String uid,
    String yearMonth, // 'YYYY-MM'
  ) =>
      (select(timesheetEntries)..where(
            (t) =>
                t.uid.equals(uid) &
                t.dateId.isBiggerOrEqualValue('$yearMonth-01') &
                t.dateId.isSmallerOrEqualValue('$yearMonth-31'),
          ))
          .get();

  Future<void> upsertEntry(TimesheetEntriesCompanion entry) =>
      into(timesheetEntries).insertOnConflictUpdate(entry);

  Future<void> deleteEntry(String uid, String dateId) => (delete(
    timesheetEntries,
  )..where((t) => t.uid.equals(uid) & t.dateId.equals(dateId))).go();

  Future<void> seedPcmOfficeLocationsIfNeeded() async {
    final now = DateTime.now().toUtc().toIso8601String();
    await batch((b) {
      b.insertAllOnConflictUpdate(
        pcmOfficeLocations,
        pcmOfficeSeeds
            .map((office) {
              return PcmOfficeLocationsCompanion.insert(
                id: office.id,
                locationName: office.locationName,
                structureName: office.structureName,
                address: office.address,
                city: Value(office.city),
                latitude: office.latitude,
                longitude: office.longitude,
                sortOrder: office.sortOrder,
                isActive: Value(office.isActive),
                updatedAt: now,
              );
            })
            .toList(growable: false),
      );
    });
  }

  Future<List<PcmOfficeLocation>> getPcmOfficeLocations() =>
      (select(pcmOfficeLocations)..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.structureName),
          ]))
          .get();
}

// ── Provider ─────────────────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase?>((ref) {
  // Web userebbe Drift WASM (connection_web.dart), ma gli asset build-time
  // (sqlite3.wasm, drift_worker.dart.js) non sono ancora pubblicati: la
  // connessione resterebbe sospesa a tempo indeterminato e bloccherebbe in
  // "loading" qualunque provider che interroga il DB (es. le sedi PCM).
  // Vedi docs/ROADMAP.md — "Drift WASM web — asset build". Finche' mancano,
  // su web restiamo in modalita' Firestore-only (db nullo, gestito da tutti
  // i repository).
  if (kIsWeb) return null;

  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
