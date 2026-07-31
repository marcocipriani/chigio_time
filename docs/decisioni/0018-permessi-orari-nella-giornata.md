# ADR-0018 — Segmenti orari come struttura della giornata

- **Data:** 2026-07-30
- **Owner:** Marco Cipriani
- **Stato:** Accepted

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

Il segmento `lunch` scritto dal timer ha un pavimento di 30 minuti: una pausa
pranzo più breve viene registrata come 30, coerentemente col contatore che il
timer mostra dal vivo e con la regola CCNL delle nove ore. Il pavimento
**anticipa l'inizio** del segmento invece di posticiparne la fine: una pausa a
ridosso dell'uscita sforerebbe il turno, sottrarrebbe la durata reale invece
dei 30 minuti e produrrebbe una giornata che viola l'invariante `lunch` dentro
lo span, bloccando ogni modifica successiva dalla timeline. L'inizio
retrodatato si ferma all'entrata **e** alla fine dell'ultima pausa già chiusa:
un pranzo più breve del pavimento che finisce meno di 30 minuti dopo la pausa
(o il permesso) precedente ci entrerebbe dentro, e la giornata verrebbe
salvata con due segmenti sovrapposti — da lì in poi l'editor manuale rifiuta
ogni correzione e il CSV che la esporta non è reimportabile. In entrambi i
casi i minuti che avanzano restano sul contatore: `buildEntry` li riporta come
segmento senza posizione.

Il pavimento vale solo alla chiusura della pausa
(`TimerState.withPauseClosed`), non nel calcolo: un `lunch` di durata minore
che arriva dal portale via CSV resta quello che il portale dichiara, altrimenti
la riconciliazione dei cartellini non tornerebbe più.

`bancaOre` sostituisce la coppia `bancaOreMins` + `boeSlot` di
[ADR-0007](./0007-banca-ore-esonero.md): lo slot diventa derivabile dalla
posizione del segmento rispetto allo span.

### Invarianti

I segmenti di una giornata sono ordinati. Lo span è definito dai soli `work`
**posizionati**, e una giornata timbrata ne ha almeno uno: un `work` di sola
durata non ha un inizio da cui partire, quindi è un errore di validazione e non
una giornata da calcolare. `leave` e `bancaOre` possono cadere dentro o fuori
lo span; `lunch` e `pause` solo dentro.

La non sovrapposizione vale **fra segmenti dello stesso ruolo**: due `work`
sugli stessi minuti sono una timbratura doppia, due non-`work` la stessa pausa
contata due volte. Un segmento non-`work` **dentro** un `work` non è una
sovrapposizione ma la giornata che scrive il timer — lo span timbrato più le
pause che lo interrompono — e il calcolo lo sottrae dallo span invece di
sommarlo; la rappresentazione a `work` spezzati che arriva dal CSV del portale
dà gli stessi totali. È invece un errore di validazione lo *scavalcamento* di
un confine: mezza pausa dentro il turno e mezza fuori non è una giornata
rappresentabile. Trattare anche il contenimento come sovrapposizione rendeva
non modificabile dalla timeline ogni giornata timbrata con una pausa.

Il confronto è con **ogni singolo `work`**, non con la loro unione: una pausa
a cavallo della giunzione fra due `work` contigui (`09:00–13:00` +
`13:00–18:00` con pausa `12:45–13:15`) è quindi rifiutata pur cadendo dentro
copertura di lavoro continua. È il limite accettato di una regola locale: il
timer scrive un solo `work` sull'intero span e il CSV del portale spezza i
`work` esattamente sui confini dei segmenti non-`work`, ma l'editor della
timeline non lo impedisce — aggiungere un secondo `work` è un'azione ordinaria
dell'editor, e basta a raggiungere anche questa forma. Non si aggiunge una
guardia: la validazione condivisa la rifiuta già con un motivo preciso, chi la
incontra la risolve spezzando la pausa sulla giunzione, e fondere prima i
`work` contigui costerebbe un passaggio in più su ogni validazione per un caso
che resta raro.

