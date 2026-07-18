# Push Notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consegnare notifiche push affidabili, multi-device e osservabili su Android, iOS, macOS e Web, mantenendo l'inbox Firestore come sorgente unica.

**Architecture:** Ogni evento crea prima `users/{uid}/notifications/{id}`; una sola Cloud Function applica DND, risolve copy/route e invia FCM a tutte le installazioni. I reminder uscita diventano server-side tramite `activeTimer/state.reminderAt`; timer, eventi periodici e soglia straordinario producono documenti inbox deterministici.

**Tech Stack:** Flutter 3 / Dart 3.10+, Riverpod 3, Firebase Messaging 16, Cloud Firestore, Cloud Functions v2 Node 20, `flutter_test`, `node:test`.

## Global Constraints

- Android, iOS, macOS e Web ricevono push; Windows/Linux saltano FCM senza errore.
- Multi-device: una voce per installazione in `users/{uid}/private/fcm.installations`.
- DND blocca tutte le push non critiche ma non elimina l'evento inbox; `test` bypassa DND.
- Rimuovere `notifyClockIn`, `notifyClockOut`, `notifyWeekly`; nessun reminder entrata.
- Nessuna nuova dipendenza Flutter; riusare `uuid`, `shared_preferences`, Firebase e GoRouter gia' presenti.
- Non modificare manualmente file `*.g.dart`.
- Ogni task segue RED -> GREEN -> regressione -> commit -> push.
- Conservare intatti `.impeccable/`, `AGENTS.md` e `Appendice A-elenco strutture.pdf`, file utente non tracciati.

---

## File map

| File | Responsabilita' |
|---|---|
| `functions/notification_logic.js` | DND, route, copy, settimana, token e risultati multicast |
| `functions/index.js` | Trigger Firestore, scheduler, invio FCM, deduplica e logging |
| `lib/core/services/notification_routing.dart` | Allowlist route e supporto piattaforme FCM |
| `lib/core/services/fcm_service.dart` | Registrazione installazione, refresh, logout e tap routing |
| `lib/features/dashboard/data/active_timer_repository.dart` | Persistenza `reminderAt` |
| `lib/features/dashboard/presentation/timer_provider.dart` | Calcolo reminder e sincronizzazione transizioni |
| `lib/features/social/domain/app_notification.dart` | Modello social/sistema + stato consegna |
| `lib/features/profile/data/profile_repository.dart` | Preferenze reali e invio test |
| `android/`, `ios/`, `macos/`, `web/` | Channel, capability, entitlement e click Web |
| `docs/decisioni/0012-notifiche-firebase-inbox-first.md` | Decisione cross-feature |

---

### Task 1: Contratto puro backend

**Files:**
- Create: `functions/notification_logic.js`
- Create: `functions/test/notification_logic.test.js`
- Modify: `functions/package.json`

**Interfaces:**
- Produces: `routeForNotification(data) -> string`
- Produces: `isQuietTime(profile, now) -> boolean`
- Produces: `weekDateRange(now) -> {startId, endId}`
- Produces: `contentForNotification(data) -> {title, body}`
- Produces: `collectInstallations(fcmData, legacyToken) -> Array<{id, token}>`
- Produces: `summarizeDelivery(installations, responses)`
- Produces: `formatMinutes(minutes) -> string`

- [ ] **Step 1: Aggiungere lo script test Node**

In `functions/package.json` aggiungere `"test": "node --test test/*.test.js"`.

- [ ] **Step 2: Scrivere i test fallenti**

Creare `functions/test/notification_logic.test.js`:

