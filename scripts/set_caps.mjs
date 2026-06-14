// Set a user's monthly overtime caps (Art.9 / SLI / SBO hours).
// Usage: SA_KEY=/path/key.json node scripts/set_caps.mjs <email> <art9> <sli> <sbo>

import { db, uidForEmail } from './lib_fs.mjs';

const [email, art9, sli, sbo] = process.argv.slice(2);
if (!email || art9 == null || sli == null || sbo == null) {
  console.error('Usage: node scripts/set_caps.mjs <email> <art9> <sli> <sbo>');
  process.exit(1);
}

const uid = await uidForEmail(email);
const ref = db.doc(`users/${uid}`);
const before = (await ref.get()).data() || {};
console.log('before:', {
  monthlyArt9Hours: before.monthlyArt9Hours,
  monthlySliHours: before.monthlySliHours,
  monthlySboHours: before.monthlySboHours,
});

await ref.update({
  monthlyArt9Hours: Number(art9),
  monthlySliHours: Number(sli),
  monthlySboHours: Number(sbo),
});

const after = (await ref.get()).data();
console.log('after: ', {
  monthlyArt9Hours: after.monthlyArt9Hours,
  monthlySliHours: after.monthlySliHours,
  monthlySboHours: after.monthlySboHours,
});
process.exit(0);
