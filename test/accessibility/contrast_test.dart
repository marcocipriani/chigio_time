import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/app/theme/color_schemes.dart';

/// Rapporto di contrasto WCAG fra due colori.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('Accessibilità — contrasto colori (WCAG)', () {
    test('testo body neutral900 su bianco ≥ 7:1 (AAA)', () {
      expect(
        _contrast(AppColors.neutral900, AppColors.white),
        greaterThanOrEqualTo(7.0),
      );
    });

    test('testo bianco su colori di azione ≥ 4.5:1 (AA)', () {
      for (final bg in [
        AppColors.blue600,
        AppColors.green600,
        AppColors.red700,
      ]) {
        expect(
          _contrast(AppColors.white, bg),
          greaterThanOrEqualTo(4.5),
          reason: 'Contrasto basso su $bg',
        );
      }
    });

    test('testo bianco su base Aurora ≥ 7:1 (AAA)', () {
      expect(
        _contrast(AppColors.white, const Color(0xFF0A1226)),
        greaterThanOrEqualTo(7.0),
      );
    });
  });
}
