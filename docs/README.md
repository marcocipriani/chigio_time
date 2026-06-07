# Wiki di `chigio_time`

> Documentazione viva del progetto. **Punto di ingresso obbligatorio per
> qualunque agente LLM o nuovo collaboratore.** Per le regole operative
> vedi [`../CLAUDE.md`](../CLAUDE.md).

---

## 0. Overview e requisiti

- [`00-overview/README.md`](./00-overview/README.md) — vision, target utenti,
  contesto di dominio (CCNL settore pubblico).
- [`00-overview/requirements.md`](./00-overview/requirements.md) — requisiti
  funzionali e non funzionali, vincoli, fuori scope.

## 1. Architettura

- [`architecture/README.md`](./architecture/README.md) — overview e
  diagrammi a blocchi del sistema.
- [`architecture/layering.md`](./architecture/layering.md) — feature-first
  + 3 layer (`data` / `domain` / `presentation`).
- [`architecture/state-management.md`](./architecture/state-management.md) —
  pattern Riverpod (provider, family, code-gen).
- [`architecture/navigation.md`](./architecture/navigation.md) — `go_router`,
  shell con bottom nav, redirect di autenticazione e onboarding.
- [`architecture/persistence.md`](./architecture/persistence.md) — Firestore
  (cloud), Drift + `shared_preferences` + `flutter_secure_storage` (locale).

## 2. Modello di dominio (entita')

- [`entities/README.md`](./entities/README.md) — modello concettuale, ER e
  mappatura logica → fisica (Firestore + Drift).
- Schede entita':
  - [`entities/user-profile.md`](./entities/user-profile.md)
  - [`entities/onboarding-state.md`](./entities/onboarding-state.md)
  - [`entities/timesheet-entry.md`](./entities/timesheet-entry.md)
  - [`entities/daily-timesheet.md`](./entities/daily-timesheet.md)
  - [`entities/timer-state.md`](./entities/timer-state.md)

## 3. Feature

- [`features/README.md`](./features/README.md) — mappa delle feature e
  relative dipendenze.
- Schede feature:
  - [`features/authentication.md`](./features/authentication.md)
  - [`features/onboarding.md`](./features/onboarding.md)
  - [`features/dashboard.md`](./features/dashboard.md) — cronometro turno, widget contatori, totalizzatori portale PA
  - [`features/timesheet.md`](./features/timesheet.md) — 3 viste, alert giornate mancanti, inserimento manuale
  - [`features/social.md`](./features/social.md)
  - [`features/profile.md`](./features/profile.md) — dati editabili, statistiche, notifiche, widget contatori
  - [`features/chigio.md`](./features/chigio.md) — mascotte interattiva

## 4. Decisioni architetturali (ADR)

- [`decisions/README.md`](./decisions/README.md) — indice delle ADR.
- [`decisions/0000-template.md`](./decisions/0000-template.md) — template.
- [`decisions/0001-stack-iniziale.md`](./decisions/0001-stack-iniziale.md) —
  scelta di Flutter + Riverpod + Firebase + Drift.

## 5. Processi

- [`processes/README.md`](./processes/README.md) — overview.
- [`processes/build-and-run.md`](./processes/build-and-run.md) — comandi e
  troubleshooting.
- [`processes/code-generation.md`](./processes/code-generation.md) —
  `build_runner`, file `*.g.dart`, `*.freezed.dart`.

## 6. Riferimenti

- [`ccnl/README.md`](./ccnl/README.md) — conversioni Markdown dei CCNL PCM
  2016-2018 e 2019-2021, confronto articoli sostituiti e mappa prodotto.
- [`glossario.md`](./glossario.md) — termini di dominio (turno, timbratura,
  smart exit, banca ore, permessi brevi, ecc.).
- [`CHANGELOG.md`](./CHANGELOG.md) — log delle modifiche tracciate dagli
  agenti LLM.
- [`ROADMAP.md`](./ROADMAP.md) — feature completate, prossimo sprint, backlog.

---

## Convenzione di aggiornamento

Ogni pagina riporta in fondo la data dell'ultima revisione e l'**ambito**
del cambiamento (es. "rivista entita' DailyTimesheet"). Questo aiuta sia
gli umani sia gli LLM a stimare freschezza e affidabilita' del contenuto.
