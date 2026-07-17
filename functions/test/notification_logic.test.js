'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const logic = require('../notification_logic');

test('DND overnight e intervallo nullo', () => {
  const p = { doNotDisturb: true, silenceFrom: 22, silenceTo: 8 };
  assert.equal(logic.isQuietTime(p, new Date(2026, 6, 17, 23)), true);
  assert.equal(logic.isQuietTime(p, new Date(2026, 6, 18, 7)), true);
  assert.equal(logic.isQuietTime(p, new Date(2026, 6, 18, 12)), false);
  assert.equal(
    logic.isQuietTime({ ...p, silenceFrom: 8, silenceTo: 8 }, new Date()),
    false,
  );
});

test('route esplicite e type sono allowlisted', () => {
  assert.equal(logic.routeForNotification({ type: 'exit_reminder' }), '/dashboard');
  assert.equal(logic.routeForNotification({ type: 'morning_colleagues' }), '/social');
  assert.equal(logic.routeForNotification({ type: 'weekly_recap' }), '/stats');
  assert.equal(logic.routeForNotification({ type: 'overtime_threshold' }), '/stats');
  assert.equal(logic.routeForNotification({ type: 'payday' }), '/salary');
  assert.equal(logic.routeForNotification({ route: '/stats' }), '/stats');
  assert.equal(
    logic.routeForNotification({ route: 'https://evil.test' }),
    '/notifications',
  );
});

test('settimana corrente parte lunedi', () => {
  assert.deepEqual(logic.weekDateRange(new Date(2026, 6, 17, 18)), {
    startId: '2026-07-13', endId: '2026-07-17',
  });
});

test('copy social e contenuto automatico esplicito', () => {
  assert.deepEqual(
    logic.contentForNotification({ type: 'colleague_added', fromName: 'Marta' }),
    {
      title: '👋 Nuovo collegamento', body: 'Marta si è collegata con te',
    },
  );
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
    {
      success: false,
      error: { code: 'messaging/registration-token-not-registered' },
    },
  ];
  assert.deepEqual(logic.summarizeDelivery(installs, responses), {
    successCount: 1,
    staleIds: ['b'],
    errorCodes: ['messaging/registration-token-not-registered'],
  });
  assert.equal(logic.formatMinutes(457), '7h37');
});
