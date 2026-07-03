# iOS — Build e Deploy

> **Prerequisito bloccante:** è richiesto un account Apple Developer **a pagamento** (€99/anno).
> Senza di esso non è possibile firmare l'IPA né distribuirlo.

---

## Prerequisiti

| Requisito | Note |
|---|---|
| Xcode 15+ | già installato |
| Apple Developer Program | iscrizione su [developer.apple.com](https://developer.apple.com) |
| Team ID | visibile su developer.apple.com → Account → Team ID |
| Provisioning profile Ad Hoc o App Store | generato su developer.apple.com o tramite Xcode automatico |

---

## Configurazione iniziale

### 1. Aggiorna `ios/ExportOptions.plist`

```xml
<key>method</key>
<string>ad-hoc</string>          <!-- oppure: app-store | development -->
<key>teamID</key>
<string>XXXXXXXXXX</string>      <!-- il tuo Team ID -->
```

### 2. Firma automatica in Xcode

Apri `ios/Runner.xcworkspace` → seleziona target **Runner** → scheda **Signing & Capabilities**:

- Abilita **Automatically manage signing**
- Seleziona il tuo **Team**
- Verifica che il Bundle ID sia `it.marcocipriani.chigio_time`

### 3. Registra i dispositivi (solo Ad Hoc)

Su developer.apple.com → Devices → aggiungi gli UDID dei dispositivi da autorizzare.

---

## Build manuale

```bash
# IPA Ad Hoc
flutter build ipa --release \
  --build-name=X.Y.Z \
  --build-number=N \
  --export-options-plist=ios/ExportOptions.plist

# Output
build/ios/ipa/Runner.ipa
```

---

## Deploy automatico

```bash
./deploy.sh --ios            # web + android + ios
./deploy.sh --skip-android --ios   # web + ios only
```

Lo script carica l'IPA come asset della GitHub Release `vX.Y.Z`.

> iOS è **disabilitato per default** in `deploy.sh` (`SKIP_IOS=true`).
> Passa il flag `--ios` per attivarlo.

---

## Distribuzione

### Ad Hoc (attuale consigliato)

L'IPA è pubblicato sulla GitHub Release. Installazione tramite:

1. **AltStore** (gratuito, da AltStore.io) — consente di installare IPA sideload
2. **Scaricaboo / Sideloadly** — alternativa desktop
3. **Apple Configurator 2** — per deployment aziendale via Mac

Pagina installazione iOS (futuro):
```
https://chigiotime.web.app/ios/install.html
```

### App Store / TestFlight (futuro)

1. Cambia `method` in `ExportOptions.plist` → `app-store`
2. Carica l'IPA su App Store Connect con Transporter o Xcode Organizer
3. Distribuisci via TestFlight (beta) o rilascio pubblico

---

## Versione

Definita in `pubspec.yaml` (condivisa con Android):
```yaml
version: 1.0.10+10   # CFBundleShortVersionString+CFBundleVersion
```

---

## Incremento versione

Modifica `pubspec.yaml`, poi esegui `./deploy.sh --ios`.

> Il build number iOS (`CFBundleVersion`) deve essere **sempre crescente** per App Store Connect.
