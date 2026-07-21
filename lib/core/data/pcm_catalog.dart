class PcmCatalogValidationException implements Exception {
  final String message;

  const PcmCatalogValidationException(this.message);

  @override
  String toString() => 'PcmCatalogValidationException: $message';
}

class PcmCatalog {
  final String version;
  final String source;
  final List<PcmStructureSite> structures;

  const PcmCatalog({
    required this.version,
    required this.source,
    required this.structures,
  });

  factory PcmCatalog.fromMap(Map<String, Object?> map) {
    final rawStructures = map['structures'];
    if (rawStructures is! List) {
      throw const PcmCatalogValidationException(
        'Il campo structures deve essere una lista.',
      );
    }

    final catalog = PcmCatalog(
      version: _requiredString(map, 'version'),
      source: _requiredString(map, 'source'),
      structures: List.unmodifiable(
        rawStructures.map((raw) {
          if (raw is! Map) {
            throw const PcmCatalogValidationException(
              'Ogni struttura deve essere una mappa.',
            );
          }
          return PcmStructureSite.fromMap(Map<String, Object?>.from(raw));
        }),
      ),
    );
    validatePcmCatalog(catalog);
    return catalog;
  }

  Map<String, Object?> toMap() => {
    'version': version,
    'source': source,
    'structures': structures.map((entry) => entry.toMap()).toList(),
  };
}

class PcmStructureSite {
  final String id;
  final String structureName;
  final int sortOrder;
  final String siteId;
  final String siteName;
  final String address;
  final String city;
  final double latitude;
  final double longitude;

