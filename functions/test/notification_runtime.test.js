'use strict';

process.env.TZ = 'Europe/Rome';

const test = require('node:test');
const assert = require('node:assert/strict');
const { createNotificationRuntime } = require('../notification_runtime');
const {
  DELETE_FIELD,
  FakeFirestore,
  FakeLogger,
  FakeMessaging,
  FakeTimestamp,
} = require('./runtime_fakes');

const BASE_DATE = new Date('2026-07-17T08:00:00+02:00');

function success() {
  return { success: true };
}

function failure(code) {
  return { success: false, error: { code } };
}

function response(...responses) {
  return { responses };
}

function makeRuntime(db, messaging, date = BASE_DATE) {
  const logger = new FakeLogger();
  const runtime = createNotificationRuntime({
    db,
    messaging,
    logger,
    nowDate: () => new Date(date),
    nowTimestamp: () => new FakeTimestamp(date.getTime()),
    deleteField: () => DELETE_FIELD,
  });
  return { runtime, logger };
}

async function notificationEvent(db, uid, id) {
  return {
    id: `event-${uid}-${id}`,
    params: { recipientUid: uid, notifId: id },
    data: await db.doc(`users/${uid}/notifications/${id}`).get(),
  };
}

test('claim terminale evita doppio invio e costruisce il payload completo', async () => {
  const db = new FakeFirestore();
  db.seed('users/u1', {});
  db.seed('users/u1/private/fcm', {
    installations: { phone: { token: 'token-one' } },
  });
  db.seed('users/u1/notifications/n1', {
    type: 'weekly_recap',
    route: '/stats',
    title: 'Recap',
    body: 'Lavorato 38h00',
    read: false,
  });
  const messaging = new FakeMessaging([response(success())]);
  const { runtime } = makeRuntime(db, messaging);
  const event = await notificationEvent(db, 'u1', 'n1');

  await runtime.onNotificationCreated(event);
  await runtime.onNotificationCreated(event);

  assert.equal(messaging.calls.length, 1);
  assert.deepEqual(messaging.calls[0], {
    tokens: ['token-one'],
    notification: { title: 'Recap', body: 'Lavorato 38h00' },
    data: { type: 'weekly_recap', route: '/stats', fromUid: '' },
    android: {
      notification: {
        channelId: 'chigio_notifications',
        priority: 'high',
        sound: 'default',
      },
    },
    apns: { payload: { aps: { badge: 1, sound: 'default' } } },
    webpush: {
      notification: {
        icon: 'https://chigiotime.web.app/icons/web-app-manifest-192x192.png',
      },
      fcmOptions: { link: 'https://chigiotime.web.app/#/stats' },
    },
  });
  assert.deepEqual(
    {
      status: db.data('users/u1/notifications/n1').pushStatus,
      successes: db.data('users/u1/notifications/n1').pushSuccessCount,
      failures: db.data('users/u1/notifications/n1').pushFailureCount,
      retries: db.data('users/u1/notifications/n1').pushRetryCount,
    },
    { status: 'sent', successes: 1, failures: 0, retries: 0 },
  );
});

test('claim processing con lease attivo segnala busy per il retry trigger', async () => {
  const nowMs = BASE_DATE.getTime();
  const db = new FakeFirestore(nowMs);
  db.seed('users/u1', {});
  db.seed('users/u1/private/fcm', { token: 'token' });
  db.seed('users/u1/notifications/n1', {
    type: 'test',
    pushStatus: 'processing',
    pushClaimedAt: new FakeTimestamp(nowMs - 60_000),
    pushClaimAttempt: 1,
  });
  const messaging = new FakeMessaging();
  const { runtime } = makeRuntime(db, messaging);

  await assert.rejects(
    runtime.onNotificationCreated(await notificationEvent(db, 'u1', 'n1')),
    { code: 'notification/claim-busy' },
  );
  assert.equal(messaging.calls.length, 0);
  assert.equal(db.data('users/u1/notifications/n1').pushClaimAttempt, 1);
});

