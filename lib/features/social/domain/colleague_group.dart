import 'package:cloud_firestore/cloud_firestore.dart';

class ColleagueGroup {
  final String id;
  final String name;
  final List<String> memberUids;
  final DateTime createdAt;

  const ColleagueGroup({
    required this.id,
    required this.name,
    required this.memberUids,
    required this.createdAt,
  });

  factory ColleagueGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ColleagueGroup(
      id: doc.id,
      name: data['name'] as String? ?? '',
      memberUids: List<String>.from(data['memberUids'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'memberUids': memberUids,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
