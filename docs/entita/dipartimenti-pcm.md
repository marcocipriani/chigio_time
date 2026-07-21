# Entità: Dipartimento/Struttura PCM

> Payload versionato: `assets/data/pcm_catalog.json`
> Modello: `lib/core/data/pcm_catalog.dart`
> Aggiornato: 2026-07-21

## Definizione

`PcmStructureSite` rappresenta l'associazione canonica tra una voce della
prima colonna dell'Appendice A PCM e la sede indicata nella seconda colonna.
L'etichetta utente è **Dipartimento/Struttura**; per retrocompatibilità il
profilo Firestore continua a salvare il nome nel campo `dipartimento`.

```dart
class PcmStructureSite {
  String id;
  String structureName;
  int sortOrder;
  String siteId;
  String siteName;
  String address;
  String city;
  double latitude;
  double longitude;
}
```

## Catalogo

Il catalogo `2026.07.20` contiene esattamente 50 nomi univoci. Deriva solo
dalla prima colonna del PDF locale `Appendice A-elenco strutture.pdf`:

- il duplicato evidente del Dipartimento per la programmazione e il
  coordinamento della politica economica è unificato;
- abbreviazioni, apostrofi, spaziatura e capitalizzazione sono normalizzati;
- nessuna struttura esterna all'Appendice A viene aggiunta.

Il file PDF è una sorgente locale di lavoro e non viene versionato né incluso
negli asset applicativi.

## Invarianti

`PcmCatalog.fromMap` rifiuta l'intero payload se non rispetta tutte le
invarianti:

- versione CalVer `YYYY.MM.DD`;
- esattamente 50 strutture;
- ID, nomi e `sortOrder` univoci;
- ID in kebab-case;
- sede coerente per ogni `siteId`;
- CAP/città e coordinate WGS84 validi.

Onboarding e profilo devono leggere questo modello tramite il repository del
catalogo. Liste Dart separate non sono fonti ammesse.

## File correlati

- [`sedi-pcm.md`](./sedi-pcm.md)
- [`user-profile.md`](./user-profile.md)
- `assets/data/pcm_catalog.json`
- `lib/core/data/pcm_catalog.dart`