test('claim processing scaduto viene reclamato e consegnato', async () => {
  const nowMs = BASE_DATE.getTime();
  const db = new FakeFirestore(nowMs);
  db.seed('users/u1', {});
  db.seed('users/u1/private/fcm', { token: 'token' });
  db.seed('users/u1/notifications/n1', {
    type: 'test',
    pushStatus: 'processing',
    pushClaimedAt: new FakeTimestamp(nowMs - 10 * 60_000),
    pushClaimAttempt: 1,
  });
  const messaging = new FakeMessaging([response(success())]);
  const { runtime } = makeRuntime(db, messaging);

  await runtime.onNotificationCreated(await notificationEvent(db, 'u1', 'n1'));

  assert.equal(messaging.calls.length, 1);
  assert.equal(db.data('users/u1/notifications/n1').pushStatus, 'sent');
  assert.equal(db.data('users/u1/notifications/n1').pushClaimAttempt, 2);
});

test('trigger Firestore abilita retry Eventarc', () => {
  const functions = require('../index');
  assert.equal(
    functions.onNotificationCreated.__endpoint.eventTrigger.retry,
    true,
  );
});

test('DND e assenza token chiudono il claim senza chiamare FCM', async () => {
  const date = new Date('2026-07-17T23:00:00+02:00');
  const db = new FakeFirestore(date.getTime());
  db.seed('users/dnd', { doNotDisturb: true, silenceFrom: 22, silenceTo: 8 });
  db.seed('users/dnd/private/fcm', { token: 'legacy' });
  db.seed('users/dnd/notifications/n1', { type: 'weekly_recap' });
  db.seed('users/empty', {});
  db.seed('users/empty/notifications/n2', { type: 'payday' });
  const messaging = new FakeMessaging();
  const { runtime } = makeRuntime(db, messaging, date);

  await runtime.onNotificationCreated(await notificationEvent(db, 'dnd', 'n1'));
  await runtime.onNotificationCreated(await notificationEvent(db, 'empty', 'n2'));

  assert.equal(db.data('users/dnd/notifications/n1').pushStatus, 'suppressed');
  assert.equal(db.data('users/empty/notifications/n2').pushStatus, 'no-token');
  assert.equal(messaging.calls.length, 0);
});

test('multicast parziale ritenta una volta e conserva esito ed errori', async () => {
  const db = new FakeFirestore();
  db.seed('users/u1', {});
  db.seed('users/u1/private/fcm', {
    installations: {
      phone: { token: 'one' },
      web: { token: 'two' },
    },
  });
  db.seed('users/u1/notifications/n1', { type: 'test' });
  const messaging = new FakeMessaging([
    response(success(), failure('messaging/internal-error')),
    response(failure('messaging/internal-error')),
  ]);
  const { runtime, logger } = makeRuntime(db, messaging);

  await runtime.onNotificationCreated(await notificationEvent(db, 'u1', 'n1'));

  assert.equal(messaging.calls.length, 2);
  assert.deepEqual(messaging.calls[1].tokens, ['two']);
  const notification = db.data('users/u1/notifications/n1');
  assert.equal(notification.pushStatus, 'failed');
  assert.equal(notification.pushSuccessCount, 1);
  assert.equal(notification.pushFailureCount, 1);
  assert.equal(notification.pushRetryCount, 1);
  assert.equal(notification.pushError, 'messaging/internal-error');
  assert.equal(logger.errorLines.length, 1);
});

test('cleanup stale elimina tutti gli alias ma preserva token aggiornati', async () => {
  const db = new FakeFirestore();
  db.seed('users/u1', { fcmToken: 'old-token' });
  db.seed('users/u1/private/fcm', {
    token: 'old-token',
    installations: {
      changed: { token: 'old-token' },
      stale: { token: 'old-token' },
    },
  });
  db.seed('users/u1/notifications/n1', { type: 'test' });
  const messaging = new FakeMessaging([
    async () => {
      await db.doc('users/u1/private/fcm').update({
        'installations.changed.token': 'new-token',
        'installations.added.token': 'old-token',
      });
      return response(failure('messaging/registration-token-not-registered'));
    },
  ]);
  const { runtime } = makeRuntime(db, messaging);

  await runtime.onNotificationCreated(await notificationEvent(db, 'u1', 'n1'));

  const fcm = db.data('users/u1/private/fcm');
  assert.equal(fcm.installations.changed.token, 'new-token');
  assert.equal('stale' in fcm.installations, false);
  assert.equal('added' in fcm.installations, false);
  assert.equal('token' in fcm, false);
  assert.equal('fcmToken' in db.data('users/u1'), false);
});

