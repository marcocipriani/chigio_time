<div align="center">

<img src="assets/images/chigio-ciao.png" alt="Chigio" width="160" />

# Chigio Time

**Time tracking per dipendenti pubblici — con Chigio, la tartaruga che timbra.**

_Amministrativamente lento, by design._

[![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth·Firestore·FCM-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/State-Riverpod_3-00D2B8)](https://riverpod.dev)
[![Platforms](https://img.shields.io/badge/Platforms-iOS·Android·Web·macOS·Windows·Linux-4CAF50)]()
[![CalVer](https://img.shields.io/badge/version-2026.7.3-blue)]()
[![License](https://img.shields.io/badge/license-uso_interno_PCM-lightgrey)]()

[**Web app →**](https://chigiotime.web.app) · [Documentazione](docs/README.md) · [Roadmap](docs/ROADMAP.md) · [Changelog](docs/CHANGELOG.md)

</div>

---

## Cos'è

**Chigio Time** è un'app di rilevazione presenze pensata per il personale del
**Comparto autonomo della Presidenza del Consiglio dei Ministri**. Traduce le
regole del CCNL PCM (turno giornaliero, pause, Articolo 9, buoni pasto, banca
ore, straordinario liquidato) in un'esperienza semplice: **scorri per timbrare,
Chigio pensa al resto**.

Non è un gestionale HR né un workflow autorizzativo: è il **registro personale**
del dipendente, che vive accanto — non al posto — del portale ufficiale.

> Chigio è la mascotte: una tartaruga che accompagna ogni schermata con la posa
> giusta (timer, caffè, corsa quando sei in straordinario, festa a fine turno).

---

## Funzionalità

### ⏱️ Timbratura
- **TimbraturaHero a 3 fasi** — pre-turno, turno attivo, resoconto — con Chigio
  sempre in scena.
- **Slide-to-clock**: scorri per timbrare all'ora corrente, **long-press** per
  scegliere l'orario. Feedback aptico a tacche, spinner di salvataggio,
  transizioni animate tra le fasi.
- Barre di avanzamento con gate **buono pasto / orario standard / 9h**, pause
  (pranzo, brevi, permessi Art. 9), scenari di uscita intelligente, banca ore
  come esonero (BOE).
- Timbratura **GPS** automatica in ingresso/uscita (geofencing) e resoconto
  giornaliero con contatori di maggior presenza.

### 🗓️ Timesheet
- Viste **Lista / Settimana / Mese / Anno** con celle colorate per tipo giornata.
- Inserimento retroattivo, causali di assenza (ferie, permessi, malattia,
  congedi) con dettaglio CCNL, badge giornate anomale.
- **Export PDF** (incluso il cartellino ufficiale PCM), **import CSV** robusto.

### 👥 Social
- Colleghi in tempo reale (in ufficio / smart working / in pausa), invio
  **caffè** con handshake, gruppi, collegamenti reciproci, profilo privato.
- Stato del giorno con **scadenza** (1h / 4h / fine giornata).

### 💶 Stipendio & 🍅 Progetti
- Countdown al prossimo accredito, stima netto, storico cedolini.
- Progetti condivisi con **timer Pomodoro** (25/5, 45/15), riepiloghi e
  contributi per collega.

### 🏠 Home a widget
- Widget ordinabili e nascondibili: preferiti, maggior presenza, contatori,
  banca ore, totalizzatori, percorsi PCM, **tabella orari**, **Pomodoro**,
  **stipendio**. Ogni widget ha un tocco di Chigio e può essere messo **in
  evidenza** (sfondo blu).

### 📘 Extra
- **Lettore CCNL** integrato (2019-2021 e 2016-2018) con indice e ricerca.
- Statistiche avanzate (streak, puntualità, andamento straordinario **SAU**),
  notifiche push FCM, tema chiaro/scuro/auto, i18n IT/EN, resilienza offline.

---

## Dettagli tecnici

| Area | Scelta |
|---|---|
| **Framework** | Flutter 3 / Dart 3.10+ — un solo codebase per iOS, Android, Web, macOS, Windows, Linux |
| **State management** | Riverpod 3 con codegen (`@riverpod` → `*.g.dart`) |
| **Routing** | `go_router` con `StatefulShellRoute.indexedStack` (5 sezioni) |
| **Backend** | Firebase — Auth (Google + email), Cloud Firestore, Storage, Messaging (FCM), Cloud Functions |
| **Persistenza locale** | Drift (SQLite) con write-through e fallback offline; `sqlite3.wasm` su web |
| **Grafici** | `fl_chart` |
| **Versioning** | CalVer `YYYY.M.DD+build` |

### Architettura

**Feature-first + 3 layer** (`data` / `domain` / `presentation`) per ogni feature:

```
lib/
├── main.dart                  # bootstrap (Firebase + ProviderScope)
├── app/                       # shell: theme, router
├── core/                      # costanti, servizi, database, util trasversali
├── shared/                    # widget e provider condivisi
└── features/
    └── <feature>/
        ├── data/              # repository, datasource Firestore/Drift
        ├── domain/            # model, value object
        └── presentation/      # screen, widget, provider Riverpod
```

Dati canonici su **Firestore** (`users/{uid}` + sotto-collezioni `timesheets`,
`capPeriods`, `sau_monthly`, `salaryPayments`, …); cache locale Drift per
resilienza offline. Le decisioni architetturali non ovvie sono tracciate come
**ADR** in [`docs/decisioni/`](docs/decisioni/).

La wiki completa (entità, feature, processi, ADR) è in
[`docs/`](docs/README.md); il protocollo per gli agenti LLM è in
[`CLAUDE.md`](CLAUDE.md).

---

## Configurazione e comandi

**Prerequisiti:** [Flutter 3.44+](https://docs.flutter.dev/get-started/install),
un progetto Firebase configurato con FlutterFire.

```bash
# 1. Dipendenze
flutter pub get

# 2. Configurazione Firebase (genera lib/firebase_options.dart)
dart pub global activate flutterfire_cli
flutterfire configure

# 3. Code generation (Riverpod, Freezed, Drift, json_serializable)
dart run build_runner build --delete-conflicting-outputs
#   modalità watch durante lo sviluppo:
dart run build_runner watch --delete-conflicting-outputs

# 4. Run
flutter run -d chrome          # web
flutter run -d <device-id>     # mobile / desktop

# 5. Qualità (obbligatori prima di ogni rilascio)
flutter analyze
flutter test
```

### Build & deploy web

```bash
flutter clean                  # evita web_plugin_registrant stantìo dopo upgrade dep
flutter build web
firebase deploy --only hosting
firebase deploy --only firestore:rules
```

> **Nota web/Drift:** `web/sqlite3.wasm` va allineato alla versione del package
> `sqlite3` (release di [sqlite3.dart](https://github.com/simolus3/sqlite3.dart/releases));
> `web/drift_worker.dart.js` si rigenera con
> `dart compile js lib/core/database/drift_worker.dart -o web/drift_worker.dart.js`.

---

<div align="center">
<sub>Fatto con 🐢 per la PCM · uso interno</sub>
</div>
