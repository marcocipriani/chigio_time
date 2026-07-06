# Code Review completa — 2026-07-05

> Review "dura" dell'intero repository (lib/ + firestore.rules + functions/ +
> test/ + config) eseguita da Claude Code. `flutter analyze`: 0 issue.
> ~44.000 righe Dart analizzate. Findings ordinati per gravità.
> Ogni finding ha: posizione, problema, scenario di rottura, fix proposto.

Legenda severità: 🔴 critico · 🟠 alto · 🟡 medio · 🔵 basso

---

## 🔴 C1 — Dati sensibili sul doc `users/{uid}` leggibile da tutta l'amministrazione ✅ FIXATO 2026-07-06

**Dove:** `firestore.rules` (regola read users) + `lib/features/profile/data/profile_repository.dart:54-61` (`savePortaleData`) + `lib/core/services/fcm_service.dart` (`_saveToken`).

**Problema.** Le rules concedono la lettura del profilo a *qualunque* utente della
stessa amministrazione (directory colleghi). Ma sul doc principale vivono anche
campi che non c'entrano con la directory:

- `portaleJson` — l'intero blob dei totalizzatori HR: matricola, ferie residue,
  straordinari, banca ore, ore da recuperare. Dati personali/HR.
- `fcmToken` — token push del device.
- `hireDate`, `customCounters`, impostazioni notifiche (`paydayDay`, `silenceFrom`…).

**Scenario:** qualsiasi collega PCM autenticato fa `get users/{uid}` e legge
matricola, ferie e straordinari di chiunque nella stessa amministrazione.

**Fix:** spostare `portaleJson`, `fcmToken`, `customCounters` in
`users/{uid}/private/` (la sotto-collezione owner-only esiste già nelle rules).
La function `onNotificationCreated` legge poi il token da `private/`. Migrazione
lazy: on write nuova posizione, on read fallback vecchia.

---

## 🔴 C2 — Cloud Functions: orari calcolati in UTC, non Europe/Rome ✅ FIXATO 2026-07-06

**Dove:** `functions/index.js` — `hourlyNotifications` (`now.getHours()`,
`now.getDay()`, `now.getDate()`) e `_todayId()`.

**Problema.** `timeZone: 'Europe/Rome'` su `onSchedule` governa solo il *cron*,
non l'orologio del runtime: nel container `new Date()` è UTC. Quindi:

- "Colleghi oggi" alle 9 → parte alle 10:00/11:00 italiane (DST).
- Recap settimanale: giorno/ora sfasati; il venerdì sera tardi può diventare sabato.
- Push stipendio `hour === 8` → 9:00/10:00 italiane.
- `_todayId()` confronta `statusDate` con la data UTC → dopo mezzanotte UTC ma
  prima di mezzanotte italiana i conteggi "in ufficio" sbagliano giorno.

Latente (functions non deployate su Spark — vedi memoria progetto), ma esplode
appena si passa a Blaze.

**Fix (1 riga):** `process.env.TZ = 'Europe/Rome';` in cima a `index.js`, prima
di ogni `new Date()`. Node rispetta `TZ`.

---

## 🟠 A1 — Web push silenziosamente rotto: VAPID key placeholder ✅ FIXATO 2026-07-06 (chiave reale inserita)

**Dove:** `lib/core/services/fcm_service.dart` — `_vapidKey = 'YOUR_VAPID_KEY_FROM_FIREBASE_CONSOLE'`.

**Problema.** Su web `getToken(vapidKey: …)` fallisce con la chiave placeholder,
l'eccezione è inghiottita da `catch (_) {}` → nessun token salvato, push web
morte, zero segnali di errore. La piattaforma web è quella deployata (hosting).

**Fix:** mettere la VAPID key reale (Console → Cloud Messaging → Web push
certificates). Non è un segreto: può stare nel codice. Finché manca, almeno un
`debugPrint` nel catch.

---

## 🟠 A2 — Storage rules assenti dal repository ✅ FIXATO 2026-07-06 (`storage.rules` nel repo — verificare/deployare in console)

