# Build & Run

## Prerequisiti

- Flutter SDK ≥ 3.10.4 (`flutter --version`).
- Dart SDK ≥ 3.10.
- Account Firebase con progetto configurato (file
  `lib/firebase_options.dart` generato da FlutterFire CLI).
- Per Android: JDK 17+ e Android SDK.
- Per iOS / macOS: Xcode aggiornato e CocoaPods.

## Setup iniziale

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

> Il secondo comando e' **necessario** alla prima clonazione, altrimenti
> tutti i `*.g.dart` sono assenti e l'analyzer fallisce.

## Comandi di esecuzione

```bash
# Lista device disponibili
flutter devices

# Run (specifica il device id)
flutter run -d <device-id>

# Hot reload  → r
# Hot restart → R
# Quit        → q
```

## Build di release

```bash
# Android (APK)
flutter build apk --release

# iOS (richiede Xcode + cert)
flutter build ipa --release

# Web
flutter build web --release
```

## Analisi e test

```bash
flutter analyze         # statico, segue analysis_options.yaml
flutter test            # unit + widget test
```

## Troubleshooting comune

| Sintomo | Causa probabile | Rimedio |
|---|---|---|
| `error: Target of URI hasn't been generated` su `*.g.dart` | manca run di `build_runner` | `dart run build_runner build --delete-conflicting-outputs` |
| Login Google web fallisce in dev | dominio non autorizzato in Firebase Console | aggiungi `localhost`/dominio di test in *Authentication → Settings → Authorized domains*. |
| Login Google su Android fallisce con `ApiException: 10` | SHA-1 non registrata | aggiungi le SHA-1 di debug e release in *Project settings* di Firebase. |
| iOS pod install lento o rotto | cache Pods | `cd ios && pod deintegrate && pod install --repo-update`. |
| Conflitti su `*.g.dart` dopo merge | rigenera | rimuovi le versioni in conflitto e ri-esegui `build_runner build`. |
