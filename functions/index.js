'use strict';

// La timezone del cron non cambia Date#getHours/getDay/getDate nel runtime.
process.env.TZ = 'Europe/Rome';

const {
  onDocumentCreated,
  onDocumentWritten,
} = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { setGlobalOptions } = require('firebase-functions/v2');
const { initializeApp } = require('firebase-admin/app');
const {
  FieldValue,
  getFirestore,
  Timestamp,
} = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { createNotificationRuntime } = require('./notification_runtime');

setGlobalOptions({ maxInstances: 10 });
initializeApp();

const runtime = createNotificationRuntime({
  db: getFirestore(),
  messaging: getMessaging(),
  logger: {
    info: (line) => console.log(line),
    error: (line) => console.error(line),
  },
  nowDate: () => new Date(),
  nowTimestamp: () => Timestamp.now(),
  deleteField: () => FieldValue.delete(),
});

exports.onNotificationCreated = onDocumentCreated(
  {
    document: 'users/{recipientUid}/notifications/{notifId}',
    retry: true,
  },
  runtime.onNotificationCreated,
);

exports.hourlyNotifications = onSchedule(
  { schedule: '0 * * * *', timeZone: 'Europe/Rome' },
  runtime.hourlyNotifications,
);

exports.exitReminders = onSchedule(
  { schedule: '* * * * *', timeZone: 'Europe/Rome' },
  runtime.exitReminders,
);

exports.onTimesheetWritten = onDocumentWritten(
  'users/{uid}/timesheets/{dateId}',
  runtime.onTimesheetWritten,
);