**Dove:** `firebase.json` (nessuna sezione `storage`), nessun file `storage.rules`.

**Problema.** `uploadProfilePhoto` scrive su `profile_photos/{uid}.jpg` ma le
regole Storage vivono solo in console: non versionate, non riviste, non
deployabili con `deploy.sh`. Se sono le default "authenticated read/write",
**chiunque autenticato può sovrascrivere la foto profilo di un altro utente**
(path non vincolato all'uid).

**Fix:** aggiungere `storage.rules` al repo + sezione in `firebase.json`:

```
match /profile_photos/{fileName} {
  allow read: if request.auth != null;
  allow write: if request.auth != null
    && fileName == request.auth.uid + '.jpg'
    && request.resource.size < 5 * 1024 * 1024
    && request.resource.contentType.matches('image/.*');
}
```

Verificare in console cosa c'è oggi.

---

## 🟠 A3 — Notifiche cross-utente senza confine di amministrazione né rate limit ✅ FIXATO 2026-07-06 (gate amministrazione) + rate limit COMPLETO post-Blaze: 10/24h per destinatario, ban 24h in `abuseBans` oltre 20 tentativi, size-limit sui campi, throttle client 60s, `maxInstances: 10`

**Dove:** `firestore.rules` — `match /notifications/{notifId}` ramo `create` cross-user.

**Problema.** Qualunque utente autenticato può creare `coffee_invite` /
`coffee_accepted` / `colleague_added` nella inbox di **qualunque** altro utente,
anche di amministrazione diversa (il gate amministrazione esiste solo sulla
*lettura* del profilo, non qui). Ogni create scatena una push via
`onNotificationCreated`. Vettore spam/molestie: un account può bombardare di
push chiunque, in loop, gratis.

Il client si difende solo per `colleague_added` (reconcile verifica la
leggibilità del profilo mittente), non per gli inviti caffè.

**Fix minimo:** nelle rules, sul create cross-user richiedere
`get(/users/$(request.auth.uid)).data.administration == get(/users/$(userId)).data.administration`
(2 read in più per create, accettabile). Il rate limiting vero richiederebbe
una function — rimandabile finché l'utenza è interna.

---

## 🟡 M1 — `statusDate`: UTC in un punto, ora locale negli altri ✅ FIXATO 2026-07-06 (`core/utils/date_utils.dart`: `dateIdOf`/`todayId` locali usati ovunque)

**Dove:** `lib/features/profile/data/profile_repository.dart:93` (UTC) vs
`timer_provider.dart:304` `_todayStr()` (locale) vs
`timesheet_repository.dart:31-35` (locale) vs `functions/index.js` `_todayId()` (UTC).

**Problema.** `updateCurrentStatus` scrive `statusDate` con la data **UTC**;
tutto il resto dell'app scrive/confronta date **locali**. Tra mezzanotte UTC e
mezzanotte italiana (00:00–01:00/02:00 locali) lo status pubblicato porta la
data di ieri: la vista colleghi ("In ufficio") scarta o mostra stati sbagliati.

**Fix:** una sola funzione `todayId()` condivisa (locale), usata ovunque.
Rimuovere `.toUtc()` da `updateCurrentStatus`.

---

## 🟡 M2 — Export GDPR "Scarica i miei dati" perde le notifiche social ✅ FIXATO 2026-07-06 (niente orderBy; scoperto e fixato anche il crash `jsonEncode` sui Timestamp: l'export era rotto per QUALSIASI profilo con `updatedAt`)

**Dove:** `lib/features/profile/presentation/profile_screen.dart:1828-1834`.

**Problema.** `orderBy('createdAt', …)` — ma le notifiche social
(`coffee_invite`, `colleague_added`, `coffee_accepted`) hanno solo `sentAt`;
`createdAt` esiste solo sugli `exit_reminder`. In Firestore `orderBy` su campo
assente **esclude il documento dal result set** → l'export contiene solo i
reminder di uscita, non caffè/colleghi. Export dei propri dati incompleto.

**Fix:** `orderBy('sentAt')` (campo presente su tutti i type… verificare gli
exit_reminder: usano `createdAt`, quindi servono due query unite, o meglio:
scrivere `sentAt` anche sugli exit_reminder in `timer_provider._sendExitNotifToFirestore`).

---

## 🟡 M3 — Violazioni di layering (regola vincolante CLAUDE.md §6) ✅ FIXATO 2026-07-06 (`ActiveTimerRepository` in dashboard/data; export in `ProfileRepository.fetchMyData`)

**Dove:**
- `lib/features/dashboard/presentation/timer_provider.dart:157-227, 446-458` —
  accesso diretto a `FirebaseFirestore.instance` da un provider di presentation
  (sync activeTimer + notifica uscita).
- `lib/features/profile/presentation/profile_screen.dart:1801+` —
  `_downloadMyData` legge 3 collezioni Firestore direttamente da un widget.

**Problema.** CLAUDE.md vieta esplicitamente il bypass del layer `data/`.
Oltre alla regola: la logica activeTimer duplicata in 3 punti (save/load/listen
con parsing identico) non è testabile né mockabile.

**Fix:** estrarre `ActiveTimerRepository` (save/load/watch/clear) in
`features/dashboard/data/`, e spostare l'export dati in un metodo di
`ProfileRepository`. Il parsing condiviso elimina ~80 righe duplicate.

---

## 🟡 M4 — Race sul restore del timer all'avvio ✅ FIXATO 2026-07-06 (guardia `status != notStarted` + try/catch sul restore locale)

**Dove:** `timer_provider.dart:400-408`.

**Problema.** `build()` avvia `_loadTimerState(...).then((saved) { state = saved; })`
senza guardie. Se su cold start lento l'utente preme "Inizia turno" prima che il
restore completi (locale o fallback Firestore), il callback sovrascrive il turno
appena avviato con lo stato salvato (o con quello di un altro device). Finestra
piccola ma reale, e il danno è la perdita della timbratura di entrata.

**Fix:** nel `then`, applicare solo se `!state.isShiftActive && state.status == WorkState.notStarted`.
Bonus: `_loadTimerState` non ha try/catch — un pref corrotto (`DateTime.parse`)
uccide il restore con un'eccezione async non gestita (il gemello Firestore il
try/catch ce l'ha).

---

## 🟡 M5 — Zero test sulla logica più critica: il timer ✅ FIXATO 2026-07-06 (`test/features/timer_state_test.dart`: 11 casi su pranzo 3 zone, pause, remaining, copyWith)

**Dove:** `test/` (12 file).

**Problema.** Buona base (domini, CSV import, contrasto, contratto rules) ma
**nessun test su `TimerState`**: `expectedExitTime` con la regola pranzo a 3
zone, `previewDeficit`, `endPause` (minimo 30' pranzo), calcolo `extraMins`/BOE
in `endTurn`. È il cuore dell'app (calcolo orario CCNL) e ogni regressione
tocca dati salvati permanentemente. La logica è pure già estraibile:
`TimerState` è POJO puro, testabile senza Firebase.

**Fix:** un `test/features/timer_state_test.dart` con casi: turno < 9h, 9h-9h30,
> 9h30, pranzo parziale, pausa in corso, BOE. ~100 righe, copre il rischio più alto.

---

## 🟡 M6 — Job orario functions: letture O(utenti × colleghi) ogni ora ✅ MITIGATO 2026-07-06 (`select()` projection, `getAll` con fieldMask sui colleghi, token letto solo se c'è una notifica dovuta; il full-scan resta col suo `ponytail:` ceiling)

**Dove:** `functions/index.js` — `hourlyNotifications` + `_sendMorningColleagues`.

**Problema.** Ogni ora: `users.get()` completo, e per ogni utente con la
notifica mattutina attiva un `get` per **ogni** collega (N+1). Con 200 utenti ×
20 colleghi = 4.000 read extra all'ora di picco. Su Spark il quota giornaliero
free (50k read) si erode in fretta.

**Fix pigro:** filtrare la query (`where('notifyMorningColleagues','==',true)` …
servono indici/campi multipli, in alternativa `where('fcmToken','!=',null)`) e
batchare i colleghi con `getAll(...refs)`. Accettabile rimandare finché
l'utenza è < ~100.

---

## 🔵 B1 — 6 dipendenze dichiarate e mai usate ✅ FIXATO 2026-07-06 (rimosse + wiki/CLAUDE.md aggiornati)

**Dove:** `pubspec.yaml`.

`flutter_secure_storage`, `freezed_annotation` (+ `freezed` in dev),
`json_annotation` (+ `json_serializable` in dev), `table_calendar`, `badges`,
`percent_indicator`: **zero import** in `lib/`. Pesano su pub get, build e
superficie di audit. CLAUDE.md §4 cita ancora Freezed tra i code-gen attivi —
falso. Rimuoverle (e aggiornare CLAUDE.md/ADR-0001); `flutter_secure_storage`
si ri-aggiunge il giorno in cui servirà davvero un segreto locale.

---

## 🔵 B2 — Convenzione provider incoerente ✅ RISOLTO 2026-07-06 ammorbidendo la regola (CLAUDE.md §4: codegen per i provider nuovi, manuali legacy tollerati — la wiki state-management li documentava già come pattern accettato)

**Dove:** `social_repository.dart:408-458`, `timesheet_repository.dart:280-287`,
`global_providers.dart`, `app_database.dart`.

CLAUDE.md impone `@riverpod` codegen; questi file usano `Provider`/
`StreamProvider` manuali. Funziona, ma la convenzione "vincolante" è violata in
~10 provider. O si migrano, o si ammorbidisce la regola in CLAUDE.md — l'attuale
stato ibrido è il peggiore dei due mondi.

---

## 🔵 B3 — Profilo utente = `Map<String, dynamic>` ovunque ⏸ RIMANDATO consapevolmente (refactor incrementale, nessun difetto attivo — vedi sezione finale)

**Dove:** `userProfileStreamProvider` e tutti i consumer (dashboard, profile
7.8k righe, timer…).

Ogni accesso è una stringa magica (`profileData['notifyClockIn']`,
`'exitNotifMins'`, …): un typo compila e restituisce `null` in silenzio. Con
~40 campi ormai un modello `UserProfile.fromMap` tipizzato ripagherebbe in una
settimana. Refactor incrementale: prima i campi letti dal timer (quelli che
fanno danni), poi il resto.

---

## 🔵 B4 — File presentation monstre ⏸ RIMANDATO consapevolmente (solo manutenibilità — vedi sezione finale)

`profile_screen.dart` **7.824** righe, `timesheet_screen.dart` 4.509,
`social_screen.dart` 3.566, `timbratura_hero.dart` 2.395. Non è un bug, è un
costo: ogni merge/review/ricerca paga il pedaggio. Spacchettare per sheet/tab
(ogni `_showXxx` bottom sheet è già un widget naturale da estrarre).

---

## 🔵 B5 — Minori (one-liner ciascuno) ✅ 1-7 FIXATI 2026-07-06, 8 rimandato

Esiti: 1 ✅ round-trip check; 2 ✅ soglia dal profilo; 3 ✅ riordinato; 4 ✅
limit 200 + commento ceiling; 5 ✅ timestamp diretto; 6 ✅ `select` su
status/standardWorkMins in dashboard (glass_header consuma i minuti live per
le frasi di Chigio → tick necessario, non è un bug); 7 ✅ `debugPrint` nei
catch FCM; 8 ⏸ emulator tests rimandati (setup pesante, contratto grep resta).

| # | Dove | Problema |
|---|------|----------|
| 1 | `csv_import_service.dart:260` | `_validDateId` accetta `2026-02-31` (Dart normalizza a marzo) → docId con date inesistenti |
| 2 | `functions/index.js` `_sendWeeklyRecap` | soglia buono pasto hardcoded 380 vs `mealVoucherThresholdMins` configurabile nel profilo |
| 3 | `social_repository.dart:299-303` | `respondToInvite`: `update` prima del check `snap.exists` → throw su notifica appena cancellata |
| 4 | `social_repository.dart:436-458` | `coffeeStats` conta su `limit(50)` notifiche → statistiche mensili sottostimate |
| 5 | `timesheet_repository.dart:245` | `_toCompanion` chiama `e.toMap()` solo per `updatedAt` → timestamp cache ≠ timestamp Firestore |
| 6 | `timer_provider.dart:410-436` | ticker aggiorna `state` ogni secondo → rebuild di ogni watcher anche quando cambia solo `currentTime`; i widget che leggono solo lo status dovrebbero usare `select` |
| 7 | ovunque | `catch (_) {}` silenziosi (fcm, geofencing, restore) — già noto da CLAUDE.md §6, manca il logger |
| 8 | `test/security/firestore_rules_test.dart` | test "contratto" grep-based: utile ma fragile (un refactor testuale delle rules li rompe/aggira); valutare `firebase emulators:exec` con rules-unit-testing quando possibile |

---

## Cosa è FATTO BENE (per onestà di bilancio)

- `firestore.rules`: modellazione attenta (whitelist campi notifiche, join/leave
  progetti vincolati al proprio uid, gate amministrazione, commenti col perché).
- Parsing tollerante ovunque (`fromMap` null-safe, fallback epoch) — un doc
  corrotto non uccide gli stream.
- `endTurn` non muta lo stato finché il save non riesce → retry pulito.
- Router: redirect sincrono ben ragionato (commento spiega la race eliminata).
- Offline-first con Drift + fallback trasparente.
- 0 warning analyzer, 0 `print`, 0 TODO fantasma.

---

## Priorità consigliata

1. ~~**C1 + A3** (stesso giro di rules)~~ ✅ fatto 2026-07-06.
2. ~~**C2 + A1 + A2**~~ ✅ fatto 2026-07-06 — deploy rules Firestore/Storage ancora da eseguire.
3. ~~**M1, M2, M4**~~ ✅ fatto 2026-07-06.
4. ~~**M5**~~ ✅ fatto 2026-07-06.
5. ~~B1~~ ✅, ~~B2~~ ✅ (regola ammorbidita), ~~M3~~ ✅, ~~B5.1-7~~ ✅ — restano B3/B4 (refactor incrementali) e B5.8.

---

## Resta a te (produzione) — aggiornato 2026-07-06

Checklist delle azioni che il codice non può fare da solo:

1. ~~Deploy rules~~ ✅ 2026-07-06: firestore.rules + storage.rules deployate
   (A2, A3 e anti-spam attivi in produzione).
2. ~~Blaze~~ ✅ 2026-07-06: piano attivo, functions deployate (verifica lo
   stato di `onNotificationCreated`: il primo deploy Eventarc può richiedere
   un retry).
3. **Budget alert GCP** — da impostare a mano in console (Billing → Budget):
   il codice ha `maxInstances: 10` ma il tetto di spesa vero lo dà l'alert.
4. **Migrazione utenti dormienti (C1)** — script pronto:
   `SA_KEY=/path/key.json node scripts/migrate_private_fields.mjs` (dry-run,
   poi `--apply`). Serve la service-account key scaricata dalla console
   (Impostazioni progetto → Account di servizio → Genera nuova chiave).
5. **B3 (profilo tipizzato) e B4 (spacchettare i file monstre)** — refactor
   incrementali da fare quando si tocca quella zona, non in un big-bang:
   B3 partendo dai campi letti dal timer, B4 estraendo i bottom-sheet di
   `profile_screen` un widget alla volta.
6. **B5.8** — test rules su emulatore (`firebase emulators:exec` +
   `@firebase/rules-unit-testing`) quando ci sarà voglia di setup: il
   contratto grep-based continua a coprire le regressioni testuali.
