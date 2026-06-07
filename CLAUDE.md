# CLAUDE.md — Protocollo operativo per Claude Code

> **Scopo del file.** Questo file e' l'entry point che Claude Code (e qualunque altro
> agente LLM) deve leggere **prima** di toccare il repository `chigio_time`.
> Definisce regole di lettura, regole di scrittura, convenzioni di codice e le
> ancore alla wiki dettagliata in [`docs/`](./docs/README.md).

---

## 1. Identita' del progetto

- **Nome:** `chigio_time`
- **Descrizione:** Time Tracking App per dipendenti pubblici (gestione turno
  giornaliero, pause, straordinari, buoni pasto, Articolo 9).
- **Stack:** Flutter 3 / Dart 3.10+, Riverpod 3, Firebase (Auth/Firestore/
  Storage/Messaging), GoRouter, Drift (SQLite locale).
- **Piattaforme target:** iOS, Android, macOS, Windows, Linux, Web.
- **Lingua dominio:** Italiano (terminologia CCNL settore pubblico).

Per la vision completa e i requisiti vedi
[`docs/00-overview/README.md`](./docs/00-overview/README.md).

---

## 2. Regola d'oro: **leggi-prima / aggiorna-dopo**

Ogni intervento di Claude Code sul codice deve seguire questo ciclo:

