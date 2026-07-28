# DailyTimesheet e DaySegment

`DailyTimesheet` è il record consolidato di una giornata. Viene creato dalla
timbratura, dall'inserimento manuale, dallo smart working o dall'import CSV.

## Identità e storage

- Modello: `lib/features/timesheet/domain/daily_timesheet.dart`
- Segmento: `lib/features/timesheet/domain/day_segment.dart`
- Firestore: `users/{uid}/timesheets/{dateId}`
- ID: `YYYY-MM-DD`
- Cache: Drift `timesheet_entries`, schema 6

Firestore resta la sorgente completa. La cache replica i campi orari, assenze
e `segments`; `personalNote` non è memorizzata in Drift.

## Campi del giorno

| Gruppo | Campi principali | Significato |
|---|---|---|
| Intervallo | `startTime`, `endTime`, `segments` | estremi e sequenza della giornata |
| Pause | `standardPauseMins`, `lunchPauseMins` | pause brevi e pranzo, a livello giorno |
| Permessi | `leavePauseMins` | somma dei segmenti di tipo `leave` |
| Consuntivo | `netWorkedMins`, `extraMins`, `sliMins`, `sboMins` | minuti lavorati e saldo |
| Tipologia | `workType` | `presence`, `remote`, `leave`, `holiday` |
| Banca ore | `bancaOreMins`, `boeSlot` | uso BOE e sua collocazione |
| Assenza | `absenceKind`, `absenceUnit`, consumi e periodo | dettaglio personale CCNL |
| Privacy | `sensitive`, `personalNote`, `hasDocumentation` | dati non destinati alle viste sociali |

## Segmenti

Un `DaySegment` rappresenta:

- un intervallo di lavoro con `start` e `end`;
- un permesso orario con `mins` e causale opzionale.

Pranzo e pause brevi non sono segmenti. I documenti storici senza `segments`
sono derivati in lettura, senza migrazione batch. Le assenze a giornata intera
possono mantenere l'array vuoto.

`recomputedFromSegments(stdMins:)` applica queste regole:

1. `startTime` e `endTime` sono il minimo e il massimo dei segmenti di lavoro;
2. `leavePauseMins` è la somma dei segmenti di permesso;
3. `netWorkedMins` è ricalcolato dagli intervalli, sottraendo pause brevi e
   pranzo;
4. `extraMins = netWorkedMins + bancaOreMins - standardWorkMins`.

La scelta completa è in
[ADR-0016](../decisioni/0016-segmenti-giornalieri.md).

## Regola delle nove ore

La stessa funzione è usata da timer, form manuale e import CSV:

```text
effective = minuti effettivi - pause brevi

pranzo forzato = 0                       se effective < 540
               = effective - 540        se 540 <= effective < 570
               = 30                     se effective >= 570

pranzo finale = max(pranzo registrato, pranzo forzato)
```

Lo smart working dichiarato non applica pranzo forzato.

## Assenze

La classificazione è un registro personale: non invia richieste, non produce
autorizzazioni e non sostituisce i sistemi ufficiali. I campi di consumo sono
stime; il dettaglio normativo è in
[Permessi, assenze e congedi](../ccnl/permessi-assenze-congedi.md).

## Compatibilità

La deserializzazione è tollerante: campi mancanti o corrotti non devono
interrompere lo stream mensile. `workType == null` equivale a `presence`.
Le scritture usano merge per non cancellare campi non toccati.

_Ultima revisione: 2026-07-29._
