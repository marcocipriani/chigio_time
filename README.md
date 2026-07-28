<div align="center">

<img src="assets/images/chigio-ciao.png" alt="Chigio, la mascotte di Chigio Time" width="150" />

# Chigio Time

**Registro personale di presenze per il personale della Presidenza del Consiglio dei Ministri.**

[![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth·Firestore·FCM-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Versione](https://img.shields.io/badge/versione-2026.7.22%2B22-0055A5)]()

[Apri l’app Web](https://chigiotime.web.app) ·
[Guida utente](docs/panoramica/guida-utente.md) ·
[Documentazione](docs/README.md) ·
[Roadmap](docs/ROADMAP.md)

</div>

## Scopo

Chigio Time aiuta il dipendente a registrare e controllare:

- entrata, uscita, pause e permessi brevi;
- uscita prevista, regola delle 9 ore e maturazione del buono pasto;
- maggior presenza, SLI, SBO, BOE e deficit giornalieri;
- cartellino mensile, assenze personali, import CSV ed export CSV/PDF;
- stato dei colleghi, inviti caffè e notifiche;
- progetti Pomodoro e storico degli accrediti stipendiali.

L’app è un **registro personale di supporto**. Non sostituisce il sistema
ufficiale di rilevazione presenze, il portale HR o un processo autorizzativo.

## Architettura in breve

Il client è Flutter e usa un’organizzazione feature-first:

```text
lib/
├── app/            bootstrap, routing e tema
├── core/           servizi, database e costanti trasversali
├── features/       data, domain e presentation per funzionalità
└── shared/         widget e provider condivisi
```

Firebase fornisce autenticazione, Firestore, Storage, Messaging e Cloud
Functions. Drift conserva la cache locale dei timesheet e del catalogo PCM,
anche su Web tramite WASM. Le decisioni non ovvie sono registrate nelle
[ADR](docs/decisioni/README.md).

## Avvio locale

Prerequisiti:

- Flutter 3.44 o compatibile con Dart `^3.10.4`;
- progetto Firebase configurato;
- JDK 17 per Android;
- Xcode e CocoaPods per i target Apple.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome
```

## Verifica

```bash
flutter analyze
flutter test
npm test --prefix functions
npm test --prefix scripts
node scripts/check_docs.mjs
```

Il gate completo e i limiti della suite sono descritti in
[Testing](docs/processi/testing.md).

## Build Web

```bash
flutter build web --release
firebase deploy --only hosting:main
```

La procedura di rilascio, inclusa la verifica degli artefatti pubblicati, è in
[Release Web](docs/processi/web-release.md).

## Orientamento

- Vuoi usare l’app: [Guida utente](docs/panoramica/guida-utente.md).
- Vuoi capire il prodotto: [Panoramica](docs/panoramica/README.md).
- Vuoi contribuire: [CONTRIBUTING.md](CONTRIBUTING.md).
- Vuoi modificare dati o infrastruttura:
  [Processi operativi](docs/processi/README.md).
- Vuoi capire perché è stata fatta una scelta:
  [Registro delle decisioni](docs/decisioni/README.md).

Uso interno PCM.
