import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/features/salary/domain/salary_payment.dart';

void main() {
  group('SalaryPaymentType', () {
    test('id stabili (== name)', () {
      expect(SalaryPaymentType.ordinaria.id, 'ordinaria');
      expect(SalaryPaymentType.straordinaria.id, 'straordinaria');
      expect(SalaryPaymentType.buoniPasto.id, 'buoniPasto');
      expect(SalaryPaymentType.altro.id, 'altro');
    });

    test('fromId con fallback a ordinaria', () {
      expect(
        SalaryPaymentType.fromId('buoniPasto'),
        SalaryPaymentType.buoniPasto,
      );
      expect(SalaryPaymentType.fromId(null), SalaryPaymentType.ordinaria);
      expect(SalaryPaymentType.fromId('bogus'), SalaryPaymentType.ordinaria);
    });
  });

  group('SalaryPayment', () {
    test('fromMap + getter di raggruppamento', () {
      final p = SalaryPayment.fromMap('id1', {
        'date': '2026-06-23',
        'type': 'ordinaria',
        'grossAmount': 2500,
        'netAmount': 1800,
        'manual': true,
      });
      expect(p.dateId, '2026-06-23');
      expect(p.monthId, '2026-06');
      expect(p.year, 2026);
      expect(p.type, SalaryPaymentType.ordinaria);
      expect(p.netAmount, 1800);
    });
  });
}
