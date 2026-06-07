# ADR-0007 — BOE: Banca Ore come Esonero intra-giornaliero

**Data:** 2026-06-06  
**Stato:** Accettato

## Contesto

La banca ore (SBO accumulato nel tempo) può essere usata dal dipendente pubblico come **permesso intra-giornaliero** (BOE — Banca Ore come Esonero) per coprire giornate in cui l'orario lavorato è inferiore al minimo contrattuale.

Il dipendente può scegliere dove posizionare il BOE nella giornata:
- **Pre-entrata**: ore accreditate retroattivamente prima della timbratura
- **Durante pausa**: riduzione di una pausa (pranzo o breve)
- **Post-uscita**: completamento del turno dopo la timbratura

La deduzione avviene in ordine: prima **AP (anno precedente)**, poi **AC (anno corrente)** — per consumare prima la banca ore più vecchia e a rischio scadenza.

## Decisione

### Modello dati

Aggiunti due campi a `DailyTimesheet` (Firestore + Drift):

| Campo | Tipo | Default | Descrizione |
|---|---|---|---|
| `bancaOreMins` | `int` | `0` | Minuti BOE usati in questa giornata |
| `boeSlot` | `String?` | `null` | Slot: `pre_entry`, `pause`, `post_exit` |

Aggiunta classe `BoeSlot` con le costanti stringa.

### Calcolo netto

`netWorkedMins` rimane il tempo **effettivamente lavorato** (senza BOE).  
`effectiveMins = netWorkedMins + bancaOreMins` viene usato per:
- Calcolare `extraMins` (overtime → SBO)
- Determinare la soglia buono pasto

### Timer

- `previewDeficit(DateTime endTime) → int`: calcola il deficit atteso senza mutare stato. Chiamato dal UI prima di `endTurn`.
- `endTurn(DateTime, {bancaOreMins, boeSlot})`: accetta i parametri BOE e li persiste nel record.

### UX — Dialog BOE

Il dialog appare **solo a fine turno** (`endTurn`) quando `previewDeficit > 0` e la banca ore disponibile > 0.

Mostra:
- Deficit in hh:mm
- Breakdown deduzione: X da AP, Y da AC
- Copertura totale (parziale se AP+AC < deficit)
- Picker slot (pre-entrata / pausa / post-uscita)
- "Salta" per procedere senza BOE

### BancaOreTile — live delta

La tile mostra i valori portale base corretti da un delta del mese corrente:
- `+Xhm SBO`: SBO accumulato questo mese (da `sboMins` dei timesheet)
- `−Yhm BOE usati`: BOE consumato questo mese (da `bancaOreMins` dei timesheet)

I chip AP/AC vengono mostrati in **ordine di deduzione** (AP prima).

## Opzioni considerate

1. **Tipo giornata separato** (`WorkType.boe`): scartato — il BOE è un modificatore su una giornata presenza, non un tipo autonomo.
2. **Auto-deduzione senza dialog**: scartato — l'utente deve scegliere lo slot.
3. **Deduzione AC-first**: scartato — la prassi CCNL è consumare prima l'anno precedente.

## Conseguenze

- Schema Drift bump: `v1 → v2`. Migrazione via `customStatement` (SQLite ADD COLUMN).
- `BancaOreTile` ora legge `monthlyTimesheetsProvider` — aggiunge una dipendenza Riverpod.
- Il portale rimane la sorgente di verità per AC/AP assoluti; il delta mensile è una stima live non vincolante.
- `sboMins` e `bancaOreMins` su giornate passate possono essere corretti manualmente dal timesheet.
