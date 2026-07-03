# ADR-0009 — Cap di inquadramento storicizzati (effective-dated)

- **Data:** 2026-06-14
- **Autore/i:** Claude Code (su richiesta di Marco)
- **Stato:** Accepted
- **Contesto correlato:** [`entita/sedi-pcm.md`](../entita/sedi-pcm.md), [`funzionalita/profilo.md`](../funzionalita/profilo.md), `lib/features/profile/domain/cap_period.dart`

## Contesto

I cap mensili dell'utente (inquadramento, orario standard, soglia buono pasto,
Art.9, SLI, SBO, variante orario) erano campi **flat** su `users/{uid}`,
sovrascritti a ogni modifica. Cambiando inquadramento (es. Comando→Ruolo) i nuovi
cap riscrivevano i vecchi e **tutti i mesi passati venivano ricalcolati** con i
cap nuovi — sbagliato: un mese già chiuso deve mantenere i cap in vigore allora
(la card "maggior presenza" e lo split straordinari SLI/SBO dipendono dai cap del
mese). Inoltre non esisteva uno storico consultabile.

## Opzioni considerate

1. **Mantenere i campi flat** — semplice ma i mesi passati perdono i loro cap a
   ogni cambio inquadramento; nessuno storico.
2. **Array `capPeriods` sul doc utente** — una sola lettura, ma gonfia il doc
   profilo (ora leggibile dai colleghi stessa amministrazione, vedi ADR-0008) ed
   espone lo storico cap.
3. **Sub-collezione `users/{uid}/capPeriods/{id}` effective-dated** owner-only:
   ogni periodo ha `fromMonth`/`toMonth` ("YYYY-MM", `toMonth=null` = aperto) e
   lo snapshot completo dei cap. Risoluzione per mese via `capsForMonth(M)`.

## Decisione

Adottiamo l'**opzione 3**. Cambiando inquadramento: il periodo aperto viene
**chiuso** al mese corrente (`toMonth=meseCorrente`) e si apre un **nuovo
periodo** dal mese successivo (`fromMonth=meseProssimo`) coi default del nuovo
inquadramento. Le modifiche fini dei singoli cap (SLI/SBO/Art.9/orario/buono
pasto) aggiornano il periodo aperto **e** rispecchiano sui campi flat del doc
utente, che restano il mirror del mese corrente per letture rapide e
retro-compatibilità. La card "maggior presenza" e il calcolo straordinari
risolvono i cap del mese visualizzato via `capsForMonth`, con fallback ai campi
flat quando nessun periodo copre il mese (utenti pre-migrazione).

## Conseguenze

- **Positive:** i mesi passati conservano i loro cap/calcoli; esiste uno storico
  consultabile ("Storico inquadramenti"); il cambio inquadramento ha effetto dal
  mese successivo come richiesto.
- **Negative / debiti tecnici:** una lettura in più (stream `capPeriods`) nelle
  schermate che risolvono i cap; logica di chiusura/apertura periodo da
  mantenere. La storicizzazione dell'**orario standard per-mese** (ricalcolo
  minuti attesi timesheet) è fuori scope di questo ADR: per ora `stdMinsForDate`
  continua a usare i campi flat (mese corrente). Follow-up se servirà.
- **Migrazione:** script firebase-admin che crea, per ogni utente, un periodo
  aperto `fromMonth=<primo mese con timesheet>, toMonth=null` dallo snapshot dei
  campi flat. Idempotente (salta utenti che hanno già periodi).

## Note

Modello in `cap_period.dart` (`CapPeriod`, `capsForMonth`). Metodi repo:
`capPeriodsStream`, `changeInquadramento`, `updateOpenPeriodCaps`. Regola
Firestore: `match /users/{uid}/capPeriods/{id}` owner-only.
