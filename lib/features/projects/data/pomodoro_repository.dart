import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/project.dart';
import '../domain/pomodoro_session.dart';

/// Timer pomodoro in corso, reso persistente in `users/{uid}/activeTimer/current`
/// così sopravvive a chiusura app/tab (conteggio basato su [startedAt]).
class ActivePomodoro {
  final String projectId;
  final String projectName;
  final int focusMins;
  final int breakMins;
  final DateTime startedAt;

  const ActivePomodoro({
    required this.projectId,
    required this.projectName,
    required this.focusMins,
    required this.breakMins,
    required this.startedAt,
  });

  factory ActivePomodoro.fromMap(Map<String, dynamic> m) {
    final ts = m['startedAt'];
    return ActivePomodoro(
      projectId: m['projectId'] as String? ?? '',
      projectName: m['projectName'] as String? ?? '',
      focusMins: m['focusMins'] as int? ?? 25,
      breakMins: m['breakMins'] as int? ?? 5,
      startedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

class PomodoroRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  const PomodoroRepository(this._db, this._auth);

  String? get _uid => _auth.currentUser?.uid;

  /// UID dell'utente corrente (per la presentation).
  String? get currentUid => _uid;

  CollectionReference<Map<String, dynamic>> get _projects =>
      _db.collection('projects');

  static String _todayId() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<String> _myName() async {
    final uid = _uid;
    if (uid == null) return 'Io';
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['name'] as String? ?? 'Io';
  }

  // ── Projects ───────────────────────────────────────────────────────────

  /// I miei progetti (di cui sono membro: owner o collaboratore unito).
  Stream<List<Project>> watchMyProjects() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _projects
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => Project.fromDoc(d.id, d.data())).toList()
                ..sort((a, b) => a.name.toLowerCase().compareTo(
                  b.name.toLowerCase(),
                )),
        );
  }

  /// Progetti condivisi dai Collegati a cui non sono ancora unito.
  Future<List<Project>> discoverSharedFromColleagues(
    List<String> colleagueUids,
  ) async {
    final uid = _uid;
    if (uid == null || colleagueUids.isEmpty) return [];
    final found = <String, Project>{};
    for (var i = 0; i < colleagueUids.length; i += 30) {
      final chunk = colleagueUids.sublist(
        i,
        (i + 30).clamp(0, colleagueUids.length),
      );
      final snap = await _projects
          .where('shared', isEqualTo: true)
          .where('ownerUid', whereIn: chunk)
          .get();
      for (final d in snap.docs) {
        final p = Project.fromDoc(d.id, d.data());
        if (!p.isMember(uid)) found[d.id] = p;
      }
    }
    return found.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> createProject({
    required String name,
    required bool shared,
    int colorValue = 0xFF0055A5,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _projects.add({
      'name': name.trim(),
      'ownerUid': uid,
      'ownerName': await _myName(),
      'shared': shared,
      'memberUids': [uid],
      'colorValue': colorValue,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> joinProject(String projectId) async {
    final uid = _uid;
    if (uid == null) return;
    await _projects.doc(projectId).update({
      'memberUids': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> leaveProject(String projectId) async {
    final uid = _uid;
    if (uid == null) return;
    await _projects.doc(projectId).update({
      'memberUids': FieldValue.arrayRemove([uid]),
    });
  }

  Future<void> renameProject(String projectId, String name) =>
      _projects.doc(projectId).update({'name': name.trim()});

  Future<void> setShared(String projectId, bool shared) =>
      _projects.doc(projectId).update({'shared': shared});

  /// Cessione del ruolo di capo progetto a un altro membro.
  Future<void> transferOwnership(
    String projectId,
    String newOwnerUid,
    String newOwnerName,
  ) => _projects.doc(projectId).update({
    'ownerUid': newOwnerUid,
    'ownerName': newOwnerName,
    'memberUids': FieldValue.arrayUnion([newOwnerUid]),
  });

  Future<void> deleteProject(String projectId) =>
      _projects.doc(projectId).delete();

  // ── Pomodoros ────────────────────────────────────────────────────────────

  Stream<List<PomodoroSession>> watchPomodoros(String projectId) {
    return _projects
        .doc(projectId)
        .collection('pomodoros')
        .orderBy('startedAt', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => PomodoroSession.fromDoc(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> addPomodoro({
    required String projectId,
    required int focusMins,
    required int breakMins,
    DateTime? startedAt,
    bool confirmed = true,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _projects.doc(projectId).collection('pomodoros').add({
      'projectId': projectId,
      'uid': uid,
      'userName': await _myName(),
      'dateId': _todayId(),
      'focusMins': focusMins,
      'breakMins': breakMins,
      'startedAt': startedAt != null
          ? Timestamp.fromDate(startedAt)
          : FieldValue.serverTimestamp(),
      'confirmed': confirmed,
    });
  }

  Future<void> removePomodoro(String projectId, String pomodoroId) => _projects
      .doc(projectId)
      .collection('pomodoros')
      .doc(pomodoroId)
      .delete();

  // ── Active timer (persistente) ────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> get _activeTimerRef =>
      _db.collection('users').doc(_uid).collection('activeTimer').doc('current');

  Stream<ActivePomodoro?> watchActiveTimer() {
    final uid = _uid;
    if (uid == null) return Stream.value(null);
    return _activeTimerRef.snapshots().map((d) {
      final data = d.data();
      if (data == null || data['projectId'] == null) return null;
      return ActivePomodoro.fromMap(data);
    });
  }

  Future<void> startTimer(ActivePomodoro timer) => _activeTimerRef.set({
    'projectId': timer.projectId,
    'projectName': timer.projectName,
    'focusMins': timer.focusMins,
    'breakMins': timer.breakMins,
    'startedAt': Timestamp.fromDate(timer.startedAt),
  });

  Future<void> clearActiveTimer() => _activeTimerRef.delete();
}

// ── Providers ──────────────────────────────────────────────────────────────

final pomodoroRepositoryProvider = Provider<PomodoroRepository>(
  (ref) => PomodoroRepository(FirebaseFirestore.instance, FirebaseAuth.instance),
);

final myProjectsStreamProvider = StreamProvider.autoDispose<List<Project>>(
  (ref) => ref.watch(pomodoroRepositoryProvider).watchMyProjects(),
);

final activeTimerStreamProvider = StreamProvider.autoDispose<ActivePomodoro?>(
  (ref) => ref.watch(pomodoroRepositoryProvider).watchActiveTimer(),
);

final pomodorosStreamProvider = StreamProvider.autoDispose
    .family<List<PomodoroSession>, String>(
      (ref, projectId) =>
          ref.watch(pomodoroRepositoryProvider).watchPomodoros(projectId),
    );
