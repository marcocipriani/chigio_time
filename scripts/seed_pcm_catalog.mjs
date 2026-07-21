// Pubblica assets/data/pcm_catalog.json in referenceData/pcmCatalog.
// Dry-run per default; aggiungere --apply per scrivere.

import { readFileSync } from 'node:fs';
import { FieldValue } from 'firebase-admin/firestore';

import { db } from './lib_fs.mjs';
import { catalogHash, validateCatalog } from './pcm_catalog_logic.mjs';

const apply = process.argv.includes('--apply');
const local = validateCatalog(
  JSON.parse(
    readFileSync(
      new URL('../assets/data/pcm_catalog.json', import.meta.url),
      'utf8',
    ),
  ),
);
const localHash = catalogHash(local);
const ref = db.doc('referenceData/pcmCatalog');
const currentSnapshot = await ref.get();
const current = currentSnapshot.data();

let currentHash = null;
let currentStatus = 'assente';
if (current) {
  try {
    currentHash = catalogHash(current);
    currentStatus = currentHash === localHash ? 'allineato' : 'diverso';
  } catch (error) {
    currentStatus = `non valido (${error.message})`;
  }
}

console.log(`${apply ? 'APPLY' : 'DRY-RUN'} referenceData/pcmCatalog`);
console.log(`locale: version=${local.version} sha256=${localHash}`);
console.log(
  `remoto: ${currentStatus}` +
    (current?.version ? ` version=${current.version}` : '') +
    (currentHash ? ` sha256=${currentHash}` : ''),
);

if (!apply) {
  console.log('Nessuna scrittura eseguita. Ripeti con --apply.');
  process.exit(0);
}

await ref.set({
  version: local.version,
  source: local.source,
  structures: local.structures,
  updatedAt: FieldValue.serverTimestamp(),
});

const readback = (await ref.get()).data();
const readbackHash = catalogHash(readback);
if (readback.version !== local.version || readbackHash !== localHash) {
  throw new Error('Verifica readback fallita: versione/hash non coincidono.');
}
console.log(`OK readback version=${readback.version} sha256=${readbackHash}`);
