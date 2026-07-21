import 'dart:convert';
import 'dart:io';

import 'package:chigio_time/core/data/pcm_catalog.dart';
import 'package:chigio_time/core/data/pcm_locations_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late String bundledJson;
  late Map<String, Object?> payload;
  late PcmCatalog cachedCatalog;

  setUpAll(() {
    bundledJson = File('assets/data/pcm_catalog.json').readAsStringSync();
    payload = jsonDecode(bundledJson) as Map<String, Object?>;
    cachedCatalog = PcmCatalog.fromMap(payload);
  });

  test('valid remote wins and replaces the cache', () async {
    PcmCatalog? written;
    final repository = PcmCatalogRepository(
      loadRemote: () async => payload,
      loadCache: () async => null,
      replaceCache: (catalog) async => written = catalog,
      loadBundled: () async => bundledJson,
    );

    final result = await repository.load();

    expect(result.source, PcmCatalogSource.remote);
    expect(result.catalog.structures, hasLength(50));
    expect(written?.version, '2026.07.20');
  });

  test('malformed remote is rejected before replacing a valid cache', () async {
    final malformed = _copyPayload(payload);
    (malformed['structures']! as List<Object?>).removeLast();
    var cacheWrites = 0;
    final repository = PcmCatalogRepository(
      loadRemote: () async => malformed,
      loadCache: () async => cachedCatalog,
      replaceCache: (_) async => cacheWrites++,
      loadBundled: () async => bundledJson,
    );

    final result = await repository.load();

    expect(result.source, PcmCatalogSource.cache);
    expect(result.catalog, same(cachedCatalog));
    expect(cacheWrites, 0);
  });

  test('remote failure falls back to a valid cache', () async {
    final repository = PcmCatalogRepository(
      loadRemote: () async => throw StateError('offline'),
      loadCache: () async => cachedCatalog,
      replaceCache: (_) async {},
      loadBundled: () async => bundledJson,
    );

    final result = await repository.load();

    expect(result.source, PcmCatalogSource.cache);
  });

  test('empty cache falls back to the bundled payload', () async {
    final repository = PcmCatalogRepository(
      loadRemote: () async => null,
      loadCache: () async => null,
      replaceCache: (_) async {},
      loadBundled: () async => bundledJson,
    );

    final result = await repository.load();

    expect(result.source, PcmCatalogSource.bundled);
    expect(result.catalog.version, '2026.07.20');
  });

  test('all invalid sources expose a catalog unavailable error', () async {
    final malformed = jsonEncode({...payload, 'structures': const []});
    final repository = PcmCatalogRepository(
      loadRemote: () async => null,
      loadCache: () async => null,
      replaceCache: (_) async {},
      loadBundled: () async => malformed,
    );

    expect(repository.load, throwsA(isA<PcmCatalogUnavailableException>()));
  });
}

Map<String, Object?> _copyPayload(Map<String, Object?> source) {
  return jsonDecode(jsonEncode(source)) as Map<String, Object?>;
}
