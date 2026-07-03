# Chigio Time

> App di **time tracking** per dipendenti pubblici (CCNL settore pubblico).
> Gestione turni, pause, straordinari, buoni pasto, Articolo 9 e totalizzatori portale PA.

**Stack:** Flutter 3 · Dart 3.10+ · Riverpod 3 · Firebase · GoRouter

**Live (web):** https://chigiotime.web.app

**Versione:** v2026.06.07

---

## Funzionalità

| Area | Descrizione |
|---|---|
| ⏱ Dashboard | Cronometro turno, timbra entrata/uscita, pause, calcolo ore nette + regola 9h, Smart Working one-tap |
| ⚠️ Auto-abbandono | Se il turno non viene chiuso entro le 21:00, lo stato viene automaticamente rimosso da "In ufficio" (colleghi) e appare avviso con CTA per timbrata retroattiva o dismissione |
| 🗺️ Percorsi PCM | Widget Home per stimare tempi di percorrenza tra sedi PCM, con modalità a piedi/bici/auto-navetta e apertura Google Maps |
| 📅 Timesheet | 3 viste (Lista / Settimana / Mese), inserimento retroattivo, assenze classificate, import/export CSV e PDF cartellino PCM |
| 📊 Contatori | Widget blu personalizzabile: Art.9 legacy / SLI / SBO / OP (Ore Perse), barre avanzamento, scelta voci attive |
| 🏦 Portale PA | Totalizzatori ufficiali: FERIE, FESTIVITÀ SOPPRESSE, STRAORDINARI, BANCA ORE, PERMESSI, DEBITI |
| 👥 Social | Stato colleghi live, filtri per sede/dipartimento/stato, invio "caffè", gruppi e preferiti in Home |
| 🔔 Notifiche | Inviti caffè, uscita prevista configurabile, badge non letti e push FCM |
| ⚙️ Profilo | Dati editabili, sedi PCM da elenco, totalizzatori portale PA, lettore CCNL completo, download app |
| 🔄 Sync multi-device | Turno in corso sincronizzato su tutti i dispositivi via Firestore real-time |
| 🐢 Chigio | Mascotte con frasi contestuali brevi in header e galleria avatar |

---

## Stack tecnico

| Layer | Tecnologia |
|---|---|
| UI | Flutter 3 / Dart 3.10+ |
| State | Riverpod 3 con `@riverpod` (code-gen) |
| Autenticazione | Firebase Auth (Google Sign-In + email/password) |
| Database cloud | Cloud Firestore |
| Notifiche push | Firebase Messaging |
| Persistenza locale | SharedPreferences · flutter_secure_storage · Drift/SQLite |
| Routing | GoRouter · `StatefulShellRoute.indexedStack` |
| Font | Google Fonts — Plus Jakarta Sans |
| Hosting | Firebase Hosting |

**Piattaforme target:** iOS · Android · macOS · Windows · Linux · Web

---

## Setup sviluppo

```bash
# Dipendenze
flutter pub get

# Avvia (sostituire <device> con emulator/simulator/device ID)
flutter run -d <device>

# Code generation (Riverpod, Freezed, Drift, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Analisi statica
flutter analyze

# Test
flutter test
```

## Deploy

```bash
# Web + deploy Firebase Hosting
./deploy.sh --skip-android

# Android APK + GitHub Release
./deploy.sh --android-only

# Tutto (web + Android)
./deploy.sh
```

---

## Versioning

Formato **CalVer**: `AAAA.M.GG+build` (es. `2026.5.28+1`).

---

## Documentazione

La wiki del progetto è in [`docs/`](./docs/README.md):

- [`docs/panoramica/`](./docs/panoramica/README.md) — vision, requisiti, contesto di dominio
- [`docs/architettura/`](./docs/architettura/README.md) — layering, state, routing, persistenza
- [`docs/entita/`](./docs/entita/README.md) — modello di dominio + schema Firestore
- [`docs/funzionalita/`](./docs/funzionalita/README.md) — scheda per ogni feature
- [`docs/decisioni/`](./docs/decisioni/README.md) — ADR (Architecture Decision Records)
- [`docs/processi/`](./docs/processi/README.md) — build, run, code-gen
- [`docs/CHANGELOG.md`](./docs/CHANGELOG.md) — log modifiche tracciate da Claude Code

---

Sviluppato da **Marco Cipriani** · Presidenza del Consiglio dei Ministri

Assistito da [Claude Code](https://claude.ai/code) (Anthropic) per refactoring, analisi business logic e documentazione.
