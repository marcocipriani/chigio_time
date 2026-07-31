# Feature: Timesheet (calendario mensile)

## Scopo

Visualizza e gestisce il registro mensile delle giornate lavorate con 5 viste
(Giorno / Lista / Settimana / Mese / Anno), widget contatori mensili, alert giornate
mancanti, inserimento manuale, causali assenza personali, import/export CSV e
PDF.

## File coinvolti

| Path | Ruolo |
|---|---|
| `lib/features/timesheet/presentation/timesheet_screen.dart` | UI completa (5 viste + sheet inserimento) |
| `lib/features/timesheet/presentation/day_timeline.dart` | `DayTimeline` — timeline dei segmenti dentro il dettaglio giornata |
| `lib/features/timesheet/presentation/segment_editor_sheet.dart` | `showSegmentEditor` — bottom sheet di un singolo segmento |
| `lib/features/timesheet/data/timesheet_repository.dart` | `monthlyTimesheetsProvider` + `saveDailyTimesheet` + `saveRemoteWorkDay` |
| `lib/features/timesheet/domain/daily_timesheet.dart` | `DailyTimesheet`, ricalcolo e compatibilità |
| `lib/features/timesheet/domain/day_segment.dart` | Intervalli di lavoro e permessi orari |
| `lib/features/timesheet/domain/absence_kind.dart` | Tassonomia assenze personali allineata ai docs CCNL |
| `lib/features/timesheet/data/csv_export_service.dart` + `csv_import_service.dart` | CSV semplice a segmenti (ADR-0018, simmetrico import/export) + CSV dettagliato di analisi |
| `lib/features/timesheet/data/pdf_export_service.dart` | PDF mensile standard + cartellino ufficiale PCM |
| `lib/shared/widgets/monthly_summary_card.dart` | Widget contatori in stile glass S-19 (condiviso con Dashboard) |

## 5 viste

Il selettore in cima (`_ViewSelector`) è un Row compatto (non stretched, `mainAxisSize: min`) con pillole a padding ridotto:

| Enum | Label | Icona |
|---|---|---|
| `_ViewMode.day` | Giorno | `calendar_today_rounded` |
| `_ViewMode.list` | Lista | `list_rounded` |
| `_ViewMode.week` | Settimana | `calendar_view_week_rounded` |
| `_ViewMode.month` | Mese | `calendar_month_rounded` |
| `_ViewMode.year` | Anno | `grid_view_rounded` |

Default: `_ViewMode.list`. Ogni vista mostra il `MonthlySummaryCard` in cima (stesso widget della Dashboard, con nav mese attiva). Su schermi stretti (< 600px) le pillole del selettore hanno larghezza proporzionale al testo (flex su `label.length`) per evitare l'overflow di "Settimana".

### Vista Giorno

- Navigatore giorno: chevron ◀ ▶ ai bordi; dentro la barra, a sinistra il
  tasto "↩ Oggi" (nascosto se già su oggi), al centro il titolo, a destra il
  profilo orario da fare quel giorno (es. `7:36`, da `standardDailyMins`;
  nascosto per weekend/festivi).
- Nessuna barra quick-add (Presenza/SW/Ferie/Permesso): la giornata vuota si
  aggiunge col FAB `+`. Resta la sezione note.
- Sotto il riepilogo, dentro `_DayDetailCard` e sopra la sezione nota, la
  **timeline della giornata** (`DayTimeline`): vedi sotto.

### Timeline della giornata (`DayTimeline`)

Compare solo per le giornate di presenza: ferie e permessi di giornata intera
non hanno segmenti orari — il loro consumo vive sui campi di giornata, e un
segmento `leave` con causale farebbe sparire la quota dai contatori, che
privilegiano i segmenti — e lo smart working ha un orario dichiarato che il
ricalcolo falserebbe applicandogli la pausa pranzo forzata. La condizione è
`DayTimeline.showsFor`, un metodo del widget: la schermata la chiama e il
widget si nasconde comunque, così nessun nuovo punto di innesto può
riaprire il caso. Mostra una riga
per segmento nell'ordine in cui la giornata è stata vissuta — i segmenti senza orari in coda — più una riga `Non coperto · N min`
per ogni buco fra due segmenti posizionati consecutivi.

Ogni riga porta: barra colorata ed emoji del tipo, etichetta
(`DaySegment.labelFor`), la causale leggibile (`AbsenceKind.labelFor`) per i
`leave`, l'intervallo `HH:MM – HH:MM` (o `N min` quando il segmento non è
posizionato) e un tasto di eliminazione con tooltip "Elimina segmento".

Flusso di modifica:

1. Tap sulla riga → `showSegmentEditor` con il segmento; tap su "Aggiungi
   segmento" → lo stesso sheet senza segmento iniziale. Lo sheet ha selettore
   del tipo fra i cinque, i due TimePicker da/a, un campo durata usato solo
   quando gli orari sono vuoti e — solo per `leave` — il selettore di causale
   raggruppato, limitato alle causali a plafond orario
   (`AbsencePlafonds.limitFor(...) == AbsenceLimit.hourly`) più quella già
   impostata sul segmento. Il selettore ore/giornata non c'è: la giornata
   convenzionale è una proprietà della giornata, non di un segmento.
