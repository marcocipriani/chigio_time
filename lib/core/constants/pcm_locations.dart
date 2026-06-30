class PcmOfficeOption {
  final String id;
  final String locationName;
  final String structureName;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final int sortOrder;
  final bool isActive;

  const PcmOfficeOption({
    required this.id,
    required this.locationName,
    required this.structureName,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.sortOrder,
    this.isActive = true,
  });

  /// Indirizzo completo con CAP, es. "Via della Mercede, 9 · 00187 Roma".
  String get fullAddress => '$address · $city';

  /// Etichetta senza ripetizioni: se il nome coincide con la via mostra solo
  /// l'indirizzo, altrimenti "Nome — indirizzo".
  String get displayLabel =>
      locationName == address ? fullAddress : '$locationName — $fullAddress';
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

  const PcmSiteOption({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.sortOrder,
    required this.structures,
  });

  String get mapsQuery => '$address, $city';

  String get fullAddress => '$address · $city';

  String get displayLabel =>
      name == address ? fullAddress : '$name — $fullAddress';
}

/// Etichetta sede deduplicata per la UI, da nome + indirizzo completo (con CAP)
/// già salvato. Evita "Via X — Via X" quando nome e via coincidono.
String pcmSedeLabel(String sede, String fullAddress) {
  if (fullAddress.isEmpty) return sede;
  if (sede.isEmpty || fullAddress.startsWith(sede)) return fullAddress;
  return '$sede — $fullAddress';
}

List<PcmOfficeOption> activePcmOfficeSeeds() =>
    pcmOfficeSeeds.where((office) => office.isActive).toList(growable: false);

List<PcmSiteOption> pcmSitesFromOffices(List<PcmOfficeOption> offices) {
  final grouped =
      <String, ({PcmOfficeOption first, List<String> structures})>{};
  final activeOffices = offices.where((office) => office.isActive).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  for (final office in activeOffices) {
    final key = '${office.locationName}|${office.address}';
    final existing = grouped[key];
    if (existing == null) {
      grouped[key] = (first: office, structures: [office.structureName]);
    } else if (!existing.structures.contains(office.structureName)) {
      existing.structures.add(office.structureName);
    }
  }

  return grouped.values
      .map((entry) {
        final office = entry.first;
        return PcmSiteOption(
          id: office.id,
          name: office.locationName,
          address: office.address,
          city: office.city,
          latitude: office.latitude,
          longitude: office.longitude,
          sortOrder: office.sortOrder,
          structures: List.unmodifiable(entry.structures),
        );
      })
      .toList(growable: false);
}

