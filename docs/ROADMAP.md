# Roadmap `chigio_time`

> Aggiornata al **2026-07-04**.
>
> **Struttura fissa di questo file — mantienila in ogni aggiornamento:**
> 1. **Attività** — tabella unica `Stato · Sprint · Data · Feature · Note`;
> 2. **Prossimo sprint** — le funzioni da implementare nel prossimo giro;
> 3. **Evoluzioni** — backlog raggruppato per argomento con stima
>    Impatto/Complessità (Basso/Medio/Alto);
> 4. **Fuori scopo** — non realizzabile, con motivo.
>
> Numerazione sprint: S-1…S-8 assegnati retroattivamente per cluster di date;
> S-9/S-10 saltati (allineamento con la numerazione storica S-11…S-14);
> da S-15 in poi progressivi. Stato: ✅ fatto · 🔜 pianificato · 💡 backlog.

---

## 1. Attività

| Stato | Sprint | Data | Feature | Note |
|---|---|---|---|---|
| ✅ | S-1 | 2026-05-21 | Autenticazione Google + Onboarding | Solo Google all'avvio. |
| ✅ | S-1 | 2026-05-21 | Dashboard cronometro turno + pause | Anello turno, DayCheckpoints, uscita prevista. |
| ✅ | S-1 | 2026-05-21 | MonthlySummaryCard | Art.9/SLI/SBO/OP, progress bar, collassabile. |
| ✅ | S-1 | 2026-05-21 | Widget contatori personalizzabile | Voci e barre scelte dall'utente. |
| ✅ | S-1 | 2026-05-21 | Totalizzatori portale PA | Chip used/total + badge data aggiornamento. |
| ✅ | S-1 | 2026-05-21 | Timesheet 3 viste (Lista/Sett/Mese) | Alert giornate mancanti, summary card. |
| ✅ | S-1 | 2026-05-21 | Social: gruppi + invio caffè | Gruppi su Firestore. |
| ✅ | S-1 | 2026-05-21 | Profilo editabile + statistiche | Stats mensili, tema persistito. |
| ✅ | S-1 | 2026-05-21 | Chigio mascotte + schermata Notifiche | 7 pose; coffee invite Accetta/Rifiuta. |
| ✅ | S-2 | 2026-05-25 | Coffee handshake completo + 3 risposte | `coffee_accepted`, ✅/🤔/❌ + messaggio. |
| ✅ | S-2 | 2026-05-25 | Totalizzatori editabili (portaleJson) | Form 30+ campi. |
| ✅ | S-2 | 2026-05-25 | Dipartimento + tema Sistema + favicon | Picker ☀️/🌙/📱. |
| ✅ | S-2 | 2026-05-25 | Nota attività giornaliera | Salvata su Firestore, visibile in timesheet. |
| ✅ | S-2 | 2026-05-25 | Inserimento retroattivo timesheet | `_EntrySheet` pre-popolato, edit da lista. |
| ✅ | S-3 | 2026-05-27/28 | Centralizzazione stringhe (`AppStrings`) | Mesi/giorni condivisi. |
| ✅ | S-3 | 2026-05-27 | Timesheet: summary pinned + auto-scroll a oggi | — |
| ✅ | S-3 | 2026-05-28 | Auto-abbandono turno alle 21:00 | `WorkState.abandoned` + CTA registra/ignora. |
| ✅ | S-3 | 2026-05-28 | CalVer (`YYYY.M.DD+build`) | — |
| ✅ | S-3 | 2026-05-28 | Social: colleghi live | `currentStatus` scritto dal timer, stream RT. |
| ✅ | S-4 | 2026-05-29 | Notifiche push FCM + Cloud Functions | Token, foreground snackbar, service worker web. |
| ✅ | S-4 | 2026-05-29 | Offline resilience (Drift) | Write-through + fallback offline. |
| ✅ | S-4 | 2026-05-29 | Auth email/password + onboarding esteso | Step 9-10 (dipartimento, SLI/SBO). |
| ✅ | S-4 | 2026-05-29 | Dark mode auto (orario) + i18n IT/EN | Auto 18-06; LocaleNotifier. |
| ✅ | S-4 | 2026-05-29 | Export PDF + Import CSV timesheet | `PdfExportService`, `CsvImportService`. |
| ✅ | S-4 | 2026-05-29 | Multi-ente/contratto + stats avanzate | 25 enti, preset orari; bar chart OT 6 mesi. |
| ✅ | S-5 | 2026-05-30 | Lotto UX multi-sprint | Template CSV, pill viste, ente solo PCM, preset orario. |
| ✅ | S-5 | 2026-05-30 | StatsScreen `/stats` | Media ore/gg, OT per giorno, permessi. |
| ✅ | S-5 | 2026-05-30 | Exit reminder in-app + GPS auto-timbratura | Geolocator, `GeofencingService`, ADR-0004. |
| ✅ | S-5 | 2026-05-30 | Chigio phrase engine + header avatar | 12 pool frasi, sottotitolo dinamico. |
| ✅ | S-5 | 2026-05-30 | Gruppi mobile + profilo desktop + contatori custom | CRUD Firestore, 6 preset PCM. |
| ✅ | S-6 | 2026-06-06 | BOE — Banca ore come esonero | Dialog fine turno, deduzione AP→AC. ADR-0007. |
| ✅ | S-6 | 2026-06-07 | Push uscita prevista + preferiti Home + filtri colleghi | `exitNotifMins`; `FavoriteColleaguesCard`. |
| ✅ | S-6 | 2026-06-07 | Drift WASM (logica) + cartellino PCM ufficiale | Asset build mancanti; PDF 11 colonne + firme. |
| ✅ | S-6 | 2026-06-07 | GPS clock-out background + stats avanzate | Streak, pausa media, puntualità. |
| ✅ | S-6 | 2026-06-07 | CCNL: conversioni md + tassonomia assenze P0/P1 | 2019-21 + 2016-18, `AbsenceKind`, consumo permessi. |
| ✅ | S-6 | 2026-06-07 | Lettore CCNL nel profilo | Indice articoli navigabile. |
| ✅ | S-6 | 2026-06-07 | Sedi PCM strutturate + Percorsi PCM in Home | 34 sedi Drift; `PcmRoutePlannerCard`. |
| ✅ | S-6 | 2026-06-07 | Backfill cartellino storico | 112 giornate importate in produzione. |
| ✅ | S-7 | 2026-06-09/10 | Stringhe residue + fix straordinari hardcoded | `stdMins` da profilo (era 456 fisso). |
| ✅ | S-7 | 2026-06-10 | Lotto P/S/T/H/I (18 item) | DND fascia oraria, dettaglio collega, visibilità widget Home, vista Anno, SmartExit 3 scenari, recap push, GDPR export, sezioni profilo, barra timbratura, link colleghi, Drift v4, badge anomalie, ricerca colleghi, quick note, tempi PCM. |
| ✅ | S-7 | 2026-06-10 | CCNL: variabili orario in `AppConstants` | `stdMinsForDate`, fix Comando 380, onboarding uniforme/misto. |
| ✅ | S-8 | 2026-06-10 | Profilo: foto visibile, riorganizzazione sezioni, Dati personali | `ProfileEditScreen`, card Inquadramento separata. |
| ✅ | S-8 | 2026-06-10 | Dashboard: dirty-check nota, Modifica giornata | — |
| ✅ | S-11 | 2026-06-11 | ShiftRing redesign + SAU mensile storico | `sau_monthly/{YYYY-MM}`, grafico in /stats. |
| ✅ | S-11 | 2026-06-11 | Upload foto profilo + gestione gruppi avanzata | Firebase Storage. |
| ✅ | S-11 | 2026-06-11 | Alert soglia OT mensile + Drift WASM asset | `monthlyOtAlertHours`; DB attivo su web. |
| ✅ | S-12 | 2026-06-11 | Onboarding Art.9 binario, SLI+SBO, Chigio saluto | Tetto = SLI+SBO read-only. |
| ✅ | S-12 | 2026-06-11 | Timesheet: SW counter, cerchi colorati, legenda, vista mese/settimana | Celle numerate, pannello 7 giorni. |
| ✅ | S-12 | 2026-06-11 | Privacy GDPR + stats estese + elimina gruppo | — |
| ✅ | S-12b | 2026-06-11 | Bug: sedi WASM fallback, drag handle, onboarding flag | — |
| ✅ | S-13 | 2026-06-11 | Fix import CSV (pausa, SLI/SBO, cleanNote) | + `kPcmDepartments` (62 strutture). |
| ✅ | S-14 | 2026-06-14 | Fix re-show onboarding offline + dedup profilo completo | `profileDocIsComplete` unica fonte. |
| ✅ | S-14 | 2026-06-14 | Fix split SBO/SLI (dati) + riorg .md radice | Ricalcolo 25 timesheet via cascata. |
| ✅ | S-14 | 2026-06-14/15 | Redesign Inquadramento + cap storicizzati | `capPeriods` effective-dated, editor Orario unificato, storico. ADR-0009. |
| ✅ | S-15 | 2026-06-15 | Pagina Stipendio (4ª tab) | Hero countdown, storico, notifica payday. ADR-0010. |
| ✅ | S-16 | 2026-06-23 | Lotto bug/feature (B1-B6, F1-F6) | Onboarding, sedi CAP, anello stato, vista anno responsive, reciprocità colleghi, profilo privato, import robusto. |
| ✅ | S-16 | 2026-06-23 | Progetti & Pomodoro (3ª tab) | Timer 25/5-45/15, riepiloghi, capo progetto. ADR-0011. |
| ✅ | S-16 | 2026-06-23 | Shortcut tastiera desktop | `1-5`/T/O/Esc/? — navbar 5 voci. |
| ✅ | S-17 | 2026-07-03 | Rivoluzione TimbraturaHero a 3 fasi | Chigio in scena, barre, resoconto; ShiftRing eliminato. |
| ✅ | S-17 | 2026-07-03 | Bulletproof pass + wiki riorganizzata | Shortcuts affidabili, sheet sopra navbar, FAB unificati. |
| ✅ | S-17 | 2026-07-03 | Release web v2026.07.03 (+15) | chigiotime.web.app. |
| ✅ | S-18 | 2026-07-04 | Slide-to-clock + long-press picker | Snackbar rimossi, `correctLastExit` eliminato. |
| ✅ | S-18 | 2026-07-04 | Fix Drift WASM su web | `sqlite3.wasm` in `web/` + worker ricompilato (fix `DiagnosticsNode`). |
| ✅ | S-18 | 2026-07-04 | Hero: animazioni fase, spinner, bounce invito, icona badge | AnimatedSwitcher/Size, haptics a tacche. |
| ✅ | S-18 | 2026-07-04 | Resoconto: contatori maggior presenza + modifica giornata inline | `showDayEntrySheet` condiviso; delete → `resetDay()`. |
| ✅ | S-18 | 2026-07-04 | Desktop: campanella+avatar in alto a destra | `HomeHeaderActions` fuori dall'hero ≥800px. |
| ✅ | S-18 | 2026-07-04 | Widget Home: mini-Chigio + ★ in evidenza | Posa per widget; sfondo gradiente blu (tema dark forzato). |
| ✅ | S-18 | 2026-07-04 | Impostazioni: sezione unica "Widget e visibilità" | Widget Home + navbar + statistica in evidenza in uno sheet. |
| ✅ | S-18 | 2026-07-04 | Inquadramento spostato in Dati personali | + riga "Andamento straordinario". |
| ✅ | S-18 | 2026-07-04 | Schermata `/sau` | Grafico 12 mesi SLI/SBO + storico variazioni (valore, da, a). |
| ✅ | S-18 | 2026-07-04 | Lettore CCNL leggibile | Premessa ripulita, commi stilizzati, ricerca nell'indice (fix ink ListTile). |
| ✅ | S-18 | 2026-07-04 | "Scarica i tuoi dati" accanto a Privacy | Sezione Info app. |
| ✅ | S-18 | 2026-07-04 | Roadmap ristrutturata | Questo formato a 4 sezioni. |
| ✅ | S-19 | 2026-07-05 | Fix assert render cancellazione giornata | AnimatedSize/Switcher → Stack layoutBuilder; niente più `RenderBox.size` assert su web. |
| ✅ | S-19 | 2026-07-05 | Widget Pomodoro + Stipendio in Home | `PomodoroCard` (timer live/avvio rapido), `SalaryCard` (countdown + stima netto). |
| ✅ | S-19 | 2026-07-05 | Widget Tabella orari | `OrariTableCard`: variante auto da `stdMinsForDate` + selettore. |
| ✅ | S-19 | 2026-07-05 | Header widget uniformi (stile Percorsi PCM) | `HomeWidgetHeader` con mini-Chigio + `HomeWidgetEmpty` per empty state. |
| ✅ | S-19 | 2026-07-05 | Widget flaggati sempre visibili + default nuovi account | Empty state con CTA; nuovi account = solo timbratura + CTA "Aggiungi widget". |
| ✅ | S-19 | 2026-07-05 | Rollback pannelli separati Widget e visibilità | Sezione dedicata, 3 pannelli (widget Home / navbar / statistica). |
| ✅ | S-19 | 2026-07-05 | Stato del giorno fuori da Dati personali + scadenza | Chip in card personale; `statusMessageUntil` (1h/4h/fine giornata). |
| ✅ | S-19 | 2026-07-05 | Campo Data presa servizio | Profilo (Dati personali) + onboarding, mai nel futuro; marker in `/sau`. |
| ✅ | S-19 | 2026-07-05 | SAU: naming, Luglio esteso, storico orario, ordine righe | SLI+SBO=SAU; nome mese esteso; storico orario in Storico inquadramenti; SAU sotto lo storico. |
| ✅ | S-19 | 2026-07-05 | Onboarding: accorpa step (11→9) + audit campi | Nome+genere e Art.9+SLI/SBO uniti; step scrollabili; verificato salvataggio. |
| ✅ | S-19 | 2026-07-05 | README stile top-repo | Badge, Chigio, presentazione, dettagli tecnici, comandi. |

