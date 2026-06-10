# Roadmap `chigio_time`

> Stato al **2026-06-10**. Le voci senza data sono backlog non schedulato.
> Aggiorna questo file a ogni sprint, segnando la data di completamento a fianco della voce.

---

## ✅ Completato

| Data | Feature | Note |
|---|---|---|
| 2026-05-21 | Autenticazione Google + Onboarding | Solo Google. No email/password. |
| 2026-05-21 | Dashboard cronometro turno + pause | Anello turno, DayCheckpoints, uscita prevista. |
| 2026-05-21 | Dashboard MonthlySummaryCard | Art.9 / SLI / SBO / OP, progress bars, collassabile. |
| 2026-05-21 | Widget contatori personalizzabile | Utente sceglie voci e progress bar visibili. |
| 2026-05-21 | Totalizzatori portale PA | Sezione dedicata con chip used/total e badge data agg. |
| 2026-05-21 | Timesheet 3 viste (Lista/Sett/Mese) | Alert giornate mancanti, summary card in ogni vista. |
| 2026-05-21 | Social — gruppi + invio caffè | UI implementata; gruppi su Firestore. |
| 2026-05-21 | Profilo — editabile + statistiche | Stats mensili, notifiche UI, tema persistito. |
| 2026-05-21 | Chigio — mascotte interattiva | 7 immagini, bounce + fade, dot indicator. |
| 2026-05-21 | Schermata Notifiche | Coffee invite con Accetta/Rifiuta. |
| 2026-05-25 | Coffee handshake completo | Accettazione invia notifica `coffee_accepted` al mittente. |
| 2026-05-25 | Totalizzatori — editabile dall'utente | Form 30+ campi, salvataggio su Firestore (`portaleJson`). |
| 2026-05-25 | Campo Dipartimento nel profilo | Testo libero, persistito su Firestore. |
| 2026-05-25 | Tema automatico (Sistema) | Picker 3 stati: ☀️ Chiaro / 🌙 Scuro / 📱 Sistema. |
| 2026-05-25 | Link impostazioni dal widget blu | Icona `tune` nell'header → naviga a Profilo. |
| 2026-05-25 | Favicon e manifest web aggiornati | File corretti in `web/icons/`; manifest referenzia file reali. |
| 2026-05-25 | Coffee — 3 risposte + messaggio | ✅ Ci sono / 🤔 Forse / ❌ Non posso + textarea opzionale; back-notify sempre. |
| 2026-05-25 | Coffee su tutti i colleghi | Icona ☕ visibile su tutti (non solo working/paused). |
| 2026-05-25 | Nota attività giornaliera | Textarea + salva Firestore in Dashboard (turno completato / SW); visibile in lista timesheet. |
| 2026-05-25 | Inserimento retroattivo timesheet | `_EntrySheet` pre-popolato da entry esistente; edit button su `_DayDetailCard`; tap riga lista. |
| 2026-05-25 | Version chip + profilo | `v0.8-dev` in GlassHeader (chip) e fondo ProfileScreen. |
| 2026-05-25 | MonthlySummaryCard fix | Header blu larghezza piena; Personalizza spostato in sezione espansa. |
| 2026-05-27 | Strings centralization (`AppStrings`) | Core | Tutte le stringhe UI spostate in `lib/core/constants/app_strings.dart`; array mesi/giorni condivisi. |
| 2026-05-27 | Timesheet — Lista: summary pinned + auto-scroll | Timesheet | `MonthlySummaryCard` fissato sopra la lista (non scrolla); auto-scroll a oggi al primo render del mese corrente. |
| 2026-05-28 | Auto-abbandono turno alle 21:00 | Dashboard | `WorkState.abandoned`: ticker rileva turno aperto dopo le 21:00 → rimuove utente da "In ufficio" su Firestore, persiste warning su SharedPreferences; CTA dashboard "Registra uscita" / "Ignora giornata". |
| 2026-05-28 | CalVer versioning (`YYYY.M.DD+build`) | Infra | `pubspec.yaml` → `2026.5.28+1`; `AppStrings.appVersion` → `v2026.05.28`; README aggiornato con tabella funzionalità e sezione deploy. |
| 2026-05-28 | Social — lista colleghi live | Social | `watchColleagues` usa stream Firestore RT; `currentStatus`/`statusDate` scritti da `timer_provider` ad ogni transizione. Stato colleghi aggiornato in tempo reale. |
| 2026-05-29 | Timesheet — mealThreshold da profilo | Timesheet | `mealVoucherThresholdMins` letto da profilo Firestore invece di costante 380 hardcoded. |
| 2026-05-29 | Notifiche push reali (FCM) | Backend | Client: permission + token → Firestore, foreground SnackBar, tap handler. Cloud Functions: push su create `notifications/{id}`. Web: service worker. |
| 2026-05-29 | Offline resilience (Drift) | Core | `AppDatabase` SQLite con `TimesheetEntries`; write-through su ogni save Firestore; fallback su Drift quando offline. |
| 2026-05-29 | Autenticazione email/password | Auth | `signInWithEmail`, `registerWithEmail`, `sendPasswordReset` + form registrazione/login in `LoginScreen`. |
| 2026-05-29 | Dark mode automatica (⏰ Auto) | UX | Modalità Auto nel tema: dark dalle 18:00, light dalle 06:00. `AppLifecycleListener` aggiorna al resume. |
| 2026-05-29 | Multi-ente / multi-contratto | Dominio | `AppStrings.administrations` espanso a 25 enti PA italiani; `employmentTypes` + preset ore/soglia per tipo contratto. |
| 2026-05-29 | Statistiche avanzate | Profilo | Bar chart OT ultimi 6 mesi in profilo (`fl_chart`). |
| 2026-05-29 | Onboarding multi-step avanzato | Auth | Step 9 (Dipartimento) e step 10 (SLI/SBO target) aggiunti all'onboarding; persistiti su Firestore. |
| 2026-05-29 | Gruppi social — stato aggregato | Social | `_GroupTile` mostra "X/N 🏢" membri in ufficio in verde; calcolato cross-referencing `colleaguesStreamProvider`. |
| 2026-05-29 | Caffè — storia + statistiche | Social | `coffeeLogStreamProvider` + `coffeeStatsProvider` attivi; `_CoffeeToggleCard` mostra inviati/ricevuti/accettati del mese. |
| 2026-05-29 | Export PDF timesheet | Timesheet | `PdfExportService` genera PDF A4 con tabella giornate + summary; condivisione via `printing`. |
| 2026-05-29 | Import CSV timesheet | Timesheet | `CsvImportService` apre file picker, parsa CSV semicolon-separated, importa giornate. Menu ⋮ in timesheet. |
| 2026-05-29 | Internazionalizzazione (IT/EN) | UX | `LocaleNotifier` + toggle 🇮🇹/🇬🇧 in profilo; `MaterialApp` wired con `flutter_localizations`; widget nativi usano locale corretta. |
| 2026-05-30 | UX multi-sprint: strings, profilo, colleghi, timesheet, dashboard | UX | Template CSV scaricabile; pill vista compatte; riordino campi profilo; ente solo PCM; preset orario per tipo contratto; widget in evidenza; chiamata collega; tabella orari ordinata ascending. |
| 2026-05-30 | Statistiche avanzate | Profilo | `StatsScreen` (`/stats`): media ore/gg, OT per giorno settimana, permessi-ferie — 3 bar chart + tabella entrata media. Link dall'avatar card. |
| 2026-05-30 | Exit reminder in-app | Dashboard | SnackBar arancione quando `remainingTime ≤ 15 min` (one-shot via `TimerState.exitReminderPending`). |
| 2026-05-30 | GPS auto-timbratura | Dashboard/Profilo | `geolocator ^13`; `GeofencingService`; `_GpsSettingsCard` in profilo; `_GpsPromptCard` in dashboard; ADR-0004. |
| 2026-05-30 | Chigio mascotte — header avatar + frasi | UX | `ChigioPhraseEngine` (12 pool frasi); avatar pulsante in header; dialog contestuale; doc pagina dedicata; 10 nuovi avatar proposti. |
| 2026-05-30 | Chigio non-cliccabile + frase come sottotitolo | UX | Avatar solo decorativo; frase Chigio come sottotitolo dinamico dell'header. Versione pill rimossa dall'header. |
| 2026-05-30 | Gruppi da mobile | Social | `_GroupsMobileSheet`: lista gruppi, crea/elimina/invia caffè. Su desktop pannello laterale invariato. |
| 2026-05-30 | Profilo — layout desktop | UX | `maxWidth: 720` centrato. Emoji 🐢 corretta. |
| 2026-05-30 | Contatori personalizzati Totalizzatore | Dashboard | `CustomCounter`, `customCountersProvider`, CRUD Firestore, importa predefiniti PCM (6 contatori). |
| 2026-06-06 | BOE — Banca Ore come Esonero | Dashboard | `bancaOreMins`/`boeSlot` su `DailyTimesheet`; dialog a fine turno; deduzione AP→AC; `BancaOreTile` live delta. ADR-0007. |
| 2026-06-07 | Notifica push FCM uscita prevista | Notifiche | `exitNotifMins` su profilo (picker 0/5/10/15/30 min); soglia timer configurabile; write Firestore `notifications` alla scadenza. |
| 2026-06-07 | Widget colleghi preferiti in Home | Dashboard | `FavoriteColleaguesCard`: 4 avatar circolari con quick-action caffè/chiama. |
| 2026-06-07 | Filtri colleghi per Sede/Dipartimento/Stato | Social | `_ColleagueFilterBar`: chip scroll orizzontale; filtri cumulativi reset-on-tap. |
| 2026-06-07 | Contatori custom su Dashboard Home | Dashboard | `_HomeCountersRow`: strip orizzontale scorrevole con chip colorati, mostra tutti i `customCounters`. |
| 2026-06-07 | Drift WASM su web (logica) | Core | `connection_web.dart` usa `WasmDatabase.open()`; `drift_worker.dart` entry point pronto; `appDatabaseProvider` attivo anche su web. Mancano asset build-time (`sqlite3.wasm`, `drift_worker.dart.js`). |
| 2026-06-07 | Cartellino mensile ufficiale PCM | Timesheet | `PdfExportService.exportOfficialCartellino()`: layout PCM con header ente/dipendente/sede, tabella 11 colonne, firma tripla, watermark "Generato con Chigio Time". Pulsante toolbar `assignment_rounded`. |
| 2026-06-07 | GPS auto clock-out background | Mobile | `GeofencingService.startExitMonitor()`: stream posizione con `distanceFilter: 50 m`; `ACCESS_BACKGROUND_LOCATION` Android; `NSLocationAlwaysUsageDescription` + `UIBackgroundModes: location` iOS. |
| 2026-06-07 | Statistiche personali avanzate | Profilo | `_AdvancedStatsCard` in `StatsScreen`: record streak presenze, pausa media, percentuale puntualità (±15 min da 09:00). |
| 2026-06-07 | CCNL — specifica permessi/assenze personali | Docs | `docs/ccnl/permessi-assenze-congedi.md`: tassonomia personale, modello `absenceKind`, P0 completata e backlog P1-P3. |
| 2026-06-07 | CCNL PCM 2019-2021 — conversione e confronto | Docs | `ccnl-pcm-2019-2021.md` generato da PDF locale; `confronto-2016-2018-2019-2021.md` mappa articoli sostituiti, conferme della base precedente e impatto sull'app. |
| 2026-06-07 | CCNL — adeguamenti dominio post 2019-2021 | Docs/Dominio | Aggiornati riferimenti per permessi, visite, malattia, gravi patologie, congedi riservati, studio, formazione, welfare e disconnessione. |
| 2026-06-07 | Lettore CCNL nel Profilo | Profilo | Sezione `CCNL PCM` con lettura completa dei Markdown 2019-2021 e 2016-2018, etichette nuovo/precedente e indice articoli navigabile. |
| 2026-06-07 | Tassonomia assenze — fondazione P0 | Dominio/Timesheet | `AbsenceKind`/`AbsenceUnit`, campi `absenceKind/Unit/Mins/Days/period*/quotaYear/sensitive/personalNote/hasDocumentation/countsAsSicknessPeriod` su `DailyTimesheet`, selettore causale in `_EntrySheet`, colonne CSV `assenza_*` con oscuramento per assenze riservate. Vedi `docs/ccnl/permessi-assenze-congedi.md` P0. |
| 2026-06-07 | Backfill cartellino storico (script una tantum) | Dominio/Dati | Importate in produzione le 112 giornate di `2026-cartellino-import.csv` per `marcocipriani.pcm@gmail.com`: 103 nuove + 3 correzioni conflitto (`2026-04-27`, `2026-05-13`, `2026-06-01`). Verificato 0 mancanti post-import. Script rimosso dal repo a fine corsa. |
| 2026-06-07 | Permessi orari e malattia — confronto consumo (P1) | Timesheet/Dashboard | `AbsenceConsumption`/`AbsencePlafonds`/`SicknessPeriod` (`absence_consumption.dart`) + `personalAbsenceConsumptionProvider`: somma `absenceMins` per `short_leave`/`personal_family_hourly`/`specialist_visit` nell'anno corrente, raggruppa `sickness` in periodi multi-giorno. `TotalizzatoriSection` mostra il confronto "App: Xh su plafond" sotto i chip permessi e una sotto-sezione "MALATTIA — periodi". |
| 2026-06-07 | Sedi PCM strutturate | Profilo/Auth/Core | `pcmOfficeSeeds` con 34 struttura/sede, tabella Drift `pcm_office_locations`, repository con fallback seed, dropdown sede in onboarding/profilo con salvataggio id/indirizzo/coordinate. |
| 2026-06-07 | Widget Percorsi PCM in Home | Dashboard | `PcmRoutePlannerCard`: dropdown Da/A, modalità a piedi/bici/auto-navetta, stima Haversine locale, inverti percorso e apertura Google Maps. |
| 2026-06-07 | Chigio quote dedicate e header budget | UX/Docs | `ChigioQuotes` separa le quote dal motore; 79 frasi curate, zero duplicati normalizzati, frase max 58 caratteri e label max 17 con nome lungo. Doc `features/chigio.md` aggiornata. |
| 2026-06-10 | Rimozione MonthlySummaryCard da Home | Dashboard | `MonthlySummaryCard` rimosso dalla statsSection; variabili non più usate (`totalNetMins`, `art9UsedMins`, `sliUsedMins`, `sboUsedMins`, `orePerseMins`, `mealCount`, caps inutilizzate) pulite dal build. |
| 2026-06-10 | Maggior Presenza — OPE sempre visibile | Dashboard | Chip OPE in `_MaggiorPresenzaCard` sempre mostrato quando `totalCap > 0`, anche a 0h; colore grigio quando nessuno sforamento, rosso quando `opeAlloc > 0`. |
| 2026-06-09 | Centralizzazione stringhe — completamento | Core | Estratte stringhe residue: `'In ufficio'`/`'Da remoto'`/`'In pausa'` in `social_screen.dart` → `AppStrings.statusWorking/Remote/Paused`; `'Inquadramento'` in `onboarding_screen.dart` → `AppStrings.employmentType`; aggiunte costanti `AppStrings.etRuolo/etComando/etAltro` usate in 22 punti. |
| 2026-06-09 | Social — rinomina gruppi, caffè sempre visibile, due telefoni, chip gruppo | Social | Pulsante rinomina su ogni gruppo; ☕ sempre visibile (grigio se non disponibile); due pulsanti telefono separati (interno/cellulare); chip gruppo accanto al nome; info card ristrutturata con dipartimento. |
| 2026-06-10 | Tbug — Fix calcolo straordinari `marcocipriani.pcm` | Timesheet | `_save()` in `timesheet_screen.dart`: rimossi i tre `456` hardcoded, sostituiti con `stdMins` letto da `userProfileStreamProvider`; branch smart-working usa lo stesso. |
| 2026-06-10 | I1 — Fix exit_reminder Firestore rules + Cloud Function | Infra | `firestore.rules`: proprietario del documento può creare con qualsiasi campo (self-write per uscita prevista); `functions/index.js`: aggiunto `case 'exit_reminder'` in `_buildNotification`. |
| 2026-06-10 | S4 — Stato del giorno (messaggio breve) | Social/Profilo | Campo `statusMessage` (max 40 car.) in `ColleagueProfile` + profilo utente; visualizzato in `_ColleagueCard` e dettaglio collega con icona chat. |
| 2026-06-10 | P1 — Silenzio notifiche con fascia oraria | Profilo | `_NotificationSheet`: toggle DND + picker ora Da/A. Campi `doNotDisturb`, `silenceFrom`, `silenceTo` salvati su Firestore. |
| 2026-06-10 | S3 — Schermata dettaglio collega | Social | `_ColleagueDetailSheet` con `DraggableScrollableSheet`: avatar, stato, messaggio, info rows, storico caffè filtrato per collega. |
| 2026-06-10 | P6 — Visibilità widget Home | Profilo/Dashboard | `_showHomeWidgetsCustomizer` in profilo: toggle per 6 widget; lista `hiddenHomeWidgets` su Firestore; dashboard legge e nasconde sezioni. |
| 2026-06-10 | T3 — Vista annuale timesheet | Timesheet | Pill "Anno" nel selettore; `_YearView` carica 12 mesi via `monthlyTimesheetsProvider`; `_MiniMonthGrid` con dot colorati per tipo (verde/blu/ambra/viola). |
| 2026-06-10 | H4 — SmartExit tre scenari | Dashboard | `_SmartExitScenarios`: 3 chip (giornaliero verde, +1h arancione, pareggio mensile blu); deficit mensile calcolato da giorni lavorativi passati nel mese. |
| 2026-06-10 | S2 — Notifica mattutina colleghi | Profilo/Backend | `_NotificationSheet`: toggle + picker ora `morningColleaguesHour`; Cloud Function `hourlyNotifications` invia push con count ufficio/SW. |
| 2026-06-10 | P2 — Recap settimanale push | Profilo/Backend | `_NotificationSheet`: toggle + picker giorno/ora; Cloud Function invia recap (ore, OT, buoni) nel giorno/ora configurato. |
| 2026-06-10 | P4 — Scarica i tuoi dati (GDPR) | Profilo | `_downloadMyData()`: legge profilo + timesheets + notifiche da Firestore, serializza in CSV/JSON, condivide via `share_plus`; compatibile web (`XFile.fromData`) e mobile (file temp). |
| 2026-06-10 | P5 — Ristrutturazione sezioni Profilo | Profilo | 4 sezioni con `_SectionLabel`: Card personale → Statistiche → Opzioni app → Info app; `_OtTrendCard` spostata in Statistiche; appInfo/chigio in card separata "Info app". |
| 2026-06-10 | H0 — Barra timbratura con cancelli orari | Dashboard | `_TimbraturaBarra`: progress bar orizzontale (Art.9/BP/FS) integrata nel heroCard; `DayCheckpoints` rimosso come widget separato. |
| 2026-06-10 | S5 — Aggiunta colleghi via link | Social | `_AddColleagueSheet`: sezione "Condividi il tuo link" con copia/condividi via `share_plus`; campo incolla link/UID con regex 20-40 char + parsing `?uid=`. |
| 2026-06-10 | I2 — Drift schema v4 per campi assenza | Core | `TimesheetEntries`: 10 nuove colonne (`absenceKind/Unit/Mins/Days`, `periodFrom/To`, `quotaYear`, `sensitive`, `hasDocumentation`, `countsAsSicknessPeriod`); migrazione `from < 4` con ALTER TABLE. |
| 2026-06-10 | Tcheck — Fix PDF export edge case | Timesheet | `pdf_export_service.dart`: note mascherate con `'—'` per `e.sensitive`; orari nascosti per ferie e permessi giornalieri (00:00 → `'—'`). |
| 2026-06-10 | H1 — Banca ore alert + giorni coperti | Dashboard | Alert soglia banca ore con chip "X giorni coperti"; `_BancaOreAlert` in dashboard. |
| 2026-06-10 | H5 — Quick note dal widget note | Dashboard | Pulsante `+` nel widget nota giornaliera → apre direttamente il campo testo. |
| 2026-06-10 | H6 — Tempi istituzionali spostamenti PCM | Dashboard | `PcmRoutePlannerCard` mostra tempo di percorrenza istituzionale PCM accanto alla stima Haversine. |
| 2026-06-10 | S1 — Ricerca testo colleghi | Social | Campo ricerca libera per nome sopra la lista; filtro in tempo reale. |
| 2026-06-10 | T2 — Colori tipo giornata timesheet | Timesheet | Indicatori colorati per tipo in lista e viste calendario. |
| 2026-06-10 | T4 — Badge giornate anomale | Timesheet | Badge su giornate con `netWorked > 600 min` o `< 120 min` (escluse assenze/SW). |
| 2026-06-10 | CCNL — Refactor variabili orario schedule | Core/Profilo/Onboarding | Centralizzate in `AppConstants`: short/long/weekly mins, Art.9 cap mensile, `stdMinsForDate`. Fix `mealMinsByType` 360→380 per Comando. Onboarding step 5 picker uniforme/misto con selezione 2 giorni da 9h. Profilo mostra e permette di modificare variante orario. Timer/dashboard/timesheet leggono minuti per-giorno. |
| 2026-06-10 | Vista Anno — dot più piccoli con numeri | Timesheet | `_MiniMonthGrid`: dot ridotti (0.76→0.62×cellSize), numero del giorno visibile dentro ogni dot. |
| 2026-06-10 | Widget Home — checkbox + drag to reorder | Profilo/Dashboard | `_showHomeWidgetsCustomizer` usa `ReorderableListView` + checkbox; salva `homeWidgetsOrder` su Firestore; dashboard renderizza nell'ordine salvato. |
| 2026-06-10 | Profilo — card avatar senza statistiche | Profilo | Rimossi record/uscite/SW e link stats dalla card avatar; statistiche avanzate accessibili solo da `/stats`. |