```js
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const logic = require('../notification_logic');

test('DND overnight e intervallo nullo', () => {
  const p = { doNotDisturb: true, silenceFrom: 22, silenceTo: 8 };
  assert.equal(logic.isQuietTime(p, new Date(2026, 6, 17, 23)), true);
  assert.equal(logic.isQuietTime(p, new Date(2026, 6, 18, 7)), true);
  assert.equal(logic.isQuietTime(p, new Date(2026, 6, 18, 12)), false);
  assert.equal(logic.isQuietTime({ ...p, silenceFrom: 8, silenceTo: 8 }, new Date()), false);
});

test('route esplicite e type sono allowlisted', () => {
  assert.equal(logic.routeForNotification({ type: 'exit_reminder' }), '/dashboard');
  assert.equal(logic.routeForNotification({ type: 'payday' }), '/salary');
  assert.equal(logic.routeForNotification({ route: '/stats' }), '/stats');
  assert.equal(logic.routeForNotification({ route: 'https://evil.test' }), '/notifications');
});

test('settimana corrente parte lunedi', () => {
  assert.deepEqual(logic.weekDateRange(new Date(2026, 6, 17, 18)), {
    startId: '2026-07-13', endId: '2026-07-17',
  });
});

test('copy social e contenuto automatico esplicito', () => {
  assert.deepEqual(logic.contentForNotification({ type: 'colleague_added', fromName: 'Marta' }), {
    title: '👋 Nuovo collegamento', body: 'Marta si è collegata con te',
  });
  assert.deepEqual(logic.contentForNotification({ title: 'Titolo', body: 'Corpo' }), {
    title: 'Titolo', body: 'Corpo',
  });
});

test('token deduplicati con fallback legacy', () => {
  assert.deepEqual(logic.collectInstallations({
    installations: { a: { token: 'one' }, b: { token: 'one' }, c: { token: 'two' } },
    token: 'legacy-doc',
  }, 'legacy-user'), [
    { id: 'a', token: 'one' }, { id: 'c', token: 'two' },
    { id: 'legacy-private', token: 'legacy-doc' },
    { id: 'legacy-user', token: 'legacy-user' },
  ]);
});

test('multicast identifica token stale senza esporli', () => {
  const installs = [{ id: 'a', token: 'one' }, { id: 'b', token: 'two' }];
  const responses = [
    { success: true },
    { success: false, error: { code: 'messaging/registration-token-not-registered' } },
  ];
  assert.deepEqual(logic.summarizeDelivery(installs, responses), {
    successCount: 1,
    staleIds: ['b'],
    errorCodes: ['messaging/registration-token-not-registered'],
  });
  assert.equal(logic.formatMinutes(457), '7h37');
});
```

- [ ] **Step 3: Verificare RED**

Run: `npm --prefix functions test`

Expected: FAIL con `Cannot find module '../notification_logic'`.

- [ ] **Step 4: Implementare il modulo puro**

Creare `functions/notification_logic.js` con:

```js
'use strict';
const ALLOWED = new Set(['/dashboard', '/notifications', '/social', '/stats', '/salary']);
const ROUTES = Object.freeze({
  exit_reminder: '/dashboard', morning_colleagues: '/social',
  coffee_invite: '/notifications', coffee_accepted: '/notifications',
  colleague_added: '/notifications', weekly_recap: '/stats',
  overtime_threshold: '/stats', payday: '/salary', test: '/notifications',
});
const STALE = new Set([
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
]);

function routeForNotification(data = {}) {
  return ALLOWED.has(data.route) ? data.route : (ROUTES[data.type] ?? '/notifications');
}
function isQuietTime(profile = {}, now = new Date()) {
  if (profile.doNotDisturb !== true) return false;
  const from = Number.isInteger(profile.silenceFrom) ? profile.silenceFrom : 22;
  const to = Number.isInteger(profile.silenceTo) ? profile.silenceTo : 8;
  if (from === to) return false;
  const hour = now.getHours();
  return from < to ? hour >= from && hour < to : hour >= from || hour < to;
}
function localDateId(date) {
  const pad = (n) => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}
function weekDateRange(now) {
  const start = new Date(now);
  start.setHours(0, 0, 0, 0);
  start.setDate(start.getDate() - ((start.getDay() + 6) % 7));
  return { startId: localDateId(start), endId: localDateId(now) };
}
function contentForNotification(data = {}) {
  if (typeof data.title === 'string' && typeof data.body === 'string') {
    return { title: data.title, body: data.body };
  }
  const from = data.fromName ?? 'Un collega';
  if (data.type === 'colleague_added') {
    return { title: '👋 Nuovo collegamento', body: `${from} si è collegata con te` };
  }
  if (data.type === 'coffee_invite') {
    const suffix = data.scheduledAt ? ` alle ${data.scheduledAt}` : '';
    return { title: '☕ Invito caffè', body: `${from} ti ha invitato a un caffè${suffix}` };
  }
  if (data.type === 'coffee_accepted') {
    const copy = {
      accepted: ['✅ Caffè accettato', `${from} ci sarà!`],
      maybe: ['🤔 Forse…', `${from} risponde forse al tuo invito`],
      declined: ['❌ Caffè rifiutato', `${from} non può venire`],
      arriving: ['🚶 Sta arrivando', `${from} sta arrivando${data.etaMinutes ? ` tra ${data.etaMinutes} min` : ''}`],
    }[data.responseType] ?? ['Chigio Time', `${from} ha risposto al tuo invito`];
    return { title: copy[0], body: copy[1] };
  }
  return { title: 'Chigio Time', body: 'Hai una nuova notifica' };
}
function collectInstallations(fcmData = {}, legacyToken) {
  const result = [];
  const seen = new Set();
  const add = (id, token) => {
    if (typeof token !== 'string' || token.length === 0 || seen.has(token)) return;
    seen.add(token); result.push({ id, token });
  };
  for (const [id, value] of Object.entries(fcmData.installations ?? {})) add(id, value?.token);
  add('legacy-private', fcmData.token); add('legacy-user', legacyToken);
  return result;
}
function summarizeDelivery(installations, responses) {
  const staleIds = []; const errorCodes = []; let successCount = 0;
  responses.forEach((response, index) => {
    if (response.success) { successCount++; return; }
    const code = response.error?.code ?? 'messaging/unknown';
    if (!errorCodes.includes(code)) errorCodes.push(code);
    if (STALE.has(code)) staleIds.push(installations[index].id);
  });
  return { successCount, staleIds, errorCodes };
}
function formatMinutes(minutes) {
  const value = Math.max(0, Number(minutes) || 0);
  return `${Math.floor(value / 60)}h${String(value % 60).padStart(2, '0')}`;
}
module.exports = {
  routeForNotification, isQuietTime, localDateId, weekDateRange,
  contentForNotification, collectInstallations, summarizeDelivery, formatMinutes,
};
```

