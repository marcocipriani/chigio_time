import 'package:cloud_firestore/cloud_firestore.dart';

/// One month of SAU (Straordinari Autorizzati Ulteriori) data.
/// Stored at users/{uid}/sau_monthly/{YYYY-MM}.
class MonthlySau {
  final String monthId; // 'YYYY-MM'
  final int sliHours;
  final int sboHours;
  final String? note;
  final DateTime? recordedAt;

  const MonthlySau({
    required this.monthId,
    required this.sliHours,
    required this.sboHours,
    this.note,
    this.recordedAt,
  });

  int get sauHours => sliHours + sboHours;
  int get year => int.parse(monthId.substring(0, 4));
  int get month => int.parse(monthId.substring(5, 7));

  factory MonthlySau.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MonthlySau(
      monthId: doc.id,
      sliHours: (d['sliHours'] as num?)?.toInt() ?? 0,
      sboHours: (d['sboHours'] as num?)?.toInt() ?? 0,
      note: d['note'] as String?,
      recordedAt: (d['recordedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'sliHours': sliHours,
    'sboHours': sboHours,
    'sauHours': sauHours,
    if (note != null) 'note': note,
    'recordedAt': FieldValue.serverTimestamp(),
  };
}
