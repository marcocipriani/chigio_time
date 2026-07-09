# Entità: `DailyTimesheet`

> Record consolidato di una **giornata di lavoro**.
> Persiste su Firestore alla pressione di "Timbra Uscita", oppure tramite
> inserimento manuale da Timesheet, oppure tramite "Smart Working" one-tap.

## Definizione

`lib/features/timesheet/domain/daily_timesheet.dart`

```dart
class WorkType {
  static const presence = 'presence'; // default / null → presenza normale
  static const remote   = 'remote';   // smart-working
  static const leave    = 'leave';    // permesso
  static const holiday  = 'holiday';  // ferie
}

class DailyTimesheet {
  final String dateId;            // 'YYYY-MM-DD' — anche document ID
  final DateTime startTime;       // entrata effettiva (o 09:00 per remote)
  final DateTime endTime;         // uscita effettiva
  final int standardPauseMins;    // pause brevi/caffe'
  final int leavePauseMins;       // permessi brevi (Art. 35 CCNL PCM)
  final int lunchPauseMins;       // pausa pranzo (regola 9 ore 3-zone, vedi sotto; 0 per remote)
  final int netWorkedMins;        // elapsed − standardPause − leavePause − lunchPause
  final int extraMins;            // netWorkedMins − standardWorkMins (neg = deficit, pos = straordinario/maggior presenza)
  final int sliMins;              // straordinario liquidato in busta paga (default 0)
  final int sboMins;              // straordinario in banca ore (default 0)
  final String? workType;         // WorkType.* — null → retrocompat. presence
  final String? note;             // nota attivita'
  final int bancaOreMins;         // BOE: minuti banca ore usati come esonero
  final String? boeSlot;          // pre_entry | pause | post_exit
  final String? absenceKind;      // causale personale CCNL, se permesso/ferie
  final String? absenceUnit;      // hourly | daily | period
  final int absenceMins;          // consumo stimato in minuti
  final double absenceDays;       // consumo stimato in giorni
  final String? periodStart;      // YYYY-MM-DD per assenze multi-giorno
  final String? periodEnd;        // YYYY-MM-DD per assenze multi-giorno
  final int? quotaYear;           // anno contatore personale
  final bool countsAsSicknessPeriod;
  final bool sensitive;           // oscura causale in export/viste non private
  final String? personalNote;     // nota privata
  final bool hasDocumentation;    // promemoria documentazione
}
```

## Proprietà derivate

| Getter | Valore |
|---|---|
| `isRemote` | `workType == WorkType.remote` |
| `isLeave` | `workType == WorkType.leave` |
| `isHoliday` | `workType == WorkType.holiday` |

## Dettaglio assenze

Quando `workType == leave` o `holiday`, `_EntrySheet` può valorizzare una
causale `AbsenceKind` e i campi collegati. Questa è una gestione personale:
non crea richieste autorizzative, non invia documenti e non sostituisce il
portale ufficiale.

| Campo | Uso |
|---|---|
| `absenceKind` | Causale specifica (`short_leave`, `specialist_visit`, `sickness`, ecc.) |
| `absenceUnit` | Unità di fruizione: ore, giorno, periodo |
| `absenceMins` / `absenceDays` | Consumo stimato per confronti personali |
| `periodStart` / `periodEnd` | Range assenze multi-giorno, es. malattia |
| `quotaYear` | Anno di riferimento del plafond personale |
| `countsAsSicknessPeriod` | Include l'assenza nei periodi malattia stimati |
| `sensitive` | Oscura causale/nota negli export non dettagliati |
| `personalNote` | Nota privata utente |
| `hasDocumentation` | Promemoria personale sulla documentazione |

> Nota CCNL 2026-06-06: il campo `leavePauseMins` conserva la naming
> storica dell'app. Nel CCNL PCM 2016-2018 i permessi brevi sono disciplinati
> dall'Art. 35; l'Art. 9 del medesimo CCNL non e' un istituto di orario.
> Vedi [`../ccnl/articoli-app.md`](../ccnl/articoli-app.md).

## Serializzazione

| Direzione | Metodo | Note |
|---|---|---|
| Dart → Firestore | `toMap()` | `workType` scritto come stringa; `null` → `'presence'` |
| Firestore → Dart | `factory fromMap(Map)` | `workType` nullable per compatibilità con doc precedenti |

> **Nota:** `updatedAt` è una stringa ISO lato client. Gli altri documenti
> usano `Timestamp` server-side. Da uniformare in futura iterazione.

## Mappatura Firestore

