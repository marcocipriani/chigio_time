import '../../../core/constants/app_strings.dart';

/// Tipo di emissione di un accredito stipendiale.
///
/// Gli `id` sono stabili e usati come valore Firestore — non rinominarli.
enum SalaryPaymentType {
  ordinaria,
  straordinaria,
  buoniPasto,
  altro;

  /// Stable Firestore id for this type.
  String get id => name;

  /// Localised label shown in UI.
  String get label => switch (this) {
    SalaryPaymentType.ordinaria => AppStrings.salaryTypeOrdinaria,
    SalaryPaymentType.straordinaria => AppStrings.salaryTypeStraordinaria,
    SalaryPaymentType.buoniPasto => AppStrings.salaryTypeBuoniPasto,
    SalaryPaymentType.altro => AppStrings.salaryTypeAltro,
  };

  static SalaryPaymentType fromId(String? id) => SalaryPaymentType.values
      .firstWhere((t) => t.id == id, orElse: () => SalaryPaymentType.ordinaria);
}

/// A single salary credit (cedolino) received by the user.
///
/// Stored under `users/{uid}/salaryPayments/{id}`. The accredito date is
/// encoded as a `YYYY-MM-DD` string so it sorts lexicographically (same
/// convention as `timesheets/{dateId}`). Amounts are euros (Firestore `num`).
class SalaryPayment {
  final String id;

  /// Accredito date (date-only; time component is ignored).
  final DateTime date;

  final SalaryPaymentType type;

  /// Lordo da cedolino. `0` when unknown / not entered.
  final double grossAmount;

  /// Netto accreditato sul conto.
  final double netAmount;

  /// Optional free-text note added by the user.
  final String? note;

  /// True when the user added this entry by hand (vs. a future import).
  final bool manual;

  final DateTime? createdAt;

  const SalaryPayment({
    required this.id,
    required this.date,
    required this.type,
    required this.grossAmount,
    required this.netAmount,
    this.note,
    this.manual = true,
    this.createdAt,
  });

  /// `YYYY-MM` of the accredito, used to group payments by month.
  String get monthId =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  /// `YYYY-MM-DD` of the accredito (Firestore field / sort key).
  String get dateId =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  int get year => date.year;

  factory SalaryPayment.fromMap(String id, Map<String, dynamic> m) {
    final raw = m['date'] as String? ?? '';
    final parsed = DateTime.tryParse(raw) ?? DateTime.now();
    final created = m['createdAt'];
    return SalaryPayment(
      id: id,
      date: DateTime(parsed.year, parsed.month, parsed.day),
      type: SalaryPaymentType.fromId(m['type'] as String?),
      grossAmount: (m['grossAmount'] as num?)?.toDouble() ?? 0,
      netAmount: (m['netAmount'] as num?)?.toDouble() ?? 0,
      note: (m['note'] as String?)?.trim().isEmpty ?? true
          ? null
          : (m['note'] as String).trim(),
      manual: m['manual'] as bool? ?? true,
      createdAt: created is DateTime ? created : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'date': dateId,
    'type': type.id,
    'grossAmount': grossAmount,
    'netAmount': netAmount,
    if (note != null && note!.isNotEmpty) 'note': note,
    'manual': manual,
  };

  SalaryPayment copyWith({
    DateTime? date,
    SalaryPaymentType? type,
    double? grossAmount,
    double? netAmount,
    String? note,
  }) => SalaryPayment(
    id: id,
    date: date ?? this.date,
    type: type ?? this.type,
    grossAmount: grossAmount ?? this.grossAmount,
    netAmount: netAmount ?? this.netAmount,
    note: note ?? this.note,
    manual: manual,
    createdAt: createdAt,
  );
}
