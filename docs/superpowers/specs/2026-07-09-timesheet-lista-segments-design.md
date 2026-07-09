# Design: Vista Lista timesheet + segments multi-entry + ricalcolo

Data: 2026-07-09 · Stato: approvato in brainstorming

## Obiettivo

1. Riga vista Lista: enfasi su entrata/uscita/pause; contatori (ore lavorate,
   maggior presenza, buono pasto) a destra; ore default del giorno vicino alla
   data; righe weekend/festivi compatte; quick-add 4 tipi su giorni passati
   vuoti; badge deficit con minuti mancanti.
2. Widget contatori mensile: Ore tot / Maggior presenza / Buoni pasto +
   scorporo chiaro Art.9·SLI·SBO·OP; via barre di avanzamento ed espansione.
3. Multi-entry per giorno via `segments[]` (presenza + permessi multipli).
4. Ricalcolo automatico dei totali giornata a ogni salvataggio.

## 1. Modello dati — `segments[]`

Nuovo campo array nel doc `timesheets/{dateId}`. Doc-per-giorno e
`dateId = docID` invariati.

```dart
class DaySegment {
  final String type;         // 'work' | 'leave' (pause pranzo/caffè restano campi giorno)
  final DateTime? start;     // work: entrata
  final DateTime? end;       // work: uscita
  final int mins;            // leave: durata; work: derivato end-start
  final String? absenceKind; // causale CCNL per leave
}
```

- **Retrocompat lazy**: `fromMap` senza `segments` deriva 1 segment work da
  `startTime`/`endTime` (+1 leave se `leavePauseMins > 0`). Nessuna
  migrazione batch.
- **Totali sempre derivati**: al save `netWorkedMins`, `lunchPauseMins`
  (regola 9h 3-zone), `extraMins`, `leavePauseMins` ricalcolati da
  `segments[]`. Funzione unica nel repository (`recomputeFromSegments`),
  usata da `_EntrySheet`, timer e import CSV — questo È il ricalcolo
  automatico.
- `startTime`/`endTime` giorno = min/max dei segment work → export PDF/CSV,
  cartellino, dashboard invariati.
- Cache Drift: colonna testo JSON `segments` (schema v4, solo una colonna).
- Timer live: `endTurn` scrive 1 segment work; comportamento invariato.
- Fuori scopo: modifiche a export CSV/PDF e viste Settimana/Mese (leggono
  totali giorno).

## 2. Riga vista Lista

Giorno con entry:

```
│ 9    09:02 → 17:45          |   7:36  lavorate     │
│ Mer  ☕ 15m  🍽 30m  📄 1h   |  +0:37  magg.pres.   │
│ 7:36                        |   🍽️    buono pasto  │
```

- Sinistra: numero + nome giorno; sotto, ore default (`AppConstants.stdMinsForDate`),
  nascoste weekend/festivi.
- Centro: `entrata → uscita` in evidenza (14px w700); sotto, pause presenti
  (☕ brevi, 🍽 pranzo, 📄 permesso), solo se > 0.
- Destra, colonna allineata: ore lavorate; maggior presenza `+H:MM` arancio
  se > 0; 🍽️ se buono maturato.
- SW/Ferie/Permesso giornata intera: centro = label tipo + causale; destra
  solo campi sensati.
- Weekend/festivi senza entry: riga compatta ~32px (numero, nome, `—` o 🌴).
- Giorno passato feriale vuoto: chip `🏢 Presenza · 🏠 SW · 🌴 Ferie ·
  📄 Permesso`, tutti aprono `_EntrySheet` col tipo preselezionato; badge
  `⚠ −7:36` a destra.
- Giorno sotto orario (`extraMins < 0`): badge `⚠ −H:MM` al posto della
  maggior presenza; tap riga → sheet con "Copri con permesso".
- Auto-scroll a oggi: da altezza fissa 62px a offset cumulativo (altezze
  variabili).

## 3. Widget contatori (`MonthlySummaryCard`)

```
│  ‹    Luglio 2026  🖥 3 SW  🖥 2026: 21 SW  ›      │
│   142h        12:24           15 🍽️                │
│   Ore tot   Magg. presenza   Buoni pasto           │
│   Magg. presenza ──────────────────────            │
│   Art.9 8:00 · SLI 2:00 · SBO 1:30 · OP 0:54       │
│   Deficit −1:36                                    │
```

- Riga principale: Ore tot · Maggior presenza (`totalOtMins`) · Buoni pasto.
- Scorporo sotto, legato visivamente (indent/colore): Art.9 · SLI · SBO · OP
  (waterfall esistente; somma = maggior presenza; voci a 0 → `—`).
- Deficit riga separata rossa, solo se > 0 (non fa parte dello scorporo).
- Rimossi: espansione, freccia, progress bar, link Personalizza, prefs
  `summaryItems`/`summaryShowProgress` (anche da settings/profilo).
- Stesso widget per Dashboard e Timesheet; glass style e nav mese invariati.

## 4. `_EntrySheet` editor segments

Tipo Presenza:

```
Segmenti giornata
┌ 🏢 09:02 → 13:00                      ✕ ┐
┌ 📄 Permesso breve · 1h36              ✕ ┐
┌ 🏢 14:30 → 17:45                      ✕ ┐
[ + Lavoro ]  [ + Permesso ]
⚠ Mancano 1:36 all'orario (7:36)
[ Copri con permesso 1:36 ]
```

- Segment work = 2 TimePicker (riusa `_TimeTile`); leave = picker
  `AbsenceKind` + durata.
- "Copri con permesso X": visibile se totale < default; aggiunge segment
  leave precompilato coi minuti mancanti, modificabile; ripetibile.
- Footer live: totale lavorato + delta vs default.
- Validazione: work non sovrapposti, end > start.
- 1 solo segment work → UI identica a oggi.
- SW/Ferie/Permesso giornata intera: sheet invariato.
- Salva → ricalcolo automatico (§1).

## 5. Test + docs

- Unit test: totali da segments (net, 9h rule, extra, buono), retrocompat
  `fromMap`, validazione sovrapposizioni.
- Niente widget test (assenti oggi nel repo).
- Stesso commit: `docs/entita/daily-timesheet.md`,
  `docs/funzionalita/timesheet.md`, `docs/CHANGELOG.md`, ADR nuova
  (multi-entry via segments).

## Decisioni chiave (Q&A brainstorming)

| Domanda | Scelta |
|---|---|
| Permesso su giorno incompleto | Multi-entry per giorno |
| Rappresentazione multi-entry | Array `segments[]` nel doc giorno |
| Ricalcolo | Automatico a ogni salvataggio |
| Quick-add giorni vuoti | Tutti aprono sheet precompilato |
| Scope widget contatori | Unico widget, Dashboard + Timesheet |
| Tap badge deficit | Apre sheet con azione "Copri con permesso" |
