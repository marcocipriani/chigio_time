# Layering & convenzioni di cartelle

## Principio: feature-first + 3 layer

Ogni feature vive sotto `lib/features/<nome_feature>/` e ha i 3 layer
classici della clean architecture:

```
lib/features/<feature>/
├── data/             ← repository + datasource (Firestore, SharedPrefs, …)
├── domain/           ← model, value object, regole di business pure
└── presentation/     ← screen, widget di feature, provider Riverpod
```

Esempio reale per la feature `timesheet`:

```
lib/features/timesheet/
├── data/
│   ├── timesheet_repository.dart      ← TimesheetRepository + provider
│   └── timesheet_repository.g.dart    ← generato
├── domain/
│   └── daily_timesheet.dart           ← entita' di dominio
└── presentation/
    ├── timesheet_screen.dart          ← UI calendario + dettaglio
    └── social_screen.dart             ← (file mal collocato, vedi nota)
```

> **Nota di pulizia.** `lib/features/timesheet/presentation/social_screen.dart`
> e' un **placeholder leftover** (un singolo commento che rimanda al file
> "ufficiale" in `lib/features/social/presentation/social_screen.dart`).
> Va rimosso. Tracciato in [`../CHANGELOG.md`](../CHANGELOG.md).

---

## Codice trasversale

```
lib/
├── main.dart                     ← entry point (Firebase + ProviderScope)
├── firebase_options.dart         ← generato da FlutterFire CLI
├── app/                          ← shell applicativa
│   ├── app.dart                  ← MaterialApp.router + theme + router
│   ├── routes/
│   │   ├── app_router.dart       ← GoRouter come provider Riverpod
│   │   └── app_router.g.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── color_schemes.dart
│       └── text_styles.dart
├── core/                         ← util e costanti pure
│   ├── constants/app_constants.dart    (placeholder)
│   ├── errors/failures.dart            (placeholder)
│   └── utils/date_utils.dart           (placeholder)
└── shared/                       ← widget e provider riutilizzabili
    ├── models/timesheet_entry.dart     (modello legacy, vedi nota)
    ├── providers/global_providers.dart (themeModeProvider)
    └── widgets/
        ├── app_background.dart         ← gradient di sfondo
        ├── glass_card.dart             ← card "vetrose"
        ├── glass_button.dart
        ├── glass_header.dart
        ├── day_checkpoints.dart        ← timeline checkpoint giornata
        ├── floating_nav.dart           ← bottom nav personalizzata
        └── main_shell_screen.dart      ← shell con AppBackground + nav
```

> **Nota di pulizia.** `lib/shared/models/timesheet_entry.dart` definisce
> un modello `TimesheetEntry` con `startTime/endTime/isSmartWorking` che
> **non e' usato** dal codice attivo (la dashboard scrive direttamente
> un `DailyTimesheet`). Probabilmente residuo di una prima iterazione.
> Decisione futura: tenerlo come "audit log" delle timbrature singole o
> rimuoverlo. Tracciare in una ADR.

---

## Responsabilita' per layer

### `data/`
- Conosce **solo** dipendenze esterne (Firebase, SQLite, HTTP) e tipi
  del proprio modulo `domain`.
- Espone repository concreti (es. `AuthRepository`, `TimesheetRepository`)
  e i loro **provider Riverpod** (`@riverpod`).
- Mappa DTO (es. `DocumentSnapshot`, `Map<String, dynamic>`) → entita'
  di dominio.

### `domain/`
- Modelli **immutabili** (Dart `final` ovunque o Freezed).
- Logica pura riusabile (calcoli, validazioni). **Nessun import** di
  Flutter, Firebase o widget.
- Per `chigio_time` oggi e' un layer leggero: contiene solo
  `daily_timesheet.dart`. Le regole di calcolo del turno vivono nel
  `WorkTimer` (presentation) ma andrebbero progressivamente estratte in
  un use case di dominio (vedi [`../decisioni/`](../decisioni/) per
  futuro ADR).

### `presentation/`
- Widget Flutter (`*_screen.dart`, sub-widget) e provider Riverpod che
  gestiscono lo stato della vista (es. `WorkTimer`, `Onboarding`).
- I provider di presentation **possono** dipendere da provider di data
  (es. `WorkTimer` legge `timesheetRepositoryProvider` con `ref.read`).

## Naming

| Tipo | Pattern | Esempio |
|---|---|---|
| File Dart | `snake_case.dart` | `timer_provider.dart` |
| Classe | `UpperCamelCase` | `WorkTimer`, `DailyTimesheet` |
| Provider top-level | `<nome>Provider` | `workTimerProvider`, `themeModeProvider` |
| File generato | `<source>.g.dart` | `auth_repository.g.dart` |
| Screen | `<Nome>Screen` + file `<nome>_screen.dart` | `DashboardScreen` |
| Repository | `<Nome>Repository` + file `<nome>_repository.dart` | `TimesheetRepository` |
| Notifier Riverpod | classe + `@riverpod` (genera `*$Class`) | `class WorkTimer extends _$WorkTimer` |

## Regole di import

- Mai importare un modulo `presentation` da un modulo `data`.
- Mai importare `Flutter` da un file `domain`.
- L'import di package esterni e' consentito ovunque, ma per Firebase
  resta confinato al layer `data` (eccezione storica accettata: la
  dashboard usa `Timestamp` solo via `DailyTimesheet`).
