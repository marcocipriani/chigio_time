// One-off C1 (review 2026-07-05): sposta i campi sensibili dal doc utente
// (leggibile dai colleghi della stessa amministrazione) alla sotto-collezione
// owner-only users/{uid}/private/:
//   portaleJson → private/portale (campi al top level del doc)
//   fcmToken    → private/fcm     ({token, updatedAt})
// poi CANCELLA i campi legacy dal doc utente.
//
// La migrazione lazy dell'app copre gli utenti attivi; questo script chiude
// il buco per i dormienti. Idempotente: utenti già migrati vengono saltati.
//
// DRY-RUN by default. Pass --apply to write.
//   SA_KEY=/path/key.json node scripts/migrate_private_fields.mjs [--apply]

import { FieldValue } from 'firebase-admin/firestore';
import { db } from './lib_fs.mjs';

const apply = process.argv.includes('--apply');

const users = await db.collection('users').get();
let migrated = 0;
let skipped = 0;

for (const doc of users.docs) {
  const data = doc.data();
  const hasPortale = data.portaleJson && typeof data.portaleJson === 'object';
  const hasToken = typeof data.fcmToken === 'string' && data.fcmToken.length > 0;

  if (!hasPortale && !hasToken) {
    skipped++;
    continue;
  }

  console.log(
    `${apply ? 'MIGRATE' : 'DRY-RUN'} ${doc.id}: ` +
    `${hasPortale ? 'portaleJson ' : ''}${hasToken ? 'fcmToken' : ''}`,
  );
  migrated++;
  if (!apply) continue;

  const batch = db.batch();
  if (hasPortale) {
    batch.set(db.doc(`users/${doc.id}/private/portale`), data.portaleJson);
  }
  if (hasToken) {
    batch.set(db.doc(`users/${doc.id}/private/fcm`), {
      token: data.fcmToken,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  batch.update(doc.ref, {
    ...(hasPortale && { portaleJson: FieldValue.delete() }),
    ...(hasToken && { fcmToken: FieldValue.delete() }),
  });
  await batch.commit();
}

console.log(`\n${migrated} da migrare, ${skipped} già a posto/vuoti.`);
if (!apply) console.log('Nessuna scrittura eseguita. Ripeti con --apply.');
