import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show Value;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/daily_timesheet.dart';
import '../domain/day_segment.dart';
import '../../../core/errors/failures.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../../authentication/data/auth_repository.dart';

part 'timesheet_repository.g.dart';

const _logTag = 'timesheet_repo';

class TimesheetRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AppDatabase? _db;

  TimesheetRepository(this._firestore, this._auth, this._db);

  /// [fullOverwrite] = true sostituisce l'intero documento (set senza merge):
  /// usato dall'import CSV, così cambiare tipo a un giorno non lascia campi
  /// opzionali stale (es. `absenceKind` di un vecchio Permesso su una Presenza).
  Future<void> saveDailyTimesheet(
    DailyTimesheet entry, {
    bool fullOverwrite = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthenticationFailure();

    final type = entry.workType ?? WorkType.presence;
    // Always publish currentStatus when saving today — presence clocks out
    // as 'completed'; other types (remote, leave, holiday) use the type string.
    final publishStatus = entry.dateId == todayId();
    final statusToPublish = type == WorkType.presence ? 'completed' : type;

    final batch = _firestore.batch();

    batch.set(
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('timesheets')
          .doc(entry.dateId),
      entry.toMap(),
      SetOptions(merge: !fullOverwrite),
    );

    if (publishStatus) {
      batch.update(_firestore.collection('users').doc(user.uid), {
        'currentStatus': statusToPublish,
        'statusDate': entry.dateId,
      });
    }

    await batch.commit();
    if (_db != null) {
      unawaited(
        _db
            .upsertEntry(_toCompanion(user.uid, entry))
            .onError(
              (e, st) => AppLog.warning(
                _logTag,
                'DB cache write failed',
                error: e,
                stackTrace: st,
              ),
            ),
      );
    }
  }

  Future<void> saveRemoteWorkDay({required int stdMins}) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthenticationFailure();

    final today = DateTime.now();
    final dateId = todayId();
    final start = DateTime(today.year, today.month, today.day, 9, 0);
    final end = start.add(Duration(minutes: stdMins));

    final entry = DailyTimesheet(
      dateId: dateId,
      startTime: start,
      endTime: end,
      standardPauseMins: 0,
      lunchPauseMins: 0,
      netWorkedMins: stdMins,
      extraMins: 0,
      workType: WorkType.remote,
    );

    final batch = _firestore.batch();
    batch.set(
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('timesheets')
          .doc(dateId),
      entry.toMap(),
      SetOptions(merge: true),
    );
    batch.update(_firestore.collection('users').doc(user.uid), {
      'currentStatus': WorkType.remote,
      'statusDate': dateId,
    });
    await batch.commit();
    if (_db != null) {
      unawaited(
        _db
            .upsertEntry(_toCompanion(user.uid, entry))
            .onError(
              (e, st) => AppLog.warning(
                _logTag,
                'DB remote cache write failed',
                error: e,
                stackTrace: st,
              ),
            ),
      );
    }
  }

  Future<void> saveNote(String dateId, String note) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthenticationFailure();
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('timesheets')
        .doc(dateId)
        .set({
          'note': note.trim(),
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        }, SetOptions(merge: true));
  }

  Future<void> deleteDailyTimesheet(String dateId) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthenticationFailure();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('timesheets')
        .doc(dateId)
        .delete();

    if (_db != null) {
      unawaited(
        _db
            .deleteEntry(user.uid, dateId)
            .onError(
              (e, st) => AppLog.warning(
                _logTag,
                'DB cache delete failed',
                error: e,
                stackTrace: st,
              ),
            ),
      );
    }
  }

  Future<List<DailyTimesheet>> fetchRange(DateTime start, DateTime end) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthenticationFailure();
    final startId = dateIdOf(start);
    final endId = dateIdOf(end);
    final snap = await _firestore
        .collection('users/${user.uid}/timesheets')
        .where('dateId', isGreaterThanOrEqualTo: startId)
        .where('dateId', isLessThanOrEqualTo: endId)
        .orderBy('dateId')
        .get();
    return snap.docs.map((d) => DailyTimesheet.fromMap(d.data())).toList();
  }

  Stream<List<DailyTimesheet>> watchMonthlyTimesheets(int year, int month) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    final uid = user.uid;
    final prefix = '$year-${month.toString().padLeft(2, '0')}';

    final firestoreStream = _firestore
        .collection('users/$uid/timesheets')
        .where('dateId', isGreaterThanOrEqualTo: '$prefix-01')
        .where('dateId', isLessThanOrEqualTo: '$prefix-31')
        .snapshots()
        .asyncMap((snap) async {
          final entries = snap.docs
              .map((d) => DailyTimesheet.fromMap(d.data()))
              .toList();
          // Write-through to local SQLite cache.
          if (_db != null) {
            for (final e in entries) {
              unawaited(
                _db
                    .upsertEntry(_toCompanion(uid, e))
                    .onError(
                      (err, st) => AppLog.warning(
                        _logTag,
                        'DB cache write failed',
                        error: err,
                        stackTrace: st,
                      ),
                    ),
              );
            }
          }
          return entries;
        });

    final db = _db;
    return offlineFallback(
      firestoreStream,
      db == null
          ? null
          : () async => (await db.getMonthlyEntries(
              uid,
              prefix,
            )).map(_fromRow).toList(),
    );
  }

  /// Se la sorgente remota fallisce, serve il mese dalla cache locale; se la
  /// cache non c'è (Web) o è illeggibile, propaga l'errore originale.
  ///
  /// Era uno `StreamTransformer.fromHandlers` con un `handleError` `async`, e
  /// non funzionava in nessuno dei due casi. Con la cache: l'handler ritornava
  /// al primo `await`, il transformer chiudeva il sink e la `sink.add`
  /// successiva finiva su uno stream chiuso — `Bad state: Stream is already
  /// closed`, in un gap asincrono, quindi non gestito, e la cache non arrivava
  /// mai. Senza cache: l'handler non faceva nulla, così l'errore spariva e lo
  /// stream si chiudeva senza aver emesso niente. Un `StreamProvider` su uno
  /// stream chiuso senza valori resta in `AsyncLoading` per sempre: la Home
  /// restava sullo skeleton e il ramo `hasError` con il pulsante di riprova
  /// era codice irraggiungibile. Un generatore `async*` regge entrambi i casi:
  /// dentro il `catch` può ancora attendere e poi emettere.
  /// [loadCache] è null quando non c'è cache locale (Web).
  @visibleForTesting
  static Stream<List<DailyTimesheet>> offlineFallback(
    Stream<List<DailyTimesheet>> remote,
    Future<List<DailyTimesheet>> Function()? loadCache,
  ) async* {
    try {
      // `await for`, non `yield*`: in un generatore `async*` lo `yield*`
      // inoltra gli errori della sorgente direttamente a chi ascolta, senza
      // farli passare da questo `catch`, e il fallback non partirebbe mai.
      await for (final entries in remote) {
        yield entries;
      }
    } catch (error, stackTrace) {
      if (loadCache != null) {
        try {
          yield await loadCache();
          return;
        } catch (cacheError, cacheStackTrace) {
          AppLog.warning(
            _logTag,
            'DB cache read failed',
            error: cacheError,
            stackTrace: cacheStackTrace,
          );
        }
      }
      // Nessuna cache utilizzabile: chi ascolta deve vedere il guasto, non un
      // caricamento infinito.
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  // ── Drift helpers ──────────────────────────────────────────────────────────

  TimesheetEntriesCompanion _toCompanion(String uid, DailyTimesheet e) =>
      TimesheetEntriesCompanion(
        uid: Value(uid),
        dateId: Value(e.dateId),
        startTime: Value(e.startTime.toIso8601String()),
        endTime: Value(e.endTime.toIso8601String()),
        standardPauseMins: Value(e.standardPauseMins),
        leavePauseMins: Value(e.leavePauseMins),
        lunchPauseMins: Value(e.lunchPauseMins),
        netWorkedMins: Value(e.netWorkedMins),
        extraMins: Value(e.extraMins),
        sliMins: Value(e.sliMins),
        sboMins: Value(e.sboMins),
        workType: Value(e.workType),
        note: Value(e.note),
        bancaOreMins: Value(e.bancaOreMins),
        boeSlot: Value(e.boeSlot),
        absenceKind: Value(e.absenceKind),
        absenceUnit: Value(e.absenceUnit),
        absenceMins: Value(e.absenceMins == 0 ? null : e.absenceMins),
        absenceDays: Value(e.absenceDays == 0 ? null : e.absenceDays),
        periodFrom: Value(e.periodStart),
        periodTo: Value(e.periodEnd),
        quotaYear: Value(e.quotaYear?.toDouble()),
        sensitive: Value(e.sensitive),
        hasDocumentation: Value(e.hasDocumentation),
        countsAsSicknessPeriod: Value(e.countsAsSicknessPeriod),
        segments: Value(
          e.segments.isEmpty
              ? null
              : jsonEncode(e.segments.map((s) => s.toMap()).toList()),
        ),
        updatedAt: Value(DateTime.now().toUtc().toIso8601String()),
      );

  /// Entry-point pubblico per i test: il fallback offline è l'unico punto in
  /// cui una riga di cache corrotta può rompere la vista mensile.
  @visibleForTesting
  static DailyTimesheet entryFromCacheRow(TimesheetEntry row) => _fromRow(row);

  static DailyTimesheet _fromRow(TimesheetEntry r) => DailyTimesheet(
    dateId: r.dateId,
    // Tolerant parse: a corrupt local row must not throw and break the list.
    startTime:
        DateTime.tryParse(r.startTime) ??
        DateTime.tryParse(r.dateId) ??
        DateTime.fromMillisecondsSinceEpoch(0),
    endTime:
        DateTime.tryParse(r.endTime) ??
        DateTime.tryParse(r.dateId) ??
        DateTime.fromMillisecondsSinceEpoch(0),
    standardPauseMins: r.standardPauseMins,
    leavePauseMins: r.leavePauseMins,
    lunchPauseMins: r.lunchPauseMins,
    netWorkedMins: r.netWorkedMins,
    extraMins: r.extraMins,
    sliMins: r.sliMins,
    sboMins: r.sboMins,
    workType: r.workType,
    note: r.note,
    bancaOreMins: r.bancaOreMins,
    boeSlot: r.boeSlot,
    absenceKind: r.absenceKind,
    absenceUnit: r.absenceUnit,
    absenceMins: r.absenceMins ?? 0,
    absenceDays: r.absenceDays ?? 0,
    periodStart: r.periodFrom,
    periodEnd: r.periodTo,
    quotaYear: r.quotaYear?.toInt(),
    sensitive: r.sensitive,
    hasDocumentation: r.hasDocumentation,
    countsAsSicknessPeriod: r.countsAsSicknessPeriod,
    segments: _segmentsFromJson(r.segments),
  );

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
}

@riverpod
TimesheetRepository timesheetRepository(Ref ref) {
  // Rebuild on sign-in/sign-out: the repository reads _auth.currentUser
  // synchronously, so an instance created while auth was still resolving
  // would hand out an empty stream forever (Home stuck on the skeleton).
  ref.watch(currentUidProvider);
  return TimesheetRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    ref.watch(appDatabaseProvider),
  );
}

final monthlyTimesheetsProvider =
    StreamProvider.family<List<DailyTimesheet>, ({int year, int month})>((
      ref,
      args,
    ) {
      final repo = ref.watch(timesheetRepositoryProvider);
      return repo.watchMonthlyTimesheets(args.year, args.month);
    });