---

## 2. 🔜 Prossimo sprint

> _Vuoto: da riempire con Marco._

---

## 3. 🧭 Evoluzioni (backlog per argomento)

Stime: **I** = impatto per l'utente, **C** = complessità (B/M/A).

### Stipendio
| Feature | I | C | Note |
|---|---|---|---|
| Stima netto da lordo (IRPEF + addizionali) | A | A | Sostituisce la media empirica. |
| Tredicesima / arretrati ricorrenti | M | B | Emissioni note previste nel countdown. |
| Confronto cedolini (delta mese-su-mese) | M | B | Evidenzia scostamenti anomali. |
| Allegato PDF cedolino (Storage) | M | M | Upload NoiPA, link dalla riga. |
| Grafico andamento netto annuale | M | B | Riusa `fl_chart`. |
| Riconciliazione buoni pasto | M | M | Maturati timesheet vs accreditati. |
| Export storico CSV/PDF | B | B | Riusa `share_plus`/`pdf`. |
| Import automatico da NoiPA | A | A | Fattibilità da verificare. |

### Progetti & Pomodoro
| Feature | I | C | Note |
|---|---|---|---|
| Stop pomodoro su timbratura uscita | M | B | Finalizza `confirmed: false`. ADR-0011. |
| Cessione capo progetto (UI) | B | B | `transferOwnership` esiste già. |
| Cleanup pomodori orfani | B | M | Dopo cancellazione/cambio visibilità progetto. |
| Cache locale Drift progetti | B | M | v1 è Firestore-only. |
| Statistiche pomodoro in /stats | M | B | Focus time per giorno/settimana. *(nuova)* |

