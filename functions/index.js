// C2: il runtime Cloud Functions gira in UTC; timeZone su onSchedule governa
// solo il cron. Senza questo, getHours()/getDay()/getDate() e _todayId()
// sarebbero sfasati di 1-2h rispetto all'Italia (DST incluso).
process.env.TZ = 'Europe/Rome';

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule }       = require('firebase-functions/v2/scheduler');
const { setGlobalOptions } = require('firebase-functions/v2');
const { initializeApp }    = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getMessaging }     = require('firebase-admin/messaging');

// Cap di spesa Blaze: nessuna function può scalare oltre 10 istanze.
setGlobalOptions({ maxInstances: 10 });

initializeApp();

// ── Anti-spam (Blaze, 2026-07-06) ────────────────────────────────────────
// Limiti giornalieri sulle notifiche cross-user (inviti caffè & co.):
//  - max 10 notifiche / 24h dallo stesso mittente verso lo stesso
//    destinatario: oltre, il doc viene cancellato e la push non parte;
//  - chi insiste (>20 tentativi / 24h verso la stessa persona) viene
//    bannato 24h: abuseBans/{uid} — le rules NEGANO il create a monte,
//    quindi lo spam smette anche di generare scritture a nostro carico.
const SPAM_MAX_PER_DAY  = 10;
const SPAM_BAN_AFTER    = 20;
const SPAM_BAN_HOURS    = 24;

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

    // Anti-spam: vale solo per le notifiche cross-user (fromUid ≠ owner).
    const sender = data.fromUid;
    if (sender && sender !== recipientUid) {
      const spam = await _checkSpam(getFirestore(), sender, recipientUid);
      if (spam) {
        await event.data.ref.delete().catch(() => {});
        return null;
      }
    }

    const fcmToken = await _getToken(getFirestore(), recipientUid);
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
        await _clearToken(getFirestore(), recipientUid);
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
    // ponytail: full scan di users ogni ora — ok fino a ~qualche centinaio
    // di utenti; oltre, filtrare con where() sui flag notifiche (+ indici).
    // select() = projection: stessi read, molta meno banda.
    const usersSnap = await db.collection('users').select(
      'fcmToken',
      'notifyMorningColleagues', 'morningColleaguesHour',
      'notifyWeeklyRecap', 'weeklyRecapDay', 'weeklyRecapHour',
      'notifyPayday', 'paydayDay',
      'mealVoucherThresholdMins',
    ).get();

    const tasks = [];
    for (const userDoc of usersSnap.docs) {
      const data = userDoc.data();
      const uid  = userDoc.id;

      // Decide FIRST which notifications are due this hour; the FCM token
      // lives in users/{uid}/private/fcm (C1) and costs an extra read, so we
      // fetch it only for users that actually have something to send.
      const due = [];

      // S2: morning colleagues notification
      if (data.notifyMorningColleagues && hour === (data.morningColleaguesHour ?? 9)) {
        due.push((token) => _sendMorningColleagues(uid, token, db, messaging));
      }

      // P2: weekly recap (weeklyRecapDay 1=Mon…7=Sun → JS weekday)
      if (data.notifyWeeklyRecap) {
        const recapDay  = data.weeklyRecapDay  ?? 5; // default Fri
        const recapHour = data.weeklyRecapHour ?? 18;
        const jsDay     = recapDay === 7 ? 0 : recapDay;
        if (weekday === jsDay && hour === recapHour) {
          const mealThreshold = data.mealVoucherThresholdMins ?? 380;
          due.push((token) =>
            _sendWeeklyRecap(uid, token, messaging, now, db, mealThreshold));
        }
      }

      // Stipendio in arrivo: push at 08:00 on the configured payday (PCM = 23).
      if (data.notifyPayday && dayOfMonth === (data.paydayDay ?? 23) && hour === 8) {
        due.push((token) => _sendPush(
          messaging, db, uid, token,
          '💶 Stipendio in arrivo',
          'Oggi è il giorno dell\'accredito. Calma e decoro.',
        ));
      }

      if (due.length === 0) continue;
      tasks.push((async () => {
        const token = await _getToken(db, uid, data);
        if (!token) return;
        await Promise.allSettled(due.map((send) => send(token)));
      })());
    }

    await Promise.allSettled(tasks);
  },
);

