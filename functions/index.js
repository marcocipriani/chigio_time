'use strict';

// Il runtime Cloud Functions gira in UTC. La timezone del cron non modifica
// Date#getHours/getDay/getDate all'interno del processo.
process.env.TZ = 'Europe/Rome';

const {
  onDocumentCreated,
  onDocumentWritten,
} = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { setGlobalOptions } = require('firebase-functions/v2');
const { initializeApp } = require('firebase-admin/app');
const {
  getFirestore,
  FieldValue,
  Timestamp,
} = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const {
  collectInstallations,
  contentForNotification,
  formatMinutes,
  isQuietTime,
  localDateId,
  routeForNotification,
  summarizeDelivery,
  weekDateRange,
} = require('./notification_logic');

setGlobalOptions({ maxInstances: 10 });
initializeApp();

const SPAM_MAX_PER_DAY = 10;

// Ogni evento entra prima nell'inbox. Questo unico consumer applica DND,
// risolve copy/route e consegna la push a tutte le installazioni dell'utente.
exports.onNotificationCreated = onDocumentCreated(
  'users/{recipientUid}/notifications/{notifId}',
  async (event) => {
    const db = getFirestore();
    const recipientUid = event.params.recipientUid;
    const notificationId = event.params.notifId;
    const notificationRef = event.data.ref;
    const data = event.data.data() ?? {};

    const sender = data.fromUid;
    if (sender && sender !== recipientUid) {
      const spam = await _checkSpam(db, sender, recipientUid);
      if (spam) {
        await notificationRef.delete().catch(() => {});
        _logDelivery({
          recipientUid,
          notificationId,
          type: data.type,
          pushStatus: 'spam-rejected',
        });
        return null;
      }
    }

    const profileRef = db.doc(`users/${recipientUid}`);
    const fcmRef = db.doc(`users/${recipientUid}/private/fcm`);
    const [profileSnap, fcmSnap] = await Promise.all([
      profileRef.get(),
      fcmRef.get(),
    ]);
    const profile = profileSnap.data() ?? {};

    if (data.type !== 'test' && isQuietTime(profile)) {
      await notificationRef.set({
        pushStatus: 'suppressed',
        pushedAt: Timestamp.now(),
      }, { merge: true });
      _logDelivery({
        recipientUid,
        notificationId,
        type: data.type,
        pushStatus: 'suppressed',
      });
      return null;
    }

    const installations = collectInstallations(
      fcmSnap.data() ?? {},
      profile.fcmToken,
    );
    if (installations.length === 0) {
      await notificationRef.set({
        pushStatus: 'no-token',
        pushedAt: Timestamp.now(),
      }, { merge: true });
      _logDelivery({
        recipientUid,
        notificationId,
        type: data.type,
        pushStatus: 'no-token',
      });
      return null;
    }

    const route = routeForNotification(data);
    const { title, body } = contentForNotification(data);
    let response;
    try {
      response = await getMessaging().sendEachForMulticast({
        tokens: installations.map((installation) => installation.token),
        notification: { title, body },
        data: { type: data.type ?? '', route, fromUid: data.fromUid ?? '' },
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
          fcmOptions: { link: `https://chigiotime.web.app/#${route}` },
        },
      });
    } catch (error) {
      const errorCodes = [error.code ?? 'messaging/unknown'];
      await notificationRef.set({
        pushStatus: 'failed',
        pushedAt: Timestamp.now(),
        pushError: errorCodes.join(','),
      }, { merge: true });
      _logDelivery({
        recipientUid,
        notificationId,
        type: data.type,
        pushStatus: 'failed',
        errorCodes,
      }, true);
      throw error;
    }

    const { successCount, staleIds, errorCodes } = summarizeDelivery(
      installations,
      response.responses,
    );
    const updates = {};
    for (const id of staleIds) {
      if (id === 'legacy-private') updates.token = FieldValue.delete();
      else if (id !== 'legacy-user') {
        updates[`installations.${id}`] = FieldValue.delete();
      }
    }
    if (Object.keys(updates).length > 0) await fcmRef.update(updates);
    if (staleIds.includes('legacy-user')) {
      await db.doc(`users/${recipientUid}`).set(
        { fcmToken: FieldValue.delete() },
        { merge: true },
      );
    }

    const pushStatus = successCount > 0 ? 'sent' : 'failed';
    if (pushStatus === 'sent') {
      await notificationRef.set({
        pushStatus: 'sent',
        pushedAt: Timestamp.now(),
        pushError: FieldValue.delete(),
      }, { merge: true });
    } else {
      await notificationRef.set({
        pushStatus: 'failed',
        pushedAt: Timestamp.now(),
        pushError: errorCodes.join(','),
      }, { merge: true });
    }
    _logDelivery({
      recipientUid,
      notificationId,
      type: data.type,
      pushStatus,
      successCount,
      failureCount: response.responses.length - successCount,
      staleCount: staleIds.length,
      errorCodes,
    });
    return null;
  },
);

