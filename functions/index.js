const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule }       = require('firebase-functions/v2/scheduler');
const { initializeApp }    = require('firebase-admin/app');
const { getFirestore }     = require('firebase-admin/firestore');
const { getMessaging }     = require('firebase-admin/messaging');

initializeApp();

// ── Coffee / response notification push ─────────────────────────────────────
//
// Fires whenever a document is created in users/{recipientUid}/notifications.
// Reads the recipient's FCM token from their profile and sends a push.
//
exports.onNotificationCreated = onDocumentCreated(
  'users/{recipientUid}/notifications/{notifId}',
  async (event) => {
    const recipientUid = event.params.recipientUid;
    const data = event.data?.data() ?? {};

    const profileSnap = await getFirestore()
      .collection('users')
      .doc(recipientUid)
      .get();

    const fcmToken = profileSnap.data()?.fcmToken;
    if (!fcmToken) return null;

    const { title, body } = _buildNotification(data);

    try {
      await getMessaging().send({
        token: fcmToken,
        notification: { title, body },
        data: {
          type:    data.type    ?? '',
          fromUid: data.fromUid ?? '',
        },
        android: {
          notification: {
            channelId: 'chigio_notifications',
            priority: 'high',
            sound: 'default',
          },
        },
        apns: {
          payload: { aps: { badge: 1, sound: 'default' } },
        },
        webpush: {
          notification: {
            icon: 'https://chigio-time-pcm.web.app/icons/web-app-manifest-192x192.png',
          },
        },
      });
    } catch (err) {
      // Stale token: remove it so we don't retry.
      const staleCodes = [
        'messaging/invalid-registration-token',
        'messaging/registration-token-not-registered',
      ];
      if (staleCodes.includes(err.code)) {
        await getFirestore()
          .collection('users')
          .doc(recipientUid)
          .update({ fcmToken: null });
      }
    }

    return null;
  },
);

// ── Hourly scheduled notifications (S2: morning colleagues, P2: weekly recap) ─

exports.hourlyNotifications = onSchedule(
  { schedule: 'every 60 minutes', timeZone: 'Europe/Rome' },
  async () => {
    const now   = new Date();
    const hour  = now.getHours();
    const weekday = now.getDay();    // 0=Sun, 1=Mon, …, 6=Sat
    const dayOfMonth = now.getDate(); // 1…31

    const db        = getFirestore();
    const messaging = getMessaging();
    const usersSnap = await db.collection('users').get();

    const tasks = [];
    for (const userDoc of usersSnap.docs) {
      const data  = userDoc.data();
      const token = data.fcmToken;
      if (!token) continue;
      const uid   = userDoc.id;

      // S2: morning colleagues notification
      if (data.notifyMorningColleagues) {
        const targetHour = data.morningColleaguesHour ?? 9;
        if (hour === targetHour) {
          tasks.push(_sendMorningColleagues(uid, token, db, messaging));
        }
      }

      // P2: weekly recap (weeklyRecapDay 1=Mon…7=Sun → JS weekday)
      if (data.notifyWeeklyRecap) {
        const recapDay  = data.weeklyRecapDay  ?? 5; // default Fri
        const recapHour = data.weeklyRecapHour ?? 18;
        const jsDay     = recapDay === 7 ? 0 : recapDay;
        if (weekday === jsDay && hour === recapHour) {
          tasks.push(_sendWeeklyRecap(uid, token, messaging, now, db));
        }
      }

      // Stipendio in arrivo: push at 08:00 on the configured payday (PCM = 23).
      if (data.notifyPayday) {
        const payDay = data.paydayDay ?? 23;
        if (dayOfMonth === payDay && hour === 8) {
          tasks.push(_sendPush(
            messaging, token,
            '💶 Stipendio in arrivo',
            'Oggi è il giorno dell\'accredito. Calma e decoro.',
          ));
        }
      }
    }

    await Promise.allSettled(tasks);
  },
);

