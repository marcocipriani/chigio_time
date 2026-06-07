import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/pcm_locations.dart';
import '../database/app_database.dart';

class PcmLocationsRepository {
  final AppDatabase? _db;

  const PcmLocationsRepository(this._db);

  Future<List<PcmOfficeOption>> getOfficeLocations() async {
    final db = _db;
    if (db == null) return activePcmOfficeSeeds();

    await db.seedPcmOfficeLocationsIfNeeded();
    final rows = await db.getPcmOfficeLocations();
    return rows
        .where((row) => row.isActive)
        .map(
          (row) => PcmOfficeOption(
            id: row.id,
            locationName: row.locationName,
            structureName: row.structureName,
            address: row.address,
            city: row.city,
            latitude: row.latitude,
            longitude: row.longitude,
            sortOrder: row.sortOrder,
            isActive: row.isActive,
          ),
        )
        .toList(growable: false);
  }
}

final pcmLocationsRepositoryProvider = Provider<PcmLocationsRepository>((ref) {
  return PcmLocationsRepository(ref.watch(appDatabaseProvider));
});

final pcmOfficeLocationsProvider = FutureProvider<List<PcmOfficeOption>>((
  ref,
) async {
  return ref.watch(pcmLocationsRepositoryProvider).getOfficeLocations();
});

final pcmSiteLocationsProvider = FutureProvider<List<PcmSiteOption>>((
  ref,
) async {
  final offices = await ref.watch(pcmOfficeLocationsProvider.future);
  return pcmSitesFromOffices(offices);
});
