import 'package:cloud_firestore/cloud_firestore.dart';

/// Progetto su cui tracciare i pomodori (ADR-0011).
///
/// Ruolo unico e trasferibile: l'`ownerUid` è il **capo progetto**.
/// `shared == false` → progetto personale; `true` → condiviso con i Collegati.
class Project {
  final String id;
  final String name;
  final String ownerUid;
  final String ownerName;
  final bool shared;
  final List<String> memberUids;
  final int colorValue;
  final DateTime? createdAt;

  const Project({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.ownerName,
    required this.shared,
    required this.memberUids,
    required this.colorValue,
    this.createdAt,
  });

  bool isOwner(String uid) => uid == ownerUid;
  bool isMember(String uid) => memberUids.contains(uid);

  factory Project.fromDoc(String id, Map<String, dynamic> m) {
    final ts = m['createdAt'];
    return Project(
      id: id,
      name: m['name'] as String? ?? 'Progetto',
      ownerUid: m['ownerUid'] as String? ?? '',
      ownerName: m['ownerName'] as String? ?? '',
      shared: m['shared'] as bool? ?? false,
      memberUids: (m['memberUids'] as List?)?.cast<String>() ?? const [],
      colorValue: m['colorValue'] as int? ?? 0xFF0055A5,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