```
users/{uid}/timesheets/{dateId}
```

- Scrittura: `set(toMap(), SetOptions(merge: true))` → ri-timbrare lo stesso
  giorno aggiorna i campi senza perdere quelli non toccati.

## Cache Drift

Su piattaforme native `TimesheetRepository` mantiene una copia in
`timesheet_entries` (`AppDatabase` schema v3). La cache include campi orario,
pause, SLI/SBO, BOE, `workType` e `note`, ma **non include ancora i campi
`absence*`**. Firestore resta quindi la sorgente completa per causali,
privacy e dettagli assenza; serve una futura migrazione Drift schema v4 per
cache offline completa.

## Provider

| Provider | Tipo | Scopo |
|---|---|---|
| `timesheetRepositoryProvider` | `@riverpod` function | DI del repository |
| `monthlyTimesheetsProvider((year:, month:))` | `StreamProvider.family` | lista del mese in realtime |

## Modalità di creazione

### 1. Timbratura standard (timer attivo)
`WorkTimer.endTurn(endTime)` — calcola `netWorkedMins` e `extraMins`,
`workType` rimane `null` (= presence).

### 2. Smart Working one-tap
`TimesheetRepository.saveRemoteWorkDay(stdMins)` — imposta
`workType: 'remote'`, `netWorkedMins = stdMins`, `lunchPauseMins = 0`
(orario dichiarato, non un timbro reale: **nessuna pausa pranzo si applica in
nessun caso**), buono pasto automaticamente maturato.

### 3. Inserimento manuale (Timesheet screen)
`_EntrySheet` → `TimesheetRepository.saveDailyTimesheet(entry)` — qualsiasi
`workType`, entrata/uscita scelti dall'utente. Per `presence` la pausa pranzo
segue la regola 9 ore sotto (non piu' un taglio fisso 30m); `effectiveElapsed`
qui coincide con l'elapsed semplice (il form non raccoglie pause brevi/permessi).

### 4. Import CSV
`CsvImportService` — se la nota specifica una pausa esplicita quella vince,
altrimenti si applica la stessa regola 9 ore (niente piu' default fisso 30/60m).

## Regola 9 ore (consolidamento) — 3 zone

Unica regola per pausa pranzo, usata da timer live, inserimento manuale e
import CSV — `AppConstants.forcedLunchMins()`:

```text
effectiveElapsed = totalElapsedMins − standardPauseMins − leavePauseMins

forcedLunch = 0                          se effectiveElapsed < 540
            = effectiveElapsed − 540     se 540 ≤ effectiveElapsed < 570   (zona 2)
            = 30                         se effectiveElapsed ≥ 570          (zona 3)

finalLunchMins   = max(lunchPauseMins, forcedLunch)
netWorkedMins    = totalElapsedMins − standardPauseMins − leavePauseMins − finalLunchMins
extraMins        = netWorkedMins − standardWorkMins   (neg = deficit, pos = straordinario)
```

Non si applica ai giorni `remote`: li' `lunchPauseMins` resta sempre `0`.

## Esempio JSON (smart-working)

```json
{
  "dateId": "2026-04-26",
  "startTime": "2026-04-26T09:00:00.000",
  "endTime":   "2026-04-26T16:36:00.000",
  "standardPauseMins": 0,
  "lunchPauseMins": 0,
  "netWorkedMins": 456,
  "extraMins": 0,
  "workType": "remote",
  "updatedAt": "2026-04-26T09:05:00.123"
}
```

## Glossario contatori mensili (widget blu)

| ID widget | Campo sorgente | Significato |
|---|---|---|
| `art9` | `totalOtMins.clamp(0, art9Cap)` | **Art.9 / Maggior presenza** — prima fetta mensile dello straordinario fino al cap `monthlyArt9Hours`. |
| `sli` | `sliMins` | **SLI** — straordinario liquidato immediatamente in busta paga (cap mensile configurabile). |
| `sbo` | `sboMins` | **SBO** — straordinario accantonato in banca ore (cap mensile configurabile). |
| `op` | `max(0, totalOtMins − art9Cap − sliCap − sboCap)` | **OP — Ore Perse** — straordinario che eccede tutti i cap autorizzati mensili; non recuperabile né liquidabile. |
| `deficit` | `sum(extraMins < 0)` | **Deficit** — somma mensile dei giorni in cui `netWorkedMins < standardDailyMins`; va coperto con permessi o BOE. |

_Ultima revisione: 2026-06-09 — 3-zone 9h rule, OP vs deficit separati, art9UsedMins da cascata._
