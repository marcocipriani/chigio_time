import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show Value;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/daily_timesheet.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/database/app_database.dart';

part 'timesheet_repository.g.dart';

class TimesheetRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AppDatabase? _db;

  TimesheetRepository(this._firestore, this._auth, this._db);

  Future<void> saveDailyTimesheet(DailyTimesheet entry) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception(AppStrings.userNotAuthenticated);

    final today = DateTime.now();
    final todayId =
        '${today.year}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    final type = entry.workType ?? WorkType.presence;
    // Always publish currentStatus when saving today — presence clocks out
    // as 'completed'; other types (remote, leave, holiday) use the type string.
    final publishStatus = entry.dateId == todayId;
    final statusToPublish = type == WorkType.presence ? 'completed' : type;

    final batch = _firestore.batch();

    batch.set(
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('timesheets')
          .doc(entry.dateId),
      entry.toMap(),
      SetOptions(merge: true),
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
              (e, _) =>
                  debugPrint('[timesheet_repo] DB cache write failed: $e'),
            ),
      );
    }
  }

  Future<void> saveRemoteWorkDay({required int stdMins}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception(AppStrings.userNotAuthenticated);

    final today = DateTime.now();
    final dateId =
        '${today.year}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    final start = DateTime(today.year, today.month, today.day, 9, 0);
    final end = start.add(Duration(minutes: stdMins + 30));

    final entry = DailyTimesheet(
      dateId: dateId,
      startTime: start,
      endTime: end,
      standardPauseMins: 0,
      lunchPauseMins: 30,
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
              (e, _) => debugPrint(
                '[timesheet_repo] DB remote cache write failed: $e',
              ),
            ),
      );
    }
  }

  Future<void> saveNote(String dateId, String note) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception(AppStrings.userNotAuthenticated);
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
    if (user == null) throw Exception(AppStrings.userNotAuthenticated);

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
              (e, _) =>
                  debugPrint('[timesheet_repo] DB cache delete failed: $e'),
            ),
      );
    }
  }

  Future<List<DailyTimesheet>> fetchRange(DateTime start, DateTime end) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    final startId = _dateIdOf(start);
    final endId = _dateIdOf(end);
    final snap = await _firestore
        .collection('users/${user.uid}/timesheets')
        .where('dateId', isGreaterThanOrEqualTo: startId)
        .where('dateId', isLessThanOrEqualTo: endId)
        .orderBy('dateId')
        .get();
    return snap.docs.map((d) => DailyTimesheet.fromMap(d.data())).toList();
  }

  static String _dateIdOf(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
                      (err, _) => debugPrint(
                        '[timesheet_repo] DB cache write failed: $err',
                      ),
                    ),
              );
            }
          }
          return entries;
        });

    return firestoreStream.transform(
      StreamTransformer.fromHandlers(
        handleError: (e, st, sink) async {
          // Offline fallback: serve from local cache (no-op on web).
          if (_db != null) {
            final rows = await _db.getMonthlyEntries(uid, prefix);
            sink.add(rows.map(_fromRow).toList());
          }
        },
      ),
    );
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
        updatedAt: Value(e.toMap()['updatedAt'] as String),
      );

  DailyTimesheet _fromRow(TimesheetEntry r) => DailyTimesheet(
    dateId: r.dateId,
    startTime: DateTime.parse(r.startTime),
    endTime: DateTime.parse(r.endTime),
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
  );
}

@riverpod
TimesheetRepository timesheetRepository(Ref ref) => TimesheetRepository(
  FirebaseFirestore.instance,
  FirebaseAuth.instance,
  ref.watch(appDatabaseProvider),
);

final monthlyTimesheetsProvider =
    StreamProvider.family<List<DailyTimesheet>, ({int year, int month})>((
      ref,
      args,
    ) {
      final repo = ref.watch(timesheetRepositoryProvider);
      return repo.watchMonthlyTimesheets(args.year, args.month);
    });