- [ ] **Step 5: Verificare GREEN e commit**

Run: `npm --prefix functions test`

Expected: 6 test PASS.

```bash
git add functions/package.json functions/notification_logic.js functions/test/notification_logic.test.js
git commit -m "test(functions): define notification delivery contract"
git push origin main
```

---

### Task 2: Inbox-first, multicast e produttori server-side

**Files:**
- Modify: `functions/index.js`
- Test: `functions/test/notification_logic.test.js`

**Interfaces:**
- Consumes: funzioni di `notification_logic.js`.
- Produces: `onNotificationCreated`, `hourlyNotifications`, `exitReminders`, `onTimesheetWritten`.

- [ ] **Step 1: Estendere RED con tutti i type automatici**

Aggiungere route assertions per `morning_colleagues`, `weekly_recap`,
`overtime_threshold`, `payday`, poi eseguire `npm --prefix functions test`.

Expected: FAIL per ogni mappatura mancante.

- [ ] **Step 2: Implementare multicast osservabile**

In `functions/index.js` importare `onDocumentWritten`, `FieldValue` e il modulo
puro. Mantenere il cap effettivo di 10 notifiche sociali/24h; rimuovere i nuovi
writer `SPAM_BAN_AFTER`, `SPAM_BAN_HOURS` dal backend. Le rules devono però
onorare in read-only eventuali `abuseBans` creati dalla Function già
distribuita fino alla loro scadenza.

`onNotificationCreated` deve:

1. eseguire anti-spam cross-user;
2. leggere profilo e `private/fcm`;
3. scrivere `suppressed` durante DND, salvo type `test`;
4. scrivere `no-token` se non esistono installazioni;
5. inviare `sendEachForMulticast`;
6. rimuovere solo le installazioni stale;
7. scrivere `sent` o `failed` e log JSON senza token.

Payload esatto:

```js
const route = routeForNotification(data);
const { title, body } = contentForNotification(data);
const response = await getMessaging().sendEachForMulticast({
  tokens: installations.map((installation) => installation.token),
  notification: { title, body },
  data: { type: data.type ?? '', route, fromUid: data.fromUid ?? '' },
  android: { notification: { channelId: 'chigio_notifications', priority: 'high', sound: 'default' } },
  apns: { payload: { aps: { badge: 1, sound: 'default' } } },
  webpush: {
    notification: { icon: 'https://chigiotime.web.app/icons/web-app-manifest-192x192.png' },
    fcmOptions: { link: `https://chigiotime.web.app/#${route}` },
  },
});
```

Esiti:

```js
{ pushStatus: 'suppressed', pushedAt: Timestamp.now() }
{ pushStatus: 'no-token', pushedAt: Timestamp.now() }
{ pushStatus: 'sent', pushedAt: Timestamp.now(), pushError: FieldValue.delete() }
{ pushStatus: 'failed', pushedAt: Timestamp.now(), pushError: errorCodes.join(',') }
```

Pulizia puntuale:

```js
const updates = {};
for (const id of staleIds) {
  if (id === 'legacy-private') updates.token = FieldValue.delete();
  else if (id !== 'legacy-user') updates[`installations.${id}`] = FieldValue.delete();
}
if (Object.keys(updates).length > 0) await fcmRef.update(updates);
if (staleIds.includes('legacy-user')) {
  await db.doc(`users/${recipientUid}`).set({ fcmToken: FieldValue.delete() }, { merge: true });
}
```

- [ ] **Step 3: Convertire scheduler in produttori inbox**

Helper unico:

```js
async function _createNotification(db, uid, id, fields) {
  try {
    await db.doc(`users/${uid}/notifications/${id}`).create({
      ...fields, sentAt: Timestamp.now(), status: 'info', read: false,
    });
    return true;
  } catch (error) {
    if (error.code === 6 || error.code === 'already-exists') return false;
    throw error;
  }
}
```

`hourlyNotifications` usa `0 * * * *` e crea ID deterministici:

```text
morning-{YYYY-MM-DD}  type=morning_colleagues  route=/social
weekly-{mondayId}     type=weekly_recap        route=/stats
payday-{YYYY-MM}      type=payday              route=/salary
```

Il recap interroga i doc ID tra `weekDateRange(now).startId` ed `endId`, somma
`netWorkedMins`, `max(0, extraMins)` e buoni, e usa `formatMinutes`.

- [ ] **Step 4: Aggiungere reminder uscita**

`exitReminders` usa cron `* * * * *` e query:

```js
const due = await db.collectionGroup('activeTimer')
  .where('reminderAt', '<=', Timestamp.now()).limit(100).get();
