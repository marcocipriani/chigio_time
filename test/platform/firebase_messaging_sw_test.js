'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

async function main() {
  const source = fs.readFileSync('web/firebase-messaging-sw.js', 'utf8');
  const shownNotifications = [];
  let backgroundHandler;

  const context = {
    URL,
    clients: {
      matchAll: async () => [],
      openWindow: async () => null,
    },
    firebase: {
      initializeApp() {},
      messaging() {
        return {
          onBackgroundMessage(handler) {
            backgroundHandler = handler;
          },
        };
      },
    },
    importScripts() {},
    self: {
      addEventListener() {},
      location: { origin: 'https://preview.example' },
      registration: {
        showNotification(title, options) {
          shownNotifications.push({ title, options });
          return Promise.resolve();
        },
      },
    },
  };

  vm.runInNewContext(source, context, {
    filename: 'web/firebase-messaging-sw.js',
  });
  assert.equal(typeof backgroundHandler, 'function');

  await backgroundHandler({
    notification: { title: 'Backend', body: 'Gia mostrata da Firebase' },
    data: { route: '/notifications' },
  });
  assert.equal(
    shownNotifications.length,
    0,
    'notification payload must not be shown manually a second time',
  );

  await backgroundHandler({
    data: {
      title: 'Solo dati',
      body: 'Fallback manuale',
      route: '/notifications',
    },
  });
  assert.equal(shownNotifications.length, 1);
  assert.equal(shownNotifications[0].title, 'Solo dati');
  assert.equal(shownNotifications[0].options.body, 'Fallback manuale');
  assert.equal(shownNotifications[0].options.data.route, '/notifications');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
