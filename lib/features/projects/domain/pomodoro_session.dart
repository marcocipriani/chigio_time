import 'package:cloud_firestore/cloud_firestore.dart';

/// Un pomodoro svolto su un progetto in un dato giorno (ADR-0011).
///
/// `confirmed == false` → "non confermato": tipicamente un timer interrotto
/// dalla timbratura di uscita, da rivedere.
class PomodoroSession {
  final String id;
  final String projectId;
  final String uid;
  final String userName;
  final String dateId; // 'YYYY-MM-DD'
  final int focusMins;
  final int breakMins;
  final DateTime startedAt;
  final bool confirmed;

  const PomodoroSession({
    required this.id,
    required this.projectId,
    required this.uid,
    required this.userName,
    required this.dateId,
    required this.focusMins,
    required this.breakMins,
    required this.startedAt,
    required this.confirmed,
  });

  factory PomodoroSession.fromDoc(String id, Map<String, dynamic> m) {
    final ts = m['startedAt'];
    return PomodoroSession(
      id: id,
      projectId: m['projectId'] as String? ?? '',
      uid: m['uid'] as String? ?? '',
      userName: m['userName'] as String? ?? '',
      dateId: m['dateId'] as String? ?? '',
      focusMins: m['focusMins'] as int? ?? 25,
      breakMins: m['breakMins'] as int? ?? 5,
      startedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      confirmed: m['confirmed'] as bool? ?? true,
    );
  }
}
