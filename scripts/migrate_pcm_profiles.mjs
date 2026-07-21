// Azzera la coppia PCM dei profili con dipartimento non canonico.
// Dry-run per default; aggiungere --apply per scrivere.

import { readFileSync } from 'node:fs';
import { FieldValue } from 'firebase-admin/firestore';

import { db } from './lib_fs.mjs';
import {
  classifyProfile,
  profileResetPatch,
  validateCatalog,
} from './pcm_catalog_logic.mjs';

const apply = process.argv.includes('--apply');
const catalog = validateCatalog(
  JSON.parse(
    readFileSync(
      new URL('../assets/data/pcm_catalog.json', import.meta.url),
      'utf8',
    ),
  ),
);
const validNames = new Set(catalog.structures.map((row) => row.name));
const users = await db.collection('users').get();
const toClear = [];
const counts = { valid: 0, clear: 0, alreadyEmpty: 0, nonPcm: 0 };

for (const doc of users.docs) {
  const data = doc.data();
  if (data.administration !== 'Presidenza del Consiglio dei Ministri') {
    counts.nonPcm++;
    continue;
  }
  const classification = classifyProfile(data, validNames);
  counts[classification]++;
  if (classification !== 'clear') continue;

  const values = {
    dipartimento: data.dipartimento ?? '',
    sede: data.sede ?? '',
    sedeId: data.sedeId ?? '',
    sedeAddress: data.sedeAddress ?? '',
    sedeLat: data.sedeLat ?? null,
    sedeLng: data.sedeLng ?? null,
  };
  toClear.push({ ref: doc.ref, uid: doc.id, values });
  console.log(`${apply ? 'CLEAR' : 'DRY-RUN'} ${doc.id} ${JSON.stringify(values)}`);
}

console.log(
  `catalog=${catalog.version} valid=${counts.valid} clear=${counts.clear} ` +
    `alreadyEmpty=${counts.alreadyEmpty} nonPcm=${counts.nonPcm}`,
);

if (!apply) {
  console.log('Nessuna scrittura eseguita. Ripeti con --apply.');
  process.exit(0);
}

for (let offset = 0; offset < toClear.length; offset += 400) {
  const batch = db.batch();
  for (const target of toClear.slice(offset, offset + 400)) {
    batch.update(target.ref, profileResetPatch(FieldValue.delete()));
  }
  await batch.commit();
}

for (const target of toClear) {
  const readback = (await target.ref.get()).data() ?? {};
  if (classifyProfile(readback, validNames) !== 'alreadyEmpty') {
    throw new Error(`Verifica readback fallita per UID ${target.uid}.`);
  }
}

console.log(
  `OK migrazione catalog=${catalog.version} profiliAzzerati=${toClear.length}`,
);