```

Per ogni doc `state`, una transazione legge timer e notifica
`exit-{timer.date}`, rimuove `reminderAt`, scrive `reminderClaimedAt`, e se la
notifica manca la crea con type `exit_reminder`, route `/dashboard` e body
`Tra ${timer.reminderLeadMins ?? 15} min finisce il tuo turno.`.

- [ ] **Step 5: Aggiungere soglia straordinario**

`onTimesheetWritten` ascolta `users/{uid}/timesheets/{dateId}`. Legge
`monthlyOtAlertHours`, somma gli `extraMins > 0` del mese e crea una volta:

```text
id=overtime-{YYYY-MM}
type=overtime_threshold
route=/stats
title=🔔 Soglia straordinari raggiunta
body=Hai raggiunto {ore} di straordinario questo mese.
```

- [ ] **Step 6: Verificare e commit**

Run:

```bash
npm --prefix functions test
node --check functions/index.js
node --check functions/notification_logic.js
```

Expected: test PASS; syntax check senza errori.

```bash
git add functions/index.js functions/test/notification_logic.test.js
git commit -m "feat(functions): deliver unified multi-device notifications"
git push origin main
```

---

### Task 3: Persistenza server-side del reminder uscita

**Files:**
- Modify: `test/features/timer_state_test.dart`
- Modify: `lib/features/dashboard/data/active_timer_repository.dart`
- Modify: `lib/features/dashboard/presentation/timer_provider.dart`
- Modify: `lib/features/dashboard/presentation/dashboard_screen.dart`

**Interfaces:**
- Produces: `TimerState.exitReminderAt -> DateTime?`.
- Produces: `ActiveTimerData.reminderAt`, `ActiveTimerData.reminderLeadMins`.
- Consumes: scheduler `exitReminders` del Task 2.

- [ ] **Step 1: Scrivere test fallenti**

Aggiungere a `test/features/timer_state_test.dart`:

```dart
group('exitReminderAt', () {
  test('working = uscita prevista meno anticipo', () {
    final state = at(60).copyWith(exitNotifMins: 15);
    expect(state.exitReminderAt, DateTime(2026, 7, 6, 16, 21));
  });

  test('disabilitato o in pausa non schedula', () {
    expect(at(60).copyWith(exitNotifMins: 0).exitReminderAt, isNull);
    final paused = TimerState(
      status: WorkState.paused,
      startTime: start,
      currentPauseStart: start.add(const Duration(hours: 1)),
      currentPauseType: PauseType.short,
      currentTime: start.add(const Duration(hours: 2)),
      standardWorkMins: std,
      exitNotifMins: 15,
    );
    expect(paused.exitReminderAt, isNull);
  });
});
```

- [ ] **Step 2: Verificare RED**

Run: `flutter test test/features/timer_state_test.dart`

Expected: FAIL perché `exitReminderAt` non esiste.

- [ ] **Step 3: Implementare calcolo e persistenza**

In `TimerState`:

```dart
DateTime? get exitReminderAt {
  if (status != WorkState.working || exitNotifMins <= 0) return null;
  return expectedExitTime?.subtract(Duration(minutes: exitNotifMins));
}
```

In `ActiveTimerData` aggiungere:

```dart
final DateTime? reminderAt;
final int reminderLeadMins;
```

`ActiveTimerRepository.save` scrive `reminderAt` come `Timestamp` solo se non
null e scrive sempre `reminderLeadMins`. Poiché `doc.set(data)` sostituisce il
documento, pausa/disabilitazione rimuovono un reminder vecchio.

`WorkTimer._syncRemote()` passa:

```dart
reminderAt: s.exitReminderAt,
reminderLeadMins: s.exitNotifMins,
```

Nel listener profilo, dopo un cambio `exitNotifMins` durante un turno attivo,
chiamare `_syncRemote()` per rischedulare.

- [ ] **Step 4: Eliminare il reminder client duplicato**

Rimuovere:

- `TimerState.exitReminderPending` e relativo parametro `copyWith`;
- il ramo ticker che chiama `_sendExitNotifToFirestore()`;
- `_sendExitNotifToFirestore()` e `ActiveTimerRepository.sendExitReminder()`;
- il `ref.listen<TimerState>` iniziale in `DashboardScreen`.

Il ticker resta responsabile solo di `currentTime` e auto-abbandono. Le push in
foreground sono mostrate globalmente da `ChigioTimeApp`.

- [ ] **Step 5: Verificare GREEN e commit**

Run:

```bash
dart format lib/features/dashboard/data/active_timer_repository.dart lib/features/dashboard/presentation/timer_provider.dart lib/features/dashboard/presentation/dashboard_screen.dart test/features/timer_state_test.dart
flutter test test/features/timer_state_test.dart
```

Expected: tutti i test timer PASS.

```bash
git add lib/features/dashboard test/features/timer_state_test.dart
git commit -m "feat(timer): schedule exit reminders server-side"
git push origin main
```

---

### Task 4: Client FCM multi-device, platform gate e routing

**Files:**
- Create: `lib/core/services/notification_routing.dart`
- Create: `test/core/services/notification_routing_test.dart`
- Modify: `lib/core/services/fcm_service.dart`
- Modify: `lib/app/app.dart`
- Modify: `lib/features/profile/presentation/profile_screen.dart`

**Interfaces:**
- Produces: `notificationRoute(Map<String, dynamic>) -> String`.
- Produces: `supportsFcm(TargetPlatform, {required bool isWeb}) -> bool`.
- Produces: `FcmService.unregister(String uid) -> Future<void>`.

- [ ] **Step 1: Scrivere test route/piattaforme fallenti**

Creare `test/core/services/notification_routing_test.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/core/services/notification_routing.dart';