### CCNL & assenze
| Feature | I | C | Note |
|---|---|---|---|
| Malattia e comporto personale | A | A | Range multi-giorno, stima comporto. Vedi `docs/ccnl/permessi-assenze-congedi.md`. |
| Ferie e festività soppresse (maturazione/residui) | A | M | Confronto AP/AC con totalizzatori. |
| Congedi, aspettative, studio 150h | M | A | Catalogo istituti + quote. |
| Profilo esigenze personali CCNL | B | M | Note private age management, genitorialità. |
| Reperibilità e attività non in turno | M | A | Art. 13-14: chiamata, riposo compensativo. |
| Welfare integrativo (promemoria) | B | B | Solo informativo, fuori dai calcoli. |
| Ricerca full-text nel lettore CCNL | M | B | Oggi la ricerca copre solo l'indice. *(nuova)* |

### Timesheet & dati
| Feature | I | C | Note |
|---|---|---|---|
| Import da timbrature digitali (CSV/XML terminali) | M | A | Formato dipende dal sistema PA. |
| Totalizzatori: import automatico dal portale | A | A | Fetch HTTP, URL da definire. |
| Totalizzatori: preset altri enti | B | B | MIUR, MEF, Salute in `kDefaultCountersByAdmin`. |
| Promemoria cartellino a fine mese | M | B | Push + export PDF pronto l'ultimo giorno. *(nuova)* |
| Export ICS turni/assenze verso calendario | M | M | Ferie e turni visibili in Google/Apple Calendar. *(nuova)* |
| Heatmap presenze annuale in /stats | B | B | Stile GitHub, riusa dati vista Anno. *(nuova)* |

