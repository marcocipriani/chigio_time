# Widget Inventory — chigio_time

> Aggiornato 2026-06-11. Aggiornare ad ogni aggiunta/rimozione di widget significativi.

---

## Dashboard (`funzionalita/dashboard/`)

| Widget | File | ✅ Forza | ⚠️ Debolezza |
|---|---|---|---|
| **TimbraturaHero** | `widgets/timbratura_hero.dart` | Hero 3 fasi: Chigio grande a sinistra, long-press entra/esci, barre giornata/BP con gate 9h, resoconto giornaliero; assorbe saluto+campanella+avatar in Home (sostituisce `ShiftRing` e `_TimbraturaBarra`, rimossi 2026-07) | Nessun slot BOE visivo sulle barre |
| **_MaggiorPresenzaCard** | `dashboard_screen.dart` | Month-switcher, barra segmentata Art.9/SLI/SBO, chip breakdown | Non aggiornata live; barra dipende da fetch mensile; nessun drill-down giornaliero |
| **FavoriteColleaguesCard** | `widgets/favorite_colleagues_card.dart` | Quick action caffè/chiama verso colleghi preferiti | Preferiti dipendono da dati profilo/social già popolati |
| **_HomeCountersRow** | `dashboard_screen.dart` | Strip compatta con tutti i contatori custom; empty state + CTA se nessuno; long-press su un chip apre l'editor inline (`showCounterEditSheet`) | Nessun riordino drag dei chip |
| **PcmRoutePlannerCard** | `widgets/pcm_route_planner_card.dart` | Widget interattivo con dropdown sedi, modalità percorso e apertura Maps | Stima locale indicativa, non traffico reale |
| **OrariTableCard** (S-19) | `widgets/orari_table_card.dart` | Tabella orari come widget: variante auto da `stdMinsForDate` del giorno + selettore | Righe statiche (griglia 7:30→21:00 a passi 15') |
| **PomodoroCard** (S-19) | `widgets/pomodoro_card.dart` | Timer live (countdown+barra+fase) o avvio rapido 25/5·45/15; tap → `/projects` | Dipende da un progetto esistente |
| **SalaryCard** (S-19) | `widgets/salary_card.dart` | Countdown accredito + stima netto ultimi 3 ordinari; tap → `/salary` | Stima empirica, non da lordo |
| **HomeWidgetHeader / HomeWidgetEmpty** (S-19) | `shared/widgets/home_widget_header.dart` | Header uniforme (mini-Chigio) + empty state con CTA condivisi | — |
| **BancaOreTile** | `widgets/totalizzatori_section.dart` | Mostra AC/AP, totale fruibile, edit button e delta live BOE | Reconciliation con portale ancora manuale |
| **TotAlertBanner** | `widgets/totalizzatori_section.dart` | Alert condizioni critiche portale superate | Tutto da `portaleJson`, non da import HTTP |
| **TotalizzatoriSection** | `widgets/totalizzatori_section.dart` | Copertura completa metriche portale, quick-edit per chip | Inserimento/aggiornamento manuale |
| **CustomCountersSection** | `widgets/totalizzatori_section.dart` | Flessibile, personalizzabile dall'utente | Nessun template multi-ente oltre PCM |
| **_NoteSection** | `dashboard_screen.dart` | Funzionale, salva su Firestore | Nessun link a tipo giornata o BOE |
| **_NineHourBanner** | `dashboard_screen.dart` | Avverte soglia 9h Art.9 | Soglia non collegata al cap SBO/SLI mensile utente |
| **_AbandonedBadge / Cta** | `dashboard_screen.dart` | Edge case giornata non timbrata gestito | Nessun suggerimento BOE su giornata in deficit |
| **_GpsPromptCard** | `dashboard_screen.dart` | UX originale auto clock-in geofencing | Solo entrata; nessun geofence su uscita |
| **_SmartWorkingBtn** | `dashboard_screen.dart` | One-tap smart working | Orario fisso 9:00–17:06; non usa orario settimanale personalizzato |
| **_LiveBadge / _PauseBadge / _CompletedBadge** | `dashboard_screen.dart` | Badge stato turno chiari | — |
| **_MealBadge / _MealProgress** | `dashboard_screen.dart` | Soglia buono pasto con progress live | — |
| **_OrariTableSheet** | ~~`dashboard_screen.dart`~~ | Rimosso in S-19: sostituito dal widget `OrariTableCard` | — |

---

## Timesheet (`funzionalita/timesheet/`)

| Widget | File | ✅ Forza | ⚠️ Debolezza |
|---|---|---|---|
| **_GlassToolbar** | `timesheet_screen.dart` | Glass compatto Apple-style, pills vista + 3 icone inline | Nessun filtro rapido per tipo giornata |
| **_DayDetailCard** | `timesheet_screen.dart` | Mostra tutti i campi calcolati, tasto edit | Non mostra BOE usage se presente |
| **_EntrySheet** | `timesheet_screen.dart` | Gestisce tipi giornata, assenze classificate, privacy/export, pre-popola da entry esistente | Malattia/comporto e residui CCNL ancora solo fondazione dati |
| **_EmptyDayQuickAdd** | `timesheet_screen.dart` | Quick-add chip per giorni senza timbratura | Nessun chip dedicato malattia/congedi avanzati |
| **_DayNoteSection** | `timesheet_screen.dart` | Note editabili su giorni passati; pulsante Salva visibile solo a testo modificato (dirty-check) | — |
| **_ImportSheet** | `timesheet_screen.dart` | Azioni import/template in bottom sheet | — |
| **MonthlySummaryCard** | `shared/widgets/monthly_summary_card.dart` | Configurabile, progress bar Art.9/SLI/SBO/OP; badge SW mensile e annuale nell'header | SBO accumulato ≠ banca ore residua; consumo BOE non modellato |

---

## Shared / Infrastruttura

| Widget | File | ✅ Forza | ⚠️ Debolezza |
|---|---|---|---|
| **GlassHeader** | `shared/widgets/glass_header.dart` | Chigio avatar, label breve, frase dinamica contestuale, bell notifiche, avatar profilo (non più montato in Home: lì è assorbito da `TimbraturaHero`) | Frase visiva verificata staticamente; screenshot browser non sempre disponibile |
| **FloatingNav** | `shared/widgets/floating_nav.dart` | Pill animata, sliding indicator fluido | Solo 3 tab fissi; stats/Chigio solo da profilo |
| **GlassCard / GlassTile** | `shared/widgets/glass_card.dart` | Design system glass coerente | Manca variante "selected/active" |
| **GlassBtn** | `shared/widgets/glass_button.dart` | Reusable, touch-friendly | — |
| **AppBackground** | `shared/widgets/app_background.dart` | Gradiente coerente su tutti gli schermi | — |
| **DayCheckpoints** | `shared/widgets/day_checkpoints.dart` | Timeline semantica giornata | 5 step hardcoded; BOE sarebbe un 6° step opzionale |

---

## Gap trasversale aggiornato

BOE e assenze hanno ora una fondazione dati/UI. Restano da sviluppare:

1. Import automatico HTTP dei totalizzatori portale.
2. Backfill assenze storiche con `absenceKind`.
3. Calcolo personale malattia/comporto e residui per causali CCNL.
4. Visualizzazione BOE più esplicita nelle barre di `TimbraturaHero`.

Vedi [`../decisioni/0007-banca-ore-esonero.md`](../decisioni/0007-banca-ore-esonero.md),
[`../ccnl/permessi-assenze-congedi.md`](../ccnl/permessi-assenze-congedi.md)
e [`../ROADMAP.md`](../ROADMAP.md).