void main() {
  test('route esplicita ammessa e fallback per type', () {
    expect(notificationRoute({'route': '/salary'}), '/salary');
    expect(notificationRoute({'type': 'exit_reminder'}), '/dashboard');
    expect(notificationRoute({'route': 'https://evil.test'}), '/notifications');
  });

  test('FCM supportato solo web Android iOS macOS', () {
    expect(supportsFcm(TargetPlatform.android, isWeb: false), isTrue);
    expect(supportsFcm(TargetPlatform.iOS, isWeb: false), isTrue);
    expect(supportsFcm(TargetPlatform.macOS, isWeb: false), isTrue);
    expect(supportsFcm(TargetPlatform.windows, isWeb: false), isFalse);
    expect(supportsFcm(TargetPlatform.linux, isWeb: false), isFalse);
    expect(supportsFcm(TargetPlatform.linux, isWeb: true), isTrue);
  });
}
```

- [ ] **Step 2: Verificare RED**

Run: `flutter test test/core/services/notification_routing_test.dart`

Expected: FAIL perché il file non esiste.

- [ ] **Step 3: Implementare allowlist pura**

Creare `notification_routing.dart` con allowlist `/dashboard`,
`/notifications`, `/social`, `/stats`, `/salary`; preferire `data['route']`
solo se ammessa, altrimenti mappare `type` come nel backend. `supportsFcm`
restituisce true per Web oppure Android/iOS/macOS.

- [ ] **Step 4: Migrare FcmService a installazioni**

In `FcmService`:

- chiave prefs `fcm_installation_id`;
- generazione una tantum con `const Uuid().v4()`;
- registrazione con merge:

```dart
await _db.doc('users/$uid/private/fcm').set({
  'installations': {
    installationId: {
      'token': token,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    },
  },
  'updatedAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));
```

- cancellazione lazy di `users/{uid}.fcmToken`;
- no-op per init/handler/stream su piattaforme non supportate;
- `notificationRoute(message.data)` per initial, background e foreground;
- logout con `update({'installations.$id': FieldValue.delete()})`,
  `FirebaseMessaging.deleteToken()` e stop listener refresh.

- [ ] **Step 5: Collegare lifecycle e logout**

In `app.dart`, usare la route del messaggio anche per l'azione SnackBar.
In `profile_screen.dart`, prima di `AuthRepository.signOut()`:

```dart
final uid = FirebaseAuth.instance.currentUser?.uid;
if (uid != null) await ref.read(fcmServiceProvider).unregister(uid);
await ref.read(authRepositoryProvider).signOut();
```

- [ ] **Step 6: Verificare e commit**

Run:

```bash
dart format lib/core/services/notification_routing.dart lib/core/services/fcm_service.dart lib/app/app.dart lib/features/profile/presentation/profile_screen.dart test/core/services/notification_routing_test.dart
flutter test test/core/services/notification_routing_test.dart
flutter analyze
```

Expected: test PASS e analyze pulito.

```bash
git add lib/core/services lib/app/app.dart lib/features/profile/presentation/profile_screen.dart test/core/services/notification_routing_test.dart
git commit -m "feat(push): register installations and route notifications"
git push origin main
```

---

### Task 5: Inbox generica, preferenze reali e notifica di prova

**Files:**
- Create: `test/domain/app_notification_test.dart`
- Modify: `lib/features/social/domain/app_notification.dart`
- Modify: `lib/features/social/presentation/notifications_screen.dart`
- Modify: `lib/features/profile/data/profile_repository.dart`
- Modify: `lib/features/profile/presentation/profile_screen.dart`
- Modify: `lib/core/constants/app_strings.dart`

**Interfaces:**
- Produces: `AppNotification.title`, `body`, `route`, `pushStatus`.
- Produces: `ProfileRepository.updateNotificationPreferences(fields)`.
- Produces: `ProfileRepository.sendTestNotification()`.

- [ ] **Step 1: Scrivere test modello fallenti**

Creare `test/domain/app_notification_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/features/social/domain/app_notification.dart';

void main() {
  test('automatica conserva copy route ed esito', () {
    final n = AppNotification.fromMap('n1', {
      'type': 'weekly_recap', 'title': 'Recap', 'body': 'Lavorato 38h00',
      'route': '/stats', 'pushStatus': 'sent',
      'sentAt': DateTime(2026, 7, 17), 'status': 'info', 'read': false,
    });
    expect(n.title, 'Recap');
    expect(n.body, 'Lavorato 38h00');
    expect(n.route, '/stats');
    expect(n.pushStatus, 'sent');
    expect(n.isPending, isFalse);
  });

  test('solo coffee_invite pending mostra azioni', () {
    final n = AppNotification.fromMap('n2', {
      'type': 'coffee_invite', 'sentAt': DateTime(2026, 7, 17),
      'status': 'pending', 'read': false,
    });
    expect(n.isPending, isTrue);
  });
}
```

- [ ] **Step 2: Verificare RED**

Run: `flutter test test/domain/app_notification_test.dart`

Expected: FAIL per campi mancanti e `isPending` troppo generico.

- [ ] **Step 3: Estendere modello e inbox**

`AppNotification` aggiunge `String? title`, `body`, `route`, `pushStatus` e:

```dart
bool get isPending => type == 'coffee_invite' && status == 'pending';
```

`NotificationsScreen` usa titolo/body per eventi automatici, mantiene azioni
solo per inviti caffè, usa icone per type e mostra su `test` il badge
`Inviata`, `Soppressa`, `Nessun dispositivo` o `Errore`. Il tap automatico usa
la route allowlisted.

- [ ] **Step 4: Rimuovere toggle morti e migrare campi**

Eliminare da `_NotificationSheet` proprietà/stato/widget/save `clockIn`,
`clockOut`, `weekly`.

`ProfileRepository.updateNotificationPreferences` aggiunge:

```dart
'notifyClockIn': FieldValue.delete(),
'notifyClockOut': FieldValue.delete(),
'notifyWeekly': FieldValue.delete(),
'updatedAt': FieldValue.serverTimestamp(),
```

- [ ] **Step 5: Aggiungere notifica di prova**

`ProfileRepository.sendTestNotification()` crea nella propria inbox:

```dart
{
  'type': 'test',
  'title': '🔔 Notifica di prova',
  'body': 'Le notifiche di Chigio Time sono configurate.',
  'route': '/notifications',
  'sentAt': FieldValue.serverTimestamp(),
  'status': 'info',
  'read': false,
}
```

La sheet espone `Invia notifica di prova`, disabilitato durante la scrittura,
e poi apre `/notifications` per mostrare `pushStatus` aggiornato.

- [ ] **Step 6: Verificare e commit**

Run:

```bash
dart format lib/features/social/domain/app_notification.dart lib/features/social/presentation/notifications_screen.dart lib/features/profile/data/profile_repository.dart lib/features/profile/presentation/profile_screen.dart lib/core/constants/app_strings.dart test/domain/app_notification_test.dart
flutter test test/domain/app_notification_test.dart
flutter test test/core/app_strings_test.dart
```

Expected: test PASS.

```bash
git add lib/features/social lib/features/profile lib/core/constants/app_strings.dart test/domain/app_notification_test.dart
git commit -m "feat(notifications): add test delivery and generic inbox"
git push origin main
```

---

### Task 6: Configurazione Android, Apple e Web

**Files:**
- Create: `test/platform/notification_config_test.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `android/app/src/main/kotlin/it/marcocipriani/chigio_time/MainActivity.kt`
- Create: `ios/Runner/DebugProfile.entitlements`
- Create: `ios/Runner/Release.entitlements`
- Modify: `ios/Runner/Info.plist`
- Modify: `ios/Runner.xcodeproj/project.pbxproj`
- Modify: `macos/Runner/DebugProfile.entitlements`
- Modify: `macos/Runner/Release.entitlements`
- Modify: `web/firebase-messaging-sw.js`

**Interfaces:**
- Consumes: channel `chigio_notifications` del backend.
- Produces: capability APS e apertura Web `/#/<route>`.

- [ ] **Step 1: Scrivere contract test fallente**

Creare `test/platform/notification_config_test.dart` leggendo i file con
`File(...).readAsStringSync()` e verificando:

```dart
expect(androidManifest, contains('com.google.firebase.messaging.default_notification_channel_id'));
expect(androidManifest, contains('chigio_notifications'));
expect(mainActivity, contains('NotificationChannel'));
expect(iosInfo, contains('remote-notification'));
expect(iosDebugEntitlements, contains('aps-environment'));
expect(macosDebugEntitlements, contains('com.apple.security.network.client'));
expect(macosDebugEntitlements, contains('com.apple.developer.aps-environment'));
expect(serviceWorker, contains("addEventListener('notificationclick'"));
expect(serviceWorker, isNot(contains('chigio-time-pcm.web.app')));
```

- [ ] **Step 2: Verificare RED**

Run: `flutter test test/platform/notification_config_test.dart`

Expected: FAIL su channel, entitlement e click handler.

- [ ] **Step 3: Configurare Android**

Nel manifest application:

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="chigio_notifications" />
```

`MainActivity.onCreate` crea da API 26 un `NotificationChannel` con id
`chigio_notifications`, nome `Notifiche Chigio Time`, importance high e
descrizione `Promemoria e aggiornamenti di Chigio Time`.

- [ ] **Step 4: Configurare iOS e macOS**

iOS `UIBackgroundModes` contiene `location`, `fetch`, `remote-notification`.
Creare entitlements Debug/Profile con:

```xml
<key>aps-environment</key>
<string>development</string>
```

e Release con valore `production`; impostare `CODE_SIGN_ENTITLEMENTS` sulle tre
build configuration Runner.

macOS aggiunge nei due file:

```xml
<key>com.apple.developer.aps-environment</key>
<string>development</string>
<key>com.apple.security.network.client</key>
<true/>
```

usando `production` nel Release.

- [ ] **Step 5: Configurare click Web**

Prima degli import Firebase, registrare `notificationclick`: chiudere la
notifica, accettare solo route che iniziano con `/`, costruire
`${self.location.origin}/#${route}`, focalizzare/navigare una window esistente
oppure `clients.openWindow(url)`.

- [ ] **Step 6: Verificare e commit**

Run:

```bash
flutter test test/platform/notification_config_test.dart
plutil -lint ios/Runner/Info.plist ios/Runner/DebugProfile.entitlements ios/Runner/Release.entitlements
plutil -lint macos/Runner/DebugProfile.entitlements macos/Runner/Release.entitlements
```

Expected: test PASS e plist `OK`.

```bash
git add android ios macos web/firebase-messaging-sw.js test/platform/notification_config_test.dart
git commit -m "feat(push): configure Android Apple and Web delivery"
git push origin main
```

---

### Task 7: Security contract, ADR e wiki

**Files:**
- Modify: `test/security/firestore_rules_test.dart`
- Modify: `firestore.rules`
- Create: `docs/decisioni/0012-notifiche-firebase-inbox-first.md`
- Modify: `docs/decisioni/README.md`
- Modify: `docs/architettura/persistence.md`
- Modify: `docs/entita/timer-state.md`
- Modify: `docs/entita/user-profile.md`
- Modify: `docs/funzionalita/dashboard.md`
- Modify: `docs/funzionalita/profile.md`
- Modify: `docs/funzionalita/social.md`
- Modify: `docs/processi/testing.md`
- Modify: `docs/CHANGELOG.md`

**Interfaces:**
- Documents: schema, flussi, DND, multi-device, piattaforme e limiti operativi.

- [ ] **Step 1: Correggere il test di compatibilità ban legacy**

Sostituire i test `abuseBans` con un contratto che richieda il gate legacy ma
vieti un match client:

```dart
final notificationBackend = [
  'functions/index.js',
  'functions/notification_logic.js',
  'functions/notification_runtime.js',
].map((path) => File(path).readAsStringSync()).join('\n');

test('anti-spam: i ban legacy attivi restano onorati', () {
  expect(rules.contains('function hasActiveLegacyAbuseBan()'), isTrue);
  expect(rules.contains('abuseBans/\$(request.auth.uid)'), isTrue);
  expect(rules.contains(".data.get('until', null) is timestamp"), isTrue);
  expect(rules.contains(".data.get('until', null) > request.time"), isTrue);
  expect(rules.contains('.data.until'), isFalse);
  expect(rules.contains('&& !hasActiveLegacyAbuseBan()'), isTrue);
});

test('anti-spam: nessun writer backend o match client crea nuovi ban', () {
  expect(notificationBackend.contains('abuseBans'), isFalse);
  expect(rules.contains('match /abuseBans/{uid}'), isFalse);
});
```

- [ ] **Step 2: Verificare RED**

Run: `flutter test test/security/firestore_rules_test.dart`

Expected: FAIL perché manca il gate legacy nominato esplicitamente.

- [ ] **Step 3: Rendere esplicita la compatibilità read-only**

Mantenere nel create notifiche un helper `hasActiveLegacyAbuseBan` che legge
`abuseBans/{uid}` e usa `data.get('until', null)` prima dei controlli type/time,
senza `match` client e senza writer nel backend corrente. Un documento legacy
privo di `until` non deve bloccare il mittente. Il cap di 10 notifiche/24h resta
nella Function; whitelist, stessa amministrazione e limiti testuali restano
invariati. Documentare che i ban esistenti validi sono onorati fino alla
scadenza e che la rimozione richiede prima inventario IAM e cleanup.

- [ ] **Step 4: Scrivere ADR-0012**

Documentare:

1. Firebase inbox-first, scelta;
2. foreground in-app + FCM gestito dal sistema operativo/browser in background;
3. Cloud Scheduler con `onSchedule` per il reminder, senza Cloud Tasks per turno.

Conseguenze: scheduler al minuto, token per installazione, DND server-side,
Windows/Linux senza push, prerequisito APNs, fallback token legacy. Aggiornare
indice ADR e data ultima revisione.

- [ ] **Step 5: Aggiornare wiki e changelog**

Allineare:

- `private/fcm.installations` e fallback legacy;
- `activeTimer/state.reminderAt` + `reminderLeadMins`;
- type automatici e `pushStatus/pushedAt/pushError`;
- recap lunedi' -> momento invio;
- preferenze rimaste e campi legacy rimossi;
- test Node e platform contract;
- riga 2026-07-18 in cima al changelog, marcando deploy/live pending fino a
  Task 8.

- [ ] **Step 6: Verificare e commit**

Run:

```bash
flutter test test/security/firestore_rules_test.dart
git diff --check
```

Expected: test PASS, nessun whitespace error.

```bash
git add firestore.rules test/security/firestore_rules_test.dart docs
git commit -m "docs: document inbox-first notification architecture"
```

---

### Task 8: Regressione, build, deploy e prova live

**Files:**
- Verify only, salvo correzioni causate dai comandi.

**Interfaces:**
- Produces: build Web pubblicata, Functions/Rules distribuite, evidenza live.

- [ ] **Step 1: Verifica completa**

Run:

```bash
npm --prefix functions test
node --check functions/index.js
flutter analyze
flutter test
git diff --check
```

Expected: zero failure.

- [ ] **Step 2: Build piattaforme**

Run:

```bash
flutter build web --release
flutter build apk --debug
flutter build ios --no-codesign
flutter build macos --debug
```

Expected: quattro build completate. Se Apple fallisce per signing/provisioning,
separare il blocco credenziali dagli errori di compilazione e non dichiarare
verificata la piattaforma.

- [ ] **Step 3: Controllare scope Git**

Run: `git status --short --branch`

Expected: i tre file utente non tracciati restano non aggiunti.

- [ ] **Step 4: Push e deploy**

Run:

```bash
git push origin main
firebase deploy --only functions,firestore:rules,firestore:indexes,hosting:main
```

Expected: deploy riuscito per `onNotificationCreated`,
`hourlyNotifications`, `exitReminders`, `onTimesheetWritten`, Rules e Hosting.

- [ ] **Step 5: Smoke live**

Run:

```bash
firebase functions:list
firebase functions:log --only onNotificationCreated -n 30
curl -fsS https://chigiotime.web.app/firebase-messaging-sw.js | shasum -a 256
shasum -a 256 build/web/firebase-messaging-sw.js
```

Expected: Functions `ACTIVE`; hash remoto uguale al build locale; nessun errore
runtime recente.

- [ ] **Step 6: Prova end-to-end autenticata**

1. Profilo -> Notifiche -> `Invia notifica di prova`.
2. Verificare inbox e `pushStatus: sent`.
3. Verificare banner/OS notification e tap verso `/notifications`.
4. Attivare DND; evento non-test -> `suppressed`, inbox presente.
5. Secondo device/browser: stesso evento ricevuto.
6. Logout: rimossa la sola installazione corrente.

Per iOS/macOS verificare in Firebase Console la chiave APNs e ripetere su build
firmata reale. Senza sessione/device autorizzato, riportare questo come blocco
residuo: log e validate-only non provano la consegna OS.

- [ ] **Step 7: Stato finale**

Run:

```bash
git status --short --branch
git log -8 --oneline
```

Expected: `main` allineato a `origin/main`; restano solo i file utente non
tracciati presenti prima del lavoro.

---

## Self-review

- Copertura spec: multi-device Task 4; inbox/DND/routing Task 2; reminder Task
  2-3; periodiche/straordinario Task 2; preferenze/test/inbox Task 5;
  configurazioni Task 6; logging/stale token Task 2; docs/deploy Task 7-8.
- Nessuna nuova dipendenza: UUID e prefs sono gia' nel `pubspec.yaml`; test Node
  usa il runtime integrato.
- Compatibilita': token legacy mantenuto; campi preferenze morti rimossi al
  primo salvataggio; schema timesheet invariato.
- Rischi: APNs richiede console + firma; la prova consegna richiede almeno una
  sessione autorizzata reale.
