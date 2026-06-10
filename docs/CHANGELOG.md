# CHANGELOG della wiki e delle modifiche tracciate da Claude Code

## 2026-06-10 — Profilo riorganizzato, drag fix, attività dirty, foto colleghi, SAU

- **feat** — `profile_screen.dart`: sezionamento in 6 sezioni — Card personale (avatar tappabile), Inquadramento e orario, Statistiche (+link /stats), Funzionalità (GPS), Opzioni app, CCNL, Info app. CCNL spostato prima di Info app. Privacy spostata in Info app.
- **feat** — `profile_screen.dart`: card avatar tappabile → naviga a `/profile/edit` (nuova schermata dati personali). Badge edit blu in basso a destra.
- **feat** — `ProfileEditScreen` aggiunta in `profile_screen.dart`: schermata dedicata per nome, genere, ente, dipartimento, sede, piano, stanza, interno, telefono, stato del giorno.
- **feat** — `app_router.dart`: rotta `/profile/edit` collegata a `ProfileEditScreen`.
- **feat** — `profile_screen.dart`: card Inquadramento separata con tipo contratto, orario (variante), ore standard, orario settimanale, soglia buono pasto, Art.9, SLI, SBO, SAU (calcolato = SLI+SBO, read-only), cap straordinari.
- **feat** — `app_strings.dart`: aggiunte costanti `sectionInquadramento`, `sectionFeatures`, `sauMonthly`, `seeAllGraphs`, `editPersonalDetails`, `personalDetails`, `appFeaturesGps`, `appInfoFull`, `editDay`.
- **feat** — `app_strings.dart`: `appInfoBody` aggiornato con elenco funzionalità complete.
- **feat** — `profile_screen.dart/_showHomeWidgetsCustomizer`: drag handle ora usa `ReorderableDragStartListener` — trascina solo dalla maniglia, non da tutta la riga.
- **feat** — `dashboard_screen.dart/_NoteSectionState`: pulsante Salva visibile solo quando il testo attività è stato modificato (`_dirty = _ctrl.text != _originalText`). Reset `_originalText` dopo salvataggio.
- **feat** — `dashboard_screen.dart`: pulsante "Nuova giornata" sostituito con "Modifica giornata" (→ naviga a `/timesheet` per correggere timbrature sbagliate).
- **feat** — `colleague.dart`: campo `photoURL` aggiunto a `ColleagueProfile`.
- **feat** — `social_repository.dart`: `photoURL` mappato da Firestore in `watchColleagues`.
- **feat** — `social_screen.dart/_SocialAvatar`: mostra `Image.network` se `photoURL` disponibile, fallback a iniziali. Propagato a tutti e 3 i call site con ColleagueProfile.
- **feat** — `profile_repository.dart`: `syncPhotoUrl` salva `photoURL` su Firestore. `saveOnboardingData` include `photoURL` da Firebase Auth se presente.
- **feat** — `login_screen.dart`: dopo Google sign-in chiama `syncPhotoUrl` fire-and-forget.
- **fix** — `main.dart`: font pre-loading con `GoogleFonts.pendingFonts` (già committato).

## 2026-06-10 — Font pre-loading per eliminare warning Noto su CanvasKit web

- **fix** — `main.dart`: aggiunto `GoogleFonts.pendingFonts([...])` prima di `runApp()`. Pre-carica Plus Jakarta Sans (4 pesi), NotoColorEmoji, NotoSansSymbols2 per eliminare "Could not find a set of Noto fonts" su CanvasKit. Wrapped in `try-catch` per resistere a avvio offline.

---

## 2026-06-10 — Schedule CCNL refactor, profilo cleanup, widget reorder, anno dots

- **feat** — `app_constants.dart`: aggiunti `stdDailyMinsRuoloShort=400`, `stdDailyMinsComandoShort=360`, `stdDailyMinsLong=540`, `weeklyMinsRuolo/Comando`, `art9MonthlyCapMins*`, `scheduleUniform/Mixed`, helper `stdMinsForDate(profile, date)`.
- **fix** — `app_strings.dart`: `mealMinsByType` restituisce 380 per tutti i tipi (era 360 per Comando). Aggiunte stringhe `scheduleVariant*`.
- **feat** — `onboarding_provider.dart`: campi `scheduleVariant` e `longWorkDays` in `OnboardingState`; metodi `setScheduleVariant`, `toggleLongWorkDay`; `setEmploymentType` resetta variant+days.
- **feat** — `onboarding_screen.dart`: step 5 per Ruolo/Comando mostra picker variante orario (uniforme/misto 3+2) + selezione 2 giorni lunghi (lun–ven); validazione 2 giorni se misto. Widget `_VariantChip`.
- **feat** — `profile_repository.dart`: `saveOnboardingData` persiste `scheduleVariant` e `longWorkDays` su Firestore.
- **fix** — `timer_provider.dart`: `standardWorkMins` ora calcolato via `AppConstants.stdMinsForDate(profile, today)` invece di leggere `standardDailyMins` statico.
- **fix** — `dashboard_screen.dart`: `mealMins` rimossa formula proporzionale (era `stdMins*380/456`); ora costante 380 per tutti.
- **fix** — `totalizzatori_section.dart`: campo `standardWorkMins` → `standardDailyMins`.
- **fix** — `timesheet_screen.dart`: `_save()` usa `stdMinsForDate(profile, base)` + `.clamp().toInt()`; aggiunto import `app_constants.dart`.
- **feat** — `profile_screen.dart`: riga `scheduleVariant` (con giorni lunghi) dopo employmentType per Ruolo/Comando; bottom sheet `_editScheduleVariant` con variant chip + day picker.
- **feat** — `timesheet_screen.dart/_MiniMonthGrid`: dot anno più piccoli (0.62 da 0.76), numero del giorno visibile dentro ogni dot.
- **feat** — `profile_screen.dart/_showHomeWidgetsCustomizer`: `ReorderableListView` + checkbox per ogni widget; salva `homeWidgetsOrder` su Firestore.
- **feat** — `dashboard_screen.dart`: legge `homeWidgetsOrder` da Firestore e renderizza widget nell'ordine salvato via `switch` pattern.
- **refactor** — `profile_screen.dart`: rimossi stat items (record, uscite, SW) dalla card avatar; rimosso link "Statistiche avanzate →"; stats disponibili solo in `/stats`. Rimossi `_StatItem`, `maxMins`, `latestEnd`, `earliestEnd`, `swDays`, `fmtEnd`, `fmtMax`, `monthlyEntries`.

---

## 2026-06-10 — Sprint completato: 23 task (H0–H6, T2–T4/Tbug/Tcheck, S1–S5, P1–P6, I1–I2)

- **fix** — `timesheet_screen.dart/_save()`: tre `456` hardcoded → `stdMins` da profilo (Tbug).
- **fix** — `firestore.rules`: regola `notifications/{notifId}` consente self-write per `exit_reminder`; `functions/index.js`: aggiunto `case 'exit_reminder'` in `_buildNotification` (I1).
- **feat** — `social_screen.dart` + `colleague.dart` + `social_repository.dart`: campo `statusMessage` in `ColleagueProfile`; visualizzato in `_ColleagueCard` e `_ColleagueDetailSheet` (S4).
- **feat** — `profile_screen.dart/_NotificationSheet`: toggle DND + picker fascia oraria `silenceFrom`/`silenceTo` (P1).
- **feat** — `social_screen.dart/_ColleagueDetailSheet`: bottom sheet con `DraggableScrollableSheet`, info collega, storico caffè filtrato per uid (S3).
- **feat** — `profile_screen.dart/_showHomeWidgetsCustomizer` + `dashboard_screen.dart`: toggle 6 widget; lista `hiddenHomeWidgets` su Firestore; dashboard legge e nasconde (P6).
- **feat** — `timesheet_screen.dart`: pill "Anno" nel selettore viste; `_YearView` + `_MiniMonthGrid` con dot colorati per tipo (T3).
- **feat** — `dashboard_screen.dart/_SmartExitScenarios`: 3 chip uscita (giornaliero/+1h/mensile); deficit mensile calcolato da giorni lavorativi trascorsi (H4).
- **feat** — `profile_screen.dart/_NotificationSheet` + `functions/index.js`: notifica mattutina colleghi (`morningColleaguesHour`) e recap settimanale (`weeklyRecapDay`/`Hour`) (S2, P2).
- **feat** — `profile_screen.dart/_downloadMyData()`: export GDPR — profilo JSON + timesheets CSV + notifiche JSON via `share_plus`; web usa `XFile.fromData` (P4).
- **feat** — `profile_screen.dart`: 4 sezioni con `_SectionLabel` (Card personale / Statistiche / Opzioni app / Info app); `_OtTrendCard` spostata in Statistiche; appInfo/chigio in card separata (P5).
- **feat** — `dashboard_screen.dart/_TimbraturaBarra`: barra progress orizzontale con 3 gate (Art.9/BP/FS) integrata nel heroCard; import `day_checkpoints.dart` e rendering separato rimossi (H0).
- **feat** — `social_screen.dart/_AddColleagueSheet`: sezione link — condividi URL `chigiotime.web.app/add?uid=…` via `share_plus`/clipboard; campo paste link/UID con parsing query param + regex (S5).
- **feat** — `app_database.dart`: schema v4, 10 nuove colonne assenza in `TimesheetEntries` + migrazione `from < 4` con ALTER TABLE (I2).
- **fix** — `pdf_export_service.dart`: note mascherate con `'—'` quando `e.sensitive`; entrata/uscita mostrate come `'—'` per ferie e permessi giornalieri (Tcheck).
- **docs** — `docs/ROADMAP.md`: tutte le 23 task del sprint spostate in "✅ Completato" con data 2026-06-10; sezione "Prossimo sprint" svuotata.

---

## 2026-06-10 — Dashboard cleanup: remove widget blu, OPE sempre visibile, roadmap H0/H6/P6

- **feat** — `dashboard_screen.dart`: rimossa `MonthlySummaryCard` (widget blu) dalla statsSection. Rimosse anche le variabili non più usate nel build: `totalNetMins`, `totalOtMins`, `art9UsedMins`, `sliUsedMins`, `sboUsedMins`, `orePerseMins`, `mealCount`, `art9Cap`, `otCap`, `mealThreshold`, `sliCap`, `sboCap`, `visibleItems`, `showProgressBars`. Rimossa importazione `monthly_summary_card.dart` e `showCountersCustomizer` dall'import `profile_screen.dart`.
- **feat** — `dashboard_screen.dart/_MaggiorPresenzaCard`: chip OPE ora sempre visibile quando `totalCap > 0` (anche a 0h/no sforamento); colore `neutral400` quando OPE = 0, `red700` quando OPE > 0.
- **docs** — `docs/ROADMAP.md`: aggiunto H0 (barra timbratura con cancelli orari, redesign heroCard + DayCheckpoints), H6 (tempi istituzionali spostamenti PCM in `PcmRoutePlannerCard`), P6 (visibilità widget Home personalizzabile da Profilo). Aggiunte righe ✅ per le due feature completate oggi.

---

## 2026-06-10 — Roadmap sprint review

- **roadmap** — `docs/ROADMAP.md`: revisione sprint per pagina. H1 semplificato (rimossa previsione smaltimento, aggiunto calcolo giorni coperti da BOE). H4 espanso (3 scenari SmartExit: pareggio giornaliero, pareggio mensile, ora extra). H2/H3 → backlog. T1 rimosso (CSV/PDF già esistenti; aggiunto Tcheck per verifica). T2 colori per tipo giornata. T3 nuova pill "Anno". T5 rimosso, sostituito con Tbug fix straordinari `marcocipriani.pcm`. S2 notifica mattutina configurabile. S3 schermata dettaglio collega con storico caffè. S4 stato del giorno + asterisco in lista. P1 silenzio semplificato. P2 recap venerdì 18:00 configurabile. P3 → backlog. P4 → "Scarica i tuoi dati". P5 nuova: ristrutturazione sezioni Profilo. I1/I2 segnati ⚠️ priorità alta.

---

## 2026-06-09 — Chigio visual identity doc + prompt generativi

- **docs** — `docs/features/chigio-visual-identity.md`: nuova pagina dedicata all'identità visiva di Chigio. Contiene analisi stile (3D clay render, palette cromatica con hex esatti, token per ogni parte del corpo), scheda per ogni asset esistente (7), prompt di generazione pronti all'uso per tutti i 17 asset (7 esistenti + 10 proposti), tabella riepilogativa stato asset, note tecniche e checklist di consistenza visiva.
- **docs** — `docs/features/chigio.md`: aggiunto link alla nuova pagina identità visiva.
- **docs** — `docs/features/README.md`: aggiunta voce indice per `chigio-visual-identity.md`.

---

## 2026-06-09 — Social: rename gruppi, caffè sempre visibile, due telefoni, chip gruppo

- **feat** — `social_screen.dart`: pulsante ☕ sempre visibile su ogni collega; disabilitato (grigio) quando status è `completed`/`remote`/`holiday`/`leave`/`notStarted`. Rimossa condizione `showCoffeeButton`.
- **feat** — `social_screen.dart`: due pulsanti telefono separati — Interno (☎ verde, `interno`) e Cellulare (📱 blu, `phoneNumber`) — visibili solo se il campo è compilato nel profilo.
- **feat** — `social_screen.dart/_ColleagueCard`: chip gruppo/i accanto al nome (tag blu piccoli) calcolati live da `groupsStreamProvider`.
- **refactor** — `social_screen.dart/_ColleagueCard`: info ristrutturata — Dipartimento riga 1, Sede·Piano·Stanza riga 2; azioni (telefono/caffè/stella/stato) spostate in riga sotto il testo.
- **feat** — `social_screen.dart`: pulsante matita ✏️ su ogni `_GroupTile` per rinominare il gruppo; dialog con testo pre-compilato; attivo sia nel pannello desktop che nel foglio mobile.
- **feat** — `social_repository.dart`: aggiunto `renameGroup(id, newName)`.
- **feat** — `app_strings.dart`: aggiunte costanti `rename`, `renameGroup`, `cellulare`.

