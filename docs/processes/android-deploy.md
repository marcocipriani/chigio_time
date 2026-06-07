# Android — Build e Deploy

## Artefatti

| File | Uso |
|---|---|
| `build/app/outputs/flutter-apk/app-release.apk` | Distribuzione diretta (sideloading) |
| `build/app/outputs/bundle/release/app-release.aab` | Google Play Store |

---

## Keystore (firma)

Keystore generato una tantum e conservato **fuori dal repository** (gitignored):

```
android/keystore/release.jks   ← NON committare MAI
android/key.properties          ← NON committare MAI
```

> ⚠️ **Backup obbligatorio.** Perso il keystore, non è possibile pubblicare aggiornamenti sulla stessa app su Google Play. Salvare `release.jks` + password in un luogo sicuro (password manager di team o vault aziendale).

`key.properties` contiene:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=chigio-time
storeFile=../keystore/release.jks
```

---

## Build manuale

```bash
# APK per distribuzione diretta
flutter build apk --release --build-name=X.Y.Z --build-number=N

# AAB per Google Play
flutter build appbundle --release --build-name=X.Y.Z --build-number=N
```

Versione corrente definita in `pubspec.yaml`:
```yaml
version: 1.0.11+11   # versionName+versionCode
```

---

## Deploy automatico

```bash
./deploy.sh                  # web + android + (ios se --ios)
./deploy.sh --skip-android   # solo web
./deploy.sh --skip-web       # solo android + github release
./deploy.sh --ios            # include build IPA (richiede Apple Developer)
```

Lo script:
1. Legge `version` da `pubspec.yaml`
2. `flutter build web --release` → Firebase Hosting
3. `flutter build apk --release` + `flutter build appbundle --release`
4. Crea/aggiorna GitHub Release `vX.Y.Z` e carica l'APK come asset
5. `firebase deploy --only hosting` (rimuove APK da build/web prima di deploy — Spark plan vieta eseguibili)

---

## Distribuzione — Sideloading (attuale)

L'APK è pubblicato come asset di ogni GitHub Release:

```
https://github.com/marcocipriani/chigio_time/releases/latest
```

Pagina di installazione guidata:
```
https://chigiotime.web.app/android/install.html
```

**Istruzioni per l'utente:**
1. Aprire la pagina di installazione sul telefono Android
2. Toccare "Scarica APK Android"
3. Aprire il file scaricato e, se richiesto, abilitare "Installa app sconosciute" per il browser/file manager
4. Toccare "Installa"
5. Accedere con le credenziali Google istituzionali

---

## Google Play Store (futuro)

Prerequisiti:
- Account Google Play Console (€25 una tantum)
- AAB firmato (già generato da `deploy.sh`)
- Privacy policy pubblica (richiesta da Google Play)

Steps:
1. Creare l'app su Play Console: `it.marcocipriani.chigio_time`
2. Caricazione iniziale su traccia **Internal testing**
3. Aggiornamenti successivi tramite traccia **Production** o **Closed testing**

> Il `applicationId` è già impostato correttamente in `android/app/build.gradle.kts`.

---

## Incremento versione

Modificare `pubspec.yaml`:
```yaml
version: 1.0.12+12   # incrementa sia versionName che versionCode
```

Poi eseguire `./deploy.sh`.

> Il `versionCode` (build number) deve essere **sempre crescente** per aggiornamenti Play Store.
