const { onDocumentCreated } = require('firebase-functions/v2/firestore');
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