---

## 2026-06-09 — Fix DayCheckpoints widget (pausa pranzo e uscita reale)

- **fix** — `lib/shared/widgets/day_checkpoints.dart`: rimossa euristica errata `pausaDone = workedMins > 180` (si attivava dopo 3h indipendentemente dalla pausa). Ora `pausaDone = lunchPauseMins > 0` basato sul dato reale.
- **fix** — `lib/shared/widgets/day_checkpoints.dart`: `exitMin` ora usa `endTime` effettivo per turni completati; fallback a `entrataMin + standardWorkMins` per turni attivi.
- **fix** — `lib/shared/widgets/day_checkpoints.dart`: rimossi `_stdMins` e `_mealMins` hardcoded (`AppConstants.stdDailyMinsRuolo` / `defaultMealVoucherThresholdMins`). Widget ora riceve `standardWorkMins` e `mealThresholdMins` dal chiamante.
- **refactor** — `lib/features/dashboard/presentation/dashboard_screen.dart`: entrambe le call site di `DayCheckpoints` aggiornate per passare `lunchPauseMins`, `endTime`, `standardWorkMins`, `mealThresholdMins` da `effectiveShift` (turno completato) o `state` (turno attivo).

---

## 2026-06-09 — 9h 3-zone rule, OP vs Deficit, art9 cascade

- **fix** — `timer_provider.dart`: regola 9 ore corretta con logica a 3 zone in `endTurn`, `previewDeficit` e `expectedExitTime`. Zona 1 (`effectiveElapsed < 540`): nessuna pausa forzata. Zona 2 (`540–569`): pausa forzata = `effectiveElapsed − 540`. Zona 3 (`≥ 570`): pausa forzata = 30 min. Precedente: addeva sempre 30 min se `workedSoFar ≥ 540`, ignorando la zona 2.
- **fix** — `dashboard_screen.dart`: `art9UsedMins` calcolato via cascata mensile (`totalOtMins.clamp(0, art9Cap * 60)`) invece dell'erroneo `sum(leavePauseMins)`.
- **fix** — `_NineHourBanner`: condizione basata su `effectiveElapsed` (non `workedMins`); messaggio dinamico "Pausa pranzo virtuale +Xm inclusa" con `X` corretto per zona 2/3.
- **refactor** — `AppStrings.deficitLabel`: rinominato da `'Ore perse'` a `'Deficit'`; aggiunta `lunchVirtualBanner(int mins)`.
- **docs** — `glossario.md`, `features/orario-e-presenza.md`, `entities/daily-timesheet.md`, `entities/README.md`, `00-overview/requirements.md`: documentazione regola 9h aggiornata con le 3 zone; chiarita distinzione OP (straordinario oltre tutti i cap) vs Deficit (giornate sotto standard); tabella widget contatori corretta.

---

## 2026-06-09 — Centralizzazione stringhe — completamento

- **refactor** — `lib/features/social/presentation/social_screen.dart`: `'In ufficio'`, `'Da remoto'`, `'In pausa'` nei chip `_PresenceCount` sostituiti con `AppStrings.statusWorking`, `AppStrings.statusRemote`, `AppStrings.statusPaused`.
- **refactor** — `lib/features/authentication/presentation/onboarding_screen.dart`: `'Inquadramento'` → `AppStrings.employmentType`; chip Ruolo/Comando/Altro → `AppStrings.etRuolo/etComando/etAltro`; rimosso import `app_constants.dart` non più usato.
- **refactor** — `lib/features/authentication/presentation/onboarding_provider.dart`: comparazioni `== 'Ruolo'`/`'Comando'` in `setEmploymentType` → `AppStrings.etRuolo/etComando`; aggiunto import `app_strings.dart`.
- **refactor** — `lib/features/profile/presentation/profile_screen.dart`: lista chip `['Ruolo', 'Comando', 'Altro']` e comparazioni di tipo contratto → `AppStrings.etRuolo/etComando/etAltro`.
- **feat** — `lib/core/constants/app_strings.dart`: aggiunte costanti `etRuolo = 'Ruolo'`, `etComando = 'Comando'`, `etAltro = 'Altro'`; `employmentTypes` refactored per usarle; switch `stdMinsByType`/`mealMinsByType` aggiornati.

---

## 2026-06-07 — Audit approfondito wiki docs, Persistenza e Indice feature

- **docs** — `docs/index.html`: menu laterale portato a copertura completa (48 pagine Markdown), aggiunta sezione CCNL PCM, ADR-0000/0006/0007, widget inventory e indice processi; `ALL_PAGES` allineato per la ricerca; badge versione aggiornato a `v2026.06.07`; link Markdown interni normalizzati anche con `../`.
- **docs** — `docs/architecture/persistence.md`: riscritta come mappa completa Firestore/SharedPreferences/Drift, con subcollection reali (`timesheets`, `activeTimer`, `colleagues`, `groups`, `notifications`, `coffeeLog`), differenza native/web, schema Drift v3, seed sedi PCM, FCM token, regole e gap noti.
- **docs** — `docs/features/README.md`: dipendenze e stato feature riallineati a sedi PCM, CCNL in app, assenze P0/P1, totalizzatori manuali, notifiche e Drift web.
- **docs** — `docs/README.md`, `docs/architecture/README.md`, `docs/entities/README.md`, `docs/decisions/README.md`, `docs/processes/README.md`: indici e overview aggiornati alle pagine/ADR/processi correnti.
- **docs** — `docs/entities/daily-timesheet.md`, `docs/ROADMAP.md`: documentato gap Drift schema v4 per cache offline dei campi `absence*`.
- **verify** — Link-check locale: 48 Markdown, 48 voci menu, 48 pagine indicizzate nella ricerca, 0 link rotti.

---

## 2026-06-07 — Docs riallineate a auth, sedi PCM, route planner e Chigio quotes

- **docs** — `README.md`, `docs/features/README.md`, `docs/00-overview/README.md`, `docs/00-overview/requirements.md`: aggiornati stato feature, auth Google+email, notifiche FCM, Drift, lettore CCNL, percorsi PCM e Chigio.
- **docs** — `docs/features/authentication.md`: documentati login email/password, registrazione, reset password, bottone Google branded con PNG e card login a larghezza massima.
- **docs** — `docs/features/dashboard.md`: aggiunti `FavoriteColleaguesCard`, `_HomeCountersRow`, `PcmRoutePlannerCard`, sorgente `portaleJson` e repository sedi PCM.
- **docs** — `docs/features/profile.md` + `docs/entities/onboarding-state.md`: documentati sede PCM strutturata, coordinate, genere Chigio, target SLI/SBO e lettore CCNL integrato.
- **docs** — `docs/features/chigio.md`, `docs/features/widget-inventory.md`, `docs/ROADMAP.md`: allineati a `ChigioQuotes`, frasi brevi per header, route planner Home, sedi PCM e gap residui aggiornati.

---

## 2026-06-07 — Confronto consumo permessi (P1, CCNL PCM 2019-2021)