test('errore cleanup conserva il risultato FCM e un errore operativo separato', async () => {
  const db = new FakeFirestore();
  db.seed('users/u1', {});
  db.seed('users/u1/private/fcm', {
    installations: {
      ok: { token: 'one' },
      stale: { token: 'two' },
    },
  });
  db.seed('users/u1/notifications/n1', { type: 'test' });
  const originalRunTransaction = db.runTransaction.bind(db);
  let transactionCall = 0;
  db.runTransaction = async (callback) => {
    transactionCall++;
    if (transactionCall === 2) {
      throw Object.assign(new Error('cleanup-failed'), {
        code: 'firestore/cleanup-failed',
      });
    }
    return originalRunTransaction(callback);
  };
  const messaging = new FakeMessaging([response(
    success(),
    failure('messaging/registration-token-not-registered'),
  )]);
  const { runtime } = makeRuntime(db, messaging);

  await runtime.onNotificationCreated(await notificationEvent(db, 'u1', 'n1'));

  const notification = db.data('users/u1/notifications/n1');
  assert.equal(notification.pushStatus, 'failed');
  assert.equal(notification.pushSuccessCount, 1);
  assert.equal(notification.pushFailureCount, 1);
  assert.equal(
    notification.pushError,
    'messaging/registration-token-not-registered',
  );
  assert.equal(
    notification.pushOperationalError,
    'cleanup:firestore/cleanup-failed',
  );
});

test('primo finalize fallito ritenta persistendo i conteggi reali', async () => {
  const db = new FakeFirestore();
  db.seed('users/u1', {});
  db.seed('users/u1/private/fcm', {
    installations: {
      ok: { token: 'one' },
      retry: { token: 'two' },
    },
  });
  db.seed('users/u1/notifications/n1', { type: 'test' });
  const originalSet = db._set.bind(db);
  let failuresLeft = 1;
  db._set = (path, data, options) => {
    if (path.endsWith('/notifications/n1') && failuresLeft-- > 0) {
      throw Object.assign(new Error('write-failed'), {
        code: 'firestore/write-failed',
      });
    }
    return originalSet(path, data, options);
  };
  const messaging = new FakeMessaging([
    response(success(), failure('messaging/internal-error')),
    response(failure('messaging/internal-error')),
  ]);
  const { runtime } = makeRuntime(db, messaging);

  await runtime.onNotificationCreated(await notificationEvent(db, 'u1', 'n1'));

  const notification = db.data('users/u1/notifications/n1');
  assert.equal(notification.pushStatus, 'failed');
  assert.equal(notification.pushSuccessCount, 1);
  assert.equal(notification.pushFailureCount, 1);
  assert.equal(notification.pushRetryCount, 1);
  assert.equal(notification.pushError, 'messaging/internal-error');
  assert.equal(
    notification.pushOperationalError,
    'persistence:firestore/write-failed',
  );
});

test('doppio finalize fallito propaga errore al retry trigger', async () => {
  const db = new FakeFirestore();
  db.seed('users/u1', {});
  db.seed('users/u1/private/fcm', { token: 'one' });
  db.seed('users/u1/notifications/n1', { type: 'test' });
  const originalSet = db._set.bind(db);
  let failuresLeft = 2;
  db._set = (path, data, options) => {
    if (path.endsWith('/notifications/n1') && failuresLeft-- > 0) {
      throw Object.assign(new Error('write-failed'), {
        code: 'firestore/write-failed',
      });
    }
    return originalSet(path, data, options);
  };
  const messaging = new FakeMessaging([response(success())]);
  const { runtime } = makeRuntime(db, messaging);

  await assert.rejects(
    runtime.onNotificationCreated(await notificationEvent(db, 'u1', 'n1')),
    { code: 'firestore/write-failed' },
  );
  assert.equal(messaging.calls.length, 1);
  assert.equal(db.data('users/u1/notifications/n1').pushStatus, 'processing');
});

test('anti-spam usa createTime server e ignora sentAt manipolato', async () => {
  const nowMs = BASE_DATE.getTime();
  const db = new FakeFirestore(nowMs);
  db.seed('users/victim', {});
  db.seed('users/victim/private/fcm', { token: 'token' });
  for (let index = 0; index < 10; index++) {
    db.seed(`users/victim/notifications/old-${index}`, {
      type: 'coffee_invite',
      fromUid: 'spammer',
      sentAt: new FakeTimestamp(nowMs - 30 * 24 * 3600 * 1000),
    }, { createTimeMs: nowMs - 60_000 });
  }
  db.seed('users/victim/notifications/current', {
    type: 'coffee_invite',
    fromUid: 'spammer',
    sentAt: new FakeTimestamp(nowMs - 30 * 24 * 3600 * 1000),
  }, { createTimeMs: nowMs });
  const messaging = new FakeMessaging();
  const { runtime } = makeRuntime(db, messaging);

  await runtime.onNotificationCreated(
    await notificationEvent(db, 'victim', 'current'),
  );

  assert.equal(db.data('users/victim/notifications/current'), undefined);
  assert.equal(messaging.calls.length, 0);
});

