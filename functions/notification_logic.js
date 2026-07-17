'use strict';

const ALLOWED = new Set([
  '/dashboard',
  '/notifications',
  '/social',
  '/stats',
  '/salary',
]);
const ROUTES = Object.freeze({
  exit_reminder: '/dashboard',
  morning_colleagues: '/social',
  coffee_invite: '/notifications',
  coffee_accepted: '/notifications',
  colleague_added: '/notifications',
  weekly_recap: '/stats',
  overtime_threshold: '/stats',
  payday: '/salary',
  test: '/notifications',
});
const STALE = new Set([
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
]);

function routeForNotification(data = {}) {
  return ALLOWED.has(data.route)
    ? data.route
    : (ROUTES[data.type] ?? '/notifications');
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
  const pad = (number) => String(number).padStart(2, '0');
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
    return {
      title: '👋 Nuovo collegamento',
      body: `${from} si è collegata con te`,
    };
  }
  if (data.type === 'coffee_invite') {
    const suffix = data.scheduledAt ? ` alle ${data.scheduledAt}` : '';
    return {
      title: '☕ Invito caffè',
      body: `${from} ti ha invitato a un caffè${suffix}`,
    };
  }
  if (data.type === 'coffee_accepted') {
    const copy = {
      accepted: ['✅ Caffè accettato', `${from} ci sarà!`],
      maybe: ['🤔 Forse…', `${from} risponde forse al tuo invito`],
      declined: ['❌ Caffè rifiutato', `${from} non può venire`],
      arriving: [
        '🚶 Sta arrivando',
        `${from} sta arrivando${data.etaMinutes ? ` tra ${data.etaMinutes} min` : ''}`,
      ],
    }[data.responseType] ?? [
      'Chigio Time',
      `${from} ha risposto al tuo invito`,
    ];
    return { title: copy[0], body: copy[1] };
  }
  return { title: 'Chigio Time', body: 'Hai una nuova notifica' };
}

function collectInstallations(fcmData = {}, legacyToken) {
  const result = [];
  const seen = new Set();
  const add = (id, token) => {
    if (typeof token !== 'string' || token.length === 0 || seen.has(token)) {
      return;
    }
    seen.add(token);
    result.push({ id, token });
  };
  for (const [id, value] of Object.entries(fcmData.installations ?? {})) {
    add(id, value?.token);
  }
  add('legacy-private', fcmData.token);
  add('legacy-user', legacyToken);
  return result;
}

function summarizeDelivery(installations, responses) {
  const staleIds = [];
  const errorCodes = [];
  let successCount = 0;
  responses.forEach((response, index) => {
    if (response.success) {
      successCount++;
      return;
    }
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
  routeForNotification,
  isQuietTime,
  localDateId,
  weekDateRange,
  contentForNotification,
  collectInstallations,
  summarizeDelivery,
  formatMinutes,
};