2. La lista risultante passa per `DaySegment.validationError`, **la stessa
   regola che usa il parser di import**: niente sovrapposizioni (nemmeno per
   contenimento), `lunch` e `pause` dentro lo span dei `work`, almeno un
   segmento `work`. Se la regola non passa, la modifica non viene emessa e il
   motivo compare in una SnackBar: quello che l'import rifiuta l'interfaccia
   non lo salva.
3. `DayTimeline` non tocca Firestore: emette la lista via `onChanged`.
   `_DayDetailCard` la applica con `copyWith(segments:)`, chiama
   `recomputedFromSegments(stdMins:)` con l'orario standard del profilo per
   quella data (`AppConstants.stdMinsForDate`) e salva con
   `timesheetRepositoryProvider.saveDailyTimesheet`. Netto ed eccedenza non
   sono mai scritti a mano. Vedi
   [ADR-0018](../decisioni/0018-permessi-orari-nella-giornata.md).

### Vista Lista

- Layout: `Column` con `MonthlySummaryCard` **pinned** (non scorre) + `Expanded(ListView.builder(...))` sotto — i contatori restano visibili mentre la lista scorre.
- **Auto-scroll a oggi**: al primo render del mese corrente, `WidgetsBinding.addPostFrameCallback` calcola l'offset `(today.day - 1) × 62.0 px` e chiama `animateTo(offset, 450ms, easeOutCubic)`. Un flag `_listScrollKey` (`'YYYY-M'`) impedisce lo scroll automatico se l'utente ha già navigato nel mese.
- Ogni riga: numero giorno + nome giorno abbreviato, info turno (orari, tipo, ore nette) + badge 🍽️ e badge straordinario.
- **Alert giornate mancanti**: giorni feriali passati senza entry mostrano bordo arancio + sfondo arancio tenue + ⚠️. I chip Presenza/SW restano cliccabili per inserimento retroattivo.
- Pulsante `+` in alto a destra → apre `_EntrySheet`.

### Vista Settimana

- Card con nav settimana (← / →) + 7 pillole giorno.
- Selezionare un giorno mostra `_DayDetailCard` o `_EmptyDayQuickAdd`.
- "Sett. WW" sopra il range date.

### Vista Mese (calendario)

- Griglia 7 colonne con dot colorati per `workType`.
- Desktop (≥ 800px): split view — lista giorni a sinistra (260px), calendario a destra.
- `+` in alto → `_EntrySheet`.

### Dot colorati

| Colore | Condizione |
|---|---|
| 🔵 Blu | `workType == remote` |
| 🟢 Verde | `workType == presence`, `extraMins == 0` |
| 🟠 Arancione | `workType == presence`, `extraMins > 0` |
| ⚫ Grigio | `workType == leave ∥ holiday` |

## Inserimento manuale (`_EntrySheet`)

`showModalBottomSheet` aperto dal `+` o dalla quick-add card.

Campi principali:
1. **Giorno** — DatePicker limitato al mese corrente.
2. **Tipo** — chip: Presenza / Smart Working / Permesso / Ferie.
3. **Entrata / Uscita** — TimePicker (solo per Presenza).
4. **Causale assenza** — se `Tipo == Permesso/Ferie`, picker raggruppato da
   `AbsenceKind.groups`.
5. **Unità assenza** — ore/giorni/periodo in base alla causale.
6. **Privacy/documentazione** — switch "Assenza riservata" e "Documentazione
   presente", nota privata.
7. Pulsante "Salva giornata".

Per le giornate miste il form gestisce una sequenza di segmenti lavoro o
permesso. Gli estremi, i minuti lavorati e il deficit sono ricalcolati dal
modello; i documenti storici vengono derivati in lettura. Vedi
[ADR-0016](../decisioni/0016-segmenti-giornalieri.md).

Logica:
- `remote` → `saveRemoteWorkDay(stdMins)`.
- `presence` → gli orari inseriti diventano un segmento `work` e la giornata
  passa da `recomputedFromSegments(stdMins:)`, come timer e import
  (ADR-0018): pausa pranzo dalla regola delle 9 ore, netto ed eccedenza mai
  scritti a mano. Il segmento non è un dettaglio della timeline: senza,
  la scrittura in merge lascerebbe su Firestore i segmenti precedenti e il
  primo tocco sulla timeline riporterebbe gli orari vecchi.
- `leave / holiday` → `netWorkedMins = 0`, con eventuali campi
  `absenceKind`, `absenceUnit`, `absenceMins`, `absenceDays`, `periodStart`,
  `periodEnd`, `quotaYear`, `sensitive`, `hasDocumentation`, `personalNote`.

## Widget contatori (`MonthlySummaryCard`)

Stesso widget della Dashboard, in stile glass S-19 (`GlassCard`, niente più header blu pieno; testi theme-aware). Legge le preferenze utente (`summaryItems`, `summaryShowProgress`) da `profileData` e passa a `MonthlySummaryCard`. Include nav mese (← / →) e tap sul mese per picker. Badge SW mensile e annuale con icona 🖥.

