# Entita': `UserProfile`

> Profilo del lavoratore: contiene le **regole contrattuali personali**
> (orario standard, soglie buono pasto, monte ore permessi brevi/label
> storica "Art.9" e straordinari)
> e le preferenze (tema). E' il "settings" persistente dell'utente.

## Forma logica

`UserProfile` non e' definito come classe Dart "tipata": e' la
rappresentazione del documento Firestore `users/{uid}`, scritto da
`ProfileRepository.saveOnboardingData(...)` e letto come
`Map<String, dynamic>?` da `userProfileStreamProvider`.

| Campo Firestore | Tipo | Origine | Note |
|---|---|---|---|
| `name` | `String` | `OnboardingState.name` | nome visibile |
| `administration` | `String` | `OnboardingState.administration` | default *"Presidenza del Consiglio dei Ministri"* — picker mostra solo PCM attivo |
| `employmentType` | `String` | `OnboardingState.employmentType` | `Ruolo` / `Comando` / `Altro` |
| `gender` | `String` | onboarding/profilo | `M` / `F` / `A` / `N`; usato da Chigio per accordi grammaticali |
| `dipartimento` | `String` | onboarding/profilo editabile | dipartimento / struttura organizzativa |
| `sede` | `String` | onboarding/profilo editabile | sede PCM selezionata da elenco |
| `sedeId` | `String` | onboarding/profilo editabile | id stabile dell'opzione sede/struttura |
| `sedeAddress` | `String` | onboarding/profilo editabile | indirizzo completo sede |
| `sedeLat` | `double` | onboarding/profilo editabile | latitudine WGS84 sede |
| `sedeLng` | `double` | onboarding/profilo editabile | longitudine WGS84 sede |
| `piano` | `String` | profilo editabile | piano dell'ufficio |
| `stanza` | `String` | profilo editabile | numero stanza/ufficio |
| `interno` | `String` | profilo editabile | numero interno (SIP/VOIP); usato anche per chiamata diretta colleghi |
| `phoneNumber` | `String` | profilo editabile | numero mobile; usato per chiamata colleghi |
| `standardDailyMins` | `int` | preset contrattuale | Ruolo: 456 (7h36) o 400 (6h40) · Comando: 432 (7h12) o 372 (6h12) |
| `mealVoucherThresholdMins` | `int` | profilo editabile | soglia per maturare il buono pasto (slider 240–480 min) |
| `monthlyArt9Hours` | `int` | `OnboardingState.monthlyArt9Hours` | tetto mensile legacy per contatore `art9`; da riallineare con Art. 35 permessi brevi e/o label portale |
| `monthlyOvertimeHours` | `int` | `OnboardingState.monthlyOvertimeHours` | tetto mensile straordinari (SLI + SBO) |
| `monthlySliHours` | `int` | profilo editabile | cap SLI mensile (default 0 = nessun cap) |
| `monthlySboHours` | `int` | profilo editabile | cap SBO mensile (default 0 = nessun cap) |
| `summaryItems` | `List<String>` | preferenza utente | voci visibili nel widget blu: `['art9','sli','sbo','op']`; default = tutte |
| `summaryShowProgress` | `bool` | preferenza utente | mostra/nascondi barre avanzamento nel widget blu (default `true`) |
| `highlightWidget` | `String` | preferenza utente | widget in evidenza in dashboard: `'none'`/`'bankHours'`/`'overtime'`/`'mealCount'` (default `'none'`) |
| `portaleJson` | `Map<String,dynamic>` | profilo editabile | snapshot manuale totalizzatori portale PA letto da `totalizzatoriProvider` |
| `gpsAutoClockIn` | `bool` | preferenza utente | abilita prompt GPS auto-timbratura entrata (default `false`) |
| `officeLat` | `double` | impostato da profilo GPS | latitudine ufficio (WGS84) |
| `officeLng` | `double` | impostato da profilo GPS | longitudine ufficio (WGS84) |
| `officeRadiusM` | `double` | impostato da profilo GPS | raggio geofence in metri (default 150) |
| `notifyClockIn` | `bool` | preferenza utente | promemoria timbratura entrata |
| `notifyClockOut` | `bool` | preferenza utente | promemoria timbratura uscita |
| `notifyWeekly` | `bool` | preferenza utente | report settimanale |
| `exitNotifMins` | `int` | preferenza utente | soglia notifica push uscita prevista: 0/5/10/15/30 |
| `themePreference` | `String` | `themePreference.toString()` | es. `"ThemeMode.system"` |
| `hasCompletedOnboarding` | `bool` | costante `true` | flag esplicito |
| `updatedAt` | `Timestamp` (server) | `FieldValue.serverTimestamp()` | last write |

## Mappatura su codice

| Operazione | Provider / metodo | File |
|---|---|---|
| Scrittura iniziale (onboarding) | `ProfileRepository.saveOnboardingData(state)` | `lib/features/profile/data/profile_repository.dart` |
| Esistenza profilo (gating router) | `hasProfileStreamProvider` | `lib/features/profile/data/profile_repository.dart` |
| Lettura per UI Profilo | `userProfileStreamProvider` | `lib/features/profile/data/profile_repository.dart` |

## Vincoli e regole

- **Unicita':** un documento per `uid` Firebase Auth.
- **Idempotenza scrittura:** `set(..., SetOptions(merge: true))`.
- **Cache locale:** `SharedPreferences['hasProfile_<uid>']` viene
  scritto a `true` al primo successo del check Firestore. Va invalidato
  al logout (vedi nota in `auth_repository.dart`: oggi non e' fatto
  esplicitamente — candidato a fix).
- **Sede strutturata:** `sede*` serve sia per profilo/social sia per widget
  percorsi; non sostituisce i campi GPS `officeLat`/`officeLng`, che restano
  configurazione geofence personale.

## Estensioni previste

- `email` e `photoUrl` redondati dal `User` di Firebase Auth (oggi presi
  direttamente da `FirebaseAuth.instance.currentUser`).
- `updatedAt` lato dispositivo (per merge offline futuri).
- Campo `schemaVersion` per gestire migrazioni.

_Ultima revisione: 2026-06-07 — aggiunti genere, sede PCM strutturata, `portaleJson` ed `exitNotifMins`._
