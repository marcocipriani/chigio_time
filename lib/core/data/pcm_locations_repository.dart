import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/pcm_locations.dart' as legacy;
import '../database/app_database.dart';
import 'pcm_catalog.dart';

typedef RemoteCatalogLoader = Future<Map<String, Object?>?> Function();
typedef CacheCatalogLoader = Future<PcmCatalog?> Function();
typedef CacheCatalogWriter = Future<void> Function(PcmCatalog catalog);
typedef BundledCatalogLoader = Future<String> Function();

enum PcmCatalogSource { remote, cache, bundled }

class PcmCatalogLoadResult {
  final PcmCatalog catalog;
  final PcmCatalogSource source;

  const PcmCatalogLoadResult({required this.catalog, required this.source});
}

class PcmCatalogUnavailableException implements Exception {
  final String message;

  const PcmCatalogUnavailableException(this.message);

  @override
  String toString() => 'PcmCatalogUnavailableException: $message';
}

class PcmCatalogRepository {
  final RemoteCatalogLoader loadRemote;
  final CacheCatalogLoader loadCache;
  final CacheCatalogWriter replaceCache;
  final BundledCatalogLoader loadBundled;

  const PcmCatalogRepository({
    required this.loadRemote,
    required this.loadCache,
    required this.replaceCache,
    required this.loadBundled,
  });

  Future<PcmCatalogLoadResult> load() async {
    try {
      final remotePayload = await loadRemote();
      if (remotePayload != null) {
        final remote = PcmCatalog.fromMap(remotePayload);
        try {
          await replaceCache(remote);
        } catch (_) {
          // A cache unavailable must not hide a valid remote catalog.
        }
        _log(PcmCatalogSource.remote, remote.version);
        return PcmCatalogLoadResult(
          catalog: remote,
          source: PcmCatalogSource.remote,
        );
      }
    } catch (_) {
      // Remote unavailable or malformed: keep the last valid local catalog.
    }

    try {
      final cached = await loadCache();
      if (cached != null) {
        validatePcmCatalog(cached);
        _log(PcmCatalogSource.cache, cached.version);
        return PcmCatalogLoadResult(
          catalog: cached,
          source: PcmCatalogSource.cache,
        );
      }
    } catch (_) {
      // Drift can be unavailable on Web; continue with the bundled catalog.
    }

    try {
      final raw = jsonDecode(await loadBundled());
      if (raw is! Map) {
        throw const PcmCatalogValidationException(
          'Il payload bundled deve essere una mappa.',
        );
      }
      final bundled = PcmCatalog.fromMap(Map<String, Object?>.from(raw));
      _log(PcmCatalogSource.bundled, bundled.version);
      return PcmCatalogLoadResult(
        catalog: bundled,
        source: PcmCatalogSource.bundled,
      );
    } catch (_) {
      throw const PcmCatalogUnavailableException(
        'Catalogo Dipartimento/Struttura non disponibile.',
      );
    }
  }

  void _log(PcmCatalogSource source, String version) {
    debugPrint('PCM catalog: ${source.name} $version');
  }
}

final pcmCatalogRepositoryProvider = Provider<PcmCatalogRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return PcmCatalogRepository(
    loadRemote: () async {
      final snapshot = await FirebaseFirestore.instance
          .doc('referenceData/pcmCatalog')
          .get();
      final data = snapshot.data();
      return data == null ? null : Map<String, Object?>.from(data);
    },
    loadCache: () async => database?.getPcmCatalog(),
    replaceCache: (catalog) async {
      await database?.replacePcmCatalog(catalog);
    },
    loadBundled: () => rootBundle.loadString('assets/data/pcm_catalog.json'),
  );
});

final pcmCatalogLoadProvider = FutureProvider<PcmCatalogLoadResult>((ref) {
  return ref.watch(pcmCatalogRepositoryProvider).load();
});

final pcmCatalogProvider = FutureProvider<PcmCatalog>((ref) async {
  return (await ref.watch(pcmCatalogLoadProvider.future)).catalog;
});

// Compatibility adapters kept until all screens use PcmCatalog directly.
final pcmOfficeLocationsProvider = FutureProvider<List<legacy.PcmOfficeOption>>(
  (ref) async {
    final catalog = await ref.watch(pcmCatalogProvider.future);
    return catalog.structures
        .map(
          (entry) => legacy.PcmOfficeOption(
            id: entry.id,
            locationName: entry.siteName,
            structureName: entry.structureName,
            address: entry.address,
            city: entry.city,
            latitude: entry.latitude,
            longitude: entry.longitude,
            sortOrder: entry.sortOrder,
          ),
        )
        .toList(growable: false);
  },
);

final pcmSiteLocationsProvider = FutureProvider<List<legacy.PcmSiteOption>>((
  ref,
) async {
  final catalog = await ref.watch(pcmCatalogProvider.future);
  return pcmSitesFromStructures(catalog.structures)
      .map(
        (site) => legacy.PcmSiteOption(
          id: site.id,
          name: site.name,
          address: site.address,
          city: site.city,
          latitude: site.latitude,
          longitude: site.longitude,
          sortOrder: site.sortOrder,
          structures: site.structures,
        ),
      )
      .toList(growable: false);
});
