import 'package:cloud_firestore/cloud_firestore.dart';

/// One month of SAU (Straordinario Autorizzato mensile = SLI + SBO) data.
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
  // Tolerant: a malformed monthId (out-of-band write) must not throw.
  int get year =>
      int.tryParse(monthId.split('-').elementAtOrNull(0) ?? '') ?? 0;
  int get month =>
      int.tryParse(monthId.split('-').elementAtOrNull(1) ?? '') ?? 0;

  factory MonthlySau.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? const {};
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
