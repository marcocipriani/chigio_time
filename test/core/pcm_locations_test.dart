import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/core/constants/pcm_locations.dart';

void main() {
  group('pcm_locations — dati sedi (B4)', () {
    test('ogni sede ha un CAP nel campo city', () {
      final cap = RegExp(r'\d{5}');
      for (final o in pcmOfficeSeeds) {
        expect(
          cap.hasMatch(o.city),
          isTrue,
          reason: 'Manca il CAP per "${o.locationName}" (city="${o.city}")',
        );
      }
    });

    test('fullAddress = "address · city"', () {
      const o = PcmOfficeOption(
        id: 'x',
        locationName: 'Palazzo Test',
        structureName: 'Dip. Test',
        address: 'Via Roma, 1',
        city: '00187 Roma',
        latitude: 0,
        longitude: 0,
        sortOrder: 0,
      );
      expect(o.fullAddress, 'Via Roma, 1 · 00187 Roma');
      // nome diverso dalla via → "Nome — indirizzo"
      expect(o.displayLabel, 'Palazzo Test — Via Roma, 1 · 00187 Roma');
    });

    test('displayLabel evita la ripetizione quando nome == via', () {
      const o = PcmOfficeOption(
        id: 'y',
        locationName: 'Via della Mercede, 9',
        structureName: 'Dip. Y',
        address: 'Via della Mercede, 9',
        city: '00187 Roma',
        latitude: 0,
        longitude: 0,
        sortOrder: 0,
      );
      expect(o.displayLabel, 'Via della Mercede, 9 · 00187 Roma');
      expect(o.displayLabel.contains('—'), isFalse);
    });

    test('pcmSedeLabel deduplica nome/indirizzo', () {
      expect(
        pcmSedeLabel(
          'Via della Mercede, 9',
          'Via della Mercede, 9 · 00187 Roma',
        ),
        'Via della Mercede, 9 · 00187 Roma',
      );
      expect(
        pcmSedeLabel('Palazzo Chigi', 'Piazza Colonna, 370 · 00187 Roma'),
        'Palazzo Chigi — Piazza Colonna, 370 · 00187 Roma',
      );
    });
  });
}
