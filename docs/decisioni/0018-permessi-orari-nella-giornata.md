# ADR-0018 — Segmenti orari come struttura della giornata

- **Data:** 2026-07-30
- **Owner:** Marco Cipriani
- **Stato:** Proposed

## Contesto

[ADR-0016](./0016-segmenti-giornalieri.md) ha introdotto `segments[]` con i tipi
`work` e `leave`, ma la struttura è rimasta a metà. I segmenti `leave` non hanno
mai `start`, `end` né `absenceKind`: né il timer né l'import li valorizzano. Le
pause e la banca ore restano minuti sciolti sul documento giornata
(`lunchPauseMins`, `standardPauseMins`, `bancaOreMins`), senza posizione. Una
giornata timbrata non è quindi rappresentabile come sequenza.

Le conseguenze sono misurabili. Un permesso orario non concorre a coprire
l'orario dovuto, perché `recomputedFromSegments` calcola `extraMins` dal solo
lavoro: una giornata coperta da permesso risulta in deficit e non produce
maggior presenza. `computeAbsenceConsumption` legge solo i campi di giornata e
ignora i segmenti, quindi un permesso fruito dentro una giornata di presenza non
scala il plafond annuo. Il template CSV di import assegna un solo `tipo` a ogni
riga e non sa esprimere né un permesso intra-giornata, né una pausa con orario,
né un esonero da banca ore.

La riconciliazione dei cartellini 2026 del portale HR-WorkFlow (gennaio-luglio,
96 giornate di presenza) mostra che il resto del modello è corretto: 70 giornate
coincidono col contatore del portale, e le 26 rimanenti hanno tutte la cella
contatori troncata nell'HTML salvato, con differenza sempre a favore del calcolo
dell'app. Le giornate con permesso intra-giornata sono tre, per 355 minuti di
visita specialistica oggi non conteggiati; due giornate usano un esonero da
banca ore che il CSV non sa trasportare.

Il portale distingue infine la fruizione a ore da quella a giornata (suffisso
`GG`). Per l'Art. 16 CCNL 2019-2021 la giornata convenzionale vale 6 ore
qualunque sia l'orario dovuto, come già documentato in
[permessi-assenze-congedi.md](../ccnl/permessi-assenze-congedi.md): consumo del
plafond e copertura dell'orario sono due grandezze distinte.

## Opzioni considerate

1. **Completare i soli segmenti `leave`**, lasciando pause e banca ore come
   minuti di giornata. Diff minimo, ma la giornata resta non rappresentabile
   come sequenza e la timeline avrebbe buchi che non sa nominare.
2. **Riga CSV per giornata con colonne `permesso_da`/`permesso_a`.** Nessuna
   riscrittura del parser, ma un solo permesso per giorno e nessun posto per
   pause ed esoneri.
3. **Riga CSV per segmento, con merge dei `work` prima del calcolo.** Il file
   descrive la giornata reale; il calcolo collassa i segmenti di lavoro e
   produce gli stessi totali verificati sul portale.

## Decisione

Adottiamo l'opzione 3, e i segmenti diventano la struttura della giornata
timbrata in tutta l'app.

### Tipologie di segmento orario

Un segmento orario occupa un intervallo dentro la giornata. Il comportamento è
definito da tre proprietà, non dal nome:

| Tipo | Conta come lavorato | Copre l'orario dovuto | Consuma |
|---|---|---|---|
| `work` | sì | — | — |
| `leave` | no | sì | plafond della causale |
| `bancaOre` | no | sì | saldo banca ore (AP poi AC) |
| `lunch` | no | no | — |
| `pause` | no | no | — |

Gli istituti non ancora modellati si collocano nella stessa griglia senza codice
nuovo: sciopero è `no / no / niente`, assemblea è `no / sì / plafond`, recupero
di festività lavorata è `no / sì / credito`.

`bancaOre` sostituisce la coppia `bancaOreMins` + `boeSlot` di
[ADR-0007](./0007-banca-ore-esonero.md): lo slot diventa derivabile dalla
posizione del segmento rispetto allo span.

### Invarianti

I segmenti di una giornata sono ordinati e non sovrapposti. Lo span è definito
dai soli `work`. `leave` e `bancaOre` possono cadere dentro o fuori lo span;
`lunch` e `pause` solo dentro. La sovrapposizione è un errore di validazione.

Gli invarianti e la formula sono verificati sui cartellini reali da
`cartellini/check_csv.py`: sulle 17 giornate del 2026 con contatori completi il
calcolo coincide col portale, e su nessuna delle 79 troncate scende sotto il
minimo che il portale dichiara.

### Calcolo

I segmenti `work` collassano nell'intervallo `[prima entrata, ultima uscita]`,
poi si sottrae quanto non è lavorato:

```
netto     = span − (lunch + pause + leave∩span + bancaOre∩span)
copertura = netto + leave_totale + bancaOre_totale
extra     = copertura − orario_dovuto
```

Il merge dei `work` è deliberato: il portale conta come lavorato i buchi non
giustificati fra una timbratura e la successiva, e la formula riproduce i totali
verificati su tutte le giornate del 2026. Il dettaglio dei segmenti viene
conservato ma non entra nel calcolo, e serve alla timeline.

`uncoveredDeficitMins` si riduce a `max(0, -extraMins)`: ora che `extraMins`
contiene la copertura, sottrarre di nuovo `leavePauseMins` sarebbe un doppio
conteggio.

### Unità di consumo