Un segmento **senza posizione** resta fuori da ogni controllo: non ha un
intervallo da confrontare. La conseguenza dichiarata è che la stessa pausa può
risultare contata due volte — un `lunch` posizionato e un `lunch` di soli
minuti si sommano, e il netto scende di entrambi. È anche, di proposito, la
forma che il pavimento del pranzo e il riempimento dai contatori producono
quando l'intervallo non può contenere i 30 minuti: su un turno `13:00–18:00`
con pranzo `13:10–13:20` la giornata è
`work 13:00–18:00 | lunch 13:00–13:20 | lunch 10′`, dove i 30 minuti sono il
pavimento intero e non una pausa doppia. Sarebbe invece un errore la stessa
forma da un'altra sorgente — un CSV che dichiarasse `lunch 13:00–13:30` e
`lunch ;;0:30` sulla stessa giornata toglierebbe 60 minuti — e il modello non
sa distinguere i due casi, perché il resto di un arrotondamento e un doppione
vero hanno la stessa forma. Servirebbe un marcatore sul segmento che nessun
altro calcolo userebbe; finché le sole sorgenti di segmenti sciolti sono i
contatori del timer e le righe senza intervallo del portale, non vale il
prezzo.

Gli invarianti e la formula sono stati verificati sui cartellini reali: sulle
17 giornate del 2026 con contatori completi il calcolo coincide col portale, e
su nessuna delle 79 troncate scende sotto il minimo che il portale dichiara.

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

La forma limite della regola è un `leave` che copre l'intero span — giornata
timbrata e insieme tutta a permesso: netto zero, copertura pari allo span,
eccedenza positiva se lo span supera l'orario dovuto, e l'intera durata
addebitata al plafond della causale. Non è un caso di laboratorio: l'editor di
segmento della timeline offre tutti e cinque i tipi con selettori orari
liberi, e bastano quattro tocchi su una giornata già timbrata — pulsante di
aggiunta, tipo Permesso, gli stessi orari del lavoro, una causale — per
raggiungerla. Non si impedisce: è coerente con la griglia (il permesso copre,
non lavora), la validazione la accetta come qualunque contenimento, ed è il
motivo per cui l'uscita prevista **non** si allunga della durata del permesso:
restare oltre il dovuto durante un permesso produce eccedenza vera, e il
plafond viene scalato per intero lo stesso.

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
data;segmento;da;a;minuti;causale;periodo_da;periodo_a;nota