1. **PRIMA di scrivere codice** leggi:
   - questo `CLAUDE.md`;
   - l'indice [`docs/README.md`](./docs/README.md);
   - le pagine della wiki rilevanti per la zona di codice toccata
     (entita', feature, ADR pertinenti).
2. **DURANTE** la modifica rispetta layering, naming e convenzioni indicate
   nelle pagine wiki linkate.
3. **DOPO** la modifica, **aggiorna la wiki** nello stesso commit:
   - se cambia un'entita' di dominio → aggiorna `docs/entities/<entita>.md`;
   - se cambia un flusso utente o un repository → aggiorna
     `docs/features/<feature>.md`;
   - se la modifica e' una **scelta architetturale non ovvia** → crea una
     nuova ADR in `docs/decisions/`;
   - aggiungi sempre una riga in `docs/CHANGELOG.md`.

> Una PR che modifica codice in `lib/` **senza** aggiornare la wiki o il
> changelog e' considerata incompleta.

---

## 3. Mappa rapida del repository

```
chigio_time/
├── CLAUDE.md                  ← sei qui
├── README.md                  ← landing page del repo
├── pubspec.yaml               ← dipendenze (riferimento per ADR-0001)
├── docs/                      ← WIKI DEL PROGETTO
│   ├── README.md              ← indice
│   ├── 00-overview/           ← vision + requisiti
│   ├── architecture/          ← layering, state, routing, persistenza
│   ├── entities/              ← modello concettuale + ER
│   ├── features/              ← schede per ciascuna feature
│   ├── decisions/             ← ADR (Architecture Decision Records)
│   ├── processes/             ← build, run, code-gen, branching
│   ├── glossario.md           ← termini di dominio
│   └── CHANGELOG.md           ← log modifiche tracciate da Claude Code
└── lib/                       ← codice Dart
    ├── main.dart              ← bootstrap (Firebase + ProviderScope)
    ├── firebase_options.dart  ← generato da FlutterFire
    ├── app/                   ← shell applicativa (theme, router)
    ├── core/                  ← util e costanti trasversali
    ├── shared/                ← widget e provider condivisi
    └── features/              ← una cartella per feature, layered
        └── <feature>/
            ├── data/          ← repository, datasource Firestore/Drift
            ├── domain/        ← model, value object, use case
            └── presentation/  ← screen, widget, provider Riverpod
```

---

## 4. Convenzioni di codice (vincolanti)

| Argomento | Convenzione | Riferimento |
|---|---|---|
| Architettura | Feature-first + 3 layer (`data` / `domain` / `presentation`) | [`docs/architecture/layering.md`](./docs/architecture/layering.md) |
| State management | Riverpod 3 con annotazione `@riverpod` (genera `*.g.dart`) | [`docs/architecture/state-management.md`](./docs/architecture/state-management.md) |
| Routing | `go_router` con `StatefulShellRoute.indexedStack` per le 3 sezioni principali | [`docs/architecture/navigation.md`](./docs/architecture/navigation.md) |
| Persistenza remota | Cloud Firestore, collezione `users/{uid}` + sub-collezione `timesheets/{dateId}` | [`docs/architecture/persistence.md`](./docs/architecture/persistence.md) |
| Persistenza locale | Drift (SQLite) + `shared_preferences` per flag, `flutter_secure_storage` per token | [`docs/architecture/persistence.md`](./docs/architecture/persistence.md) |
| Nomi file Dart | `snake_case.dart`. Provider in `*_provider.dart`, repo in `*_repository.dart` | [`docs/architecture/layering.md`](./docs/architecture/layering.md) |
| ID giornaliero timesheet | `YYYY-MM-DD` (stringa, usata anche come doc ID Firestore) | [`docs/entities/daily-timesheet.md`](./docs/entities/daily-timesheet.md) |
| Lingua UI / commenti | Italiano per stringhe utente. Codice in inglese | — |
| Lint | `flutter_lints` via `analysis_options.yaml` | — |

---

## 5. Comandi rapidi

```bash
# Setup
flutter pub get

# Code generation (Riverpod, Freezed, Drift, json_serializable)
dart run build_runner build --delete-conflicting-outputs
# In modalita' watch
dart run build_runner watch --delete-conflicting-outputs

# Run
flutter run -d <device>

# Test / analisi
flutter analyze
flutter test
```

Dettagli e troubleshooting in [`docs/processes/build-and-run.md`](./docs/processes/build-and-run.md)
e [`docs/processes/code-generation.md`](./docs/processes/code-generation.md).

---

## 6. Cosa NON fare

- **Non** modificare i file `*.g.dart` a mano (sono generati da `build_runner`).
- **Non** introdurre nuove dipendenze senza una ADR motivante in
  `docs/decisions/`.
- **Non** bypassare il layer `data/` accedendo a `FirebaseFirestore.instance`
  da dentro un widget o un provider di presentation.
- **Non** salvare in chiaro su `shared_preferences` informazioni sensibili
  (token, credenziali). Per quelle si usa `flutter_secure_storage`.
- **Non** usare `print` per errori in produzione: e' tollerato solo come
  placeholder. Le pagine `docs/features/*.md` riportano i punti dove va
  introdotto un logger/telemetria reale.

---

## 7. Quando aprire una nuova ADR

Apri una nuova `docs/decisions/NNNN-<slug>.md` (a partire dal template
`0000-template.md`) ogni volta che:

- aggiungi/sostituisci una libreria di rilievo (es. cambi state-management,
  router, ORM);
- modifichi lo schema Firestore in modo incompatibile (campi rinominati,
  collezioni spostate);
- introduci un meccanismo cross-feature (es. un sistema di permessi, un
  canale di notifiche);
- prendi una decisione "non ovvia" che un futuro lettore potrebbe voler
  rimettere in discussione.

Una ADR e' breve (1-2 pagine): contesto, opzioni considerate, decisione,
conseguenze.

---

## 8. Stato vivo del progetto

Per non duplicare informazioni che invecchiano in fretta, il **what's
new / next** vive in [`docs/CHANGELOG.md`](./docs/CHANGELOG.md). Tutto cio'
che e' stabile e descrittivo (entita', architettura, processi) sta nelle
altre pagine della wiki.

---

## 9. Commit e push frequenti

Ogni volta che si completa una modifica esaustiva (una feature, un fix,
un refactor coerente) **crea subito un commit** dedicato e pushalo. Non
lasciare la HEAD locale troppo indietro rispetto a `origin/main`: piu'
a lungo si accumulano modifiche non committate, piu' diventa difficile
ricostruire una cronologia leggibile e attribuire correttamente le date.
