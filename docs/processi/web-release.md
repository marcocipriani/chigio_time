# Release Web

Procedura canonica per Firebase Hosting `main`.

## 1. Versione

Aggiornare `version` in `pubspec.yaml` usando CalVer:
`YYYY.M.DD+build`. Allineare la costante mostrata nell'app; il relativo test
impedisce divergenze.

## 2. Gate locale

```bash
flutter pub get
flutter analyze
flutter test
npm test --prefix functions
npm test --prefix scripts
node scripts/check_docs.mjs
flutter build web --release
```

La build deve contenere `build/web/version.json`.

## 3. Deploy

```bash
firebase deploy --only hosting:main
```

Questo comando pubblica in produzione. Verificare progetto e target prima di
eseguirlo.

## 4. Verifica live

Confrontare risposta e contenuto locale almeno per:

- `version.json`;
- `main.dart.js`;
- `index.html`;
- `flutter_bootstrap.js`.

La parità statica dimostra il deploy dell'artefatto, non il funzionamento di
login, profilo o flussi autenticati. Per questi serve uno smoke separato con
un account reale.

_Ultima revisione: 2026-07-29._
