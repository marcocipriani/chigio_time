# Entità: Sedi PCM

> File canonico: `lib/core/constants/pcm_locations.dart`
> Aggiornato: 2026-06-11

---

## Struttura dati

Le sedi PCM sono modellate in due livelli:

### `PcmOfficeOption` (per struttura)

```dart
class PcmOfficeOption {
  final String id;           // slug kebab-case, es. "dfp-palazzo-vidoni"
  final String locationName; // Nome breve sede, es. "Palazzo Vidoni"
  final String structureName;// Nome struttura ospitata
  final String address;      // Via/Piazza, numero
  final String city;         // Città (es. "Roma")
  final double lat;
  final double lng;
  final int sortOrder;
  final bool isActive;
}
```

### `PcmSiteOption` (per indirizzo fisico)

Raggruppamento logico di più `PcmOfficeOption` con lo stesso indirizzo.
Usato nella dropdown sede del profilo e del route planner.

---

## Sedi disponibili (fonte: `pcmOfficeSeeds`, 34 entries)

| ID | Location Name | Indirizzo |
|---|---|---|
| `dagl-palazzo-chigi` | Palazzo Chigi | Piazza Colonna 370, Roma |
| `segreteria-cdm-palazzo-chigi` | Palazzo Chigi (CDM) | Piazza Colonna 370, Roma |
| `segretario-generale-chigi-mercede-96` | Palazzo Chigi / Mercede 96 | Piazza Colonna 370 / Via della Mercede 96 |
| `cerimoniale-palazzo-chigi` | Palazzo Chigi (Cerimoniale) | Piazza Colonna 370, Roma |
| `affari-europei-largo-chigi` | Largo Chigi | Largo Chigi 19, Roma |
| `rapporti-parlamento-largo-chigi` | Largo Chigi (Parl.) | Largo Chigi 19, Roma |
| `pari-opportunita-largo-chigi` | Largo Chigi (PO) | Largo Chigi 19, Roma |
| `riforme-istituzionali-largo-chigi` | Largo Chigi (Riforme) | Largo Chigi 19, Roma |
| `missione-pnrr-largo-chigi` | Largo Chigi (PNRR) | Largo Chigi 19, Roma |
| `dfp-palazzo-vidoni` | Palazzo Vidoni | Corso Vittorio Emanuele II 116, Roma |
| `personale-mercede-96` | Via della Mercede 96 | Via della Mercede 96, Roma |
| `servizi-strumentali-mercede-96` | Via della Mercede 96 (SS) | Via della Mercede 96, Roma |
| `ubbrac-mercede-96` | Via della Mercede 96 (UBBRAC) | Via della Mercede 96, Roma |
| `uci-mercede-96` | Via della Mercede 96 (UCI) | Via della Mercede 96, Roma |
| `programma-governo-mercede-96` | Via della Mercede 96 (PG) | Via della Mercede 96, Roma |
| `dica-mercede-9` | Via della Mercede 9 | Via della Mercede 9, Roma |
| `die-mercede-9` | Via della Mercede 9 (DIE) | Via della Mercede 9, Roma |
| `dipe-mercede-9` | Via della Mercede 9 (DIPE) | Via della Mercede 9, Roma |
| `daras-stamperia` | Via della Stamperia | Via della Stamperia 8, Roma |
| `conferenza-stato-citta-stamperia` | Via della Stamperia (Conf.) | Via della Stamperia 8, Roma |
| `protezione-civile-ulpiano` | Via Ulpiano | Via Ulpiano 11, Roma |
| `dtd-brazza` | Via Serbelloni / Brazza | Via Serbelloni 15 / Via Brazza, Milano |
| `politiche-spaziali-molise` | Via Molise | Via Molise 2, Roma |
| `sport-sardegna` | Via Sardegna | Via Sardegna 19, Roma |
| `casa-italia-ferratella` | Ferratella (Casa Italia) | Via Ferratella in Laterano 51, Roma |
| `droga-dipendenze-ferratella` | Ferratella (Antidroga) | Via Ferratella in Laterano 51, Roma |
| `giovani-scu-ferratella` | Ferratella (Giovani) | Via Ferratella in Laterano 51, Roma |
| `famiglia-iv-novembre` | Via IV Novembre | Via IV Novembre 119, Roma |
| `coesione-sud-sicilia` | Via Sicilia | Via Sicilia 162-164, Roma |
| `disabilita-panetteria` | Via della Panetteria | Via della Panetteria 28, Roma |
| `sport-sardegna` | Via Sardegna | Via Sardegna 19, Roma |

---

## Mappatura Dipartimento → Sede primaria

Definita in `lib/core/constants/pcm_departments.dart`.

Ogni `PcmDepartment` ha un `primarySedeId` opzionale. La funzione
`sortedOfficesForDepartment(departmentName, allOffices)` restituisce la lista
di uffici con la sede primaria in cima (usata in onboarding e profilo per il
suggerimento ★).

---

## Bug noti

**Bug A — ID mismatch onboarding/profilo**: l'onboarding salva
`PcmOfficeOption.id` (per struttura), ma il profilo usa
`pcmSiteLocationsProvider` che raggruppa per indirizzo e usa l'ID del primo
ufficio del gruppo. Fix previsto: ricerca per address match o iterazione di
tutti gli uffici del sito.

**Bug B — WASM null guard**: il provider `pcmSiteLocationsProvider` non ha
fallback `error:` handler nel profilo. Fix: `try/catch` in
`getOfficeLocations()` con fallback a `activePcmOfficeSeeds()`.

---

## File correlati

- `lib/core/constants/pcm_locations.dart` — costanti sedi (fonte canonica)
- `lib/core/constants/pcm_departments.dart` — costanti strutture + mapping sede primaria
- `lib/features/profile/data/profile_repository.dart` — `getPcmOfficeLocations()`
- `lib/features/authentication/presentation/onboarding_screen.dart` — step sede
- `lib/features/profile/presentation/profile_screen.dart` — dropdown sede in edit
- `departments.md` (radice) — lista strutturata strutture PCM per riferimento editoriale
