import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/date_utils.dart';

part 'active_timer_repository.g.dart';

/// Stato del turno attivo persistito su `users/{uid}/activeTimer/state` per
/// il sync cross-device (M3, review 2026-07-05: prima il provider di
/// presentation parlava direttamente con Firestore, con il parsing duplicato
/// in tre punti).
///
/// Contiene SOLO i dati persistiti: la conversione in `TimerState`
/// (stdMins, currentTime, exitNotifMins…) resta al provider.
class ActiveTimerData {
  final String status; // WorkState.name (mai notStarted/completed)
  final DateTime startTime;
  final DateTime? pauseStart;
  final String pauseType; // PauseType.name
  final int stdPauseMins;
  final int leavePauseMins;
  final int lunchPauseMins;
  final DateTime? reminderAt;
  final int reminderLeadMins;

  const ActiveTimerData({
    required this.status,
    required this.startTime,
    this.pauseStart,
    this.pauseType = 'none',
    this.stdPauseMins = 0,
    this.leavePauseMins = 0,
    this.lunchPauseMins = 0,
    this.reminderAt,
    this.reminderLeadMins = 0,
  });
}

class ActiveTimerRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  ActiveTimerRepository(this._db, this._auth);

  DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.doc('users/$uid/activeTimer/state');
  }

  /// Parsing condiviso tra [load] e [watch]. Restituisce null se il doc
  /// manca, è di un giorno diverso, non rappresenta un turno attivo o è
  /// corrotto (start time non parsabile).
  static ActiveTimerData? parse(Map<String, dynamic>? d) {
    if (d == null) return null;
    if ((d['date'] as String?) != todayId()) return null;
    final status = d['status'] as String?;
    if (status == null || status == 'notStarted' || status == 'completed') {
      return null;
    }
    final start = DateTime.tryParse(d['startTime'] as String? ?? '');
    if (start == null) return null;
    final pauseStr = d['pauseStart'] as String?;
    return ActiveTimerData(
      status: status,
      startTime: start,
      pauseStart: pauseStr != null ? DateTime.tryParse(pauseStr) : null,
      pauseType: d['pauseType'] as String? ?? 'none',
      stdPauseMins: d['stdPauseMins'] as int? ?? 0,
      leavePauseMins: d['leavePauseMins'] as int? ?? 0,
      lunchPauseMins: d['lunchPauseMins'] as int? ?? 0,
      reminderAt: (d['reminderAt'] as Timestamp?)?.toDate(),
      reminderLeadMins: d['reminderLeadMins'] as int? ?? 0,
    );
  }

  /// Fire-and-forget: un fallimento di sync non deve bloccare la timbratura
  /// (lo stato locale su SharedPreferences resta la fonte primaria del device).
  Future<void> save(ActiveTimerData d) async {
    final doc = _doc;
    if (doc == null) return;
    final data = <String, dynamic>{
      'date': todayId(),
      'status': d.status,
      'pauseType': d.pauseType,
      'stdPauseMins': d.stdPauseMins,
      'leavePauseMins': d.leavePauseMins,
      'lunchPauseMins': d.lunchPauseMins,
      'reminderLeadMins': d.reminderLeadMins,
      'startTime': d.startTime.toIso8601String(),
    };
    if (d.pauseStart != null) {
      data['pauseStart'] = d.pauseStart!.toIso8601String();
    }
    if (d.reminderAt != null) {
      data['reminderAt'] = Timestamp.fromDate(d.reminderAt!);
    }
    unawaited(
      doc
          .set(data)
          .onError((e, _) => debugPrint('[activeTimer] sync failed: $e')),
    );
  }

  Future<ActiveTimerData?> load() async {
    final doc = _doc;
    if (doc == null) return null;
    try {
      final snap = await doc.get();
      return parse(snap.data());
    } catch (e) {
      debugPrint('[activeTimer] load failed: $e');
      return null;
    }
  }

  /// Stream del doc remoto già parsato (null = nessun turno attivo valido).
  Stream<ActiveTimerData?> watch() {
    final doc = _doc;
    if (doc == null) return const Stream.empty();
    return doc.snapshots().map((snap) => parse(snap.data()));
  }

  Future<void> clear() async {
    _doc?.delete().ignore();
  }
}

@riverpod
ActiveTimerRepository activeTimerRepository(Ref ref) =>
    ActiveTimerRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