// Il job scatta al minuto zero e produce solo documenti inbox deterministici.
exports.hourlyNotifications = onSchedule(
  { schedule: '0 * * * *', timeZone: 'Europe/Rome' },
  async () => {
    const now = new Date();
    const hour = now.getHours();
    const weekday = now.getDay();
    const dayOfMonth = now.getDate();
    const todayId = localDateId(now);
    const db = getFirestore();

    const usersSnap = await db.collection('users').select(
      'notifyMorningColleagues',
      'morningColleaguesHour',
      'notifyWeeklyRecap',
      'weeklyRecapDay',
      'weeklyRecapHour',
      'notifyPayday',
      'paydayDay',
      'mealVoucherThresholdMins',
    ).get();

    const tasks = [];
    for (const userDoc of usersSnap.docs) {
      const profile = userDoc.data();
      const uid = userDoc.id;

      if (
        profile.notifyMorningColleagues &&
        hour === (profile.morningColleaguesHour ?? 9)
      ) {
        tasks.push(_createMorningNotification(db, uid, now));
      }

      if (profile.notifyWeeklyRecap) {
        const recapDay = profile.weeklyRecapDay ?? 5;
        const recapHour = profile.weeklyRecapHour ?? 18;
        const jsDay = recapDay === 7 ? 0 : recapDay;
        if (weekday === jsDay && hour === recapHour) {
          tasks.push(_createWeeklyRecap(
            db,
            uid,
            now,
            profile.mealVoucherThresholdMins ?? 380,
          ));
        }
      }

      if (
        profile.notifyPayday &&
        dayOfMonth === (profile.paydayDay ?? 23) &&
        hour === 8
      ) {
        tasks.push(_createNotification(db, uid, `payday-${todayId.slice(0, 7)}`, {
          type: 'payday',
          route: '/salary',
          title: '💶 Stipendio in arrivo',
          body: 'Oggi è il giorno dell\'accredito. Calma e decoro.',
        }));
      }
    }

    await Promise.all(tasks);
  },
);

async function _createMorningNotification(db, uid, now) {
  const colleaguesSnap = await db.collection(`users/${uid}/colleagues`).get();
  const colleagueUids = colleaguesSnap.docs.map((doc) => doc.id);
  if (colleagueUids.length === 0) return false;

  const profiles = await db.getAll(
    ...colleagueUids.map((colleagueUid) => db.doc(`users/${colleagueUid}`)),
    { fieldMask: ['currentStatus', 'statusDate'] },
  );
  const todayId = localDateId(now);
  let inOffice = 0;
  let remote = 0;
  for (const profileSnap of profiles) {
    const profile = profileSnap.data();
    if (!profile || profile.statusDate !== todayId) continue;
    if (profile.currentStatus === 'working') inOffice++;
    else if (profile.currentStatus === 'remote') remote++;
  }
  if (inOffice + remote === 0) return false;

  let body = `${inOffice} in ufficio`;
  if (remote > 0) body += `, ${remote} in smart working`;
  return _createNotification(db, uid, `morning-${todayId}`, {
    type: 'morning_colleagues',
    route: '/social',
    title: '👥 Colleghi oggi',
    body,
  });
}

async function _createWeeklyRecap(db, uid, now, mealVoucherThresholdMins) {
  const { startId, endId } = weekDateRange(now);
  const snap = await db.collection(`users/${uid}/timesheets`)
    .where('__name__', '>=', startId)
    .where('__name__', '<=', endId)
    .get();

  let workedMins = 0;
  let overtimeMins = 0;
  let mealVouchers = 0;
  for (const timesheetDoc of snap.docs) {
    const timesheet = timesheetDoc.data();
    const netWorkedMins = Number(timesheet.netWorkedMins) || 0;
    workedMins += netWorkedMins;
    overtimeMins += Math.max(0, Number(timesheet.extraMins) || 0);
    if (netWorkedMins >= mealVoucherThresholdMins) mealVouchers++;
  }

  return _createNotification(db, uid, `weekly-${startId}`, {
    type: 'weekly_recap',
    route: '/stats',
    title: '📊 Recap settimana',
    body: `Lavorato: ${formatMinutes(workedMins)} · ` +
      `OT: ${formatMinutes(overtimeMins)} · Buoni: ${mealVouchers}`,
  });
}