- **feat** — Nuovo `lib/features/timesheet/domain/absence_consumption.dart`: `AbsencePlafonds` (plafond annui personali — `short_leave` 38h, `personal_family_hourly` 18h, `specialist_visit` 18h), `SicknessPeriod` (raggruppa giorni consecutivi di malattia in periodi), `AbsenceConsumption` + `computeAbsenceConsumption()` (somma `absenceMins`/conta documentazione per le entries `leave` con `absenceKind` valorizzato nell'anno corrente).
- **feat** — Nuovo `lib/features/dashboard/presentation/personal_absence_consumption_provider.dart`: `personalAbsenceConsumptionProvider` legge le entries dell'anno via `TimesheetRepository.fetchRange` e calcola il consumo personale.
- **feat** — `TotalizzatoriSection` (sezione PERMESSI): ogni chip `Permesso breve` / `Motivi personali` / `Visita specialist.` mostra ora una riga di confronto "App: Xh su Yh plafond (anno)" col consumo tracciato in app, con evidenza ambra se il plafond CCNL personale e' superato. Vedi tabella "Integrazione con totalizzatori" in [`docs/ccnl/permessi-assenze-congedi.md`](../docs/ccnl/permessi-assenze-congedi.md).
- **feat** — Nuova sotto-sezione "MALATTIA — periodi (anno)" in `TotalizzatoriSection`: elenca i periodi di malattia multi-giorno tracciati in app (raggruppamento giorni consecutivi), con conteggio periodi e giorni totali — copre il punto P1 "sickness come periodo multi-giorno, senza workflow amministrativo".
- **note** — Il portale resta sorgente di verita': l'app mostra solo un confronto informativo, nessun blocco né sincronizzazione bidirezionale.

---

## 2026-06-07 — Backfill storico cartellino (script una tantum)

- **data** — Eseguito script Python una tantum (OAuth via refresh token + Firestore REST API, poi rimosso dal repo) per importare in produzione le 112 giornate di `2026-cartellino-import.csv` nell'account `marcocipriani.pcm@gmail.com` (`users/{uid}/timesheets/{dateId}`).
- **import** — Create 103 giornate mancanti (gennaio–giugno 2026), replicando la logica di mappatura di `CsvImportService._parse` (`presenza`→`presence`, `smart_working`→`remote` con `standardDailyMins=456` + pausa 30 min, `ferie`/`permesso`→`holiday`/`leave` a zero ore).
- **fix-data** — Corrette 3 giornate in conflitto col cartellino ufficiale, sovrascritte coi dati corretti: `2026-04-27` (`remote`→`presence` 11:01–19:13), `2026-05-13` (`remote`→`presence` 09:40–18:21), `2026-06-01` (`remote`→`holiday`, Festività Soppresse).
- **verify** — Riletta l'intera sotto-collezione `timesheets`: tutte le 112 date del cartellino presenti, 0 mancanti, conflitti risolti. Le 2 giornate preesistenti non presenti nel CSV (`2026-03-14`, `2026-04-26`) lasciate intatte (fuori dallo scope autorizzato).

---

## 2026-06-07 — Tassonomia assenze (P0 fondazione, CCNL PCM 2019-2021)

- **feat** — `absence_kind.dart` (NEW): `AbsenceKind` con 20 causali (permessi orari/giornalieri, malattia, congedi, studio/formazione, istituti sensibili) + `AbsenceUnit` (`hourly`/`daily`/`period`), label IT e raggruppamento per categoria. Specifica in `docs/ccnl/permessi-assenze-congedi.md`.
- **feat** — `daily_timesheet.dart`: aggiunti campi opzionali `absenceKind`, `absenceUnit`, `absenceMins`, `absenceDays`, `periodStart`/`periodEnd`, `quotaYear`, `countsAsSicknessPeriod`, `sensitive`, `personalNote`, `hasDocumentation` (tutti nullable/default — nessuna entry storica invalidata).
- **feat** — `_EntrySheet` (`timesheet_screen.dart`): selettore causale raggruppato per categoria quando il tipo giornata è "Permesso/assenza", scelta unità (ore/giorni/periodo) con picker condizionali, switch "Assenza riservata" e "Documentazione presente", nota privata.
- **feat** — `csv_export_service.dart`/`csv_import_service.dart`: nuove colonne `assenza_tipo;assenza_min;assenza_giorni;periodo_da;periodo_a` su CSV semplice (re-importabile) e dettagliato; oscuramento automatico di causale/periodo/nota quando `sensitive == true` (colonna `riservata` nel dettagliato); validazione causale in import contro `AbsenceKind`.
- **docs** — `articoli-app.md`: aggiornato stato implementativo `DailyTimesheet`/`Timesheet export-import` con i nuovi campi e copertura CSV.
- **chore** — Backfill sulle entries storiche Firestore rimandato: da concordare come script separato prima di girarlo su prod (vedi `docs/ROADMAP.md`).

---

## 2026-06-07 — CCNL PCM 2019-2021: conversione, confronto e adeguamenti app

- **docs** — `docs/ccnl/ccnl-pcm-2019-2021.md` (NEW): conversione Markdown del PDF locale `2025_10_28_CCNL_C_PCM_2019-2021_Pubblicazione.pdf` con intestazione di provenienza.
- **docs** — `docs/ccnl/confronto-2016-2018-2019-2021.md` (NEW): mappa degli articoli sostituiti/disapplicati, istituti della base precedente ancora utili e confronto con implementazione attuale.
- **docs** — `docs/ccnl/articoli-app.md` + `docs/ccnl/permessi-assenze-congedi.md`: aggiornati riferimenti per permessi, visite, malattia, gravi patologie, congedi riservati, studio, formazione, welfare e diritto alla disconnessione come preferenza notifiche.
- **docs** — `docs/ccnl/README.md`, `docs/README.md`, `docs/ROADMAP.md`: aggiunti collegamenti, adeguamenti di dominio e backlog post CCNL 2019-2021.
- **feat** — `profile_screen.dart`: nuova sezione `CCNL PCM` nel Profilo con lettore full-screen dei contratti 2019-2021 e 2016-2018, switch nuovo/precedente e indice articoli navigabile.
- **chore** — `pubspec.yaml`: aggiunti come asset i Markdown completi `ccnl-pcm-2019-2021.md` e `ccnl-pcm-2016-2018.md`.

---

## 2026-06-07 — Hosting: nuovo dominio web `chigiotime.web.app`

- **infra** — Aggiunto hosting site secondario `chigiotime` al progetto `chigio-time-pcm` (i siti Hosting sono indipendenti dal project ID, che resta immutabile e continua a servire Auth/Firestore). Target hosting `main` ripuntato su `chigiotime` in `firebase.json`/`.firebaserc`. `deploy.sh` e tutti i link in-app/doc (`README.md`, `install.html`, `profile_screen.dart`, `android-deploy.md`, `ios-deploy.md`) aggiornati a `https://chigiotime.web.app`.
- **infra** — Default Hosting site `chigio-time-pcm.web.app` non eliminabile (`Cannot delete default Hosting Site`): trasformato in redirect 301 verso `https://chigiotime.web.app` tramite secondo entry hosting (target `legacy`, `public: web/legacy_redirect`, `redirects` in `firebase.json`). Risultato: una sola URL live funzionante, nessuna rottura per chi ha ancora il vecchio link in cache/bookmark.

---

## 2026-06-07 — Header Chigio: label chip + colori leggibili per tema

- **fix** — `glass_header.dart`: sezione sinistra header riscritta con gerarchia visiva a due livelli. Label Chigio (es. "In marcia!", "Pausa!") esposta come chip colorato bold sopra la frase. Colori tema-consapevoli: label `blue300/blue700`, frase `white α0.72` (dark) / `neutral800` (light). Rimosso `textSub` opaco precedente.
- **chore** — `pubspec.yaml` + `AppStrings.appVersion`: bump `2026.6.5+3` → `2026.6.7+4`.
- **fix** — `timer_provider.dart`: normal tick preserva `exitReminderPending` — notifica FCM non si ripete ogni tick.
- **fix** — `pdf_export_service.dart`: `DateTime.tryParse(e.dateId)` sostituisce `day.clamp(1,31)` — nessun overflow per mesi corti.
- **fix** — `stats_screen.dart`: streak itera `allEntries` ordinati per dateId, non solo `presenceEntries` — il reset su assenza/ferie funziona correttamente.

---

## 2026-06-07 — CCNL: dettaglio permessi/assenze come registro personale

- **docs** — `docs/ccnl/permessi-assenze-congedi.md` (NEW): specifica dettagliata dei permessi mancanti come gestione personale, non workflow autorizzativo PA. Include tassonomia `absenceKind`, campi suggeriti, priorita' P0-P3 e integrazione con totalizzatori.
- **docs** — `docs/ccnl/articoli-app.md`: riorientata l'analisi su residui, consumi e note personali; rimossi come obiettivo i workflow richiesta/autorizzazione/scadenze.
- **docs** — `docs/ROADMAP.md`: aggiunti riferimenti al registro assenze personali, permessi orari/visite, malattia/comporto, ferie residue e congedi.

---

## 2026-06-07 — Sprint: notifiche, colleghi, filtri, contatori, PDF ufficiale, GPS bg, stats, Drift WASM

### Notifica push FCM uscita prevista
- **feat** — `timer_provider.dart` `TimerState.exitNotifMins`: soglia configurable (default 15 min). `build()` legge `exitNotifMins` dal profilo Firestore e aggiorna con `ref.listen`. `_sendExitNotifToFirestore()`: scrive doc in `users/{uid}/notifications` quando la soglia scatta (attiva Cloud Function FCM esistente).
- **feat** — `profile_screen.dart` `_NotificationSheet`: nuova riga "Notifica push uscita prevista" con `ChoiceChip` picker (Off/5/10/15/30 min). Persistita su Firestore come `exitNotifMins`.

### Widget colleghi preferiti in Home
- **feat** — `favorite_colleagues_card.dart` (NEW): `FavoriteColleaguesCard` mostra fino a 4 colleghi preferiti come avatar circolari con iniziali. Tap → `_ColleagueActionSheet` con azioni "Manda caffè" e "Chiama".
- **feat** — `dashboard_screen.dart`: `FavoriteColleaguesCard` inserita nella `statsSection` sopra `_MaggiorPresenzaCard`.

### Contatori custom su Dashboard Home
- **feat** — `dashboard_screen.dart` `_HomeCountersRow`: strip orizzontale scorrevole di chip colorati con valore+unità+etichetta. Appare solo se `customCounters` non è vuota. Posizionata prima di `MonthlySummaryCard`.

### Filtri colleghi per Sede/Dipartimento/Stato
- **feat** — `social_screen.dart` `_ColleagueFilterBar` (NEW): chip animati scroll orizzontale per `sede`, `dipartimento` e `effectiveStatus`. Filtri cumulativi, tap su chip attivo per resettarlo. Valori unici estratti dinamicamente dalla lista colleghi. Reset automatico quando il valore scompare dalla lista.

### Cartellino mensile ufficiale PCM
- **feat** — `pdf_export_service.dart` `exportOfficialCartellino()`: layout PCM con header ente/dipendente/dipartimento/sede, tabella 11 colonne (G/Giorno/Tipo/Entrata/Uscita/Lav./P.Lun/P.Brv/OT-Def/BP/Nota), righe week-end evidenziate, blocco firme (Dipendente/Responsabile/Ufficio Personale), footer "Generato con Chigio Time · Pag. N/N".
- **feat** — `timesheet_screen.dart`: pulsante `assignment_rounded` nella `_GlassToolbar` → `_exportOfficialCartellino()`. Legge `dipartimento` e `sede` dal profilo.

### GPS auto clock-out background
- **feat** — `geofencing_service.dart` `startExitMonitor()`: stream `Geolocator.getPositionStream()` con `distanceFilter: 50 m` e `accuracy: medium` (battery-friendly). Chiama `onExit` una volta quando il device supera `radiusM` dalla sede, poi cancella la subscription. Restituisce `StreamSubscription` che il chiamante gestisce.
- **feat** — `geofencing_service.dart` `requestBackgroundPermission()`: richiede `LocationPermission.always` dopo che `whileInUse` è già stato concesso.
- **chore** — `AndroidManifest.xml`: `ACCESS_BACKGROUND_LOCATION` aggiunto.
- **chore** — `ios/Runner/Info.plist`: `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSLocationAlwaysUsageDescription`, `UIBackgroundModes: location` aggiunti.

### Statistiche personali avanzate
- **feat** — `stats_screen.dart` `_AdvancedStatsCard`: 3 pill (🔥 Record streak presenze / ☕ Pausa media / 🎯 Puntualità ±15 min da 09:00) calcolati sugli ultimi 6 mesi.

### Drift WASM su web (logica)
- **feat** — `connection_web.dart`: usa `WasmDatabase.open()` con `sqlite3Uri` da `sqlite3_flutter_libs` e `drift_worker.dart.js`. Fallback graceful se asset mancanti.
- **feat** — `drift_worker.dart` (NEW): entry point per `dart compile js` → `web/drift_worker.dart.js`.
- **feat** — `app_database.dart`: rimosso guard `kIsWeb → null`; provider ora restituisce DB su tutte le piattaforme. Asset build richiesti: `sqlite3.wasm` e `drift_worker.dart.js` in `web/`.

### ROADMAP
- Sprint completato spostato in `## ✅ Completato`.
- Nuovo sprint: import portale HTTP, predefiniti altri enti, alert banca ore, tipi assenza avanzati, XLSX.
- Sezione `## 🚫 Non realizzabile` creata: Widget nativo, Traduzione EN, Richiesta ferie in-app, QR code timbratura.
- Rimossa: Dashboard dipartimento (Social) — out of scope.

---

## 2026-06-06 — CCNL PCM in Markdown e analisi articoli app

- **docs** — `docs/ccnl/ccnl-pcm-2016-2018.md`: conversione completa del PDF locale `CCNL_PCM 16-18.pdf` con Microsoft MarkItDown `0.1.6`, con intestazione di provenienza.
- **docs** — `docs/ccnl/articoli-app.md`: analisi degli articoli 17-48 con stato di copertura app, gap e backlog consigliato; evidenziato il riallineamento necessario della nomenclatura "Art.9".
- **docs** — `docs/ccnl/README.md` + `docs/README.md`: nuova sezione CCNL collegata dall'indice wiki.

---

## 2026-06-06 — BOE: Banca Ore come Esonero

- **feat** — `daily_timesheet.dart`: nuovi campi `bancaOreMins: int` (BOE usati) e `boeSlot: String?` (`pre_entry` / `pause` / `post_exit`). Nuova classe `BoeSlot` con costanti. Persistiti su Firestore + Drift.
- **feat** — `app_database.dart`: schema v2 — colonne `banca_ore_mins` e `boe_slot` aggiunte via `customStatement` (migration sicura SQLite). `build_runner` rigenerato.
- **feat** — `timer_provider.dart` `previewDeficit(DateTime)`: calcola il deficit atteso senza mutare stato. `endTurn()` esteso con params opzionali `bancaOreMins` e `boeSlot`; calcola `effectiveMins = net + BOE` per determinare overtime e buono pasto.
- **feat** — `dashboard_screen.dart` pulsante "Timbra Uscita": intercetta il deficit prima di `endTurn`. Se `deficit > 0` e banca ore disponibile, apre `_BoeSheet`.
- **feat** — `_BoeSheet` (bottom sheet): mostra deficit, breakdown deduzione AP→AC, copertura parziale con avviso, slot picker animato (pre-entrata / pausa / post-uscita). Pulsanti "Salta" e "Conferma BOE".
- **feat** — `BancaOreTile`: ora `ConsumerWidget` legge `monthlyTimesheetsProvider` — mostra delta live mese corrente (`+Xhm SBO accumulati`, `−Yhm BOE usati`). Chip riordinati AP → AC (ordine di deduzione). Calcolo fruibile aggiornato live.
- **docs** — ADR-0007: rationale BOE, modello dati, ordine deduzione AP→AC, scelte scartate. — [`docs/decisions/0007-banca-ore-esonero.md`](./decisions/0007-banca-ore-esonero.md)
- **docs** — `docs/features/widget-inventory.md` (NEW): inventario completo widget con punti forza/debolezza per categoria. Gap BOE documentato.

---

## 2026-06-06 — Export/Import CSV + Glass toolbar timesheet

### Nuove feature

- **feat** — `csv_export_service.dart` (NEW): `CsvExportService.exportBoth()` genera e condivide via share sheet **due file CSV** — semplice re-importabile (`data;tipo;entrata;uscita;nota`) + completo con tutti i campi calcolati (`pausa_std_min`, `pausa_art9_min`, `pausa_pranzo_min`, `netto_min`, `netto_hhmm`, `extra_min`, `extra_hhmm`, `sbo_min`, `sli_min`, `buono_pasto`, `nota`). `downloadTemplate()` condivide il template `.csv` da compilare.
- **feat** — `timesheet_repository.dart` `fetchRange(start, end)`: query Firestore con range su `dateId` ISO (ordinamento lessicografico = cronologico). Usato dall'export CSV per recuperare dati su periodo libero.
- **feat** — `timesheet_screen.dart` — barra strumenti completamente ridisegnata: `_GlassToolbar` glass pill Apple-style (ClipRRect + BackdropFilter 24σ) sostituisce il vecchio PopupMenuButton + `_ViewSelector`. Layout: pills vista (Giorno/Lista/Settimana/Mese) + divisore + 3 icone inline (PDF, CSV export, Import/Template).
- **feat** — `_exportCsv()`: apre `showDateRangePicker` Flutter Material per selezione periodo libero → chiama `fetchRange()` → `CsvExportService.exportBoth()`.
- **feat** — `_showImportSheet()`: bottom sheet `_ImportSheet` con due azioni — "Importa CSV" (file picker) e "Scarica Template" (share file `.csv`). Sostituisce le vecchie voci menu ⋮.
- **chore** — `pubspec.yaml`: aggiunto `share_plus: ^10.1.0` (risolto a 10.1.4). — [ADR-0006](./decisions/0006-share-plus-file-export.md)
- **docs** — ADR-0006: `share_plus` per export file CSV — API v10: `Share.shareXFiles(List<XFile>, subject: String)`. Web: `XFile.fromData(Uint8List)`.

### Analisi allineamento schema DB ↔ `2026-cartellino-import.csv`

| Campo | Stato | Note |
|---|---|---|
| `dateId` | ✅ mappato | ISO `YYYY-MM-DD`, tutti i 113 record validi |
| `workType` | ✅ mappato | `smart_working→remote`, `ferie→holiday`, `presenza→presence`, `permesso→leave` |
| `startTime`/`endTime` | ✅ presenza | vuoti per smart_working/ferie/permesso (9:00 sintetico) |
| `netWorkedMins` | ⚠️ approssimato | pausa pranzo fissa 30 min; pausa reale varia (es. 65 min il 2026-01-08 → errore +35 min) |
| `note` | ✅ preservata | nessun `;` nel campo nota — split by `;` sicuro su questo dataset |
| `sboMins` | ⬜ 0 post-import | dati Art.9 presenti in nota (es. `2:09Indennità Art.9`) ma non parsati — assegnazione manuale |
| `sliMins` | ⬜ 0 post-import | dati Banca Ore in nota (es. `0:36Banca Ore`) ma non parsati |
| `leavePauseMins` | ⬜ 0 post-import | non derivabile da entrata/uscita senza parse della nota |
| `standardPauseMins` | ⬜ 0 post-import | idem |

Tutte le 113 righe importano senza errori. Limitazione nota: netto minuti approssimato (+30 min fisso anziché pausa reale). Classificazione SBO/SLI richiede assegnazione manuale post-import come da design.

---

## 2026-06-06 — Security audit + bug-fix sprint (Claude Code impeccable audit)

### Sicurezza
- **security** — `firestore.rules`: regola `create` su `notifications` rafforzata — il mittente deve essere `request.auth.uid == fromUid`, i campi sono limitati a allowlist (`hasOnly`), e `read` deve essere `false`. Previene injection di notifiche arbitrarie da utenti autenticati.

### Bug-fix critici
- **fix** — `timesheet_repository.dart`: `publishStatus` era invertito (`type != WorkType.presence`) — le giornate in presenza non aggiornavano mai `currentStatus`. Fix: pubblica sempre per oggi; le presenze usano `'completed'`, gli altri tipi usano il loro `workType` string.
- **fix** — `timer_provider.dart` `_saveToFirestore`: `.ignore()` sostituito con `.onError(debugPrint)` — le failure di sync Firestore su mid-shift vengono ora loggiate invece di essere silenziose.
- **fix** — `social_repository.dart` `watchColleagues`: N letture individuali `doc.get()` per snapshot sostituite con query `whereIn` a batch (ceil(N/30) letture) — riduzione drastica delle letture Firestore su team numerosi.
- **fix** — `timer_provider.dart` `build()`: `ref.listen` su `userProfileStreamProvider` ora passa `prev` — il primo emit (cold-start) aggiorna `standardWorkMins` anche se il turno è già attivo, correggendo la race condition avvio rapido.
- **fix** — `timer_provider.dart` Firestore sync listener: `standardWorkMins: stdMins` (valore catturato al build) → `state.standardWorkMins` — evita che il secondary device usi un valore stale dopo un aggiornamento profilo.
- **fix** — `auth_repository.dart` `signInWithGoogle()`: `initialize()` ora chiamato al massimo una volta (flag statico `_googleSignInInitialized`) — impedisce crash su re-login senza riavvio app.
- **fix** — `auth_repository.dart` `signInWithGoogle()`: `authentication.idToken` (nullable in google_sign_in v7) ora verificato non-null prima di passarlo a `GoogleAuthProvider.credential` — previene crash con `invalid-credential`.
- **fix** — `auth_repository.dart` `signOut()`: `disconnect()` wrappato in try/catch separato — `_auth.signOut()` viene sempre eseguito anche se `disconnect()` fallisce.
- **fix** — `timesheet_repository.dart`: rimossa la funzione locale `void unawaited(Future _) {}` che oscurava `dart:async`'s `unawaited`. Tutte le scritture Drift ora hanno `.onError(debugPrint)`.
- **fix** — `shared/models/timesheet_entry.dart`: eliminata — classe morta che collideva per nome con il tipo generato da Drift `TimesheetEntry`.

### Bug-fix medi
- **fix** — `profile_repository.dart` `updateCurrentStatus`: `DateTime.now()` → `DateTime.now().toUtc()` per `statusDate` — evita date errate su dispositivi con fuso orario/orologio sbagliato.
- **fix** — `profile_repository.dart`: tutti i metodi di scrittura che facevano `return` silenzioso su `user == null` ora lanciano `StateError('User not authenticated')` — le chiamate post-logout non appaiono più come successo.
- **fix** — `profile_repository.dart` `hasProfileStream` + `userProfileStream`: reattivi ai cambi auth tramite `ref.watch(authStateChangesProvider)` (Riverpod rebuild = switchMap semantico) — non più fermi sull'uid del precedente utente dopo sign-out/sign-in.
- **fix** — `profile_repository.dart` `hasProfileStream`: back-fill `hasCompletedOnboarding` ora eseguito al massimo una volta per sessione (flag locale `backfilled`) — niente scritture ripetute per utenti offline.
- **fix** — `totalizzatori_provider.dart`: restituisce `null` invece di fixture zero-filled quando `portaleJson` mancante — gli utenti nuovi non vedono badge verdi su dati fasulli. Factory wrappata in try/catch.
- **fix** — `custom_counters_provider.dart`: `CustomCounter.fromJson` wrappato in try/catch per elemento — un valore malformato nel profilo non azzera più l'intera sezione dashboard.
- **fix** — `onboarding_provider.dart` `addDailyMinutes`/`addMealMinutes`: soglia minima alzata da `0` a `60` min — impedisce `standardDailyMins = 0` che causerebbe divisione per zero e falsi straordinari.
- **fix** — `csv_import_service.dart`: `sboMins` non viene più auto-assegnato dall'importer (`sboMins: 0`) — la categoria straordinario spetta all'utente.
- **fix** — `csv_import_service.dart` `_validDateId`: usa `DateTime.tryParse` invece di check manuali — date come `2026-02-30` vengono ora rifiutate.
- **fix** — `pdf_export_service.dart`: `int.tryParse(...) ?? 0` → `?? 1).clamp(1, 31)` — un `dateId` malformato non produce più `DateTime(y, m, 0)` (ultimo giorno del mese precedente).
- **fix** — `geofencing_service.dart`: `catch (_)` in `checkInOffice` ora distingue `TimeoutException` (→ `GeofenceResult.timeout`) da errori hardware (→ `GeofenceResult.error`). Aggiunto `GeofenceResult.timeout` all'enum.
- **fix** — `profile_screen.dart` `_editEmploymentType`: rimosso `StatefulBuilder` esterno morto (il `setState` non era mai usato). Singolo `StatefulBuilder` con `setLocalState`.
- **fix** — `profile_screen.dart` `_editEmploymentType`: i default contrattuali (`standardDailyMins`, `mealVoucherThresholdMins`, `monthlyArt9Hours`) vengono sovrascritti solo se `selected != current` — un salvataggio no-op non distrugge più le personalizzazioni utente.

### Miglioramenti architetturali
- **arch** — `app_database.dart`: aggiunto override `MigrationStrategy` con hook `onUpgrade` — impedisce corruzione silenziosa del DB locale a versioni future dello schema Drift.
- **arch** — `global_providers.dart` `ThemeModeNotifier`: `build()` installa un `Timer.periodic(1 min)` quando `_savedName == 'auto'` — il tema automatico ora commuta realmente a 06:00 e 18:00 senza richiedere un riavvio.
- **arch** — `totalizzatori.dart`: costanti `bancaOreMinMins`, `bancaOreMaxMins`, `permessoBreveGreenThresholdMins` estratte da magic numbers inline.

### Polish
- **polish** — `profile_repository.dart`: rimosso blocco commento duplicato (8 righe ripetute), eliminato commento pianificativo `// Use a Batch or a simple set with merge`, rimosso `// Extra safety flag`.
- **polish** — `profile_repository.dart` `saveOnboardingData`: `throw Exception(...)` → `throw StateError(...)` — coerente con tutti gli altri metodi di scrittura.
- **polish** — `daily_timesheet.dart` `toMap()` e `timesheet_repository.dart` `saveNote`: `DateTime.now().toIso8601String()` → `DateTime.now().toUtc().toIso8601String()` — timestamp UTC coerenti con `updateCurrentStatus`.
- **polish** — `onboarding_provider.dart`: rimossi commenti `// <-- ...` (Preimpostato, Di default 0, Default Ruolo, Default Comando) — valori auto-esplicativi.
- **polish** — `csv_import_service.dart`: rimosso commento what-doc su `pickAndParse` — nome funzione già descrittivo.

## 2026-06-05 — Sprint 3: UX polish — Chigio, banca ore, maggior presenza mensile, pill switcher

- **feat** — `glass_header.dart`: `GlassHeader` → `ConsumerStatefulWidget`. Frase Chigio **italic**, contrasto alzato (alpha 0.7). Tap su area sinistra (avatar + frase) incrementa seed → cambia frase immediatamente.
- **feat** — `timesheet_screen.dart` `_ViewSelector`: pill switcher ora **full-width** su mobile (ogni voce `Expanded`). Altezza 34 px. Padding end corretto.
- **feat** — `timesheet_screen.dart`: icona festività cambiata da 🏛️ → 🌴 in vista Giorno e lista giornaliera.
- **feat** — `totalizzatori_section.dart` `BancaOreTile`: convertita a `ConsumerWidget`. Layout ridisegnato: icona + header + **tasto edit** (matita), **totale fruibile in grande** (32 px), chips AC / AP separate. Tap edit → bottom sheet con due campi HH:MM per AC e AP; salva su `portaleJson` e ricalcola il totale.
- **feat** — `dashboard_screen.dart` `_MaggiorPresenzaCard`: ora `ConsumerStatefulWidget` **auto-contenuto** (legge profilo e timesheet internamente). **Month switcher** inline (< Mag 2026 >) per sfogliare i mesi. Barra segmentata aggiornata a `_SegmentedBarThresholds` con **linee verticali** ai confini Art.9 / SLI / SBO. Etichette proporzionali ai segmenti. Chip breakdown invariati.

## 2026-06-05 — Sprint 2: maggior presenza, vista giorno, festivita', orario settimanale, social compact

- **version** — `pubspec.yaml` → `2026.6.5+3`; `AppStrings.appVersion` → `v2026.06.05`.
- **feat** — `dashboard_screen.dart`: rimosso `_buildHighlightWidget` (multi-modalità). Nuovo widget `_MaggiorPresenzaCard` sempre visibile: barra progressiva segmentata (blu=Art.9, verde=SLI, arancio=SBO), chip breakdown con valori/cap, badge OPE (rosso) se si supera il totale dei cap. Logica allocazione sequenziale: Art.9 → SLI → SBO → OPE.
- **feat** — `profile_screen.dart`: campi **SLI mensile** e **SBO mensile** ora editabili nel profilo (erano già letti da Firestore ma non modificabili).
- **feat** — `social_screen.dart`: su mobile, `_GroupsMobileTile` e `_CoffeeToggleCard` sostituiti da `_SocialQuickBar` — barra compatta 44px con gruppi a sinistra e toggle caffè a destra. Desktop invariato.
- **feat** — `timesheet_screen.dart` `_ViewMode.day`: vista Giorno ora **default**; navigatore con tasto "Oggi", nome festività 🏛️ e orario pianificato del giorno; `_DayNoteSection` supporta `Key` per reset corretto al cambio giorno.
- **feat** — `italian_holidays.dart` (NEW): `ItalianHolidays.forYear()` calcola festività nazionali italiane (fisse + Pasqua/Lunedì Angelo via algoritmo Gregoriano) + Natale di Roma (21/04). `label()` restituisce il nome della festività. Usato nel timesheet: liste giornaliere mostrano nome festività, warning ⚠️ non appare su giorni festivi.
- **feat** — `profile_screen.dart`: nuova sezione **Orario settimanale** — permette di impostare ore diverse per ciascun giorno (Lun-Ven) con slider 0-600 min. Salvato in Firestore come `weeklyScheduleMins: {"1": 456, ...}`. La vista Giorno del timesheet mostra "Standard: Xh Ym" quando l'orario personalizzato differisce dall'orario uniforme.
- **feat** — `onboarding_screen.dart` + `onboarding_provider.dart`: passo **Genere** aggiunto come step 2 (dopo il nome). Valori M/F/A (Altrə). `saveOnboardingData` salva `gender`. `_editGender` in profile screen aggiornato con opzione "Altrə". `ChigioPhraseEngine._applyGender` supporta 'A' → schwa `ə`.
- **fix** — `onboarding_screen.dart`: tutti i case numerici spostati di +1 dopo inserimento step genere; `_totalSteps = 12`; validazione step 2→3, 3→4.

## 2026-06-05 — UX sprint: Chigio genere/dipartimento/stipendio, header monofrase, vista giorno timesheet, note su giorni passati, fix tastiera

- **fix** — `dashboard_screen.dart` `_NoteSection`: aggiunto `scrollPadding: EdgeInsets.only(bottom: 220)` al `TextField` note attività → risolve il bug in cui la tastiera copriva il campo.
- **feat** — `chigio_phrase_engine.dart`: riscrittura completa. Nuovi parametri `gender` ('M'/'F'/'N'), `department` (String), `isPayDay` (bool — 23 del mese). Placeholder `{o|a}` per accordo grammaticale di genere. Frasi più goffe e divertenti. Pool speciale per il 23 (stipendio). ~70 frasi totali nelle 12 pool.
- **refactor** — `glass_header.dart`: rimosso il titolo di saluto separato (`Buongiorno, Marco 👋`). L'header ora mostra **una sola frase dinamica** Chigio (`maxLines: 2`, nessun troncamento). Legge `gender` e `dipartimento` dal profilo Firestore; calcola `isPayDay` da `DateTime.now().day == 23`.
- **feat** — `profile_screen.dart`: aggiunto picker **Genere (per Chigio)** (♂ Maschile / ♀ Femminile / ⚥ Neutro) → salvato in Firestore come `gender`. Usato da `ChigioPhraseEngine` per accordo grammaticale.
- **feat** — `timesheet_screen.dart`: aggiunta **vista Giorno** (`_ViewMode.day`) con navigazione giorno per giorno, `_DayDetailCard` + sezione note editabile `_DayNoteSection`. Permette aggiungere/modificare note su qualsiasi giorno passato.
- **refactor** — `timesheet_screen.dart` `_ViewSelector`: selettore ripulito — icona + etichetta solo per vista attiva, icona sola per le inattive. Altezza aumentata a 32 px. Tooltip su ogni voce. 4 modalità: Giorno / Lista / Settimana / Mese.

## 2026-05-30 — UX sprint: concetti, Chigio header, gruppi mobile, profilo desktop, contatori custom

- **refactor** — `glass_header.dart`: Chigio avatar **non più cliccabile** (decorativo, solo pulse); versione pill rimossa dall'header (rimane solo in ProfileScreen). Sottotitolo dinamico: frase contestuale `ChigioPhraseEngine` in italic sotto il saluto.
- **refactor** — `GlassHeader`: rimosso parametro `subtitle` (non più necessario); tutte le schermate aggiornate.
- **feat** — `social_screen.dart`: gruppi accessibili su **mobile** via tile + bottom sheet `_GroupsMobileSheet` (lista gruppi, crea/elimina/invia caffè). Su desktop rimane il pannello laterale.
- **feat** — `profile_screen.dart`: layout **desktop constraint** `maxWidth: 720` centrato. Emoji Chigio 🐦 → 🐢.
- **feat** — `custom_counter.dart` (NEW): modello `CustomCounter` (id, label, value, unit, colorIndex, sortOrder). `kPcmDefaultCounters`: 6 contatori predefiniti PCM.
- **feat** — `custom_counters_provider.dart` (NEW): `customCountersProvider` (Riverpod @riverpod) — legge `users/{uid}.customCounters[]` dal profilo Firestore.
- **feat** — `profile_repository.dart`: `saveCustomCounters(List<Map>)` — scrive `customCounters` nel documento utente.
- **feat** — `totalizzatori_section.dart`: `CustomCountersSection` (ConsumerWidget) — sezione chip contatori custom con add/edit/delete + "Importa predefiniti PCM". `_CounterEditSheet`: form nome + valore + unità + color picker (6 colori).
- **feat** — `dashboard_screen.dart`: `CustomCountersSection` aggiunta sotto `TotalizzatoriSection`.
- **feat** — `app_strings.dart`: `customCounters`, `addCounter`, `counterLabel`, `counterValue`, `counterUnit`, `importDefaults`, `importDefaultsDone`, `noCustomCounters`, `noGroups`, `deleteCounterConfirm`.
- **docs** — `docs/architecture/`: aggiunte pagine concetto per Home, Timesheet, Social.
- **docs** — ROADMAP aggiornata.

## 2026-05-30 — Chigio mascotte: header avatar, frasi contestuali, doc

- **feat** — `chigio_phrase_engine.dart` (NEW): `ChigioPhraseEngine.resolve()` genera frasi personalizzate con nome utente in base a pagina, stato turno e ora del giorno. 12 pool di frasi (mattina/pomeriggio/sera × stato turno + timesheet/social/profilo/stats). Rotazione ogni 5 min.
- **feat** — `glass_header.dart`: Chigio avatar (38px, pulse 0.96↔1.04 loop) aggiunto in alto a sinistra di ogni header. Al tap → `_ChigioPhraseDialog` con avatar 140px contestuale + frase speech bubble + bottone "Vai da Chigio →".
- **feat** — `GlassHeader`: nuovo parametro `chigioPage: ChigioPage` (default `dashboard`). Cablato in `DashboardScreen`, `TimesheetScreen`, `SocialScreen`.
- **fix** — `AppStrings.chigioSubtitle`: "La tartaruga di Chigio Time" (era "La mascotte"). Chigio è una **tartaruga** 🐢.
- **fix** — `AppStrings.chigioLabels[6]`: 🐦 → 🐢.
- **feat** — `AppStrings`: aggiunti `chigioVisit` ("Vai da Chigio →").
- **docs** — `docs/features/chigio.md`: pagina dedicata completa con tono di voce, API engine, avatar esistenti, **10 proposte nuovi avatar tartaruga** (corsa, spiaggia, computer, champagne, pensiero, lente, ombrello, sole, trofeo, banca ore).

## 2026-05-30 — sprint features: stats, GPS, exit reminder

- **feat** — `stats_screen.dart` (NEW): schermata statistiche avanzate (`/stats`). 4 sezioni: contatori mese (MonthlySummaryCard), widget in evidenza, 3 bar chart (ore giornaliere / OT per giorno settimana / permessi-ferie), tabella orario medio entrata. Usa `fl_chart`, dati da `monthlyTimesheetsProvider` × 6 mesi.
- **feat** — `profile_screen.dart`: link "Statistiche avanzate →" in fondo all'avatar card; navigazione a `/stats`.
- **feat** — `app_router.dart`: aggiunta rotta `/stats` → `StatsScreen`.
- **feat** — `timer_provider.dart`: `TimerState.exitReminderPending` (bool, one-shot) — il ticker lo imposta a `true` quando `remainingTime ≤ 15 min` e lo resetta automaticamente a ogni `copyWith`.
- **feat** — `dashboard_screen.dart`: `ref.listen` su `exitReminderPending` → SnackBar arancione floating "⏰ Mancano N min all'uscita prevista."
- **feat** — `geofencing_service.dart` (NEW): `GeofencingService` — `checkInOffice()`, `getCurrentPosition()`, `requestPermission()`, formula Haversine. Nessuna dipendenza esterna oltre `geolocator`.
- **feat** — `pubspec.yaml`: aggiunto `geolocator: ^13.0.2`.
- **feat** — `AndroidManifest.xml`: `ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION`.
- **feat** — `ios/Runner/Info.plist`: `NSLocationWhenInUseUsageDescription`.
- **feat** — `profile_screen.dart`: sezione `_GpsSettingsCard` con toggle auto-timbratura + `_GpsSettingsSheet` (acquisizione posizione attuale, slider raggio 50–500m). Salva `officeLat`, `officeLng`, `officeRadiusM`, `gpsAutoClockIn` su Firestore.
- **feat** — `dashboard_screen.dart`: `_GpsPromptCard` — appare quando turno non iniziato + GPS auto abilitato + 06:00–11:00 → rileva posizione → dialog conferma → `startTurn`.
- **docs** — ADR-0004: GPS geofencing `geolocator` foreground (accepted).
- **docs** — ADR-0005: Drift WASM su web (proposed, rimandato — `drift_dev web-wasm` non disponibile in 2.16).
- **feat** — `AppStrings`: aggiunte costanti stats (`advancedStats`, `statsAvgDaily`, `statsOtByWeekday`, …) e GPS (`gpsAutoClockIn`, `gpsOfficeLocation`, `gpsLocationSaved`, …).

## 2026-05-30 — bugfix sprint 2

- **fix** — `timer_provider.dart`: `expectedExitTime` non contava la pausa in corso (`currentPauseStart`) in `minsToAdd`, mostrando l'uscita prevista troppo presto durante qualsiasi pausa. Fix: aggiunto `ongoingPauseMins` a `minsToAdd` e alla verifica soglia 9h.
- **fix** — `app_router.dart`: errore Firestore durante check `hasProfile` impostava `hasProfile=false` e reindirizzava all'onboarding. Fix: `return null` dal catch (nessun reindirizzamento), il check viene rieseguito al prossimo cambio auth.
- **fix** — `profile_repository.dart`: `updatePhoneNumber` non aggiornava `updatedAt`. Fix: aggiunto `FieldValue.serverTimestamp()`.
- **fix** — `profile_screen.dart`: `_editStandardHoursPresets` usava doppio `StatefulBuilder` con `selected` nella closure esterna (reset su rebuild); `setLocal` dead code. Fix: singolo `StatefulBuilder`, `selected` nel suo stato.
- **fix** — `profile_screen.dart`: `Padding(right:8)` su tutti i chip preset incluso l'ultimo. Fix: `SizedBox(width:8)` solo tra chip.
- **fix** — `dashboard_screen.dart`: `_buildHighlightWidget` tipava `totData: dynamic` e `textSub` inutilizzato. Fix: `Totalizzatori?`, parametro rimosso.
- **fix** — `profile_screen.dart` / `dashboard_screen.dart`: `_memberSince` e `_italianDate` ridichiaravano array mesi/giorni. Fix: usano `AppStrings.monthsShort`/`.months`/`.weekdaysFull`.
- **fix** — `firestore.rules`: sub-collections `groups`, `coffeeLog`, `activeTimer` mancanti → `permission-denied` su web. Fix: regole aggiunte, deployate.
- **feat** — `firestore.indexes.json`: aggiunto indice composito `administration + hasCompletedOnboarding` per query `getUsersInAdministration`. Deployato.
- **chore** — `firebase.json`: aggiunta sezione `firestore` per abilitare deploy rules/indexes via CLI.
- **docs** — Roadmap: rimossa traduzione EN da next sprint (solo italiano per PCM), aggiunto backlog con 11 feature proposals.

## 2026-05-30 (UX multi-sprint: strings audit, profilo, colleghi, timesheet, dashboard)

- **feat** — `AppStrings`: `viewWeek`→`'Settimana'`; aggiunti `downloadCsvTemplate`, `csvTemplateContent`, `orarioPreset*`, `highlightWidget*`, `callColleague`, `noOtherUsers`, `coffeeToastSent`, `inOfficeCount`, `presidenzaPCM`.
- **feat** — `timesheet_screen.dart`: voce menu "Scarica template CSV" → bottom sheet con `SelectableText` + pulsante copia clipboard. Pill `_ViewSelector` compatte (non-expanded, padding ridotto, font 9).
- **feat** — `profile_screen.dart`: riordino campi → Dipartimento → Sede → Piano → Stanza → Interno → Telefono → Inquadramento. Lista Ente: solo PCM attiva, altri opacizzati con "Prossimamente". "Orario standard" → chips preset (7:36/6:40 per Ruolo, 7:12/6:12 per Comando) al posto dello slider. Aggiunto row settings "Widget in evidenza" con picker (nessuno / banca ore / straordinari / buoni pasto). Stringhe hardcoded sostituiti con `AppStrings.*`.
- **feat** — `social_screen.dart`: pulsante telefono su `_ColleagueCard` se `interno` o `phoneNumber` impostati; chiama via `tel:` URI con `url_launcher`. Stringhe hardcoded → `AppStrings`.
- **feat** — `dashboard_screen.dart`: `_OrariTableSheet` — modalità riordinate ascending (6:12, 6:40, 7:36), etichette semplificate. Aggiunto `_buildHighlightWidget` che mostra card colorata (banca ore / straordinari / buoni) basata su `profileData['highlightWidget']`.

## 2026-05-29 (v2026.05.29 — Roadmap completa: push, offline, auth, stats, PDF/CSV, i18n)

### Next sprint completato
- **fix** — `timesheet_screen.dart`: `mealVoucherThresholdMins` letto da profilo invece di 380 hardcoded; propagato a `_buildDayList`, `_buildListView`, `_buildEntryInfo`, `_DayDetailCard`.
- **feat** — FCM push notifiche: `FcmService` (token → Firestore, permission, refresh); background handler; foreground SnackBar + tap → `/notifications`. `app.dart` → `ConsumerStatefulWidget` con `AppLifecycleListener`. `web/firebase-messaging-sw.js` service worker. `functions/index.js` Cloud Function trigger su `notifications/{id}`.
- **feat** — Drift offline cache: `AppDatabase` con `TimesheetEntries`; `TimesheetRepository` write-through su ogni save; `StreamTransformer` fallback su Drift in caso di errore Firestore.

### Backlog completato
- **feat** — Auth email/password: `signInWithEmail`, `registerWithEmail`, `sendPasswordReset` in `AuthRepository`; `LoginScreen` con form toggle login/registrazione, campo conferma password, link reset.
- **feat** — Dark mode automatica: `ThemeModeNotifier` → modalità `'auto'` (dark 18:00–06:00); pulsante ⏰ in `_ThemePicker`; `AppLifecycleListener` refresh al resume.
- **feat** — Multi-ente: `AppStrings.administrations` espanso a 25 enti PA; `employmentTypes` con preset `stdMinsByType` / `mealMinsByType`.
- **feat** — Statistiche avanzate: `_OtTrendCard` (bar chart OT 6 mesi, `fl_chart`) in profilo.
- **feat** — Onboarding multi-step: step 9 Dipartimento + step 10 SLI/SBO target; salvati su Firestore.
- **feat** — Gruppi stato aggregato: `_GroupTile` mostra "X/N 🏢" in verde; cross-reference `colleaguesStreamProvider`.
- **feat** — Export PDF: `PdfExportService` — tabella A4 + summary chip; menu ⋮ in timesheet. ADR-0003.
- **feat** — Import CSV: `CsvImportService` — file picker + parser semicolon CSV; menu ⋮ in timesheet. ADR-0003.
- **feat** — Internazionalizzazione: `LocaleNotifier` + `localeProvider`; toggle 🇮🇹/🇬🇧 in profilo; `MaterialApp` wired `flutter_localizations`; `main.dart` carica locale da SharedPreferences.
- **chore** — `pubspec.yaml`: `pdf ^3.11`, `printing ^5.13`, `file_picker ^8.1`, `flutter_localizations`, `path_provider ^2.1`, `path ^1.9`. ADR-0003.
- **chore** — Versione → `2026.5.29+1`.

---

> Questo file è un **log cronologico** delle modifiche a codice + wiki
> effettuate con assistenza LLM. **Una riga per cambiamento significativo.**
> Formato: `YYYY-MM-DD — <ambito> — <sintesi> — <link a ADR / pagina wiki>`.

## 2026-05-28 (v2026.05.28 — CalVer, auto-abandon, strings, timesheet list fix)

### Versioning
- **chore** — `pubspec.yaml`: versione migrata a CalVer `2026.5.28+1`.
- **chore** — `AppStrings.appVersion` → `v2026.05.28`.
- **docs** — `README.md`: aggiornato con nuove funzionalità, versioning CalVer, sezione deploy.

### Auto-abandon (uscita non timbrata dopo le 21:00)
- **feat** — `WorkState.abandoned` aggiunto all'enum.
- **feat** — `timer_provider.dart`: ticker controlla `now.hour >= 21 && state.isShiftActive` ogni secondo; chiama `_autoAbandon()`.
- **feat** — `_autoAbandon()`: pubblica `currentStatus = notStarted` su Firestore (il collega sparisce da "In ufficio"), cancella `activeTimer/state`, persiste stato `abandoned` in SharedPreferences (warning sopravvive al riavvio).
- **feat** — `endTurnFromAbandoned(DateTime)`: timbra retroattivamente dallo stato abandoned (delega a `endTurn`).
- **feat** — `dismissAbandoned()`: ignora la giornata senza salvare; reset a `notStarted`.
- **feat** — `AppStrings`: `abandonedBadge`, `abandonedTitle`, `abandonedBody`, `registerExit`, `dismissDay`.
- **feat** — `dashboard_screen.dart`: flag `isAbandoned`; ring center orange con ⚠️ e ore al cut-off 21:00; badge `_AbandonedBadge`; card `_AbandonedCta` con "Registra uscita" + "Ignora giornata".

---

## 2026-05-27 (v1.0.11 — Strings, timesheet list fix)

### Strings
- **feat** — `lib/core/constants/app_strings.dart`: aggiunte ~30 nuove costanti (greetings, timesheet detail stats, ETA/time-ago, notif response labels + templates, totalizzatori helpers, `chigioCounter`, `bankHoursDetail`, `phoneNumber`, ecc.).
- **refactor** — `lib/shared/widgets/glass_header.dart`: `_timeGreeting()` usa `AppStrings.greetingMorning/Afternoon/Evening`.
- **refactor** — `lib/features/chigio/presentation/chigio_screen.dart`: `tapToChange` + `chigioCounter` cablati.
- **refactor** — `lib/features/social/presentation/notifications_screen.dart`: tutte le stringhe UI → AppStrings (notif titles, response labels, time-ago, ETA picker, cancel).
- **refactor** — `lib/features/dashboard/widgets/totalizzatori_section.dart`: AVVISI, BANCA ORE, TOTALIZZATORI PORTALE, disponibile, Salva → AppStrings.
- **refactor** — `lib/features/dashboard/presentation/dashboard_screen.dart`: tutti i badge di stato, ore lavorate, STRAORDINARIO, note, Salva → AppStrings.
- **refactor** — `lib/features/social/presentation/social_screen.dart`: Annulla, Crea, Elimina, Rimuovi, Nome gruppo, Rimuovi collega → AppStrings.
- **refactor** — `lib/features/profile/presentation/profile_screen.dart`: Profilo, Chiudi, Dati portale PA, Telefono, Voci visibili, Numero di telefono, Salva, OK → AppStrings.
- **refactor** — `lib/shared/widgets/monthly_summary_card.dart`: Personalizza → AppStrings.
- **refactor** — `lib/features/timesheet/presentation/timesheet_screen.dart`: Entrata, Lavorato, Uscita, Giorno, tipo-giornata labels, Salva giornata; array `_italianMonths/_months/_dayLabels` sostituiti con `AppStrings.months/monthsShort/weekdayLetters`.

### Timesheet — List view
- **feat** — `lib/features/timesheet/presentation/timesheet_screen.dart`: `summaryCard` spostato sopra la lista (pinned), la lista scorre indipendentemente; auto-scroll a "oggi" al primo render del mese corrente (`_listScrollController`, `_listScrollKey`).

---

## 2026-05-27 (v1.0.11 — Polish, iOS infra, download banner profilo)

### App
- **fix** — `lib/features/authentication/data/auth_repository.dart`: rimosso import `flutter_riverpod` inutilizzato; `print` → `debugPrint`.
- **fix** — `lib/features/dashboard/widgets/smart_exit_widget.dart`: `withOpacity` → `withValues` (deprecato).
- **feat** — `lib/features/profile/presentation/profile_screen.dart`: banner download in fondo (Android APK + iOS coming soon); usa `url_launcher`.
- **feat** — `pubspec.yaml`: aggiunto `url_launcher ^6.3.1`; versione → `1.0.11+11`.
- **feat** — `lib/core/constants/app_strings.dart`: `appVersion` → `v1.0.11`.

### iOS
- **feat** — `ios/ExportOptions.plist`: template per export IPA (Ad Hoc; da aggiornare con Team ID).
- **feat** — `deploy.sh`: supporto `--ios` flag (disabilitato di default); upload IPA su GitHub Release.
- **docs** — `docs/processes/ios-deploy.md`: guida completa firma, build IPA, distribuzione Ad Hoc e futuro App Store.

### Web / Install page
- **feat** — `web/android/install.html`: tab Android/iOS; pannello iOS "prossimamente" con link web app.
- **feat** — Refactor install page: titolo generico, tab platform switcher JS.

### Cleanup
- **chore** — Rimosso `lib/features/settings/` (cartella vuota).
- **chore** — Rimosso `lib/features/timesheet/presentation/social_screen.dart` (placeholder comment).

---

## 2026-05-27 (v1.0.10 — Build Android, distribuzione APK)

### Android
- **feat** — `android/app/build.gradle.kts`: configurazione release signing con `key.properties` + `keystore/release.jks` (gitignored). Rimosso TODO debug-signing.
- **feat** — `pubspec.yaml`: versione aggiornata a `1.0.10+10`.
- **feat** — `android/app/src/main/AndroidManifest.xml`: `android:label` → "Chigio Time" (era "chigio_time").
- **feat** — `web/android/install.html`: pagina di installazione guidata (sideloading) con istruzioni step-by-step in italiano.
- **feat** — `deploy.sh`: script unificato web + APK + AAB + GitHub Release.
- **feat** — GitHub Release `v1.0.10` creata con APK allegato; repository reso pubblico.
- **docs** — `docs/processes/android-deploy.md`: guida completa build, firma, distribuzione sideload e futuro Play Store.

### Docs
- `firebase.json`: rimossa regola headers `/android/**` (APK non più su Firebase Hosting — Spark plan vieta eseguibili).

---

## 2026-05-26 (v0.10 — Proposte caffè (5), piano/stanza profilo e colleghi)

### Social — 5 proposte caffè
- **feat** — `AppNotification`: nuovi campi `scheduledAt: String?` e `etaMinutes: int?`.
- **feat** — `ColleagueProfile`: nuovo campo `coffeeAvailable: bool?`.
- **feat** — `SocialRepository.setCoffeeAvailable(bool)`: scrive `coffeeAvailable` su Firestore.
- **feat** — `SocialRepository.sendCoffeeInvite`: param opzionale `scheduledAt`; scrive anche su `users/{uid}/coffeeLog/{id}` per tracciare gli inviati.
- **feat** — `SocialRepository.respondToInvite`: param opzionale `etaMinutes`; incluso nel back-notify.
- **feat** — `SocialRepository.sendGroupCoffee(groupId)`: invia invito caffè a tutti i membri del gruppo.
- **feat** — `SocialRepository.watchCoffeeLog()`: stream del coffeeLog per statistiche.
- **feat** — `coffeeLogStreamProvider` + `coffeeStatsProvider` (`{sent, received, accepted}` per mese corrente).
- **feat** — `_CoffeeToggleCard` in social screen: toggle "Disponibile per caffè" + statistiche mese (inviati/ricevuti/accettati).
- **feat** — Badge `coffeeAvailable` visibile nella card collega (verde ☕ se disponibile).
- **feat** — `_showCoffeeOptions`: tap ☕ apre `_CoffeeScheduleSheet` con scelta "Adesso" o "Pianifica" (time picker).
- **feat** — `_GroupTile`: pulsante ☕ su gruppi con membri; `_sendGroupCoffee` invia a tutti e mostra snackbar.
- **feat** — `_NotifCard`: 4° risposta "🚶 Sto arrivando" apre dialog ETA (5/10/15 min); `responseType: 'arriving'` + `etaMinutes` nel back-notify.
- **feat** — Mappe `_responseEmoji/Label/Color` aggiornate per `'arriving'`. `_inviteTitle` gestisce ETA e `scheduledAt`. `_ResponseChip` supporta suffisso.

### Profilo + Social — Piano e Stanza
- **feat** — `ColleagueProfile`: nuovi campi `piano: String?` e `stanza: String?`.
- **feat** — `SocialRepository.watchColleagues`: legge `piano` e `stanza` dal profilo Firestore del collega.
- **feat** — Profilo: due nuove righe editabili "Piano" e "Stanza / Ufficio" (dopo Dipartimento, prima di Inquadramento).
- **feat** — `_ColleagueCard`: mostra riga compatta "📍 Piano X · St. Y" quando uno o entrambi i campi sono impostati.

### Docs
- **docs** — `docs/features/social.md`: schema Firestore aggiornato (piano, stanza, coffeeAvailable, coffeeLog, scheduledAt, etaMinutes); flusso principale aggiornato.

---

## 2026-05-26 (v0.9 — Cross-device sync, quick-edit inline, per-chip portale, dipartimento colleghi)

### Timer — Cross-device sync
- **feat** — `timer_provider.dart`: stato turno scritto su `users/{uid}/activeTimer/state` (Firestore) a ogni transizione (`startTurn`, `startPause`, `endPause`). Al riavvio: se `SharedPreferences` vuoto per oggi, legge da Firestore come fallback. Al completamento turno: cancella sia locale che Firestore.

### Dashboard + Timesheet — Quick-edit inline
- **fix** — `MonthlySummaryCard.onEditTap` in dashboard/timesheet non naviga più a `/profile`; apre direttamente `_CountersCustomizerSheet` via `showCountersCustomizer(context, ref, profileData)`.
- **fix** — `TotalizzatoriSection.onEdit` in dashboard non naviga più a `/profile`; apre direttamente `showPortaleEdit(context, ref, profileData)`.
- **refactor** — `_showCountersCustomizer` e `_showPortaleEdit` in `profile_screen.dart` rinominati pubblici (`showCountersCustomizer`, `showPortaleEdit`). Rimossi import `go_router` inutilizzati da dashboard e timesheet screen.

### Totalizzatori portale — Quick-edit per singolo contatore
- **feat** — `_Chip` ha nuovi campi `jsonKey`, `jsonKeyTotal`, `isMinutes`. Tutti i chip hanno le chiavi JSON mappate.
- **feat** — `_MetricChip`: chip con `jsonKey` mostra icona matita (9px); tap apre `_QuickChipEditSheet` con campo "Valore attuale" + "Spettante" (se applicabile).
- **feat** — `TotalizzatoriSection` ha nuovo callback `onChipEdit(Map<String, dynamic>)`. Dashboard salva via `profileRepositoryProvider.savePortaleData` aggiornando solo i campi modificati.
- **feat** — `_CategorySection` thread `onChipEdit` fino a ogni `_MetricChip`.

### Social — Dipartimento nella card colleghi
- **feat** — `ColleagueProfile` ha nuovo campo `dipartimento: String?`.
- **feat** — `SocialRepository.watchColleagues` legge `p['dipartimento']` dal profilo Firestore del collega.
- **feat** — `_ColleagueCard`: sotto il nome mostra dipartimento (se impostato) o inquadramento. Telefono sempre visibile quando presente (riga separata, 10px).

### Docs
- **docs** — `docs/features/social.md`: aggiornato flusso principale + aggiunta sezione "Proposte evoluzione caffè" con 6 idee.

---

## 2026-05-25 (v0.8.1 — Retroattivo timesheet, fix counters widget, version chip, profilo versione)

### Timesheet — Inserimento retroattivo
- **feat** — `_EntrySheet` accetta parametro `existingEntry: DailyTimesheet?`; `initState` pre-popola tipo, orario entrata/uscita dall'entry esistente.
- **feat** — Titolo sheet cambia in "Modifica giornata" quando si edita un'entry esistente.
- **feat** — `_DayDetailCard`: aggiunto parametro `onEdit: VoidCallback?`; mostra pulsante matita (blu) nell'header quando valorizzato.
- **feat** — Tapping su riga lista (vista Lista) apre `_EntrySheet` pre-popolato con l'entry esistente.
- **feat** — `_showEntrySheet` aggiornato con parametro `existingEntry`; passato ai `_DayDetailCard` in vista Settimana e Mese.

### UX — Versione app
- **feat** — `AppStrings.appVersion = 'v0.8-dev'` aggiunto a `app_strings.dart`.
- **feat** — `GlassHeader`: chip versione (blu traslucido, 9px, bold) tra campanella e avatar.
- **feat** — `ProfileScreen`: stringa versione centrata in fondo alla pagina (sotto logout).

### MonthlySummaryCard — Fix + UX
- **fix** — Header blu non riempiva tutta la larghezza: rimosso `Stack`, usato `Container(width: double.infinity)`.
- **ux** — Link "Personalizza" (icona tune) spostato dall'header blu alla sezione espansa (visibile solo dopo espansione).

---

## 2026-05-25 (v0.8 — Coffee 3 risposte + messaggio, nota attività, colleghi live stream, coffee su tutti)

### Social — Coffee 3 risposte + messaggio
- **feat** — `AppNotification` ha due nuovi campi opzionali: `responseType: String?` (`accepted|maybe|declined`) e `message: String?`.
- **feat** — `SocialRepository.respondToInvite` aggiornato: accetta `responseType` e `message?`; invia back-notification per **tutte** le risposte (non più solo accept).
- **feat** — `NotificationsScreen`: rimpiazzati i 2 pulsanti Accetta/Rifiuta con 3 icone ✅ Ci sono / 🤔 Forse / ❌ Non posso + textarea messaggio opzionale (max 160 char).
- **feat** — Card `coffee_accepted` mostra chip colorato (verde/arancio/grigio) con la risposta e il messaggio se presente.
- **feat** — Icona ☕ visibile su **tutti** i colleghi nella lista (rimosso filtro `canReceiveCoffee`).

### Dashboard + Timesheet — Nota attività giornaliera
- **feat** — `DailyTimesheet.note: String?` aggiunto a dominio + `toMap`/`fromMap`.
- **feat** — `TimesheetRepository.saveNote(dateId, note)`: `set merge:true` su Firestore.
- **feat** — `DashboardScreen`: sezione `_NoteSection` mostrata quando `isCompleted` (turno normale o smart working). Textarea 3 righe, bottone Salva, conferma "Salvata ✓". Pre-popola da `todayEntry.note`.
- **feat** — `TimesheetScreen._buildEntryInfo`: nota mostrata in corsivo sotto le info orario nella lista giornaliera (max 2 righe).

---

## 2026-05-25 (v0.7 — Coffee handshake, Portale edit, Dipartimento, tema sistema, widget link)

### Social — Coffee handshake completo
- **feat** — `respondToInvite` invia ora una notifica `coffee_accepted` al mittente originale quando l'invito viene accettato (sub-collezione `users/{uid}/notifications`).
- **feat** — `NotificationsScreen._NotifCard` gestisce tipo `coffee_accepted`: mostra "XXX ha accettato il tuo caffè ☕" come card informativa (no pulsanti azione).

### Totalizzatori portale — editabile dall'utente
- **feat** — `ProfileRepository.savePortaleData(Map)`: salva `portaleJson` nel documento Firestore dell'utente.
- **feat** — `totalizzatoriProvider` legge `portaleJson` dal profilo utente (tramite `userProfileStreamProvider`); usa la fixture solo se il campo è assente.
- **feat** — `TotalizzatoriSection`: aggiunto parametro `onEdit: VoidCallback?` e icona matita nell'header. Dashboard passa `() => context.push('/profile')`.
- **feat** — `ProfileScreen`: nuovo menù "🏦 Dati portale PA" → `_PortaleEditSheet` con form scrollabile per tutti i campi (30+ campi suddivisi in sezioni: Identificativo, Ferie, Festività, Straordinari, Banca Ore, Permessi, Buoni Pasto).

### Profilo — Dipartimento
- **feat** — Campo `dipartimento: String?` aggiunto al documento Firestore. Nuova `_InfoRow` nel profilo tra "Ente" e "Inquadramento".

### Profilo — Tema automatico (3 stati)
- **feat** — Sostituito toggle binario "Tema scuro" con `_ThemePicker` a 3 pulsanti: ☀️ Chiaro / 🌙 Scuro / 📱 Sistema. Sistema usa `ThemeMode.system` (già supportato da `themeModeProvider`).

### MonthlySummaryCard — link a impostazioni widget
- **feat** — Parametro `onEditTap: VoidCallback?`. Quando valorizzato, mostra icona `tune` nell'angolo in alto a destra dell'header blu.
- **feat** — Dashboard e Timesheet passano `onEditTap: () => context.push('/profile')`.

### Web — favicon e manifest
- **fix** — Spostati file favicon aggiornati da `favicon/` (root) a `web/icons/`; rimossa cartella stray `favicon/`.
- **fix** — `web/manifest.json`: aggiornati path icone ai file reali (`icons/web-app-manifest-192x192.png`, `512x512`, `apple-touch-icon.png`). Corretti nome app, colori tema.
- **fix** — `web/index.html`: link favicon aggiornati a `icons/favicon.ico`, `icons/favicon.svg`, `icons/favicon-96x96.png`.
- **fix** — `web/favicon.ico` aggiornato alla versione recente; `web/favicon.svg` rimosso (duplicato).

### MonthlySummaryCard — background fix (light mode)
- **fix** — Container esterno e sezione espansa ora usano `Colors.white` (opaco) in light mode, eliminando il bleed-through del gradiente di sfondo.

---

## 2026-05-21 (v0.6f — README + docs update)

### Documentazione
- **docs** — `README.md` (root): riscritto da zero (era template Flutter). Aggiunta live URL, feature table, stack table, comandi dev e deploy.
- **docs** — `00-overview/README.md`: stato attuale aggiornato con tabella feature; mindmap esteso con widget contatori, Totalizzatori, Social gruppi, Chigio.
- **docs** — `features/profile.md`: riscritta completamente (era obsoleta — diceva "read-only").
- **docs** — `features/dashboard.md`: aggiornato — rimosso Straordinari bar, aggiornata sezione MonthlySummaryCard, aggiunti dettagli Totalizzatori chip used/total + fetchedAt.
- **docs** — `features/timesheet.md`: aggiornato con 3 viste, alert giornate mancanti, summary card condivisa.
- **docs** — `features/chigio.md`: creata (nuova feature).
- **docs** — `features/README.md`: aggiornata mappa dipendenze + tabella stato.
- **docs** — `entities/README.md`: ER aggiornato con `leavePauseMins`, `sliMins`, `sboMins`, `workType` su DailyTimesheet; nuovi campi profilo (`summaryItems`, `notifyClockIn`, ecc.).
- **fix** — `docs/.DS_Store` rimosso.

---

## 2026-05-21 (v0.6e — Dashboard polish, background fix, Totalizzatori)

### MonthlySummaryCard — background fix
- **fix** — Aggiunto `color:` alla `BoxDecoration` del Container esterno: dark `#0a1628`, light `white@80%`. Risolve il problema di sfondo trasparente/incoerente visible in Home.

### Dashboard — rimozione widget Straordinari
- **remove** — Rimossi entrambi i `GlassTile` "Straordinari" (erano duplicati) e `SizedBox(height:4)` orfano.

### Totalizzatori portale — polish
- **feat** — `_Chip.total: String?`: quando valorizzato, `_MetricChip` mostra `valore / totale` con slash e colore attenuato.
- **feat** — `fetchedAt: String?` aggiunto a `Totalizzatori` (campo `fetched_at` nel JSON). Header mostra badge "Agg. DD/MM/YYYY" in alto a destra.
- **feat** — `periodo` mostrato inline accanto al titolo ("TOTALIZZATORI PORTALE · Aprile 2026").
- **feat** — FERIE: chip `Fruito annuo / Spettanza`, `Residuo ac / Spettanza`. FESTIVITÀ: `Fruito / Spettanza`, `Residuo / Spettanza`. STRAORDINARI: `Liquidati / Autorizzato`, `Liquidabili / Autorizzato`. Rimosso chip `Spettanza` ridondante.

---

## 2026-05-21 (v0.6d — Fix OP/Ore Perse, background card, docs)

### MonthlySummaryCard — fix OP
- **fix** — `'op'` ora mappa `deficitMins` (Ore Perse = giorni con ore < standard). Rimosso item duplicato `'perse'`. `defaultItems` = `['art9','sli','sbo','op']`.
- **fix** — Colore OP = `AppColors.red700` (era teal). Progress bar OP mostra deficit senza cap.
- **fix** — Sfondo sezione espansa: dark mode `#0a1628` @ 82% (era quasi trasparente), light mode `white` @ 80%.

### Profilo — customizer OP
- **fix** — Label "OP — Ore perse" (era "OP — Ore di produzione"). Label Art.9 = "Estensione orario mensile". Lista `_kAllItems` aggiornata a 4 item.

### Docs
- **docs** — `daily-timesheet.md`: aggiunto glossario contatori mensili; Art.9 = istituto opzionale; OP = `extraMins < 0`.
- **docs** — `user-profile.md`: aggiunti campi `monthlySliHours`, `monthlySboHours`, `summaryItems`, `summaryShowProgress`, `notifyClockIn/Out/Weekly`; corretto Art.9 description.

---

## 2026-05-21 (v0.6c — Widget contatori personalizzabile)

### MonthlySummaryCard — voci dinamiche
- **feat** — Aggiunto `overtimeCap`, `visibleItems`, `showProgressBars` al costruttore. Default: `['art9','sli','sbo','op','perse']`. La card legge `summaryItems` e `summaryShowProgress` dal profilo Firestore e rende header e barre dinamicamente.
- **feat** — Nuovo item `op` (OP — Ore di produzione) mappa `totalOtMins` con cap `monthlyOvertimeHours`. Colore teal `#00ACC1`.
- **feat** — Header usa `Wrap` per gestire 4-5 voci senza overflow.
- **rename** — `deficitLabel` = `'Ore perse'` ovunque (era `'Deficit'`).

### Profilo — Widget contatori (impostazioni)
- **feat** — Nuova voce "Widget contatori 📊" nel pannello Impostazioni del profilo. Apre `_CountersCustomizerSheet`: 5 tile con toggle colorati (Art.9/SLI/SBO/OP/Ore perse), switch "Mostra barre di avanzamento", pulsante "Ripristina default", salvataggio su Firestore. Funzione `_showCountersCustomizer`, widget `_CountersCustomizerSheet`.

---

## 2026-05-21 (v0.6b — UX profilo, alert timesheet, redesign card mensile)

### MonthlySummaryCard — redesign header
- **feat** — Header blu ora mostra Art.9 / SLI / SBO / Perse come 4 stat hero (ore extra del mese a colpo d'occhio). Sezione espansa mostra Ore tot / Straord / Buoni + barre di avanzamento Art9/SLI/SBO. Aggiunto widget `_SecStat` per le stat secondarie. `accent` color opzionale su `_BigStat` per il valore Perse (rosso chiaro se > 0).

### Timesheet — alert giorni passati senza timbrature
- **feat** — In vista Lista, le giornate feriali passate senza entry vengono evidenziate con bordo arancio, sfondo arancio tenue e icona ⚠️. I chip "Presenza / SW" restano cliccabili per inserimento retroattivo.

### Profilo — statistiche personali
- **feat** — La card avatar ora mostra 4 stat calcolate dai dati del mese corrente: Record gg (massimo ore/giorno), Uscita tardiva (max endTime), Uscita rapida (min endTime), Smart W. (gg in remoto). Rimossi i contatori generici Giorni/Ore mese/Buoni.

### Profilo — Notifiche
- **feat** — Schermata Notifiche implementata: bottom sheet con 3 toggle (Promemoria entrata, Promemoria uscita, Report settimanale). Preferenze salvate su Firestore come `notifyClockIn`, `notifyClockOut`, `notifyWeekly`. Widget `_NotificationSheet` + `_NotifToggle`.

### Profilo — Privacy
- **feat** — Schermata Privacy implementata: bottom sheet informativo con 3 sezioni (Dati al sicuro, Nessuna condivisione, Diritto cancellazione). Widget `_PrivacyRow`.

### Profilo — Ente picker
- **fix** — Lista amministrazioni ridotta a sola "Presidenza del Consiglio dei Ministri" (`AppStrings.administrations`).

---

## 2026-04-30 (v0.5d — Fix dialog Social, Totalizzatori portale Dashboard)

### Social — fix dialog gruppi
- **fix** — `_createGroup` e `_deleteGroup` in `_GroupsPanelState`: `Navigator.pop()` ora usa il `BuildContext` del builder della dialog (`dialogCtx`) invece del contesto esterno del widget. L'uso del contesto esterno in GoRouter causava `AssertionError: currentConfiguration.isNotEmpty` perché veniva fatto pop allo stack GoRouter invece che alla dialog. — [`social_screen.dart`](../lib/features/social/presentation/social_screen.dart)

---

## 2026-04-30 (v0.5c — Totalizzatori portale nella Dashboard)

### Dashboard — Totalizzatori portale
- **feat** — Nuovo modello `Totalizzatori` con tutti i campi del portale PA (FERIE, FESTIVITÀ SOPPRESSE, STRAORDINARI, BANCA ORE, PERMESSI, BUONI PASTO, DEBITI). — [`lib/features/dashboard/domain/totalizzatori.dart`](../lib/features/dashboard/domain/totalizzatori.dart)
- **feat** — `totalizzatoriProvider` (`@riverpod`) con fixture statica di sviluppo; sostituibile con una chiamata HTTP al portale. — [`lib/features/dashboard/presentation/totalizzatori_provider.dart`](../lib/features/dashboard/presentation/totalizzatori_provider.dart)
- **feat** — `TotAlertBanner` — banner in cima alla sezione statistiche con chip colorati (amber/red) per le condizioni di alert (ferie anno prec., accumulo ferie >30 gg, maggior presenza >8h, straordinari in sospeso, ore da recuperare).
- **feat** — `BancaOreTile` — tile full-width prominente con totale fruibile (hh:mm), breakdown AC/AP, badge verde se banca ore è tra 1h e 8h.
- **feat** — `TotalizzatoriSection` — sezione in fondo alla dashboard con tutte le categorie in `_MetricChip` colorati per livello di alert (info / amber / red).
- **feat** — Tile "BUONI PASTO" nel grid mostra il conteggio ufficiale del portale (`buoni_pasto_mensili`) e affianca il conteggio calcolato localmente da Firestore.

---

## 2026-04-30 (v0.5b — Profilo editabile, fix architettura background)

### Profilo
- **feat** — Tutti i campi del profilo sono ora editabili direttamente dalla schermata Profilo: nome, ente, inquadramento (chip), orario standard (slider), soglia buono pasto (slider), Articolo 9 (slider), tetto straordinari (slider), telefono (field).
- **feat** — `ProfileRepository.updateProfileFields(Map)` — metodo generico per aggiornare uno o più campi Firestore in un unico `update`. [`profile_repository.dart`](../lib/features/profile/data/profile_repository.dart)
- **feat** — Bottom sheet riutilizzabile `_EditSheet` + widget `_SaveButton` con stato di loading integrato.
- **feat** — `_editSlider` bottom sheet con slider e preview live del valore formattato.
- **feat** — Cambio inquadramento aggiorna automaticamente `standardDailyMins`, `mealVoucherThresholdMins`, `monthlyArt9Hours` ai valori predefiniti del contratto.
- **feat** — Settings rows (`Notifiche`, `Privacy`, `Informazioni app`) ora con `onTap`: le prime due mostrano snackbar "prossimamente", la terza apre un dialog informativo.
- **fix** — Rimosso `Container(gradient)` duplicato nel body di `ProfileScreen`: il gradiente è già fornito da `AppBackground` in `app.dart`.

### Architettura background (fix definitivo)
- **fix** — `AppBackground` rimosso da `MainShellScreen` e centralizzato in `app.dart` per tutte le dimensioni schermo. Elimina la doppia istanza con sistemi di coordinate diversi che causava una linea visibile al bordo del contenitore 430 px su viewport intermedi.
- **fix** — `GlassButton` — `Text` wrappato in `Flexible` con `TextOverflow.ellipsis`; elimina overflow di sub-pixel durante il resize della finestra.

---

## 2026-04-29 (v0.5 — pianificato: desktop adattivo, FloatingNav overlay, gruppi Social)

### Architettura
- **plan** — `MainShellScreen`: passaggio da `Column` a `Stack` per rendere `FloatingNav` un vero overlay; elimina la riga separatrice tra contenuto e gradiente. — [`architecture/navigation.md`](./architecture/navigation.md)
- **plan** — `FloatingNav` convertita in `StatefulWidget` con sliding pill animata (`TweenAnimationBuilder`, 300 ms, `Curves.easeOutCubic`). — [`architecture/navigation.md`](./architecture/navigation.md)
- **plan** — Aggiunto breakpoint `kDesktopBreakpoint = 800 px`; su schermi ≥ 800 px rimosso il vincolo 430 px, ogni screen gestisce il proprio layout split-view. — [`architecture/navigation.md`](./architecture/navigation.md)

### Dashboard
- **plan** — Saluto dinamico in `GlassHeader`: Buongiorno (05–13) / Buon pomeriggio (13–18) / Buona sera (18–05). — [`features/dashboard.md`](./features/dashboard.md)
- **plan** — Pulsante Smart Working compatto: stessa riga di "Timbra Entrata", solo icona + "SW" su mobile, "Smart Working" su desktop. — [`features/dashboard.md`](./features/dashboard.md)
- **plan** — Layout desktop: timer + CTA a sinistra, riepilogo giornaliero a destra, stats full-width sotto. — [`features/dashboard.md`](./features/dashboard.md)

### Timesheet
- **plan** — Layout desktop split-view: scroll list giornate a sinistra (280 px), calendario + dettaglio a destra. — [`features/timesheet.md`](./features/timesheet.md)

### Social — Gruppi (nuova feature)
- **plan** — Nuova sub-collezione Firestore `users/{uid}/groups/{groupId}` con `name`, `createdAt`, `memberUids`. — [ADR-0002](./decisions/0002-social-groups.md)
- **plan** — Operazioni: crea gruppo, aggiungi membro, rimuovi membro, elimina gruppo. — [`features/social.md`](./features/social.md)
- **plan** — Layout desktop Social: pannello sinistro gruppi (240 px), pannello destro lista colleghi filtrata. — [`features/social.md`](./features/social.md)

### Bug fix (rilasciati)
- **fix** — `appRouterProvider` ora `keepAlive: true` + `_RouterNotifier` con `refreshListenable`; elimina la ricreazione del `GoRouter` ad ogni emissione di `authStateChanges`. — [`architecture/navigation.md`](./architecture/navigation.md)
- **fix** — Redirect `hasProfile` usa `Firestore.get()` diretto invece di `hasProfileStreamProvider.future`; elimina l'errore "disposed during loading state" che mandava l'utente all'onboarding. — [`architecture/navigation.md`](./architecture/navigation.md)
- **fix** — `AppBackground` usato come wrapper full-screen nel builder desktop di `app.dart`; gradiente ora copre l'intera larghezza dello schermo (non solo i 430 px centrali).

---

## 2026-04-27 (v0.4 — Social, Notifiche, Riepilogo mensile dashboard)

### Social (nuovo)
- **feat** — Schermata Social completamente riscritta con dati reali Firestore. — [`features/social.md`](./features/social.md)
- **feat** — Lista colleghi personalizzabile: aggiungi/rimuovi utenti della stessa amministrazione.
- **feat** — Preferiti (⭐) in cima alla lista; long-press per rimuovere.
- **feat** — Stato presenza in tempo reale (`working`/`paused`/`remote`/`completed`/`notStarted`) pubblicato su `users/{uid}.currentStatus` ad ogni transizione del timer.
- **feat** — Pulsante ☕ invia invito caffè a colleghi presenti/in pausa → notifica Firestore.

### Notifiche (nuovo)
- **feat** — Schermata `/notifications` con inviti caffè ricevuti; Accetta/Rifiuta aggiorna `status` del documento. — [`features/social.md`](./features/social.md)
- **feat** — Badge rosso sul campanello in `GlassHeader` quando ci sono notifiche non lette (`hasUnreadProvider`).
- **feat** — Tutte le notifiche marcate come lette all'apertura della schermata.

### Profilo
- **feat** — Campo `phoneNumber` editabile via bottom sheet (pulsante ✏️ nella riga Telefono).
- **feat** — Numero di telefono visibile nelle card colleghi della schermata Social.

### Dashboard — Riepilogo mensile (nuovo)
- **feat** — **Riga 1** (4 tile): Art.9 svolte | SLI svolte | SBO svolte | Deficit ore. — [`features/dashboard.md`](./features/dashboard.md)
- **feat** — **Riga 2** (3 tile): Ore mancanti al target (Art9+SLI+SBO) | Giorni lavorativi rimanenti (escluse ferie/permessi dal timesheet) | Extra ore/giorno necessarie.
- **feat** — **Riga 3**: Buoni pasto maturati con soglia visibile.
- **feat** — `_remainingWorkingDays()` conta lun–ven rimanenti escludendo giorni con `workType: leave|holiday` già registrati nel timesheet.

### Modello dati
- **schema** — `DailyTimesheet` — aggiunto `sliMins: int` (straordinario liquidato, default 0) e `sboMins: int` (banca ore, default 0). — [`entities/daily-timesheet.md`](./entities/daily-timesheet.md)
- **feat** — `WorkTimer.endTurn()` imposta `sboMins = max(extraMins, 0)` di default; l'utente può modificare la ripartizione SLI/SBO nel Timesheet.

### Sicurezza
- **infra** — Creato `firestore.rules` con regole aggiornate: profili leggibili da tutti gli utenti autenticati; `notifications` creabili da chiunque sia autenticato (per ricevere inviti).

### Wiki
- **wiki** — Aggiornate: [`features/social.md`](./features/social.md), [`entities/daily-timesheet.md`](./entities/daily-timesheet.md), [`features/dashboard.md`](./features/dashboard.md).

---

## 2026-04-26 (v0.3 — Art. 9, dati reali profilo, oggi auto-detect)

### Dashboard
- **feat** — **Art. 9 tracking reale**: `Σ entry.leavePauseMins` da Firestore; card mostra `usate / cap` con progress bar + colore arancione al raggiungimento del tetto. — [`entities/daily-timesheet.md`](./entities/daily-timesheet.md)
- **feat** — Target mensile ore calcolato con `_workingDaysInMonth()` (conta lun–ven effettivi) invece di valore fisso 22. — [`features/dashboard.md`](./features/dashboard.md)
- **feat** — **Oggi auto-detect**: dopo un riavvio, se il turno del giorno è già su Firestore, la dashboard lo mostra in stato `completed` senza richiedere una nuova timbratura. — [`features/dashboard.md`](./features/dashboard.md)

### Timer
- **feat** — `totalLeavePauseMins` aggiunto a `TimerState` + chiave `timer_leavePauseMins` su SharedPreferences. — [`entities/timer-state.md`](./entities/timer-state.md)
- **fix** — `PauseType.leave` ora accumula in `totalLeavePauseMins` (non più in `totalStandardPauseMins`): i permessi brevi Art. 9 sono separati dalle pause caffè nel calcolo del `netWorkedMins`.

### Modello dati
- **schema** — `DailyTimesheet` — aggiunto campo `leavePauseMins: int` (default 0, backwards-compat). — [`entities/daily-timesheet.md`](./entities/daily-timesheet.md)
- **fix** — `netWorkedMins` ora sottrae anche `leavePauseMins` oltre a `standardPauseMins` e `lunchPauseMins`.

### Profilo
- **feat** — `GlassHeader` usa nome reale da Firestore/Firebase Auth e foto Google.
- **feat** — `ProfileScreen` mostra foto Google, sottotitolo `employmentType · administration`, statistiche mensili reali (giorni, ore, buoni pasto).

### Wiki
- **wiki** — Aggiornate: [`entities/timer-state.md`](./entities/timer-state.md), [`entities/daily-timesheet.md`](./entities/daily-timesheet.md), [`features/dashboard.md`](./features/dashboard.md).

---

## 2026-04-26 (v0.2 — Glass Redesign + Funzionalità complete)

### UI / Design system
- **ui** — Redesign completo glass-morphism su tutti gli schermi (Login, Onboarding, Dashboard, Timesheet, Social, Profile) basato su design file Claude Design. — [`features/dashboard.md`](./features/dashboard.md)
- **ui** — Layout **mobile-first**: su desktop/tablet il contenuto è centrato a 430 px su backdrop scuro. — [`app.dart`](../lib/app/app.dart)
- **ui** — `FloatingNav` glass pill a 3 tab (Home / Timesheet / Social); Profile via avatar in header. — [`architecture/navigation.md`](./architecture/navigation.md)
- **ui** — `ShiftRing` custom painter: arco blu → verde, dot buono pasto, anello OT arancione.
- **ui** — `DayCheckpoints` timeline: Entrata → Pausa → Buono → Fine turno → Straordinario.
- **ui** — Icone nav aggiornate: `home_rounded`, `calendar_month_rounded`, `group_rounded`.

### Dashboard
- **feat** — Stato `WorkState.completed` aggiunto: dopo "Timbra Uscita" la dashboard mostra il riepilogo della giornata. — [`entities/timer-state.md`](./entities/timer-state.md)
- **feat** — Pulsante **Smart Working** 🏠 one-tap affianco a "Timbra Entrata": registra giornata remota + buono pasto automatico. — [`features/dashboard.md`](./features/dashboard.md)
- **feat** — Statistiche mensili (ore, buoni, straordinari, Art. 9) collegate a **dati reali Firestore** via `monthlyTimesheetsProvider` e `userProfileStreamProvider`.

### Timer
- **fix** — `_ticker` ora cancellato con `ref.onDispose` → nessun memory leak.
- **feat** — Tick a **1 secondo** (era 1 minuto) → anello live fluido.
- **feat** — `standardWorkMins` letto da `userProfile.standardDailyMins` via `ref.listen` (non più hardcoded 456).
- **feat** — **Persistenza mid-day su SharedPreferences**: se l'app viene chiusa durante il turno, lo stato viene ripristinato all'avvio se la data è ancora oggi. — [`entities/timer-state.md`](./entities/timer-state.md)

### Timesheet
- **fix** — Frecce di navigazione mensile (`‹` `›`) ora visibili e cliccabili — rimpiazzate con `Icon` Material + container touch-friendly 30 px.
- **feat** — Calendario più compatto (`childAspectRatio: 1.25`, celle 24 px).
- **feat** — **Inserimento manuale** giornate: bottom sheet con selettore data, tipo (Presenza / Smart Working / Permesso / Ferie) e TimePicker per entrata/uscita. — [`features/timesheet.md`](./features/timesheet.md)
- **feat** — Dot calendario colorati per `workType`: verde, arancione (OT), blu (remote), grigio (assenza).
- **feat** — Card dettaglio giornata mostra badge `workType` e barra colore coerente con il tipo.

### Modello dati
- **schema** — `DailyTimesheet` — aggiunto campo `workType: String?` (backwards-compatible: `null` → `'presence'`). — [`entities/daily-timesheet.md`](./entities/daily-timesheet.md)
- **schema** — `TimesheetRepository` — aggiunto metodo `saveRemoteWorkDay(stdMins)`.

### Autenticazione / Onboarding
- **fix** — `onboarding_screen.dart`: sostituito `ref.read(authStateChangesProvider).value` (lancia eccezione in Riverpod 3 se stream in loading) con `FirebaseAuth.instance.currentUser`. Questo era la causa principale del loop onboarding.
- **feat** — Tema persiste su `SharedPreferences`: scelta light/dark sopravvive ai riavvii. — [`shared/providers/global_providers.dart`](../lib/shared/providers/global_providers.dart)
- **feat** — `hasProfileStream` ora verifica `hasCompletedOnboarding == true` (non solo `doc.exists`) → onboarding non viene risaltato se il documento esiste parzialmente.

### Wiki
- **wiki** — Aggiornate: [`entities/timer-state.md`](./entities/timer-state.md), [`entities/daily-timesheet.md`](./entities/daily-timesheet.md), [`features/dashboard.md`](./features/dashboard.md), [`features/timesheet.md`](./features/timesheet.md).

---

## 2026-04-26 (v0.1 — Init)

- **wiki** — Creata struttura iniziale della wiki (`docs/`) e `CLAUDE.md` di radice. Documentate entità, feature, architettura. — [`README.md`](./README.md)
- **adr** — `ADR-0001 — Stack iniziale: Flutter + Riverpod 3 + Firebase + Drift`. — [`decisions/0001-stack-iniziale.md`](./decisions/0001-stack-iniziale.md)

---

## Convenzioni di compilazione

- **Una riga per cambiamento utente-visibile** (feature, refactor con effetto su API, modifica schema dati, dipendenza nuova).
- **Non duplicare** quello che già c'è in `git log`: questo file è per il *significato* del cambiamento, non per il diff.
- Per ogni modifica architetturale linkare la ADR corrispondente.
- Per ogni modifica a un'entità linkare la sua scheda in `docs/entities/`.
