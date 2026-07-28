# ADR-0016 — Segmenti di lavoro e permesso nel cartellino

- **Data:** 2026-07-09
- **Owner:** Marco Cipriani
- **Stato:** Accepted

## Contesto

Un singolo intervallo entrata/uscita non rappresenta giornate composte da più
fasce di lavoro e permessi orari. Una migrazione distruttiva dei documenti
storici avrebbe aumentato il rischio senza aggiungere informazione reale.

## Opzioni considerate

1. Creare un documento Firestore per ogni intervallo.
2. Sostituire i campi giornalieri con un array obbligatorio e migrare tutto.
3. Aggiungere segmenti al documento giornaliero, mantenendo i totali derivati
   e compatibilità lazy.

## Decisione

Adottiamo l'opzione 3. `users/{uid}/timesheets/{dateId}` resta l'unità
atomica. `segments[]` contiene intervalli di lavoro e permessi orari; pranzo e
pause brevi restano campi del giorno.

I documenti legacy senza segmenti vengono derivati in lettura. Non esiste una
migrazione batch obbligatoria. `DailyTimesheet.recomputedFromSegments`
ricalcola estremi, permessi, netto e saldo usando l'orario del profilo. Drift
salva l'array come JSON a partire dallo schema 5; lo schema corrente è 6.

## Conseguenze

- Giornate miste e interrotte sono rappresentabili senza nuove collezioni.
- I totali duplicati migliorano query e UI ma devono essere ricalcolati da un
  solo metodo di dominio.
- Documenti legacy conservano il loro significato.
- Un deficit può essere coperto con un segmento permesso senza trasformare il
  comportamento neutro dell'app in una sanzione.

Vedi [DailyTimesheet](../entita/daily-timesheet.md) e
[Timesheet](../funzionalita/timesheet.md).

_Ultima revisione: 2026-07-29._
