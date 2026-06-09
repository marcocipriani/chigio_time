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

---

## 🔜 Prossimo sprint

### 🏠 Home (Dashboard)

| # | Feature | Dettaglio |
|---|---|---|
| H0 | **Barra timbratura con cancelli orari** | Redesign completo del widget heroCard + DayCheckpoints in un'unica barra di progresso oraria. Cancelli colorati per zona: **buono pasto** (verde, soglia `mealThresholdMins`), **fine turno standard** (blu, `standardWorkMins`), **9h** (arancione, 540 min), **9h + pausa pranzo** (rosso, 570 min con 30 min forzati). Chigio rimane visibile dentro il widget con l'avatar contestuale. La barra avanza in tempo reale durante il turno. |
| H1 | **Banca ore — alert + giorni coperti** | Alert configurabile quando banca ore supera soglia. Mostra quante giornate lavorative complete si possono coprire con il saldo attuale (es. "3 giorni 7h36" per Ruolo, "3 giorni 7h12" per Comando) — utile per pianificare giorni BOE interi senza lavorare. |
| H4 | **SmartExit — tre scenari uscita** | Widget attivo durante turno. Calcola in tempo reale tre orari uscita proposti: **Pareggio giornaliero** (azzera deficit oggi), **Pareggio mensile** (porta il mese a zero deficit), **Ora extra utile** (accumula +1h di straordinario). Mostra scostamento rispetto alla media dello stesso giorno della settimana nel mese. |
| H5 | **Quick note dal widget note** | Pulsante `+` sul widget nota giornaliera in dashboard — apre direttamente il campo testo senza passare per il dettaglio giornata. |
| H6 | **Widget spostamenti sede — tempi istituzionali** | `PcmRoutePlannerCard` mostra, accanto alla stima Haversine locale, anche il **tempo di percorrenza istituzionale** dalla tabella PCM (es. Palazzo Chigi–EUR: 25 min). Il tempo istituzionale è quello ufficialmente riconosciuto come tempo di spostamento sede, distinto dalla stima reale. Tabella da aggiornare in `pcm_locations.dart`. |

### 📅 Timesheet

| # | Feature | Dettaglio |
|---|---|---|
| T2 | **Colori per tipo giornata** | Indicatore visivo colorato per tipo in lista e viste calendario: presenza (verde), smart working (blu), ferie (giallo), permesso/assenza (viola), anomala (rosso). In aggiunta ai chip filtro già presenti. |
| T3 | **Pill "Anno" — vista annuale** | Nuova pill "Anno" nel selettore viste del Timesheet. Griglia 12 mesi × giorni, ogni cella colorata per tipo giornata con intensità proporzionale alle ore lavorate. Mostra pattern presenze, streak e confronto con anno precedente. |
| T4 | **Alert giornate anomale** | Badge su giornate con `netWorked > 600 min` o `netWorked < 120 min` (esclude assenze e SW). |
| Tbug | **🐛 Fix calcolo straordinari `marcocipriani.pcm`** | Le ore di straordinario non vengono conteggiate correttamente per l'account di produzione. Causa probabile: `lunchPauseMins` sommato erroneamente nel calcolo `netWorkedMins` o `extraMins`. Verificare tutte le giornate del mese con `extraMins` negativo o nullo nonostante turni lunghi. |
| Tcheck | **Verifica export CSV e PDF** | Verificare che export CSV (`CsvImportService`) e PDF cartellino ufficiale PCM (`PdfExportService.exportOfficialCartellino`) producano file corretti su tutti i casi: assenze, SW, BOE, note riservate. |

### 👥 Social

| # | Feature | Dettaglio |
|---|---|---|
| S1 | **Ricerca testo nella lista colleghi** | Campo di ricerca libera per nome sopra la lista; filtra in tempo reale. |
| S2 | **Notifica mattutina "Colleghi in ufficio"** | Push all'ora X configurabile in Profilo (default 09:00): mostra quanti colleghi sono già in ufficio, con avatar. Utile per decidere se andare in presenza. Opzionale, attivabile in Profilo. |
| S3 | **Schermata dettaglio collega** | Tap sulla card collega → schermata dedicata con tutti i campi visibili (nome, dipartimento, sede, piano, stanza, interno, cellulare) e storico caffè scambiati con quella persona nel mese corrente e ultimi 3 mesi. Pulsanti chiama interno / chiama cellulare / invia caffè. |
| S4 | **Stato del giorno (messaggio breve)** | Campo opzionale nel proprio profilo (max 40 caratteri, es. "Qui fino alle 17:00", "In riunione tutto il pomeriggio"). Visibile nella schermata dettaglio collega. Nella lista sociale, asterisco `*` sulla label di stato indica che il collega ha un messaggio attivo. |
| S5 | **Aggiunta colleghi via link/QR** | Deep link `chigiotime.web.app/add?uid=…` o QR generato dal profilo; semplifica l'onboarding social in ufficio. |

### 👤 Profilo

| # | Feature | Dettaglio |
|---|---|---|
| P1 | **Silenzio notifiche** | Toggle semplice: on/off manuale oppure fascia oraria programmata (da–a, es. 20:00–08:00). Nessuna granularità per tipo di notifica. |
| P2 | **Recap settimanale push** | Notifica push riassuntiva. Default: venerdì ore 18:00. Configurabile (giorno della settimana + ora) in Profilo. Contenuto: ore totali, OT/deficit settimanale, giorni SW, caffè scambiati. |
| P4 | **Scarica i tuoi dati** | Sezione "Scarica i tuoi dati" in Profilo. Export ZIP con: `timesheets.csv` (tutte le giornate), `profile.json`, `notifications.json`. Copertura GDPR minima. |
| P5 | **Ristrutturazione sezioni Profilo** | Nuova organizzazione della schermata Profilo in 4 sezioni distinte: **(1) Card personale** — avatar, badge "Timbronauta", nome e ruolo, tap per modificare tutti i dettagli (rimosso link diretto alle statistiche); **(2) Statistiche** — grafici avanzati `StatsScreen` e tutte le opzioni correlate (soglie, obiettivi); **(3) Opzioni app** — tema, notifiche (silenzio, recap, uscita), GPS, lingua, scarica dati; **(4) Info app** — versione, galleria Chigio, download APK Android, crediti. |
| P6 | **Visibilità widget Home personalizzabile** | Sezione in Profilo (o in Impostazioni app) con toggle per ogni widget della dashboard: Barra timbratura, Colleghi preferiti, Maggior Presenza, Contatori custom, Banca Ore, Totalizzatori portale, Percorsi PCM. Stato salvato su Firestore (`users/{uid}/profile.homeWidgets`). La dashboard legge i flag e mostra/nasconde ogni sezione in base alle preferenze. |

### 🔧 Infra / Notifiche

| # | Feature | Dettaglio |
|---|---|---|
| I1 | ⚠️ **Verifica rules/funzione `exit_reminder`** | Allineare `timer_provider.dart`, `firestore.rules` e `functions/index.js` sui campi `notifications` creati dai promemoria uscita prevista. Priorità alta: possibili scritture non autorizzate o promemoria silenziosi. |
| I2 | ⚠️ **Drift schema v4 per assenze** | Aggiungere alla cache `timesheet_entries` i campi `absenceKind`, `absenceUnit`, `absenceMins`, `absenceDays`, `periodStart/End`, `quotaYear`, `sensitive`, `hasDocumentation`, `countsAsSicknessPeriod`. Necessario per offline completo. |

---

## 📋 Backlog (non schedulato)

| Feature | Ambito | Note |
|---|---|---|
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