test('scheduler crea inbox deterministiche e isola un utente fallito', async () => {
  const db = new FakeFirestore();
  db.seed('users/good', {
    notifyMorningColleagues: true,
    morningColleaguesHour: 8,
    notifyWeeklyRecap: true,
    weeklyRecapDay: 5,
    weeklyRecapHour: 8,
    notifyPayday: true,
    paydayDay: 17,
    mealVoucherThresholdMins: 380,
  });
  db.seed('users/good/colleagues/c1', {});
  db.seed('users/c1', { currentStatus: 'working', statusDate: '2026-07-17' });
  db.seed('users/good/timesheets/2026-07-13', {
    netWorkedMins: 400,
    extraMins: 20,
  });
  db.seed('users/good/timesheets/2026-07-17', {
    netWorkedMins: 380,
    extraMins: -10,
  });
  db.seed('users/bad', {
    notifyMorningColleagues: true,
    morningColleaguesHour: 8,
  });
  db.seed('users/bad/colleagues/fail', {});
  db.seed('users/fail', { currentStatus: 'working', statusDate: '2026-07-17' });
  const originalGetAll = db.getAll.bind(db);
  db.getAll = async (...refs) => {
    if (refs.some((ref) => ref.path === 'users/fail')) throw new Error('read-fail');
    return originalGetAll(...refs);
  };
  const { runtime, logger } = makeRuntime(db, new FakeMessaging());

  await runtime.hourlyNotifications();

  assert.equal(
    db.data('users/good/notifications/morning-2026-07-17').type,
    'morning_colleagues',
  );
  assert.equal(
    db.data('users/good/notifications/weekly-2026-07-13').body,
    'Lavorato: 13h00 · OT: 0h20 · Buoni: 2',
  );
  assert.equal(
    db.data('users/good/notifications/payday-2026-07').route,
    '/salary',
  );
  assert.equal(logger.errorLines.length, 1);
});

test('reminder viene reclamato in transazione una sola volta', async () => {
  const db = new FakeFirestore();
  db.seed('users/u1/activeTimer/state', {
    date: '2026-07-17',
    reminderAt: new FakeTimestamp(BASE_DATE.getTime() - 60_000),
    reminderLeadMins: 20,
  });
  const { runtime } = makeRuntime(db, new FakeMessaging());

  await runtime.exitReminders();
  await runtime.exitReminders();

  const timer = db.data('users/u1/activeTimer/state');
  assert.equal('reminderAt' in timer, false);
  assert.ok(timer.reminderClaimedAt instanceof FakeTimestamp);
  assert.equal(
    db.data('users/u1/notifications/exit-2026-07-17').body,
    'Tra 20 min finisce il tuo turno.',
  );
});

test('write timesheet crea una sola notifica soglia mensile', async () => {
  const db = new FakeFirestore();
  db.seed('users/u1', { monthlyOtAlertHours: 1 });
  db.seed('users/u1/timesheets/2026-07-10', { extraMins: 30 });
  db.seed('users/u1/timesheets/2026-07-17', { extraMins: 40 });
  const { runtime } = makeRuntime(db, new FakeMessaging());
  const event = {
    params: { uid: 'u1', dateId: '2026-07-17' },
    data: { after: { exists: true } },
  };

  await runtime.onTimesheetWritten(event);
  await runtime.onTimesheetWritten(event);

  const notification = db.data('users/u1/notifications/overtime-2026-07');
  assert.equal(notification.type, 'overtime_threshold');
  assert.equal(
    notification.body,
    'Hai raggiunto 1h10 di straordinario questo mese.',
  );
});

test('indice collection-group activeTimer.reminderAt è dichiarato', () => {
  const indexes = require('../../firestore.indexes.json');
  assert.equal(indexes.fieldOverrides.some((override) => {
    return override.collectionGroup === 'activeTimer' &&
      override.fieldPath === 'reminderAt' &&
      override.indexes.some((index) => {
        return index.queryScope === 'COLLECTION_GROUP' &&
          index.order === 'ASCENDING';
      });
  }), true);
});
