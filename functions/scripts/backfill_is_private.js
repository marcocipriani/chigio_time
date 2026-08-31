#!/usr/bin/env node
'use strict';

/**
 * Scrive `isPrivate: false` su ogni profilo che non ha il campo.
 *
 * Perché serve: la regola di lettura su `users/{userId}` nega i profili
 * privati, e `getUsersInAdministration` filtra `isPrivate == false` per non
 * far negare l'intera query. Ma `isPrivate == false` NON seleziona i documenti
 * in cui il campo manca: senza questo backfill, distribuendo le regole nuove
 * la rubrica colleghi resterebbe vuota finché ogni utente non riapre l'app
 * (il backfill client in `profileGate` copre solo chi si collega).
 *
 * ORDINE DI RILASCIO
 *   1. node functions/scripts/backfill_is_private.js        (questo script)
 *   2. firebase deploy --only firestore:rules,firestore:indexes
 *   3. ./deploy.sh                                          (app con la query)
 *
 * Credenziali: Application Default Credentials.
 *   gcloud auth application-default login
 *   (oppure GOOGLE_APPLICATION_CREDENTIALS=/percorso/service-account.json)
 *
 * Idempotente: rileggendo, i documenti già a posto vengono saltati.
 * `--dry-run` conta soltanto, senza scrivere.
 */

const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const DRY_RUN = process.argv.includes('--dry-run');
const PROJECT_ID = process.env.GCLOUD_PROJECT || 'chigio-time-pcm';
const BATCH_SIZE = 400; // il limite di un batch è 500: margine per sicurezza.

async function main() {
  initializeApp({ credential: applicationDefault(), projectId: PROJECT_ID });
  const db = getFirestore();

  // Il campo va letto per intero: `where('isPrivate', '==', null)` non trova i
  // documenti in cui manca, quindi si scorre tutta la collection.
  const snapshot = await db.collection('users').select('isPrivate').get();
  const missing = snapshot.docs.filter(
    (doc) => typeof doc.data().isPrivate !== 'boolean',
  );

  console.log(`progetto      : ${PROJECT_ID}`);
  console.log(`profili totali: ${snapshot.size}`);
  console.log(`senza isPrivate: ${missing.length}`);

  if (DRY_RUN) {
    console.log('dry-run: nessuna scrittura.');
    return;
  }
  if (missing.length === 0) {
    console.log('niente da fare.');
    return;
  }

  let written = 0;
  for (let i = 0; i < missing.length; i += BATCH_SIZE) {
    const batch = db.batch();
    for (const doc of missing.slice(i, i + BATCH_SIZE)) {
      batch.update(doc.ref, { isPrivate: false });
    }
    await batch.commit();
    written += Math.min(BATCH_SIZE, missing.length - i);
    console.log(`  ${written}/${missing.length}`);
  }
  console.log('fatto.');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