async function _sendMorningColleagues(uid, token, db, messaging) {
  const today = _todayId();
  const colleaguesSnap = await db.collection(`users/${uid}/colleagues`).get();
  const collegueUids   = colleaguesSnap.docs.map((d) => d.id);
  if (collegueUids.length === 0) return;

  // M6: batch read (1 RPC) con fieldMask invece di N get sequenziali.
  const snaps = await db.getAll(
    ...collegueUids.map((c) => db.doc(`users/${c}`)),
    { fieldMask: ['currentStatus', 'statusDate'] },
  );

  let inOffice = 0;
  let remote   = 0;
  for (const snap of snaps) {
    const p = snap.data();
    if (!p) continue;
    if (p.statusDate !== today) continue;
    if (p.currentStatus === 'working') inOffice++;
    else if (p.currentStatus === 'remote') remote++;
  }

  const total = inOffice + remote;
  if (total === 0) return;

  let body = `${inOffice} in ufficio`;
  if (remote > 0) body += `, ${remote} in smart working`;

  await _sendPush(messaging, db, uid, token, '👥 Colleghi oggi', body);
}

async function _sendWeeklyRecap(uid, token, messaging, now, db, mealThreshold = 380) {
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
    if ((d.netWorkedMins ?? 0) >= mealThreshold) meals++;
  }

  const fmtH = (m) => `${Math.floor(m / 60)}h${pad(m % 60)}`;
  const body = `Lavorato: ${fmtH(worked)} · OT: ${fmtH(ot)} · Buoni: ${meals}`;

  await _sendPush(messaging, db, uid, token, '📊 Recap settimana', body);
}

async function _sendPush(messaging, db, uid, token, title, body) {
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
      // Clear the stale token so the hourly job stops retrying it.
      await _clearToken(db, uid);
    }
  }
}

// C1: il token FCM vive in users/{uid}/private/fcm (owner-only, non leggibile
// dai colleghi). Fallback sul campo legacy `fcmToken` del doc utente per gli
// account non ancora migrati (la migrazione avviene al primo login post-fix).
// [userData]: doc utente già letto, se disponibile — evita un get quando il
// fallback legacy basta a rispondere.
async function _getToken(db, uid, userData) {
  const snap = await db.doc(`users/${uid}/private/fcm`).get().catch(() => null);
  const token = snap?.data()?.token;
  if (token) return token;
  if (userData !== undefined) return userData?.fcmToken ?? null;
  const profile = await db.collection('users').doc(uid).get().catch(() => null);
  return profile?.data()?.fcmToken ?? null;
}

// Anti-spam: true se il mittente ha superato il limite giornaliero verso
// questo destinatario. Oltre la soglia di ban scrive abuseBans/{sender}
// (le rules negano i create successivi finché `until` non scade).
// Query su singolo campo (fromUid) senza indice composito: la inbox di un
// destinatario da uno stesso mittente è piccola, il filtro 24h è in memoria.
async function _checkSpam(db, sender, recipientUid) {
  try {
    const snap = await db
      .collection(`users/${recipientUid}/notifications`)
      .where('fromUid', '==', sender)
      .get();
    const dayAgo = Date.now() - 24 * 3600 * 1000;
    // Conta le notifiche delle ultime 24h (quella appena creata inclusa).
    const recent = snap.docs.filter((d) => {
      const t = d.data().sentAt;
      return t?.toMillis ? t.toMillis() > dayAgo : true;
    }).length;

    if (recent > SPAM_BAN_AFTER) {
      await db.doc(`abuseBans/${sender}`).set({
        until: Timestamp.fromMillis(Date.now() + SPAM_BAN_HOURS * 3600 * 1000),
        reason: `>${SPAM_BAN_AFTER} notifiche/24h verso ${recipientUid}`,
        createdAt: Timestamp.now(),
      });
    }
    return recent > SPAM_MAX_PER_DAY;
  } catch (err) {
    console.error('[spam-check] failed:', err);
    return false; // fail-open: mai bloccare notifiche legittime per un errore
  }
}

async function _clearToken(db, uid) {
  await db.doc(`users/${uid}/private/fcm`).delete().catch(() => {});
  await db.collection('users').doc(uid)
    .set({ fcmToken: null }, { merge: true }).catch(() => {});
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
