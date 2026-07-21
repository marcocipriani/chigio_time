import 'dart:convert';
import 'dart:io';

import 'package:chigio_time/core/data/pcm_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, Object?> payload;

  setUpAll(() {
    payload =
        jsonDecode(File('assets/data/pcm_catalog.json').readAsStringSync())
            as Map<String, Object?>;
  });

  group('PcmCatalog', () {
    test('parses the canonical payload with exactly 50 structures', () {
      final catalog = PcmCatalog.fromMap(payload);

      expect(catalog.version, '2026.07.20');
      expect(catalog.structures, hasLength(50));
      expect(
        catalog.structures.map((entry) => entry.id).toSet(),
        hasLength(50),
      );
      expect(
        catalog.structures.map((entry) => entry.structureName).toSet(),
        hasLength(50),
      );
    });

    test('contains valid CAP and WGS84 coordinates', () {
      final catalog = PcmCatalog.fromMap(payload);
      final cap = RegExp(r'^\d{5} Roma$');

      for (final entry in catalog.structures) {
        expect(cap.hasMatch(entry.city), isTrue, reason: entry.structureName);
        expect(entry.latitude, inInclusiveRange(-90, 90));
        expect(entry.longitude, inInclusiveRange(-180, 180));
      }
    });

    test('aggregates the 12 physical sites without losing structures', () {
      final catalog = PcmCatalog.fromMap(payload);
      final sites = pcmSitesFromStructures(catalog.structures);

      expect(sites, hasLength(12));
      expect(
        sites.expand((site) => site.structures).toSet(),
        catalog.structures.map((entry) => entry.structureName).toSet(),
      );
    });

    test('sorts the exact recommended site first without selecting it', () {
      final catalog = PcmCatalog.fromMap(payload);
      const structure = 'Dipartimento per le politiche antidroga';
      final sites = sortedSitesForStructure(structure, catalog.structures);

      expect(
        recommendedSiteIdForStructure(structure, catalog.structures),
        'via-dei-laterani-34',
      );
      expect(sites.first.id, 'via-dei-laterani-34');
      expect(sites.where((site) => site.isRecommended), hasLength(1));
    });

    test('rejects duplicate structure ids atomically', () {
      final broken = _copyPayload(payload);
      final structures = broken['structures']! as List<Object?>;
      final first = structures.first! as Map<String, Object?>;
      final second = structures[1]! as Map<String, Object?>;
      second['id'] = first['id'];

      expect(
        () => PcmCatalog.fromMap(broken),
        throwsA(isA<PcmCatalogValidationException>()),
      );
    });

    test('rejects incomplete catalogs and invalid coordinates', () {
      final incomplete = _copyPayload(payload);
      (incomplete['structures']! as List<Object?>).removeLast();
      final invalidCoordinates = _copyPayload(payload);
      ((invalidCoordinates['structures']! as List<Object?>).first!
              as Map<String, Object?>)['latitude'] =
          120;

      expect(
        () => PcmCatalog.fromMap(incomplete),
        throwsA(isA<PcmCatalogValidationException>()),
      );
      expect(
        () => PcmCatalog.fromMap(invalidCoordinates),
        throwsA(isA<PcmCatalogValidationException>()),
      );
    });

    test('rejects malformed versions', () {
      final broken = _copyPayload(payload)..['version'] = 'latest';

      expect(
        () => PcmCatalog.fromMap(broken),
        throwsA(isA<PcmCatalogValidationException>()),
      );
    });
  });

  group('pcmSiteLabel', () {
    test('does not repeat the address when it is also the site name', () {
      expect(
        pcmSiteLabel(
          'Via della Mercede, 9',
          'Via della Mercede, 9 · 00187 Roma',
        ),
        'Via della Mercede, 9 · 00187 Roma',
      );
      expect(
        pcmSiteLabel('Palazzo Chigi', 'Piazza Colonna, 370 · 00187 Roma'),
        'Palazzo Chigi — Piazza Colonna, 370 · 00187 Roma',
      );
    });
  });
}

Map<String, Object?> _copyPayload(Map<String, Object?> source) {
  return jsonDecode(jsonEncode(source)) as Map<String, Object?>;
}
