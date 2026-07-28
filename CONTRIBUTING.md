# Contribuire a Chigio Time

## Prima modifica

1. Leggi la [mappa della documentazione](docs/README.md).
2. Identifica feature, entità e ADR coinvolte.
3. Verifica lo stato del repository con `git status --short`.
4. Installa dipendenze e rigenera il codice:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
npm ci --prefix functions
npm ci --prefix scripts
```

## Convenzioni

- Codice e nomi tecnici in inglese; copy e terminologia di dominio in italiano.
- File Dart in `snake_case.dart`.
- Una feature vive in `lib/features/<feature>/` e separa:
  - `data`: repository e accesso a servizi esterni;
  - `domain`: modelli e logica pura;
  - `presentation`: widget e stato UI.
- I nuovi provider Riverpod usano `@riverpod` salvo motivazione documentata.
- I file generati `*.g.dart` non si modificano a mano.
- Le date timesheet usano `YYYY-MM-DD`, anche come ID Firestore.

## Cambiare dati o architettura

Una modifica è incompleta se il contratto documentato resta indietro.

| Cambiamento | Documenti richiesti |
|---|---|
| Campo o regola di dominio | entità + feature + changelog |
| Schema Firestore o Drift | persistenza + entità + test + changelog |
| Flusso utente | feature + requisiti + changelog |
| Dipendenza o scelta cross-feature | ADR + architettura + changelog |
| Nuova pagina documentale | `docs/navigation.json` + controllo link |

Le migrazioni devono essere idempotenti e dry-run per impostazione predefinita.
Le scritture richiedono un flag esplicito come `--apply` e una verifica di
read-back.

## Qualità

Prima del commit:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
npm test --prefix functions
npm test --prefix scripts
node --check functions/index.js
node --check functions/notification_logic.js
node --check functions/notification_runtime.js
node scripts/check_docs.mjs
git diff --check
```

Per modifiche Web eseguire anche:

```bash
flutter build web --release
```

I test automatici non sostituiscono uno smoke autenticato quando il flusso
dipende da Firebase, notifiche, cache browser o permessi di dispositivo.

## Commit e rilascio

- Un commit per modifica coerente.
- Messaggio imperativo e specifico, per esempio
  `docs: reorganize architecture guide`.
- Non includere cambiamenti non correlati.
- Eseguire il push dopo il gate pertinente.
- Per la pubblicazione seguire
  [Release Web](docs/processi/web-release.md) o le guide mobile in
  [docs/processi/](docs/processi/README.md).
