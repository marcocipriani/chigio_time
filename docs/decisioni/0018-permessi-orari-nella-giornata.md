# ADR-0018 — Permessi orari dentro la giornata e unità di consumo

- **Data:** 2026-07-30
- **Owner:** Marco Cipriani
- **Stato:** Proposed

## Contesto

[ADR-0016](./0016-segmenti-giornalieri.md) ha introdotto `segments[]` con il
tipo `leave`, ma i segmenti di permesso restano incompleti: `start`, `end` e
`absenceKind` non vengono mai valorizzati, né dal timer né dall'import CSV. Le
conseguenze sono tre.

Un permesso orario non concorre a coprire l'orario dovuto: `recomputedFromSegments`
calcola `extraMins` dal solo lavoro, quindi una giornata coperta da permesso
risulta in deficit e non produce maggior presenza.

`computeAbsenceConsumption` legge solo i campi di giornata `absenceKind` e
`absenceMins`, quindi ignora i segmenti: un permesso fruito dentro una giornata
di presenza non scala il plafond annuo.

Il template CSV di import non ha modo di esprimere un permesso dentro una
giornata di presenza, e assegna a ogni riga un solo `tipo`.

La riconciliazione dei cartellini 2026 del portale HR-WorkFlow (gennaio-luglio,
96 giornate di presenza) mostra che il resto del modello è corretto: 70 giornate
coincidono col contatore del portale, e le 26 rimanenti hanno tutte la cella
contatori troncata nell'HTML salvato, con differenza sempre a favore del calcolo
dell'app. Le giornate con permesso intra-giornata nel 2026 sono tre, per 355
minuti complessivi di visita specialistica, oggi non conteggiati.

Il portale distingue inoltre la fruizione a ore da quella a giornata (suffisso
`GG`). Per l'Art. 16 CCNL 2019-2021 la giornata convenzionale vale 6 ore
qualunque sia l'orario dovuto, come già documentato in
[permessi-assenze-congedi.md](../ccnl/permessi-assenze-congedi.md): il consumo
del plafond e la copertura dell'orario sono due grandezze distinte.

## Opzioni considerate

1. **Riga CSV per segmento.** Fedeltà massima, ma richiede di rimuovere il
   controllo sulle date duplicate e di riscrivere l'aggregazione del parser.
2. **Riuso delle colonne `assenza_*` sulle righe di presenza.** Nessuna colonna
   nuova, ma il permesso perde gli orari e non è distinguibile un permesso
   interno allo span da uno esterno.
3. **Due colonne `permesso_da` / `permesso_a`.** Il segmento conosce la propria
   posizione nella giornata, che è l'informazione necessaria al calcolo.

## Decisione

Adottiamo l'opzione 3. Nessun campo nuovo nel modello: il permesso orario è un
`DaySegment(type: leave)` con `start`, `end` e `absenceKind` valorizzati. Il
template CSV diventa:

```
data;tipo;entrata;uscita;nota;assenza_tipo;assenza_min;assenza_giorni;periodo_da;periodo_a;permesso_da;permesso_a
```

**Costruzione dei segmenti.** Il segmento `leave` copre l'intervallo dichiarato;
i segmenti `work` coprono lo span entrata-uscita meno l'intersezione col
permesso. Un permesso esterno allo span non riduce il lavoro, uno interno lo
divide in due. Una sola regola copre entrambi i casi.

**Copertura dell'orario.** `extraMins` diventa `net + leaveSum + bancaOreMins -
stdMins`: il permesso copre il dovuto e l'eventuale eccedenza resta maggior
presenza. Di conseguenza `uncoveredDeficitMins` si riduce a `max(0, -extraMins)`,
perché sottrarre di nuovo `leavePauseMins` sarebbe un doppio conteggio.

**Unità di consumo.** La fruizione a giornata resta una giornata intera
(`workType: leave`, `absenceUnit: daily`, `absenceDays`), non un segmento. Il
consumo del plafond si ottiene moltiplicando `absenceDays` per la giornata
convenzionale della causale; la copertura dell'orario resta quella della
giornata. La giornata convenzionale è una costante accanto ai plafond esistenti
in `AbsencePlafonds`. L'unica causale che ne ha una è `personal_family_hourly`
(6 ore): le altre restano orarie finché non emergono dai dati.

**Conteggio.** `computeAbsenceConsumption` itera le quote di assenza estratte da
una entry — sia i campi di giornata sia i segmenti `leave` con causale.

**Superfici.** L'editor della giornata permette di aggiungere un permesso a una
giornata di presenza, col selettore ore/giornata visibile solo per le causali che
hanno una giornata convenzionale. Il timer chiede la causale all'avvio di una
pausa `PauseType.leave` e scrive orari e causale nel segmento. `csv_export_service`
emette le due colonne nuove, così import ed export restano simmetrici, e il PDF
mostra il permesso come riga della giornata.

## Conseguenze

- **Positive:** giornate miste rappresentate con fedeltà verificata sui dati
  reali del portale; i permessi intra-giornata scalano il plafond; import ed
  export restano simmetrici.
- **Negative:** il template CSV cresce di due colonne; le causali fuori
  tassonomia (sciopero, assemblea, recuperi di festività lavorata) restano testo
  in nota, senza contatore dedicato.
- **Migrazione:** nessuna migrazione di schema. La formula nuova cambia però
  `extraMins` delle giornate già salvate con `leavePauseMins > 0`: i documenti
  legacy derivano un segmento `leave` in lettura, quindi al primo ricalcolo la
  loro eccedenza sale di quei minuti. È la correzione attesa, ma i totali storici
  si muovono.

Vedi [DailyTimesheet](../entita/daily-timesheet.md) e
[Timesheet](../funzionalita/timesheet.md).

_Ultima revisione: 2026-07-30._
