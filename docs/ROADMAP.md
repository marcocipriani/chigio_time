# Roadmap `chigio_time`

> Stato al **2026-06-09**. Le voci senza data sono backlog non schedulato.
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
| 2026-06-09 | Centralizzazione stringhe — completamento | Core | Estratte stringhe residue: `'In ufficio'`/`'Da remoto'`/`'In pausa'` in `social_screen.dart` → `AppStrings.statusWorking/Remote/Paused`; `'Inquadramento'` in `onboarding_screen.dart` → `AppStrings.employmentType`; aggiunte costanti `AppStrings.etRuolo/etComando/etAltro` usate in 22 punti (comparazioni Firestore + chip UI) in `onboarding_screen.dart`, `onboarding_provider.dart`, `profile_screen.dart` e switch `stdMinsByType`/`mealMinsByType`. |

---

## 🔜 Prossimo sprint

| # | Feature | Ambito | Dettaglio |
|---|---|---|---|
| 1 | **Totalizzatori — import da portale HTTP** | Backend | Fetch automatica dal portale PA (URL da definire); sostituisce l'inserimento manuale. |
| 2 | **Totalizzatori: predefiniti per altri enti** | Dashboard | Estendere `kDefaultCountersByAdmin` con preset per MIUR, MEF, Ministero della Salute, etc. |
| 3 | **Banca ore — alert e previsioni** | Dashboard | Alert quando banca ore supera soglia; previsione smaltimento automatico. |
| 4 | **Backfill assenze storiche** | Dominio | Script una-tantum su export Firestore: valorizza `absenceKind`/`absenceUnit` sulle entries `leave`/`holiday` esistenti per euristica (durata, note "Art.9", giornata intera). Da concordare su come/quando girarlo in prod. Fondazione P0 gia' in `daily_timesheet.dart`/`_EntrySheet`/CSV — vedi `docs/ccnl/permessi-assenze-congedi.md`. |
| 5 | **Quiet hours e disconnessione** | Profilo/Notifiche | Preferenze personali per silenziare notifiche non urgenti fuori orario, collegate al contesto CCNL 2019-2021 Art. 7. |
| 6 | **Export XLSX** | Timesheet | Fogli di calcolo compatibili con sistemi di gestione presenze PA. |
| 7 | **Verifica rules/funzione `exit_reminder`** | Notifiche | Allineare `timer_provider.dart`, `firestore.rules` e `functions/index.js` sui campi creati in `users/{uid}/notifications` dai promemoria uscita prevista. |

---

## 📋 Backlog (non schedulato)

| Feature | Ambito | Note |
|---|---|---|
| Import automatico da timbrature digitali | Timesheet | Lettura CSV/XML dai terminali di timbratura (formato dipende dal sistema PA). |
| Malattia e comporto personale | Dominio | Range multi-giorno, giorni calendario, stima comporto, categorie gravi patologie/infortunio. Vedi `docs/ccnl/permessi-assenze-congedi.md`. |
| Ferie e festivita' soppresse personali | Timesheet | Maturazione/residui AP-AC e confronto con totalizzatori; niente workflow autorizzativo. |
| Congedi, aspettative, studio/formazione | Dominio | Catalogo personale per congedi parentali, aspettative, studio 150h/160h, formazione e istituti sensibili con privacy. |
| Drift schema v4 per assenze | Core | Aggiungere alla cache `timesheet_entries` i campi `absenceKind`, `absenceUnit`, `absenceMins`, `absenceDays`, `periodStart/End`, `quotaYear`, `sensitive`, `hasDocumentation`, `countsAsSicknessPeriod`. |
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