const pcmOfficeSeeds = <PcmOfficeOption>[
  PcmOfficeOption(
    id: 'dfp-palazzo-vidoni',
    locationName: 'Palazzo Vidoni',
    structureName: 'Dipartimento della funzione pubblica',
    address: 'Corso Vittorio Emanuele II, 116',
    city: '00186 Roma',
    latitude: 41.8959,
    longitude: 12.4749,
    sortOrder: 10,
  ),
  PcmOfficeOption(
    id: 'casa-italia-ferratella',
    locationName: 'Ferratella',
    structureName: 'Dipartimento Casa Italia',
    address: 'Via della Ferratella in Laterano, 51',
    city: '00184 Roma',
    latitude: 41.8837,
    longitude: 12.5023,
    sortOrder: 20,
  ),
  PcmOfficeOption(
    id: 'droga-dipendenze-ferratella',
    locationName: 'Ferratella',
    structureName:
        'Dipartimento delle politiche contro la droga e le altre dipendenze',
    address: 'Via della Ferratella in Laterano, 51',
    city: '00184 Roma',
    latitude: 41.8837,
    longitude: 12.5023,
    sortOrder: 21,
  ),
  PcmOfficeOption(
    id: 'giovani-scu-ferratella',
    locationName: 'Ferratella',
    structureName:
        'Dipartimento per le politiche giovanili e il Servizio civile universale',
    address: 'Via della Ferratella in Laterano, 51',
    city: '00184 Roma',
    latitude: 41.8837,
    longitude: 12.5023,
    sortOrder: 22,
  ),
  PcmOfficeOption(
    id: 'dtd-brazza',
    locationName: 'Largo Pietro di Brazzà',
    structureName: 'Dipartimento per la trasformazione digitale',
    address: 'Largo Pietro di Brazzà, 86',
    city: '00187 Roma',
    latitude: 41.9000,
    longitude: 12.4836,
    sortOrder: 30,
  ),
  PcmOfficeOption(
    id: 'affari-europei-largo-chigi',
    locationName: 'Largo Chigi',
    structureName: 'Dipartimento per gli affari europei',
    address: 'Largo Chigi, 19',
    city: '00187 Roma',
    latitude: 41.9020,
    longitude: 12.4808,
    sortOrder: 40,
  ),
  PcmOfficeOption(
    id: 'pari-opportunita-largo-chigi',
    locationName: 'Largo Chigi',
    structureName: 'Dipartimento per le pari opportunità',
    address: 'Largo Chigi, 19',
    city: '00187 Roma',
    latitude: 41.9020,
    longitude: 12.4808,
    sortOrder: 41,
  ),
  PcmOfficeOption(
    id: 'riforme-istituzionali-largo-chigi',
    locationName: 'Largo Chigi',
    structureName: 'Dipartimento per le riforme istituzionali',
    address: 'Largo Chigi, 19',
    city: '00187 Roma',
    latitude: 41.9020,
    longitude: 12.4808,
    sortOrder: 42,
  ),
  PcmOfficeOption(
    id: 'rapporti-parlamento-largo-chigi',
    locationName: 'Largo Chigi',
    structureName: 'Dipartimento per i rapporti con il Parlamento',
    address: 'Largo Chigi, 19',
    city: '00187 Roma',
    latitude: 41.9020,
    longitude: 12.4808,
    sortOrder: 43,
  ),
  PcmOfficeOption(
    id: 'missione-pnrr-largo-chigi',
    locationName: 'Largo Chigi',
    structureName: 'Struttura di missione PNRR',
    address: 'Largo Chigi, 19',
    city: '00187 Roma',
    latitude: 41.9020,
    longitude: 12.4808,
    sortOrder: 44,
  ),
  PcmOfficeOption(
    id: 'dica-mercede-9',
    locationName: 'Via della Mercede, 9',
    structureName: 'Dipartimento per il coordinamento amministrativo',
    address: 'Via della Mercede, 9',
    city: '00187 Roma',
    latitude: 41.9022,
    longitude: 12.4818,
    sortOrder: 50,
  ),
  PcmOfficeOption(
    id: 'die-mercede-9',
    locationName: 'Via della Mercede, 9',
    structureName: "Dipartimento per l'informazione e l'editoria",
    address: 'Via della Mercede, 9',
    city: '00187 Roma',
    latitude: 41.9022,
    longitude: 12.4818,
    sortOrder: 51,
  ),
  PcmOfficeOption(
    id: 'personale-mercede-96',
    locationName: 'Via della Mercede, 96',
    structureName: 'Dipartimento per il personale',
    address: 'Via della Mercede, 96',
    city: '00187 Roma',
    latitude: 41.9031,
    longitude: 12.4845,
    sortOrder: 60,
  ),
  PcmOfficeOption(
    id: 'programma-governo-mercede-96',
    locationName: 'Via della Mercede, 96',
    structureName: 'Dipartimento per il programma di Governo',
    address: 'Via della Mercede, 96',
    city: '00187 Roma',
    latitude: 41.9031,
    longitude: 12.4845,
    sortOrder: 61,
  ),
  PcmOfficeOption(
    id: 'servizi-strumentali-mercede-96',
    locationName: 'Via della Mercede, 96',
    structureName: 'Dipartimento per i servizi strumentali',
    address: 'Via della Mercede, 96',
    city: '00187 Roma',
    latitude: 41.9031,
    longitude: 12.4845,
    sortOrder: 62,
  ),
  PcmOfficeOption(
    id: 'ubbrac-mercede-96',
    locationName: 'Via della Mercede, 96',
    structureName:
        'Ufficio del bilancio e per il riscontro di regolarità amministrativo-contabile',
    address: 'Via della Mercede, 96',
    city: '00187 Roma',
    latitude: 41.9031,
    longitude: 12.4845,
    sortOrder: 63,
  ),
  PcmOfficeOption(
    id: 'uci-mercede-96',
    locationName: 'Via della Mercede, 96',
    structureName:
        "Ufficio del controllo interno, la trasparenza e l'integrità",
    address: 'Via della Mercede, 96',
    city: '00187 Roma',
    latitude: 41.9031,
    longitude: 12.4845,
    sortOrder: 64,
  ),
  PcmOfficeOption(
    id: 'dagl-palazzo-chigi',
    locationName: 'Palazzo Chigi',
    structureName: 'Dipartimento per gli affari giuridici e legislativi',
    address: 'Piazza Colonna, 370',
    city: '00187 Roma',
    latitude: 41.9009,
    longitude: 12.4798,
    sortOrder: 70,
  ),
  PcmOfficeOption(
    id: 'cerimoniale-palazzo-chigi',
    locationName: 'Palazzo Chigi',
    structureName: 'Ufficio del cerimoniale di Stato e per le onorificenze',
    address: 'Piazza Colonna, 370',
    city: '00187 Roma',
    latitude: 41.9009,
    longitude: 12.4798,
    sortOrder: 71,
  ),
  PcmOfficeOption(
    id: 'segreteria-cdm-palazzo-chigi',
    locationName: 'Palazzo Chigi',
    structureName: 'Ufficio di segreteria del Consiglio dei Ministri',
    address: 'Piazza Colonna, 370',
    city: '00187 Roma',
    latitude: 41.9009,
    longitude: 12.4798,
    sortOrder: 72,
  ),
  PcmOfficeOption(
    id: 'segretario-generale-chigi-mercede-96',
    locationName: 'Palazzo Chigi / Via della Mercede, 96',
    structureName: 'Ufficio del Segretario generale',
    address: 'Piazza Colonna, 370 / Via della Mercede, 96',
    city: '00187 Roma',
    latitude: 41.9020,
    longitude: 12.4822,
    sortOrder: 73,
  ),
  PcmOfficeOption(
    id: 'disabilita-panetteria',
    locationName: 'Via della Panetteria, 18/A',
    structureName:
        'Dipartimento per le politiche in favore delle persone con disabilità',
    address: 'Via della Panetteria, 18/A',
    city: '00187 Roma',
    latitude: 41.9008,
    longitude: 12.4833,
    sortOrder: 80,
  ),
  PcmOfficeOption(
    id: 'sna-roma',
    locationName: 'SNA Roma',
    structureName: "Scuola Nazionale dell'Amministrazione",
    address: 'Via dei Robilant, 11',
    city: '00194 Roma',
    latitude: 41.9346,
    longitude: 12.4563,
    sortOrder: 90,
  ),
  PcmOfficeOption(
    id: 'sna-caserta',
    locationName: 'SNA Caserta',
    structureName: "Scuola Nazionale dell'Amministrazione",
    address: 'Reggia di Caserta',
    city: '81100 Caserta',
    latitude: 41.0732,
    longitude: 14.3276,
    sortOrder: 91,
  ),
  PcmOfficeOption(
    id: 'daras-stamperia',
    locationName: 'Via della Stamperia, 8',
    structureName: 'Dipartimento per gli affari regionali e le autonomie',
    address: 'Via della Stamperia, 8',
    city: '00187 Roma',
    latitude: 41.9011,
    longitude: 12.4847,
    sortOrder: 100,
  ),
  PcmOfficeOption(
    id: 'conferenza-stato-citta-stamperia',
    locationName: 'Via della Stamperia, 8',
    structureName:
        'Ufficio di segreteria della Conferenza Stato-città ed autonomie locali',
    address: 'Via della Stamperia, 8',
    city: '00187 Roma',
    latitude: 41.9011,
    longitude: 12.4847,
    sortOrder: 101,
  ),
  PcmOfficeOption(
    id: 'famiglia-iv-novembre',
    locationName: 'Via IV Novembre, 144',
    structureName: 'Dipartimento per le politiche della famiglia',
    address: 'Via IV Novembre, 144',
    city: '00187 Roma',
    latitude: 41.8975,
    longitude: 12.4852,
    sortOrder: 110,
  ),
  PcmOfficeOption(
    id: 'dipe-mercede-9',
    locationName: 'Via della Mercede, 9',
    structureName:
        'Dipartimento per la programmazione e il coordinamento della politica economica',
    address: 'Via della Mercede, 9',
    city: '00187 Roma',
    latitude: 41.9022,
    longitude: 12.4818,
    sortOrder: 120,
  ),
  PcmOfficeOption(
    id: 'politiche-spaziali-molise',
    locationName: 'Via Molise, 2',
    structureName: 'Ufficio per le politiche spaziali e aerospaziali',
    address: 'Via Molise, 2',
    city: '00187 Roma',
    latitude: 41.9071,
    longitude: 12.4901,
    sortOrder: 130,
  ),
  PcmOfficeOption(
    id: 'sport-sardegna',
    locationName: 'Via Sardegna, 49',
    structureName: 'Dipartimento per lo sport',
    address: 'Via Sardegna, 49',
    city: '00187 Roma',
    latitude: 41.9088,
    longitude: 12.4911,
    sortOrder: 140,
  ),
  PcmOfficeOption(
    id: 'coesione-sud-sicilia',
    locationName: 'Via Sicilia, 162/C',
    structureName: 'Dipartimento per le politiche di coesione e per il Sud',
    address: 'Via Sicilia, 162/C',
    city: '00187 Roma',
    latitude: 41.9075,
    longitude: 12.4922,
    sortOrder: 150,
  ),
  PcmOfficeOption(
    id: 'zes-sicilia',
    locationName: 'Via Sicilia, 162/C',
    structureName: 'Struttura di missione ZES (cessata il 31/03/2026)',
    address: 'Via Sicilia, 162/C',
    city: '00187 Roma',
    latitude: 41.9075,
    longitude: 12.4922,
    sortOrder: 151,
    isActive: false,
  ),
  PcmOfficeOption(
    id: 'protezione-civile-ulpiano',
    locationName: 'Protezione Civile - Via Ulpiano',
    structureName: 'Dipartimento della protezione civile',
    address: 'Via Ulpiano, 11',
    city: '00193 Roma',
    latitude: 41.9042,
    longitude: 12.4696,
    sortOrder: 160,
  ),
  PcmOfficeOption(
    id: 'protezione-civile-vitorchiano',
    locationName: 'Protezione Civile - Via Vitorchiano',
    structureName: 'Dipartimento della protezione civile',
    address: 'Via Vitorchiano, 2',
    city: '00189 Roma',
    latitude: 41.9600,
    longitude: 12.4884,
    sortOrder: 161,
  ),
];
