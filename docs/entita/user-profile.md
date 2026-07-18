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
| `administration` | `String` | `OnboardingState.administration` | per i nuovi profili può essere solo *"Presidenza del Consiglio dei Ministri"*; dopo il primo set è immutabile |
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
| `monthlyArt9Hours` | `int` | `OnboardingState.monthlyArt9Hours` | cap mensile ore di maggior presenza Art. 9 (8 ruolo / 17 comando); istituto distinto dai permessi brevi Art. 35 |
| `monthlyOvertimeHours` | `int` | `OnboardingState.monthlyOvertimeHours` | tetto mensile straordinari (SLI + SBO) |
| `monthlySliHours` | `int` | profilo editabile | cap SLI mensile (default 0 = nessun cap) |
| `monthlySboHours` | `int` | profilo editabile | cap SBO mensile (default 0 = nessun cap) |
| `summaryItems` | `List<String>` | preferenza utente | voci visibili nel widget blu: `['art9','sli','sbo','op']`; default = tutte |
| `summaryShowProgress` | `bool` | preferenza utente | mostra/nascondi barre avanzamento nel widget blu (default `true`) |
| `highlightWidget` | `String` | preferenza utente | widget in evidenza in dashboard: `'none'`/`'bankHours'`/`'overtime'`/`'mealCount'` (default `'none'`) |
| ~~`portaleJson`~~ | `Map<String,dynamic>` | — | **migrato in `users/{uid}/private/portale`** (C1, 2026-07-06): dati HR non piu' sul doc leggibile dai colleghi; fallback legacy in `portaleRawProvider` |
| `gpsAutoClockIn` | `bool` | preferenza utente | abilita prompt GPS auto-timbratura entrata (default `false`) |
| `officeLat` | `double` | impostato da profilo GPS | latitudine ufficio (WGS84) |
| `officeLng` | `double` | impostato da profilo GPS | longitudine ufficio (WGS84) |
| `officeRadiusM` | `double` | impostato da profilo GPS | raggio geofence in metri (default 150) |
| `exitNotifMins` | `int` | preferenza utente | anticipo reminder uscita: 0/5/10/15/30 min; 0 = disattivato |
| `doNotDisturb` | `bool` | preferenza utente | sopprime la consegna push non critica, non l'evento inbox |
| `silenceFrom` / `silenceTo` | `int` | preferenza utente | ore 0–23 della fascia DND; intervallo anche overnight |
| `notifyMorningColleagues` | `bool` | preferenza utente | abilita il riepilogo colleghi presenti |
| `morningColleaguesHour` | `int` | preferenza utente | ora di invio del riepilogo colleghi |
| `notifyWeeklyRecap` | `bool` | preferenza utente | abilita il recap da lunedì al momento dell'invio |
| `weeklyRecapDay` / `weeklyRecapHour` | `int` | preferenza utente | giorno ISO 1–7 e ora del recap |
| `monthlyOtAlertHours` | `int` | preferenza utente | soglia mensile straordinario; 0 = disattivata |
| `notifyPayday` | `bool` | preferenza utente | abilita la notifica stipendio |
| `paydayDay` | `int` | preferenza utente | giorno accredito 1–28; invio alle 08:00 |
| `themePreference` | `String` | `themePreference.toString()` | es. `"ThemeMode.system"` |
| `hasCompletedOnboarding` | `bool` | costante `true` | flag esplicito |
| `updatedAt` | `Timestamp` (server) | `FieldValue.serverTimestamp()` | last write |

## Mappatura su codice

| Operazione | Provider / metodo | File |
|---|---|---|
| Scrittura iniziale (onboarding) | `ProfileRepository.saveOnboardingData(state)` | `lib/features/profile/data/profile_repository.dart` |
| Esistenza profilo (gating router) | `hasProfileStreamProvider` | `lib/features/profile/data/profile_repository.dart` |
| Lettura per UI Profilo | `userProfileStreamProvider` | `lib/features/profile/data/profile_repository.dart` |
| Salvataggio preferenze notifica | `ProfileRepository.updateNotificationPreferences(fields)` | `lib/features/profile/data/profile_repository.dart` |
| Notifica di prova | `ProfileRepository.sendTestNotification()` | `lib/features/profile/data/profile_repository.dart` |

## Vincoli e regole

- **Unicita':** un documento per `uid` Firebase Auth.
- **Idempotenza scrittura:** `set(..., SetOptions(merge: true))`.
- **Confine tenant:** `administration` governa directory e notifiche
  cross-user. Le rules consentono a un doc parziale pre-onboarding di ometterla,
  poi accettano solo PCM come primo valore e la rendono immutabile. Valori
  legacy diversi restano validi ma non modificabili; gli altri campi del
  profilo continuano a essere aggiornabili. Il delete del documento profilo è
  negato al client per evitare delete+recreate. Resta aperta la prova di
  membership dei nuovi account PCM: richiede una futura authority server-side.
- **Cache locale:** `SharedPreferences['hasProfile_<uid>']` viene
  scritto a `true` al primo successo del check Firestore. Va invalidato
  al logout (vedi nota in `auth_repository.dart`: oggi non e' fatto
  esplicitamente — candidato a fix).
- **Sede strutturata:** `sede*` serve sia per profilo/social sia per widget
  percorsi; non sostituisce i campi GPS `officeLat`/`officeLng`, che restano
  configurazione geofence personale.
- **Token FCM:** non appartengono al profilo pubblico. Vivono in
  `users/{uid}/private/fcm.installations.{installationId}` con `token`,
  `platform`, `updatedAt`; `private/fcm.token` e `users/{uid}.fcmToken` sono
  fallback temporanei per account non ancora migrati.
- **Campi notifica rimossi:** `notifyClockIn`, `notifyClockOut` e
  `notifyWeekly` non hanno più UI o comportamento. Il salvataggio delle
  preferenze li elimina con `FieldValue.delete()`; non esiste un reminder
  entrata.

## Estensioni previste

- `email` e `photoUrl` redondati dal `User` di Firebase Auth (oggi presi
  direttamente da `FirebaseAuth.instance.currentUser`).
- `updatedAt` lato dispositivo (per merge offline futuri).
- Campo `schemaVersion` per gestire migrazioni.

_Ultima revisione: 2026-07-18 — tenant set-once/delete-safe; membership PCM ancora aperta._