### UX / Chigio / piattaforma
| Feature | I | C | Note |
|---|---|---|---|
| Nuovi avatar Chigio (10 pose proposte) | M | M | Vedi `docs/funzionalita/chigio.md`. |
| Streak & traguardi con Chigio (gamification leggera) | M | M | Badge presenze/puntualità, festeggia al traguardo. *(nuova)* |
| Notifica intelligente pausa pranzo | M | B | Avviso quando scatta il pranzo forzato (regola 3 zone). *(nuova)* |
| Prompt installazione PWA + banner offline | M | B | `beforeinstallprompt` su web. *(nuova)* |


---

## 4. 🚫 Fuori scopo (non realizzabile)

| Feature | Ambito | Motivo |
|---|---|---|
| Widget nativo iOS/Android (home screen di sistema) | Mobile | Richiede Kotlin/Swift fuori dallo scope Flutter. |
| Traduzione EN completa | UX | App usata solo in contesto PCM italiano. |
| Workflow autorizzativo PA | Workflow | L'app è un registro personale, non gestisce approvazioni ufficiali. |
| QR code timbratura ai tornelli | Mobile | Richiede integrazione con terminali fisici PA. |
| Import automatico NoiPA senza API ufficiali | Backend | Nessuna API pubblica; scraping autenticato fragile e fuori policy. |