  const PcmStructureSite({
    required this.id,
    required this.structureName,
    required this.sortOrder,
    required this.siteId,
    required this.siteName,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  factory PcmStructureSite.fromMap(Map<String, Object?> map) {
    return PcmStructureSite(
      id: _requiredString(map, 'id'),
      structureName: _requiredString(map, 'name'),
      sortOrder: _requiredInt(map, 'sortOrder'),
      siteId: _requiredString(map, 'siteId'),
      siteName: _requiredString(map, 'siteName'),
      address: _requiredString(map, 'address'),
      city: _requiredString(map, 'city'),
      latitude: _requiredDouble(map, 'latitude'),
      longitude: _requiredDouble(map, 'longitude'),
    );
  }

  String get fullAddress => '$address · $city';

  String get displayLabel => pcmSiteLabel(siteName, fullAddress);

  Map<String, Object?> toMap() => {
    'id': id,
    'name': structureName,
    'sortOrder': sortOrder,
    'siteId': siteId,
    'siteName': siteName,
    'address': address,
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
  };
}

class PcmSiteOption {
  final String id;
  final String name;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final int sortOrder;
  final List<String> structures;
  final bool isRecommended;

  const PcmSiteOption({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.sortOrder,
    required this.structures,
    this.isRecommended = false,
  });

  String get mapsQuery => '$address, $city';

  String get fullAddress => '$address · $city';

  String get displayLabel => pcmSiteLabel(name, fullAddress);

  PcmSiteOption withRecommendation(bool value) => PcmSiteOption(
    id: id,
    name: name,
    address: address,
    city: city,
    latitude: latitude,
    longitude: longitude,
    sortOrder: sortOrder,
    structures: structures,
    isRecommended: value,
  );
}

void validatePcmCatalog(PcmCatalog catalog) {
  if (!RegExp(r'^\d{4}\.\d{2}\.\d{2}$').hasMatch(catalog.version)) {
    throw const PcmCatalogValidationException(
      'La versione deve usare il formato YYYY.MM.DD.',
    );
  }
  if (catalog.source.trim().isEmpty) {
    throw const PcmCatalogValidationException('La sorgente è obbligatoria.');
  }
  if (catalog.structures.length != 50) {
    throw PcmCatalogValidationException(
      'Il catalogo deve contenere esattamente 50 strutture, non '
      '${catalog.structures.length}.',
    );
  }

  final ids = <String>{};
  final names = <String>{};
  final sortOrders = <int>{};
  final siteDefinitions = <String, String>{};
  final slug = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
  final city = RegExp(r'^\d{5} Roma$');

  for (final entry in catalog.structures) {
    if (!slug.hasMatch(entry.id) || !slug.hasMatch(entry.siteId)) {
      throw PcmCatalogValidationException(
        'ID non valido per ${entry.structureName}.',
      );
    }
    if (!ids.add(entry.id)) {
      throw PcmCatalogValidationException(
        'ID struttura duplicato: ${entry.id}.',
      );
    }
    if (!names.add(entry.structureName)) {
      throw PcmCatalogValidationException(
        'Nome struttura duplicato: ${entry.structureName}.',
      );
    }
    if (!sortOrders.add(entry.sortOrder)) {
      throw PcmCatalogValidationException(
        'Ordinamento duplicato: ${entry.sortOrder}.',
      );
    }
    if (!city.hasMatch(entry.city)) {
      throw PcmCatalogValidationException(
        'CAP/città non valido per ${entry.structureName}.',
      );
    }
    if (entry.latitude < -90 || entry.latitude > 90) {
      throw PcmCatalogValidationException(
        'Latitudine non valida per ${entry.structureName}.',
      );
    }
    if (entry.longitude < -180 || entry.longitude > 180) {
      throw PcmCatalogValidationException(
        'Longitudine non valida per ${entry.structureName}.',
      );
    }

    final definition = [
      entry.siteName,
      entry.address,
      entry.city,
      entry.latitude,
      entry.longitude,
    ].join('|');
    final existing = siteDefinitions[entry.siteId];
    if (existing != null && existing != definition) {
      throw PcmCatalogValidationException(
        'Definizione incoerente per la sede ${entry.siteId}.',
      );
    }
    siteDefinitions[entry.siteId] = definition;
  }
}

List<PcmSiteOption> pcmSitesFromStructures(List<PcmStructureSite> structures) {
  final grouped = <String, ({PcmStructureSite first, List<String> names})>{};
  final ordered = [...structures]
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  for (final entry in ordered) {
    final existing = grouped[entry.siteId];
    if (existing == null) {
      grouped[entry.siteId] = (first: entry, names: [entry.structureName]);
    } else {
      existing.names.add(entry.structureName);
    }
  }

  return grouped.values
      .map(
        (entry) => PcmSiteOption(
          id: entry.first.siteId,
          name: entry.first.siteName,
          address: entry.first.address,
          city: entry.first.city,
          latitude: entry.first.latitude,
          longitude: entry.first.longitude,
          sortOrder: entry.first.sortOrder,
          structures: List.unmodifiable(entry.names),
        ),
      )
      .toList(growable: false);
}

String? recommendedSiteIdForStructure(
  String? structureName,
  List<PcmStructureSite> structures,
) {
  if (structureName == null || structureName.isEmpty) return null;
  for (final entry in structures) {
    if (entry.structureName == structureName) return entry.siteId;
  }
  return null;
}

List<PcmSiteOption> sortedSitesForStructure(
  String? structureName,
  List<PcmStructureSite> structures,
) {
  final recommendedId = recommendedSiteIdForStructure(
    structureName,
    structures,
  );
  final sites = pcmSitesFromStructures(structures);
  if (recommendedId == null) return sites;

  return [
    ...sites
        .where((site) => site.id == recommendedId)
        .map((site) => site.withRecommendation(true)),
    ...sites.where((site) => site.id != recommendedId),
  ];
}

String pcmSiteLabel(String site, String fullAddress) {
  if (fullAddress.isEmpty) return site;
  if (site.isEmpty || fullAddress.startsWith(site)) return fullAddress;
  return '$site — $fullAddress';
}

String _requiredString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.trim().isEmpty) {
    throw PcmCatalogValidationException('$key deve essere una stringa.');
  }
  return value.trim();
}

int _requiredInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) {
    throw PcmCatalogValidationException('$key deve essere un intero.');
  }
  return value;
}

double _requiredDouble(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! num) {
    throw PcmCatalogValidationException('$key deve essere un numero.');
  }
  return value.toDouble();
}