// Reclama i reminder scaduti in transazione: un secondo job concorrente vede
// il reminder già rimosso o la notifica deterministica già esistente.
exports.exitReminders = onSchedule(
  { schedule: '* * * * *', timeZone: 'Europe/Rome' },
  async () => {
    const db = getFirestore();
    const now = Timestamp.now();
    const due = await db.collectionGroup('activeTimer')
      .where('reminderAt', '<=', now)
      .limit(100)
      .get();

    await Promise.all(due.docs
      .filter((timerDoc) => timerDoc.id === 'state')
      .map((timerDoc) => _claimExitReminder(db, timerDoc.ref, now)));
  },
);

async function _claimExitReminder(db, timerRef, now) {
  const userRef = timerRef.parent.parent;
  if (!userRef) return false;

  return db.runTransaction(async (transaction) => {
    const timerSnap = await transaction.get(timerRef);
    if (!timerSnap.exists) return false;
    const timer = timerSnap.data() ?? {};
    if (
      typeof timer.reminderAt?.toMillis !== 'function' ||
      timer.reminderAt.toMillis() > now.toMillis() ||
      typeof timer.date !== 'string'
    ) {
      return false;
    }

    const notificationRef = db.doc(
      `users/${userRef.id}/notifications/exit-${timer.date}`,
    );
    const notificationSnap = await transaction.get(notificationRef);
    transaction.update(timerRef, {
      reminderAt: FieldValue.delete(),
      reminderClaimedAt: Timestamp.now(),
    });
    if (!notificationSnap.exists) {
      transaction.create(notificationRef, {
        type: 'exit_reminder',
        route: '/dashboard',
        title: 'Uscita prevista',
        body: `Tra ${timer.reminderLeadMins ?? 15} min finisce il tuo turno.`,
        sentAt: Timestamp.now(),
        status: 'info',
        read: false,
      });
    }
    return !notificationSnap.exists;
  });
}

exports.onTimesheetWritten = onDocumentWritten(
  'users/{uid}/timesheets/{dateId}',
  async (event) => {
    if (!event.data?.after.exists) return null;

    const { uid, dateId } = event.params;
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dateId)) return null;
    const db = getFirestore();
    const profileSnap = await db.doc(`users/${uid}`).get();
    const thresholdHours = Number(profileSnap.data()?.monthlyOtAlertHours) || 0;
    if (thresholdHours <= 0) return null;

    const monthId = dateId.slice(0, 7);
    const timesheets = await db.collection(`users/${uid}/timesheets`)
      .where('__name__', '>=', `${monthId}-01`)
      .where('__name__', '<=', `${monthId}-31`)
      .get();
    const overtimeMins = timesheets.docs.reduce((total, timesheetDoc) => {
      return total + Math.max(0, Number(timesheetDoc.data().extraMins) || 0);
    }, 0);
    if (overtimeMins < thresholdHours * 60) return null;

    await _createNotification(db, uid, `overtime-${monthId}`, {
      type: 'overtime_threshold',
      route: '/stats',
      title: '🔔 Soglia straordinari raggiunta',
      body: `Hai raggiunto ${formatMinutes(overtimeMins)} di straordinario questo mese.`,
    });
    return null;
  },
);

async function _createNotification(db, uid, id, fields) {
  try {
    await db.doc(`users/${uid}/notifications/${id}`).create({
      ...fields,
      sentAt: Timestamp.now(),
      status: 'info',
      read: false,
    });
    return true;
  } catch (error) {
    if (error.code === 6 || error.code === 'already-exists') return false;
    throw error;
  }
}

async function _checkSpam(db, sender, recipientUid) {
  try {
    const snap = await db.collection(`users/${recipientUid}/notifications`)
      .where('fromUid', '==', sender)
      .get();
    const dayAgo = Date.now() - 24 * 3600 * 1000;
    const recent = snap.docs.filter((doc) => {
      const sentAt = doc.data().sentAt;
      return sentAt?.toMillis ? sentAt.toMillis() > dayAgo : true;
    }).length;
    return recent > SPAM_MAX_PER_DAY;
  } catch (error) {
    console.error(JSON.stringify({
      event: 'notification_spam_check',
      senderUid: sender,
      recipientUid,
      errorCode: error.code ?? 'unknown',
    }));
    return false;
  }
}

function _logDelivery(details, isError = false) {
  const line = JSON.stringify({ event: 'notification_delivery', ...details });
  if (isError) console.error(line);
  else console.log(line);
}