La fruizione a giornata resta una giornata intera (`workType: leave`,
`absenceUnit: daily`, `absenceDays`), non un segmento: ferie, smart working e
permesso giornaliero non hanno un intervallo reale, e l'orario `07:30–15:06` che
il portale scrive è una convenzione. Quelle giornate hanno zero segmenti.

Il consumo del plafond si ottiene moltiplicando `absenceDays` per la giornata
convenzionale della causale, una costante accanto ai plafond esistenti in
`AbsencePlafonds`. L'unica causale che ne ha una è `personal_family_hourly`
(6 ore); le altre restano orarie finché non emergono dai dati.

`computeAbsenceConsumption` itera le quote di assenza estratte da una entry, sia
dai campi di giornata sia dai segmenti `leave` con causale.

### Causali e contatori

La tassonomia si estende con gli istituti che il portale registra e che il
modello non nomina, elencati in
[permessi-assenze-congedi.md](../ccnl/permessi-assenze-congedi.md):
`suppressed_holiday` (4 giornate/anno, L. 937/77), `assembly` (12 ore/anno,
Art. 10 base 2016-2018), `strike` (senza plafond, non retribuito),
`worked_holiday_comp` e `compensatory_rest` (consumo su credito, saldo del
portale).

Nel 2026 sono tre giornate intere oggi importate senza causale. Un'assenza di
giornata intera non partecipa alla formula di copertura — netto zero, eccedenza
zero — quindi nessuno di questi istituti ha bisogno di un tipo di segmento
proprio: sono causali, non segmenti.

`AbsenceConsumption` passa da campi nominati per istituto a contatori indicizzati
per causale, con una tabella dei plafond a fianco. Cinque istituti nuovi
sarebbero cinque campi, cinque rami di `switch` e cinque soglie; una mappa più il
lookup è meno codice di quello che sostituisce, e il prossimo istituto non tocca
il calcolo. I getter già esposti restano come facciata, così i consumatori
attuali non cambiano.

Un contatore dichiara il proprio tipo di limite: plafond annuo in ore, quota
annua in giorni, credito con saldo esterno, oppure nessun limite. `strike` è del
quarto tipo e viene registrato senza confronto; i due recuperi sono del terzo, e
come per la banca ore il saldo resta del portale mentre l'app conta il consumo.

### Formato CSV

```
data;segmento;da;a;minuti;causale;nota

2026-07-23;work;10:25;12:52;;;Permesso visita specialistica | 0:01Maggior Presenza…
2026-07-23;leave;12:52;15:08;;specialist_visit;
2026-07-23;work;15:08;18:02;;;
2026-07-29;lunch;09:30;10:03;;;
2026-03-04;pause;;;0:07;;
2026-03-04;banca_ore;08:40;10:23;;;
2026-07-24;permesso_gg;;;;personal_family_hourly;Permesso motivi personali…
2026-07-14;ferie;;;;;Ferie | 1:00Ferie GG…
2026-07-03;smart_working;;;;;Smart Working | …
```

Il suffisso `_gg` distingue la giornata convenzionale dalla fruizione a ore,
riusando il vocabolario del portale. La nota è di giornata: vale la prima non
vuota fra le righe di quel giorno. Il controllo sulle date duplicate viene
sostituito dalla validazione delle sovrapposizioni.

La colonna `minuti` copre i segmenti di durata nota e posizione ignota, che
`DaySegment.mins` già rappresenta: il portale registra alcune voci senza
intervallo (una pausa di 7 minuti il 04/03/2026), e il timer scrive oggi un
segmento `leave` con i soli minuti. Un segmento senza intervallo si assume
dentro lo span, perché proviene dalla giornata timbrata.

### Superfici

Timer, editor e import scrivono segmenti; i campi minuti di giornata restano
esclusivamente come valore derivato da `recomputedFromSegments`. L'editor della
giornata diventa una timeline che mostra la sequenza ordinata e permette di
aggiungere, modificare ed eliminare un segmento su una giornata timbrata, coi
buchi non coperti visibili. La manipolazione diretta sulla barra resta fuori
scope. `csv_export_service` emette il formato a segmenti, così import ed export
restano simmetrici.

## Conseguenze

- **Positive:** la giornata è rappresentabile come sequenza; i permessi
  intra-giornata scalano il plafond; pause ed esoneri hanno una posizione; la
  regex che oggi indovina la pausa pranzo dal testo della nota sparisce; i nuovi
  istituti si aggiungono dichiarando tre proprietà; le tre giornate del 2026 oggi
  importate senza causale vengono classificate.
- **Negative:** parser ed export vanno riscritti, non modificati; il CSV passa da
  146 a 241 righe per il 2026, meno scansionabile a occhio; il dettaglio
  dei segmenti viene salvato ma nessun calcolo lo legge finché la timeline non lo
  usa; i contatori dei due recuperi dipendono da un saldo che solo il portale
  conosce, quindi mostrano il consumo ma non un residuo.
- **Migrazione:** nessuna migrazione di schema, i documenti legacy continuano a
  derivare i segmenti in lettura. La formula nuova cambia però `extraMins` delle
  giornate già salvate con `leavePauseMins > 0`: al primo ricalcolo la loro
  eccedenza sale di quei minuti. È la correzione attesa, ma i totali storici si
  muovono. I CSV già generati nel formato a giornata vanno rigenerati.

Vedi [DailyTimesheet](../entita/daily-timesheet.md) e
[Timesheet](../funzionalita/timesheet.md).

_Ultima revisione: 2026-07-30._
