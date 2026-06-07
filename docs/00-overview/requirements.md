# Analisi dei requisiti

> Documento estratto a partire dallo stato attuale del codice (`lib/`) e
> dalle decisioni implicite gia' codificate (es. soglie minuti standard).
> Quando un nuovo requisito viene scoperto o cambiato, **aggiornare questo
> file** e, se architetturalmente rilevante, aprire una ADR.

---

## RF — Requisiti funzionali

### Autenticazione & sessione

- **RF-01** L'utente accede tramite **Google Sign-In** oppure
  **email/password**.
- **RF-02** Su web l'autenticazione usa il popup di Firebase
  (`signInWithPopup`); su mobile usa il flusso `GoogleSignIn` v7
  (`initialize` → `authenticate` → `authorizationClient.authorizeScopes`).
- **RF-03** L'utente puo' registrarsi con email/password, fare login con
  email/password e richiedere il reset password via email.
- **RF-04** L'utente puo' fare logout (`disconnect` + `signOut`); lo
  `authStateChanges` di Firebase pilota il redirect del router.

### Onboarding

- **RF-05** Al primo accesso (documento utente assente in
  `users/{uid}`) viene mostrato il flusso di onboarding multi-step.
- **RF-06** Dati raccolti: `name`, `gender`, `administration` (default
  *"Presidenza del Consiglio dei Ministri"*), `employmentType`
  (`Ruolo` / `Comando`), `dipartimento`, `sede`, `sedeId`, `sedeAddress`,
  `sedeLat`, `sedeLng`, `standardDailyHours`, `mealVoucherThreshold`,
  `monthlyArt9Hours`, `monthlySliHours`, `monthlySboHours`,
  `monthlyOvertimeHours`, `themePreference`.
- **RF-07** Selezionando `employmentType` vengono pre-impostati valori
  contrattuali tipici:
  - **Ruolo:** 7h 36m / pausa pranzo 6h 20m / contatore legacy `art9` = 8h.
  - **Comando:** 7h 12m / pausa pranzo 6h 20m / contatore legacy `art9` = 17h.
- **RF-08** Al termine, lo stato viene scritto in `users/{uid}` con
  `hasCompletedOnboarding: true` e cache locale in `SharedPreferences`
  (`hasProfile_<uid>`).

### Dashboard giornaliera (timer)

- **RF-09** L'utente esegue **Timbra Entrata** scegliendo l'orario
  effettivo (TimePicker, non orario di sistema cieco).
- **RF-10** Durante il turno puo' avviare una pausa di tipo `lunch`,
  `short` (breve) o `leave` (permesso). La pausa termina con **Riprendi**.
- **RF-11** Durante il turno l'app calcola in tempo reale:
  - minuti lavorati netti (elapsed - somma pause);
  - **uscita prevista** = `startTime + standardWorkMins +
    totalStandardPauseMins + totalLunchPauseMins`;
  - se i minuti lavorati superano le 9 ore (540 min) **e** la pausa pranzo
    e' inferiore a 30 min, viene aggiunta d'ufficio una pausa pranzo di
    30 min (**RF-11.b — regola delle 9 ore**).
- **RF-12** Il **buono pasto** e' considerato maturato quando i minuti
  netti lavorati raggiungono la soglia profilo `mealVoucherThresholdMins`
  (default 380 = 6h 20m).
- **RF-13** Lo **straordinario** e' la differenza positiva fra minuti netti
  lavorati e `standardWorkMins` (default 456 = 7h 36m).
- **RF-14** **Timbra Uscita** consolida un record `DailyTimesheet`
  (con `dateId = YYYY-MM-DD`) e lo salva in
  `users/{uid}/timesheets/{dateId}` con `merge: true`.
- **RF-15** Il timer ticka una volta al minuto (`Timer.periodic`).

### Timesheet mensile

- **RF-16** L'utente vede un calendario mensile in italiano (settimana
  inizia da Lunedi') con un dot verde se la giornata ha record, arancione
  se ci sono straordinari.
- **RF-17** Riepiloghi a inizio pagina: ore totali del mese, straordinari
  totali, numero di buoni pasto.
- **RF-18** Selezionando un giorno con dato, viene mostrato dettaglio:
  entrata, uscita, lavorato, badge buono pasto, eventuale straordinario.
- **RF-19** Navigazione mese precedente / mese successivo.
- **RF-20** Dati caricati via `monthlyTimesheetsProvider((year, month))`
  (StreamProvider Firestore filtrato per `dateId` `YYYY-MM-01`–`YYYY-MM-31`).

### Social

- **RF-21** Vista lista colleghi live da Firestore con stato (`Presente`,
  `In arrivo`, `Da remoto`, `Assente`) e metadati di profilo.