2026-07-23;work;10:25;12:52;;;;;Permesso visita specialistica | 0:01Maggior Presenza…
2026-07-23;leave;12:52;15:08;;specialist_visit;;;
2026-07-23;work;15:08;18:02;;;;;
2026-07-29;lunch;09:30;10:03;;;;;
2026-03-04;pause;;;0:07;;;;
2026-03-04;banca_ore;08:40;10:23;;;;;
2026-07-24;permesso_gg;;;;personal_family_hourly;;;Permesso motivi personali…
2026-03-02;permesso_gg;;;;sickness;2026-03-02;2026-03-11;Malattia
2026-07-14;ferie;;;;;;;Ferie | 1:00Ferie GG…
2026-07-03;smart_working;;;;;;;Smart Working | …
```

Il suffisso `_gg` distingue la giornata convenzionale dalla fruizione a ore,
riusando il vocabolario del portale. La nota è di giornata: vale la prima non
vuota fra le righe di quel giorno. Il controllo sulle date duplicate viene
sostituito dalla validazione delle sovrapposizioni.

`periodo_da` e `periodo_a` sono valorizzate solo sulle righe di giornata
intera con unità `period` (assenza multi-giorno, tipicamente malattia): le due
date sono l'unico contenuto di quell'unità, che non ha né minuti né giornate.
Senza queste colonne il round-trip non era lossy ma distruttivo — azzerava
`absenceMins`, `absenceDays`, il periodo e i flag, e l'import riscriveva il
documento buono con `fullOverwrite: true`.

Il formato non ha una colonna per ogni campo del modello, e non la avrà:
`countsAsSicknessPeriod` si ricava dalla causale (malattia o infortunio), come
già fa l'editor manuale, e `sensitive` dalla causale mascherata
`sensitive_leave` che l'export scrive al posto di quella vera — sia sulla riga
di giornata intera sia sul segmento `leave` di una giornata timbrata.

Le causali ammesse su un segmento `leave` sono quelle a plafond orario **più**
la maschera `sensitive_leave`: senza, l'app esportava un file che non sapeva
rileggere, e la giornata riservata con permesso intra-giornata veniva scartata
in blocco. La maschera copre l'orario dovuto come il permesso che nasconde — è
lo stesso segmento, con la causale oscurata — ma non consuma nessun plafond:
attribuirla a un istituto inventato sarebbe peggio che non contarla, e il
consumo reale resta sul documento originale. Una causale **ignota** su un
segmento `leave` scarta la giornata come una conosciuta ma non ammessa:
segnalarla e lasciar passare la giornata rendeva la restrizione aggirabile con
un errore di battitura (`leave;…;sciopero` produceva `extra +24`). Fuori dai
segmenti `leave` una causale ignota resta un errore di riga: viene segnalata,
non scritta sul documento, e la giornata entra.
**`hasDocumentation` non sopravvive al round-trip**: è un promemoria personale
che nessuna causale implica, e un CSV rimportato lo riporta a `false`. È il
limite residuo accettato: aggiungere una colonna per un flag che nessun
calcolo legge costerebbe più di quanto valga.

Un file a 7 colonne, scritto prima dell'aggiunta delle due del periodo, resta
leggibile: la posizione della nota si deduce dal numero di colonne, così i CSV
già distribuiti non vanno rigenerati.

La colonna `minuti` copre i segmenti di durata nota e posizione ignota, che
`DaySegment.mins` già rappresenta: il portale registra alcune voci senza
intervallo (una pausa di 7 minuti il 04/03/2026), e il timer scrive oggi un
segmento `leave` con i soli minuti. Un segmento senza intervallo si assume
dentro lo span, perché proviene dalla giornata timbrata — con l'eccezione di
`banca_ore`, che è un credito e non tempo trascorso: assumerlo dentro lo span
gli farebbe sottrarre due volte gli stessi minuti, una come tempo non lavorato
e una come copertura. La regola la dichiara il tipo, in
`DaySegment.insideSpanWhenUnpositioned`, ed è la stessa applicata dalla
verifica amministrativa dei dati.

### Superfici

Timer, editor e import scrivono segmenti; i campi minuti di giornata restano
esclusivamente come valore derivato da `recomputedFromSegments`. L'editor
manuale della giornata riscrive il **solo** segmento `work` dagli orari
inseriti e conserva gli altri: correggere l'orario di uscita è un'azione
ordinaria, e sostituire l'intera lista cancellava in silenzio permessi, pause
ed esoneri già registrati. I segmenti conservati sono quelli della giornata di
**destinazione**, cercata per `dateId` fra le giornate del mese già caricate:
sceglierla dal chiamante li cancellava lo stesso, perché lo sheet permette di
cambiare giorno e "Aggiungi giornata" lo apre senza nessuna giornata su un
giorno che può essere già timbrato — e la validazione non se ne accorge,
perché una lista col solo `work` è valida. La costruzione è una funzione pura
(`buildManualDayEntry`), che valida con la stessa regola dell'import e
restituisce il motivo invece di salvare una giornata non rappresentabile.
L'editor della giornata diventa una timeline che mostra la sequenza ordinata e permette di
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
  giornate già salvate con `leavePauseMins > 0`: in lettura la loro eccedenza
  sale di quei minuti. È la correzione attesa, ma i totali storici si muovono.
  La conversione è pilotata dal marcatore `extraConvention` scritto in
  `toMap`, non dedotta dalla presenza di `segments`: le versioni fra ADR-0016 e
  questa scrivono i segmenti insieme alla formula vecchia, quindi la deduzione
  lasciava non convertita la popolazione più numerosa e riconvertiva a ogni
  lettura una presenza con `segments` vuota. I CSV già generati nel formato a
  giornata vanno rigenerati.
- **Debito noto:** il cablaggio manuale fra `TimesheetScreen._save` e
  `buildManualDayEntry` non ha un test proprio — sostituire `loadedDays` con
  una lista vuota, cioè ripristinare per intero un difetto già corretto (le
  giornate del mese non ancora caricate cancellavano i segmenti non-`work`
  dell'altro giorno), lascia la suite verde lo stesso: servirebbe un finto
  Firestore, oggi assente dalle `dev_dependencies`. In `_resetEntry`
  (`lib/features/timesheet/presentation/timesheet_screen.dart`) l'eliminazione
  usa il `dateId` del giorno **selezionato** nello sheet, mentre l'azione di
  annullamento nello snackbar ripristina `widget.existingEntry`, la giornata
  con cui lo sheet è stato **aperto**: aprendolo sul 23, spostando la
  selezione al 24 ed eliminando, sparisce il 24 e l'annulla riscrive il 23.

Vedi [DailyTimesheet](../entita/daily-timesheet.md) e
[Timesheet](../funzionalita/timesheet.md).

_Ultima revisione: 2026-07-31._
