'use strict';

const {
  contentForNotification,
  formatMinutes,
  isQuietTime,
  localDateId,
  routeForNotification,
  weekDateRange,
} = require('./notification_logic');

const SPAM_MAX_PER_DAY = 10;
const TERMINAL_PUSH_STATUSES = new Set([
  'sent',
  'suppressed',
  'no-token',
  'failed',
]);
const STALE_ERROR_CODES = new Set([
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
]);
const TRANSIENT_ERROR_CODES = new Set([
  'messaging/internal-error',
  'messaging/server-unavailable',
  'messaging/unknown-error',
  'messaging/message-rate-exceeded',
  'messaging/quota-exceeded',
  'messaging/unavailable',
]);

function createNotificationRuntime({
  db,
  messaging,
  logger,
  nowDate,
  nowTimestamp,
  deleteField,
}) {
  async function onNotificationCreated(event) {
    const recipientUid = event.params.recipientUid;
    const notificationId = event.params.notifId;
    const notificationRef = db.doc(
      `users/${recipientUid}/notifications/${notificationId}`,
    );
    const profileRef = db.doc(`users/${recipientUid}`);
    const fcmRef = db.doc(`users/${recipientUid}/private/fcm`);
    const data = await _claimNotification(notificationRef);
    if (!data) return null;

    let targetCount = 0;
    try {
      const sender = data.fromUid;
      if (
        sender &&
        sender !== recipientUid &&
        await _checkSpam(sender, recipientUid)
      ) {
        await notificationRef.delete();
        _logDelivery('info', {
          recipientUid,
          notificationId,
          type: data.type,
          pushStatus: 'spam-rejected',
        });
        return null;
      }

      const [profileSnap, fcmSnap] = await Promise.all([
        profileRef.get(),
        fcmRef.get(),
      ]);
      const profile = profileSnap.data() ?? {};

      if (data.type !== 'test' && isQuietTime(profile, nowDate())) {
        await _finalize(notificationRef, {
          pushStatus: 'suppressed',
          successCount: 0,
          failureCount: 0,
          retryCount: 0,
        });
        _logDelivery('info', {
          recipientUid,
          notificationId,
          type: data.type,
          pushStatus: 'suppressed',
        });
        return null;
      }

      const targets = _collectTokenTargets(fcmSnap.data() ?? {}, profile.fcmToken);
      targetCount = targets.length;
      if (targets.length === 0) {
        await _finalize(notificationRef, {
          pushStatus: 'no-token',
          successCount: 0,
          failureCount: 0,
          retryCount: 0,
        });
        _logDelivery('info', {
          recipientUid,
          notificationId,
          type: data.type,
          pushStatus: 'no-token',
        });
        return null;
      }

      const payload = _notificationPayload(data, targets);
      const delivery = await _deliverWithOneRetry(targets, payload);
      await _cleanupStaleTokens(profileRef, fcmRef, delivery.staleTargets);
      const pushStatus = delivery.failureCount === 0 ? 'sent' : 'failed';
      await _finalize(notificationRef, {
        pushStatus,
        successCount: delivery.successCount,
        failureCount: delivery.failureCount,
        retryCount: delivery.retryCount,
        errorCodes: delivery.errorCodes,
      });
      _logDelivery(pushStatus === 'failed' ? 'error' : 'info', {
        recipientUid,
        notificationId,
        type: data.type,
        pushStatus,
        successCount: delivery.successCount,
        failureCount: delivery.failureCount,
        retryCount: delivery.retryCount,
        staleCount: delivery.staleTargets.length,
        errorCodes: delivery.errorCodes,
      });
    } catch (error) {
      const errorCodes = [_errorCode(error)];
      await _finalize(notificationRef, {
        pushStatus: 'failed',
        successCount: 0,
        failureCount: targetCount,
        retryCount: 0,
        errorCodes,
      }).catch(() => {});
      _logDelivery('error', {
        recipientUid,
        notificationId,
        type: data.type,
        pushStatus: 'failed',
        successCount: 0,
        failureCount: targetCount,
        errorCodes,
      });
    }
    return null;
  }

  async function _claimNotification(notificationRef) {
    return db.runTransaction(async (transaction) => {
      const snap = await transaction.get(notificationRef);
      if (!snap.exists) return null;
      const data = snap.data() ?? {};
      if (
        TERMINAL_PUSH_STATUSES.has(data.pushStatus) ||
        data.pushStatus === 'processing'
      ) {
        return null;
      }
      transaction.update(notificationRef, {
        pushStatus: 'processing',
        pushClaimedAt: nowTimestamp(),
        pushError: deleteField(),
      });
      return data;
    });
  }

  async function _finalize(notificationRef, {
    pushStatus,
    successCount,
    failureCount,
    retryCount,
    errorCodes = [],
  }) {
    const fields = {
      pushStatus,
      pushedAt: nowTimestamp(),
      pushSuccessCount: successCount,
      pushFailureCount: failureCount,
      pushRetryCount: retryCount,
      pushError: errorCodes.length > 0
        ? errorCodes.join(',')
        : deleteField(),
    };
    await notificationRef.set(fields, { merge: true });
  }

  async function _checkSpam(sender, recipientUid) {
    try {
      const snap = await db.collection(`users/${recipientUid}/notifications`)
        .where('fromUid', '==', sender)
        .get();
      const dayAgo = nowDate().getTime() - 24 * 3600 * 1000;
      const recent = snap.docs.filter((doc) => {
        const createdAt = doc.createTime?.toMillis?.();
        return Number.isFinite(createdAt) && createdAt > dayAgo;
      }).length;
      return recent > SPAM_MAX_PER_DAY;
    } catch (error) {
      logger.error(JSON.stringify({
        event: 'notification_spam_check',
        senderUid: sender,
        recipientUid,
        errorCode: _errorCode(error),
      }));
      return false;
    }
  }

  async function _deliverWithOneRetry(targets, payload) {
    const firstResponses = await _sendOrFailures(payload, targets.length);
    const finalResponses = [...firstResponses];
    const retryIndexes = [];
    firstResponses.forEach((response, index) => {
      if (!response.success && TRANSIENT_ERROR_CODES.has(_responseCode(response))) {
        retryIndexes.push(index);
      }
    });

    if (retryIndexes.length > 0) {
      const retryTargets = retryIndexes.map((index) => targets[index]);
      const retryPayload = {
        ...payload,
        tokens: retryTargets.map((target) => target.token),
      };
      const retryResponses = await _sendOrFailures(
        retryPayload,
        retryTargets.length,
      );
      retryIndexes.forEach((targetIndex, retryIndex) => {
        finalResponses[targetIndex] = retryResponses[retryIndex];
      });
    }

    let successCount = 0;
    const errorCodes = [];
    const staleTargets = [];
    finalResponses.forEach((response, index) => {
      if (response.success) {
        successCount++;
        return;
      }
      const code = _responseCode(response);
      if (!errorCodes.includes(code)) errorCodes.push(code);
      if (STALE_ERROR_CODES.has(code)) staleTargets.push(targets[index]);
    });
    return {
      successCount,
      failureCount: targets.length - successCount,
      retryCount: retryIndexes.length > 0 ? 1 : 0,
      errorCodes,
      staleTargets,
    };
  }

  async function _sendOrFailures(payload, expectedCount) {
    try {
      const result = await messaging.sendEachForMulticast(payload);
      return Array.from({ length: expectedCount }, (_, index) => {
        return result.responses[index] ?? {
          success: false,
          error: { code: 'messaging/unknown' },
        };
      });
    } catch (error) {
      return Array.from({ length: expectedCount }, () => ({
        success: false,
        error: { code: _errorCode(error) },
      }));
    }
  }

  async function _cleanupStaleTokens(profileRef, fcmRef, staleTargets) {
    if (staleTargets.length === 0) return;
    await db.runTransaction(async (transaction) => {
      const fcmSnap = await transaction.get(fcmRef);
      const profileSnap = await transaction.get(profileRef);
      const fcm = fcmSnap.data() ?? {};
      const profile = profileSnap.data() ?? {};
      const fcmUpdates = {};
      const profileUpdates = {};

      for (const target of staleTargets) {
        for (const alias of target.aliases) {
          if (
            alias.kind === 'installation' &&
            fcm.installations?.[alias.id]?.token === target.token
          ) {
            fcmUpdates[`installations.${alias.id}`] = deleteField();
          } else if (
            alias.kind === 'legacy-private' &&
            fcm.token === target.token
          ) {
            fcmUpdates.token = deleteField();
          } else if (
            alias.kind === 'legacy-user' &&
            profile.fcmToken === target.token
          ) {
            profileUpdates.fcmToken = deleteField();
          }
        }
      }

      if (fcmSnap.exists && Object.keys(fcmUpdates).length > 0) {
        transaction.update(fcmRef, fcmUpdates);
      }
      if (profileSnap.exists && Object.keys(profileUpdates).length > 0) {
        transaction.update(profileRef, profileUpdates);
      }
    });
  }

  async function hourlyNotifications() {
    const now = nowDate();
    const hour = now.getHours();
    const weekday = now.getDay();
    const dayOfMonth = now.getDate();
    const todayId = localDateId(now);
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
        tasks.push(_isolate(
          () => _createMorningNotification(uid, now),
          { job: 'hourlyNotifications', uid, type: 'morning_colleagues' },
        ));
      }

      if (profile.notifyWeeklyRecap) {
        const recapDay = profile.weeklyRecapDay ?? 5;
        const recapHour = profile.weeklyRecapHour ?? 18;
        const jsDay = recapDay === 7 ? 0 : recapDay;
        if (weekday === jsDay && hour === recapHour) {
          tasks.push(_isolate(
            () => _createWeeklyRecap(
              uid,
              now,
              profile.mealVoucherThresholdMins ?? 380,
            ),
            { job: 'hourlyNotifications', uid, type: 'weekly_recap' },
          ));
        }
      }

      if (
        profile.notifyPayday &&
        dayOfMonth === (profile.paydayDay ?? 23) &&
        hour === 8
      ) {
        tasks.push(_isolate(
          () => _createNotification(uid, `payday-${todayId.slice(0, 7)}`, {
            type: 'payday',
            route: '/salary',
            title: '💶 Stipendio in arrivo',
            body: 'Oggi è il giorno dell\'accredito. Calma e decoro.',
          }),
          { job: 'hourlyNotifications', uid, type: 'payday' },
        ));
      }
    }
    await Promise.all(tasks);
  }

  async function _createMorningNotification(uid, now) {
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
    return _createNotification(uid, `morning-${todayId}`, {
      type: 'morning_colleagues',
      route: '/social',
      title: '👥 Colleghi oggi',
      body,
    });
  }

  async function _createWeeklyRecap(uid, now, mealVoucherThresholdMins) {
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
    return _createNotification(uid, `weekly-${startId}`, {
      type: 'weekly_recap',
      route: '/stats',
      title: '📊 Recap settimana',
      body: `Lavorato: ${formatMinutes(workedMins)} · ` +
        `OT: ${formatMinutes(overtimeMins)} · Buoni: ${mealVouchers}`,
    });
  }

  async function exitReminders() {
    const now = nowTimestamp();
    const due = await db.collectionGroup('activeTimer')
      .where('reminderAt', '<=', now)
      .limit(100)
      .get();
    await Promise.all(due.docs
      .filter((timerDoc) => timerDoc.id === 'state')
      .map((timerDoc) => _isolate(
        () => _claimExitReminder(timerDoc.ref, now),
        { job: 'exitReminders', path: timerDoc.ref.path },
      )));
  }

  async function _claimExitReminder(timerRef, now) {
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
        reminderAt: deleteField(),
        reminderClaimedAt: nowTimestamp(),
      });
      if (!notificationSnap.exists) {
        transaction.create(notificationRef, {
          type: 'exit_reminder',
          route: '/dashboard',
          title: 'Uscita prevista',
          body: `Tra ${timer.reminderLeadMins ?? 15} min finisce il tuo turno.`,
          sentAt: nowTimestamp(),
          status: 'info',
          read: false,
        });
      }
      return !notificationSnap.exists;
    });
  }

  async function onTimesheetWritten(event) {
    if (!event.data?.after.exists) return null;
    const { uid, dateId } = event.params;
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dateId)) return null;
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
    await _createNotification(uid, `overtime-${monthId}`, {
      type: 'overtime_threshold',
      route: '/stats',
      title: '🔔 Soglia straordinari raggiunta',
      body: `Hai raggiunto ${formatMinutes(overtimeMins)} di straordinario questo mese.`,
    });
    return null;
  }

  async function _createNotification(uid, id, fields) {
    try {
      await db.doc(`users/${uid}/notifications/${id}`).create({
        ...fields,
        sentAt: nowTimestamp(),
        status: 'info',
        read: false,
      });
      return true;
    } catch (error) {
      if (error.code === 6 || error.code === 'already-exists') return false;
      throw error;
    }
  }

  async function _isolate(operation, context) {
    try {
      return await operation();
    } catch (error) {
      logger.error(JSON.stringify({
        event: 'notification_job_error',
        ...context,
        errorCode: _errorCode(error),
      }));
      return false;
    }
  }

  function _logDelivery(level, details) {
    logger[level](JSON.stringify({ event: 'notification_delivery', ...details }));
  }

  return {
    exitReminders,
    hourlyNotifications,
    onNotificationCreated,
    onTimesheetWritten,
  };
}

function _notificationPayload(data, targets) {
  const route = routeForNotification(data);
  const { title, body } = contentForNotification(data);
  return {
    tokens: targets.map((target) => target.token),
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
  };
}

function _collectTokenTargets(fcmData, legacyUserToken) {
  const byToken = new Map();
  const add = (token, alias) => {
    if (typeof token !== 'string' || token.length === 0) return;
    let target = byToken.get(token);
    if (!target) {
      target = { token, aliases: [] };
      byToken.set(token, target);
    }
    target.aliases.push(alias);
  };
  for (const [id, value] of Object.entries(fcmData.installations ?? {})) {
    add(value?.token, { kind: 'installation', id });
  }
  add(fcmData.token, { kind: 'legacy-private' });
  add(legacyUserToken, { kind: 'legacy-user' });
  return [...byToken.values()];
}

function _responseCode(response) {
  return response.error?.code ?? 'messaging/unknown';
}

function _errorCode(error) {
  return error?.code ?? 'messaging/unknown';
}

module.exports = { createNotificationRuntime };
