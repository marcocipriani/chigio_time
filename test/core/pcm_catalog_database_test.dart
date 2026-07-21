import 'dart:convert';
import 'dart:io';

import 'package:chigio_time/core/data/pcm_catalog.dart';
import 'package:chigio_time/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('replacePcmCatalog removes rows missing from the new catalog', () async {
    await database
        .into(database.pcmOfficeLocations)
        .insert(
          PcmOfficeLocationsCompanion.insert(
            id: 'obsolete',
            locationName: 'Sede obsoleta',
            structureName: 'Struttura obsoleta',
            address: 'Via Obsoleta, 1',
            latitude: 41,
            longitude: 12,
            sortOrder: 999,
            updatedAt: 'old',
          ),
        );
    final payload =
        jsonDecode(File('assets/data/pcm_catalog.json').readAsStringSync())
            as Map<String, Object?>;
    final catalog = PcmCatalog.fromMap(payload);

    await database.replacePcmCatalog(catalog);
    final cached = await database.getPcmCatalog();
    final rows = await database.getPcmOfficeLocations();

    expect(cached?.version, catalog.version);
    expect(cached?.structures, hasLength(50));
    expect(rows.any((row) => row.id == 'obsolete'), isFalse);
  });
}
