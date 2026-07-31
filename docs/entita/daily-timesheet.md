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
| Pause | `standardPauseMins`, `lunchPauseMins` | derivati dai segmenti `pause`/`lunch` |
| Permessi | `leavePauseMins` | derivato dai segmenti `leave` (dentro o fuori lo span) |
| Consuntivo | `netWorkedMins`, `extraMins`, `sliMins`, `sboMins` | minuti lavorati e saldo |
| Tipologia | `workType` | `presence`, `remote`, `leave`, `holiday` |
| Banca ore | `bancaOreMins`, `boeSlot` | derivato dai segmenti `banca_ore`; `boeSlot` resta manuale |
| Assenza | `absenceKind`, `absenceUnit`, consumi e periodo | dettaglio personale CCNL |
| Privacy | `sensitive`, `personalNote`, `hasDocumentation` | dati non destinati alle viste sociali |

## Segmenti

Un `DaySegment` è tipizzato (`work`, `leave`, `banca_ore`, `lunch`, `pause`) e
occupa un intervallo (`start`/`end`) oppure, quando la posizione non è nota,
solo una durata (`mins`). `leave` porta anche una causale opzionale.

I documenti storici senza `segments` sono derivati in lettura (nessuna
migrazione batch): un segmento `work` dagli orari di giornata, più `leave`,
`lunch`, `pause` e `banca_ore` — senza orario — dai rispettivi campi minuti se
presenti. Le assenze a giornata intera mantengono l'array vuoto.

`recomputedFromSegments(stdMins:)` deriva `startTime`, `endTime`,
`standardPauseMins`, `leavePauseMins`, `lunchPauseMins` e `bancaOreMins` dai
segmenti, poi calcola (ADR-0018):

```
span      = ultima uscita − prima entrata (solo segmenti `work`)
netto     = span − (lunch + pause + leave∩span + bancaOre∩span)
copertura = netto + leave_totale + bancaOre_totale
extra     = copertura − orario_dovuto
```

I segmenti `work` collassano nello span: i buchi fra due timbrature non
giustificati da un altro segmento contano come lavorati. Un permesso o un
esonero banca ore posizionato **fuori** dallo span (prima dell'entrata o dopo
l'uscita) copre per intero l'orario dovuto; uno **dentro** lo span, o senza
orario (assunto dentro), rietichetta solo una parte dello span già contato —
non produce copertura aggiuntiva. `uncoveredDeficitMins` è
`max(0, -extraMins)`: `extraMins` contiene già la copertura, quindi sottrarre
di nuovo `leavePauseMins` sarebbe doppio conteggio.

La scelta completa è in [ADR-0016](../decisioni/0016-segmenti-giornalieri.md)
e [ADR-0018](../decisioni/0018-permessi-orari-nella-giornata.md).

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

_Ultima revisione: 2026-07-30._