async function _sendMorningColleagues(uid, token, db, messaging) {
  const today = _todayId();
  const colleaguesSnap = await db.collection(`users/${uid}/colleagues`).get();
  const collegueUids   = colleaguesSnap.docs.map((d) => d.id);
  if (collegueUids.length === 0) return;

  let inOffice = 0;
  let remote   = 0;
  for (const cUid of collegueUids) {
    const p = (await db.doc(`users/${cUid}`).get()).data();
    if (!p) continue;
    if (p.statusDate !== today) continue;
    if (p.currentStatus === 'working') inOffice++;
    else if (p.currentStatus === 'remote') remote++;
  }

  const total = inOffice + remote;
  if (total === 0) return;

  let body = `${inOffice} in ufficio`;
  if (remote > 0) body += `, ${remote} in smart working`;

  await _sendPush(messaging, token, '👥 Colleghi oggi', body);
}

async function _sendWeeklyRecap(uid, token, messaging, now, db) {
  const year  = now.getFullYear();
  const month = now.getMonth() + 1;
  const pad   = (n) => String(n).padStart(2, '0');
  const prefix = `${year}-${pad(month)}-`;

  const snap = await db
    .collection(`users/${uid}/timesheets`)
    .where('__name__', '>=', prefix + '01')
    .where('__name__', '<=', prefix + '31')
    .get();

  let worked = 0, ot = 0, meals = 0;
  for (const doc of snap.docs) {
    const d = doc.data();
    worked += d.netWorkedMins ?? 0;
    ot     += Math.max(0, d.extraMins ?? 0);
    if ((d.netWorkedMins ?? 0) >= 380) meals++;
  }

  const fmtH = (m) => `${Math.floor(m / 60)}h${pad(m % 60)}`;
  const body = `Lavorato: ${fmtH(worked)} · OT: ${fmtH(ot)} · Buoni: ${meals}`;

  await _sendPush(messaging, token, '📊 Recap settimana', body);
}

async function _sendPush(messaging, token, title, body) {
  try {
    await messaging.send({
      token,
      notification: { title, body },
      android: { notification: { channelId: 'chigio_notifications', priority: 'high' } },
      apns:    { payload: { aps: { badge: 1, sound: 'default' } } },
    });
  } catch (err) {
    const stale = [
      'messaging/invalid-registration-token',
      'messaging/registration-token-not-registered',
    ];
    if (stale.includes(err.code)) {
      await getFirestore().doc(`users/${(await messaging.getApp()).name}`).update({ fcmToken: null }).catch(() => {});
    }
  }
}

function _todayId() {
  const d = new Date();
  const pad = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

// ── Clock-in / clock-out reminder ────────────────────────────────────────────
//
// Scheduled reminders are written to users/{uid}/reminders/{type} by the app.
// This function is a placeholder — implement with Cloud Scheduler when needed.

// ── Helpers ──────────────────────────────────────────────────────────────────

function _buildNotification(data) {
  const from = data.fromName ?? 'Un collega';

  switch (data.type) {
    case 'coffee_invite':
      return data.scheduledAt
        ? { title: '☕ Invito caffè', body: `${from} ti ha invitato a un caffè alle ${data.scheduledAt}` }
        : { title: '☕ Invito caffè', body: `${from} ti ha invitato a prendere un caffè` };

    case 'coffee_accepted':
      return _responseNotif(data, from);

    case 'exit_reminder':
      return { title: data.title ?? 'Uscita prevista', body: data.body ?? 'Il tuo turno sta per finire' };

    default:
      return { title: 'Chigio Time', body: 'Hai una nuova notifica' };
  }
}

function _responseNotif(data, from) {
  switch (data.responseType) {
    case 'accepted':  return { title: '✅ Caffè accettato',   body: `${from} ci sarà!` };
    case 'maybe':     return { title: '🤔 Forse…',            body: `${from} risponde forse al tuo invito` };
    case 'declined':  return { title: '❌ Caffè rifiutato',   body: `${from} non può venire` };
    case 'arriving':  return { title: '🚶 Sta arrivando',     body: `${from} sta arrivando${data.etaMinutes ? ` tra ${data.etaMinutes} min` : ''}` };
    default:          return { title: 'Chigio Time',           body: `${from} ha risposto al tuo invito` };
  }
}
