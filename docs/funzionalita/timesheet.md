# Feature: Timesheet (calendario mensile)

## Scopo

Visualizza e gestisce il registro mensile delle giornate lavorate con 3 viste
(Lista / Settimana / Mese), widget contatori mensili, alert giornate
mancanti, inserimento manuale, causali assenza personali, import/export CSV e
PDF.

## File coinvolti

| Path | Ruolo |
|---|---|
| `lib/features/timesheet/presentation/timesheet_screen.dart` | UI completa (3 viste + sheet inserimento) |
| `lib/features/timesheet/data/timesheet_repository.dart` | `monthlyTimesheetsProvider` + `saveDailyTimesheet` + `saveRemoteWorkDay` |
| `lib/features/timesheet/domain/daily_timesheet.dart` | Entità `DailyTimesheet` con `WorkType` |
| `lib/features/timesheet/domain/absence_kind.dart` | Tassonomia assenze personali allineata ai docs CCNL |
| `lib/features/timesheet/data/csv_export_service.dart` + `csv_import_service.dart` | CSV semplice/dettagliato con colonne `assenza_*` |
| `lib/features/timesheet/data/pdf_export_service.dart` | PDF mensile standard + cartellino ufficiale PCM |
| `lib/shared/widgets/monthly_summary_card.dart` | Widget blu contatori (condiviso con Dashboard) |

## 3 viste

Il selettore in cima (`_ViewSelector`) è un Row compatto (non stretched, `mainAxisSize: min`) con pillole a padding ridotto:

| Enum | Label | Icona |
|---|---|---|
| `_ViewMode.list` | Lista | `list_rounded` |
| `_ViewMode.week` | Settimana | `calendar_view_week_rounded` |
| `_ViewMode.month` | Mese | `calendar_month_rounded` |

Default: `_ViewMode.list`. Ogni vista mostra il `MonthlySummaryCard` in cima (stesso widget della Dashboard, con nav mese attiva).

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

Logica:
- `remote` → `saveRemoteWorkDay(stdMins)`.
- `presence` → `netWorkedMins = (uscita − entrata − 30m lunch).clamp(0, ∞)`.
- `leave / holiday` → `netWorkedMins = 0`, con eventuali campi
  `absenceKind`, `absenceUnit`, `absenceMins`, `absenceDays`, `periodStart`,
  `periodEnd`, `quotaYear`, `sensitive`, `hasDocumentation`, `personalNote`.

## Widget contatori (`MonthlySummaryCard`)

Stesso widget della Dashboard. Legge le preferenze utente (`summaryItems`, `summaryShowProgress`) da `profileData` e passa a `MonthlySummaryCard`. Include nav mese (← / →) e tap sul mese per picker.

## Navigazione mensile

`_prevMonth` / `_nextMonth` aggiornano `_year` + `_month` + reset `_selectedDay`. La navigazione settimana (`_prevWeek` / `_nextWeek`) aggiorna anche `_year` e `_month` se la settimana attraversa un confine mensile.

## Menu ⋮ (azioni sul mese)

| Voce | Azione |
|---|---|
| Esporta PDF | `_exportPdf` → `PdfExportService.exportMonth` con `mealThresholdMins` da profilo |
| Cartellino PCM | `_exportOfficialCartellino` → PDF layout PCM con header ente/dipendente/sede e tabella 11 colonne |
| Importa CSV | `_importCsv` → `CsvImportService.pickAndParse`, dialog avvisi, salva tutte le entry |
| Scarica template CSV | `_showCsvTemplate` → bottom sheet con `SelectableText` del template + pulsante "Copia" (`Clipboard.setData`) |

### Template CSV

Formato semicolon-separated, colonne:
`data;tipo;entrata;uscita;nota;assenza_tipo;assenza_min;assenza_giorni;periodo_da;periodo_a`.
`tipo` accetta: `presenza`/`p`, `smart_working`/`sw`, `ferie`/`f`, `permesso`/`l`.
Le colonne `assenza_*` sono opzionali e validate contro `AbsenceKind`.
Il template è disponibile in `AppStrings.csvTemplateContent`.

## Note

- `mealThreshold` letto da `userProfile.mealVoucherThresholdMins` (default 380).
- I limiti query Firestore sono lessicali su `dateId`; invariante: `MM` e `DD` sempre zero-padded.

## Nota attività

`DailyTimesheet` ha un campo opzionale `note: String?`. Se presente e non vuoto:
- Visualizzata in corsivo sotto le info orario nella **lista giornaliera** (max 2 righe, ellipsis).
- Stessa visualizzazione prevista in vista Settimana e dettaglio giornaliero.
- Salvata via `TimesheetRepository.saveNote(dateId, note)` dalla Dashboard.

_Ultima revisione: 2026-06-07 — aggiunte causali assenza, CSV `assenza_*` e cartellino PCM._