La voce **Art.9** mostra le ore di maggior presenza: straordinario del mese
clampato al cap `monthlyArt9Hours` (waterfall come la Dashboard), **non** le
pause permesso (`leavePauseMins`, che sono Art. 35).

## Navigazione mensile

`_prevMonth` / `_nextMonth` aggiornano `_year` + `_month` + reset `_selectedDay`. La navigazione settimana (`_prevWeek` / `_nextWeek`) aggiorna anche `_year` e `_month` se la settimana attraversa un confine mensile.

## Menu ⋮ (azioni sul mese)

| Voce | Azione |
|---|---|
| Esporta PDF | `_exportPdf` → `PdfExportService.exportMonth` con `mealThresholdMins` da profilo |
| Cartellino PCM | `_exportOfficialCartellino` → PDF layout PCM con header ente/dipendente/sede e tabella 11 colonne |
| Importa CSV | `CsvImportService.pickAndParse` → anteprima delle righe valide, avvisi e conteggio sovrascritture; salva solo dopo conferma |
| Scarica template CSV | `CsvExportService.downloadTemplate()` → file CSV preformattato |

### Template CSV — formato a segmenti (ADR-0018)

Import ed export usano lo stesso formato semicolon-separated, colonne:
`data;segmento;da;a;minuti;causale;nota`. Più righe compongono una giornata:

- **Segmenti orari** (`da`/`a` valorizzati, o `minuti` quando la posizione è
  ignota): `work`, `leave`, `lunch`, `pause`, `banca_ore`.
- **Righe di giornata intera** (`da`/`a`/`minuti` vuoti): `ferie`,
  `smart_working`, `permesso`, `permesso_gg` (il suffisso `_gg` distingue la
  giornata convenzionale dalla fruizione a ore).

`causale` è opzionale e validata contro `AbsenceKind`. Su un segmento `leave`
sono ammesse solo le causali a plafond orario (`AbsencePlafonds.isHourlyLeave`,
la stessa regola dell'editor): un `leave;strike` coprirebbe l'orario dovuto,
l'opposto della griglia dell'ADR, quindi la giornata viene scartata invece di
essere importata sbagliata. Un intervallo con `a <= da` è rifiutato: passava, e
produceva una giornata segnaposto `09:00–09:00` che sovrascriveva quella buona.
`nota` è di giornata:
vale la prima non vuota fra le righe di quel giorno. Una giornata riservata
(`sensitive == true`) esporta la causale mascherata (`AbsenceKind.sensitiveLeave`)
e nessuna nota, in tutte le righe di quel giorno.

`CsvExportService.downloadTemplate()` scarica un file d'esempio in questo
stesso formato. Segmenti sovrapposti o incompleti vengono scartati e
segnalati nell'anteprima; le giornate già presenti sono contate prima della
conferma e vengono sostituite con overwrite completo, evitando campi obsoleti.
Vedi [ADR-0018](../decisioni/0018-permessi-orari-nella-giornata.md#formato-csv).

## Note

- `mealThreshold` letto da `userProfile.mealVoucherThresholdMins` (default 380).
- I limiti query Firestore sono lessicali su `dateId`; invariante: `MM` e `DD` sempre zero-padded.

## Cache locale (Drift)

`TimesheetRepository` scrive ogni giornata anche nella tabella Drift
`timesheetEntries` (write-through, `unawaited`: un errore di cache non fa
fallire il salvataggio remoto ed è solo loggato). La cache viene letta **solo**
nel fallback offline di `watchMonthlyTimesheets`, quando lo stream Firestore
va in errore.

La lettura è volutamente tollerante: un timestamp corrotto degrada a
`dateId` e poi all'epoch, un payload `segments` non valido degrada a lista
vuota. Una riga rotta non deve mai far sparire il mese
(`test/features/timesheet/cache_row_test.dart`).

> **Buco noto.** La tabella ha le colonne `absenceKind`, `absenceUnit`,
> `absenceMins`, `absenceDays`, `periodFrom`/`periodTo`, `quotaYear`,
> `sensitive`, `hasDocumentation`, `countsAsSicknessPeriod`, ma né
> `_toCompanion` né `_fromRow` le leggono o le scrivono: nel fallback offline
> una giornata di permesso/ferie perde causale, minuti, periodo e flag
> riservata, e i contatori personali calcolati su quel mese risultano a zero.
> Online non si nota, perché Firestore è la fonte autorevole. Da chiudere
> mappando i campi in entrambe le direzioni (attenzione: `quotaYear` è
> `double?` nella tabella e `int?` nel dominio).

## Nota attività

`DailyTimesheet` ha un campo opzionale `note: String?`. Se presente e non vuoto:
- Visualizzata in corsivo sotto le info orario nella **lista giornaliera** (max 2 righe, ellipsis).
- Stessa visualizzazione prevista in vista Settimana e dettaglio giornaliero.
- Salvata via `TimesheetRepository.saveNote(dateId, note)` dalla Dashboard.

_Ultima revisione: 2026-07-31 — CSV import/export riallineati al formato a
segmenti (ADR-0018)._