---

## 🔜 Prossimo sprint

*(da definire — sprint precedente completato 2026-06-10)*

---

## 📋 Backlog (non schedulato)

| Feature | Ambito | Note |
|---|---|---|
| Gruppi — rimuovi gruppo, aggiungi/rimuovi utenti | Social | Pulsante elimina gruppo; bottom sheet gestione membri (aggiungi da lista colleghi, rimuovi singolo); da schermata dettaglio collega si può modificare l'appartenenza ai gruppi. |
| Profilo immagini visibili ai colleghi | Social | Attualmente solo iniziali colorate; se si vuole foto reale: salvare `photoURL` su Firestore e usarla nelle card collega (opt-in). |
| Totalizzatori — import da portale HTTP | Backend | Fetch automatica dal portale PA (URL da definire); sostituisce inserimento manuale. |
| Totalizzatori: predefiniti altri enti | Dashboard | Estendere `kDefaultCountersByAdmin` con preset MIUR, MEF, Ministero della Salute, ecc. |
| Alert soglia OT mensile personalizzata | Profilo/Notifiche | Notifica quando OT mensile supera soglia configurabile dall'utente (indipendente dai cap CCNL). |
| Import automatico da timbrature digitali | Timesheet | Lettura CSV/XML dai terminali di timbratura (formato dipende dal sistema PA). |
| Malattia e comporto personale | Dominio | Range multi-giorno, giorni calendario, stima comporto, categorie gravi patologie/infortunio. Vedi `docs/ccnl/permessi-assenze-congedi.md`. |
| Ferie e festivita' soppresse personali | Timesheet | Maturazione/residui AP-AC e confronto con totalizzatori; niente workflow autorizzativo. |
| Congedi, aspettative, studio/formazione | Dominio | Catalogo personale per congedi parentali, aspettative, studio 150h/160h, formazione e istituti sensibili con privacy. |
| Profilo esigenze personali CCNL 2019-2021 | Profilo | Note private per age management, genitorialita', inclusione disabilita' e accomodamenti; nessun workflow autorizzativo. |
| Reperibilita' e attivita' non in turno | Dominio | Eventi personali per Art. 13-14 CCNL 2019-2021: reperibilita', chiamata, riposo compensativo, festivo/non lavorativo. |
| Welfare integrativo come promemoria | Profilo | Eventuale sezione informativa personale per Art. 25 CCNL 2019-2021; fuori dai calcoli timesheet. |
| Chigio — nuovi avatar tartaruga (10 proposti) | UX | Illustrare: corsa, spiaggia, computer, champagne, pensiero, lente, ombrello, sole, trofeo, banca ore. Vedi `docs/features/chigio.md`. |
| Drift WASM web — asset build | Core | Compilare `drift_worker.dart.js` e copiare `sqlite3.wasm` in `web/`; la logica Dart è pronta (`connection_web.dart`). |

---

## 🚫 Non realizzabile (out-of-scope)

| Feature | Ambito | Motivo |
|---|---|---|
| Widget nativo iOS/Android | Mobile | Richiede codice Kotlin/Swift nativo fuori dallo scope Flutter. |
| Traduzione EN | UX | App usata solo in contesto PCM italiano; rimandato a data indeterminata. |
| Workflow autorizzativo PA | Workflow | Fuori scope: l'app gestisce registro personale, non richieste/approvazioni ufficiali di ferie e permessi. |
| QR code timbratura | Mobile | QR univoco utente per tornelli — richiede integrazione con terminali fisici PA. |
