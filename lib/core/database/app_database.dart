import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pcm_catalog.dart';
// js_interop (non html): vero sia in compilazione JS sia WASM — con
// dart.library.html il target WASM sceglierebbe il path nativo dart:ffi
// (causa dei warning "wasm dry run" in flutter build web).
import 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart';

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
  BoolColumn get sensitive => boolean().withDefault(const Constant(false))();
  BoolColumn get hasDocumentation =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get countsAsSicknessPeriod =>
      boolean().withDefault(const Constant(false))();
  // ── Segments (schema v5) — JSON array of DaySegment maps ────────────────
  TextColumn get segments => text().nullable()();

  @override
  Set<Column> get primaryKey => {uid, dateId};
}

class PcmOfficeLocations extends Table {
  TextColumn get id => text()();
  TextColumn get siteId => text().nullable()();
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
  int get schemaVersion => 6;

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
      if (from < 5) {
        await m.database.customStatement(
          'ALTER TABLE timesheet_entries ADD COLUMN segments TEXT',
        );
      }
      if (from < 6) {
        await m.database.customStatement(
          'ALTER TABLE pcm_office_locations ADD COLUMN site_id TEXT',
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

  Future<List<PcmOfficeLocation>> getPcmOfficeLocations() =>
      (select(pcmOfficeLocations)..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.structureName),
          ]))
          .get();

  Future<void> replacePcmCatalog(PcmCatalog catalog) async {
    await transaction(() async {
      await delete(pcmOfficeLocations).go();
      await batch((b) {
        b.insertAll(
          pcmOfficeLocations,
          catalog.structures
              .map(
                (entry) => PcmOfficeLocationsCompanion.insert(
                  id: entry.id,
                  siteId: Value(entry.siteId),
                  locationName: entry.siteName,
                  structureName: entry.structureName,
                  address: entry.address,
                  city: Value(entry.city),
                  latitude: entry.latitude,
                  longitude: entry.longitude,
                  sortOrder: entry.sortOrder,
                  updatedAt: catalog.version,
                ),
              )
              .toList(growable: false),
        );
      });
    });
  }

  Future<PcmCatalog?> getPcmCatalog() async {
    final rows = await getPcmOfficeLocations();
    if (rows.isEmpty || rows.any((row) => row.siteId == null)) return null;

    final catalog = PcmCatalog(
      version: rows.first.updatedAt,
      source: 'Drift cache',
      structures: rows
          .where((row) => row.isActive)
          .map(
            (row) => PcmStructureSite(
              id: row.id,
              structureName: row.structureName,
              sortOrder: row.sortOrder,
              siteId: row.siteId!,
              siteName: row.locationName,
              address: row.address,
              city: row.city,
              latitude: row.latitude,
              longitude: row.longitude,
            ),
          )
          .toList(growable: false),
    );
    try {
      validatePcmCatalog(catalog);
      return catalog;
    } on PcmCatalogValidationException {
      return null;
    }
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase?>((ref) {
  // Web: Drift WASM via connection_web.dart (nativeConnection).
  // drift_worker.dart.js lives in web/ and sqlite3.wasm is served from
  // packages/sqlite3_flutter_libs/assets/sqlite3.wasm by Flutter's asset system.
  // On WASM init failure the DB stays null and all repos degrade to Firestore-only.
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
