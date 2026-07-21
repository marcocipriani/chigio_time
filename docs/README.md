# Wiki di `chigio_time`

> Documentazione viva del progetto. **Punto di ingresso obbligatorio per
> qualunque agente LLM o nuovo collaboratore.** Per le regole operative
> vedi [`../CLAUDE.md`](../CLAUDE.md).

---

## 0. Overview e requisiti

- [`panoramica/README.md`](./panoramica/README.md) — vision, target utenti,
  contesto di dominio (CCNL settore pubblico).
- [`panoramica/requirements.md`](./panoramica/requirements.md) — requisiti
  funzionali e non funzionali, vincoli, fuori scope.

## 1. Architettura

- [`architettura/README.md`](./architettura/README.md) — overview e
  diagrammi a blocchi del sistema.
- [`architettura/layering.md`](./architettura/layering.md) — feature-first
  + 3 layer (`data` / `domain` / `presentation`).
- [`architettura/state-management.md`](./architettura/state-management.md) —
  pattern Riverpod (provider, family, code-gen).
- [`architettura/navigation.md`](./architettura/navigation.md) — `go_router`,
  shell con bottom nav, redirect di autenticazione e onboarding.
- [`architettura/persistence.md`](./architettura/persistence.md) — Firestore
  (cloud), Drift + `shared_preferences` + `flutter_secure_storage` (locale).

## 2. Modello di dominio (entita')

- [`entita/README.md`](./entita/README.md) — modello concettuale, ER e
  mappatura logica → fisica (Firestore + Drift).
- Schede entita':
  - [`entita/user-profile.md`](./entita/user-profile.md)
  - [`entita/onboarding-state.md`](./entita/onboarding-state.md)
  - [`entita/timesheet-entry.md`](./entita/timesheet-entry.md)
  - [`entita/daily-timesheet.md`](./entita/daily-timesheet.md)
  - [`entita/timer-state.md`](./entita/timer-state.md)

## 3. Feature

- [`funzionalita/README.md`](./funzionalita/README.md) — mappa delle feature e
  relative dipendenze.
- Schede feature:
  - [`funzionalita/authentication.md`](./funzionalita/authentication.md)
  - [`funzionalita/onboarding.md`](./funzionalita/onboarding.md)
  - [`funzionalita/dashboard.md`](./funzionalita/dashboard.md) — cronometro turno, widget contatori, totalizzatori portale PA
  - [`funzionalita/timesheet.md`](./funzionalita/timesheet.md) — 3 viste, alert giornate mancanti, inserimento manuale
  - [`funzionalita/social.md`](./funzionalita/social.md)
  - [`funzionalita/profile.md`](./funzionalita/profile.md) — dati editabili, statistiche, notifiche, widget contatori
  - [`funzionalita/chigio.md`](./funzionalita/chigio.md) — mascotte interattiva
  - [`funzionalita/widget-inventory.md`](./funzionalita/widget-inventory.md) — inventario widget e gap trasversali

## 4. Decisioni architetturali (ADR)

- [`decisioni/README.md`](./decisioni/README.md) — indice delle ADR.
- [`decisioni/0000-template.md`](./decisioni/0000-template.md) — template.
- [`decisioni/0001-stack-iniziale.md`](./decisioni/0001-stack-iniziale.md) —
  scelta di Flutter + Riverpod + Firebase + Drift.
- [`decisioni/0006-share-plus-file-export.md`](./decisioni/0006-share-plus-file-export.md) —
  condivisione file export.
- [`decisioni/0007-banca-ore-esonero.md`](./decisioni/0007-banca-ore-esonero.md) —
  BOE, Banca Ore come Esonero.

## 5. Processi

- [`processi/README.md`](./processi/README.md) — overview.
- [`processi/build-and-run.md`](./processi/build-and-run.md) — comandi e
  troubleshooting.
- [`processi/code-generation.md`](./processi/code-generation.md) —
  `build_runner`, file `*.g.dart`, `*.freezed.dart`.
- [`processi/android-deploy.md`](./processi/android-deploy.md) — build e
  distribuzione Android.
- [`processi/ios-deploy.md`](./processi/ios-deploy.md) — build e
  distribuzione iOS.

## 6. Riferimenti

- [`ccnl/README.md`](./ccnl/README.md) — conversioni Markdown dei CCNL PCM
  2016-2018 e 2019-2021, confronto articoli sostituiti e mappa prodotto.
- [`ccnl/permessi-assenze-congedi.md`](./ccnl/permessi-assenze-congedi.md) —
  assenze personali, P0 implementata e confronto consumi P1.
- [`glossario.md`](./glossario.md) — termini di dominio (turno, timbratura,
  smart exit, banca ore, permessi brevi, ecc.).
- [`CHANGELOG.md`](./CHANGELOG.md) — log delle modifiche tracciate dagli
  agenti LLM.
- [`ROADMAP.md`](./ROADMAP.md) — feature completate, sprint proposti S-12/S-13, backlog.
- [`entita/dipartimenti-pcm.md`](./entita/dipartimenti-pcm.md) — 50 strutture canoniche associate alle 12 sedi PCM; sorgente condivisa da onboarding, profilo e percorsi.

---

## Convenzione di aggiornamento

Ogni pagina riporta in fondo la data dell'ultima revisione e l'**ambito**
del cambiamento (es. "rivista entita' DailyTimesheet"). Questo aiuta sia
gli umani sia gli LLM a stimare freschezza e affidabilita' del contenuto.

_Ultima revisione: 2026-06-14 — file `.md` di radice riorganizzati in `docs/` (departments→`entita/dipartimenti-pcm.md`, identità visiva→`funzionalita/chigio-identita-visiva.md`, `sedi.md` obsoleto rimosso)._