- **RF-22** Filtri cumulativi per sede, dipartimento e stato.
- **RF-23** Azione "manda un caffe'" con notifica al destinatario e risposta
  verso il mittente.

### Profilo

- **RF-24** Vista delle preferenze personali (le stesse impostate in
  onboarding) in sola lettura/anteprima.
- **RF-25** Toggle del tema (light / dark / system / auto) tramite
  `themeModeProvider` (Riverpod `Notifier`).
- **RF-26** Possibilita' di logout dal profilo.
- **RF-27** Lettore CCNL PCM integrato nel profilo con switch
  2019-2021/2016-2018 e indice articoli.

### Sedi PCM e percorsi

- **RF-28** Onboarding e profilo usano un elenco sedi PCM strutturato, non
  input libero, salvando anche id sede, indirizzo e coordinate.
- **RF-29** La Home mostra un widget "Percorsi PCM" che stima tempi tra sedi
  aggregate per indirizzo, con modalità a piedi/bici/auto-navetta e link a
  Google Maps.

### Chigio

- **RF-30** L'header mostra una frase contestuale di Chigio in massimo due
  righe, con label breve e avatar.
- **RF-31** Le quote sono mantenute in `ChigioQuotes`, mentre
  `ChigioPhraseEngine` gestisce solo selezione, seed temporale e placeholder.

---

## RNF — Requisiti non funzionali

| Codice | Requisito | Note |
|---|---|---|
| RNF-01 | **Cross-platform** (iOS, Android, macOS, Windows, Linux, web) | Tutte le cartelle runner sono generate. |
| RNF-02 | **Localizzazione it_IT** | `initializeDateFormatting('it_IT', null)` in `main.dart`. |
| RNF-03 | **Aspetto "glass"** (light & dark) | Famiglia di widget `glass_*` in `lib/shared/widgets/`. |
| RNF-04 | **Reattivita' UI** real-time | StreamProvider su Firestore + `Timer.periodic` per il turno. |
| RNF-05 | **Offline-friendly** | Drift/SQLite con write-through e fallback locale; asset WASM web ancora da completare. |
| RNF-06 | **Sicurezza credenziali** | `flutter_secure_storage` per token; mai `shared_preferences` per dati sensibili. |
| RNF-07 | **Analisi statica** | `flutter_lints` via `analysis_options.yaml`. |
| RNF-08 | **Generazione codice** | Riverpod, Freezed, Drift, `json_serializable` via `build_runner`. |

---

## Vincoli

- **VIN-01** Il dominio segue il **CCNL del settore pubblico**: orari,
  straordinari mensili e regola delle pause sono codificati in `WorkTimer` e
  nei default di `OnboardingState`. Il contatore storico `art9` va
  riallineato con il CCNL PCM 2016-2018: permessi brevi Art. 35, banca ore
  Art. 26, eventuali protrazioni Art.9 solo se confermate da portale/accordi.
- **VIN-02** Le date di lavoro hanno **granularita' giornaliera**: il
  documento Firestore `timesheets/{YYYY-MM-DD}` e' la chiave naturale.
  Non e' previsto multi-record per lo stesso giorno.
- **VIN-03** L'app non e' un sistema autoritativo per la timbratura
  presso l'amministrazione: e' uno **strumento personale** di calcolo.

## Fuori scope (oggi)

- Timbratura biometrica / NFC.
- Sincronizzazione bidirezionale con sistemi presenza ufficiali della PA.
- Gestione festivita' e ferie pianificate.
- Multi-utente / supervisione di team (pannello manager).

---

## Mapping requisiti → codice

| Req | File principali |
|---|---|
| RF-01..04 | `lib/features/authentication/data/auth_repository.dart`, `lib/features/authentication/presentation/login_screen.dart` |
| RF-05..08 | `lib/features/authentication/presentation/onboarding_screen.dart`, `onboarding_provider.dart`, `lib/features/profile/data/profile_repository.dart` |
| RF-09..15 | `lib/features/dashboard/presentation/timer_provider.dart`, `dashboard_screen.dart` |
| RF-16..20 | `lib/features/timesheet/presentation/timesheet_screen.dart`, `lib/features/timesheet/data/timesheet_repository.dart` |
| RF-21..23 | `lib/features/social/presentation/social_screen.dart` |
| RF-24..27 | `lib/features/profile/presentation/profile_screen.dart`, `lib/shared/providers/global_providers.dart` |
| RF-28..29 | `lib/core/constants/pcm_locations.dart`, `lib/core/data/pcm_locations_repository.dart`, `lib/features/dashboard/widgets/pcm_route_planner_card.dart` |
| RF-30..31 | `lib/core/constants/chigio_quotes.dart`, `lib/core/services/chigio_phrase_engine.dart`, `lib/shared/widgets/glass_header.dart` |
