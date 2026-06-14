// Recompute per-day SBO/SLI split for one user to match the caps-cascade
// (art9 -> SLI -> SBO -> OPE) that the dashboard "maggior presenza" card uses.
//
// The historical bug: the timer save blindly set sboMins = extraMins, ignoring
// the user's monthly caps (monthlyArt9Hours / monthlySliHours / monthlySboHours).
// For a user with sboCap=0/sliCap=0 this wrongly parked overtime in SBO.
//
// This script reallocates each MONTH's total overtime via the cascade, then
// distributes the per-bucket minutes back onto the days proportionally to each
// day's extraMins. The day-level art9/OPE portions are not stored (no field);
// only sliMins and sboMins are persisted, matching the app schema.
//
// DRY-RUN by default. Pass --apply to write.
//   SA_KEY=/path/key.json node scripts/migrate_straordinario.mjs <email> [--apply]

import { db, uidForEmail, fmtHM } from './lib_fs.mjs';

const email = process.argv[2];
const apply = process.argv.includes('--apply');
if (!email) {
  console.error('Usage: node scripts/migrate_straordinario.mjs <email> [--apply]');
  process.exit(1);
}

const uid = await uidForEmail(email);
const userSnap = await db.doc(`users/${uid}`).get();
const u = userSnap.data() || {};
const art9Cap = (u.monthlyArt9Hours ?? 0) * 60;
const sliCap = (u.monthlySliHours ?? 0) * 60;
const sboCap = (u.monthlySboHours ?? 0) * 60;
console.log(
  `caps: art9=${fmtHM(art9Cap)} sli=${fmtHM(sliCap)} sbo=${fmtHM(sboCap)}  (${apply ? 'APPLY' : 'DRY-RUN'})\n`,
);

const snap = await db.collection(`users/${uid}/timesheets`).get();

// group days by month
const months = {};
snap.forEach((d) => {
  const t = d.data();
  const extra = t.extraMins ?? 0;
  const mo = d.id.slice(0, 7);
  (months[mo] ||= []).push({
    id: d.id,
    extra: extra > 0 ? extra : 0,
    curSli: t.sliMins ?? 0,
    curSbo: t.sboMins ?? 0,
  });
});

// largest-remainder distribution of `total` over weights, summing exactly.
function distribute(total, weights) {
  const sum = weights.reduce((a, b) => a + b, 0);
  if (sum === 0 || total === 0) return weights.map(() => 0);
  const raw = weights.map((w) => (total * w) / sum);
  const floor = raw.map(Math.floor);
  let rem = total - floor.reduce((a, b) => a + b, 0);
  const order = raw
    .map((r, i) => [r - Math.floor(r), i])
    .sort((a, b) => b[0] - a[0]);
  for (let k = 0; k < rem; k++) floor[order[k][1]]++;
  return floor;
}

const writes = [];
for (const mo of Object.keys(months).sort()) {
  const days = months[mo];
  const monthOt = days.reduce((s, d) => s + d.extra, 0);
  // cascade
  const sli = Math.min(Math.max(monthOt - art9Cap, 0), sliCap);
  const sbo = Math.min(Math.max(monthOt - art9Cap - sliCap, 0), sboCap);

  const weights = days.map((d) => d.extra);
  const sliPerDay = distribute(sli, weights);
  const sboPerDay = distribute(sbo, weights);

  let changed = 0;
  days.forEach((d, i) => {
    const newSli = sliPerDay[i];
    const newSbo = sboPerDay[i];
    if (newSli !== d.curSli || newSbo !== d.curSbo) {
      changed++;
      writes.push({ id: d.id, sli: newSli, sbo: newSbo, oldSli: d.curSli, oldSbo: d.curSbo });
    }
  });
  console.log(
    `${mo}  monthOT=${fmtHM(monthOt).padStart(6)}  -> sli=${fmtHM(sli)} sbo=${fmtHM(sbo)}  (${changed} day(s) change)`,
  );
}

console.log(`\n${writes.length} day(s) to update:`);
for (const w of writes) {
  console.log(
    `  ${w.id}  sli ${fmtHM(w.oldSli)}->${fmtHM(w.sli)}   sbo ${fmtHM(w.oldSbo)}->${fmtHM(w.sbo)}`,
  );
}

if (!apply) {
  console.log('\nDRY-RUN: no writes performed. Re-run with --apply to commit.');
  process.exit(0);
}

const batchLimit = 400;
for (let i = 0; i < writes.length; i += batchLimit) {
  const batch = db.batch();
  for (const w of writes.slice(i, i + batchLimit)) {
    batch.update(db.doc(`users/${uid}/timesheets/${w.id}`), {
      sliMins: w.sli,
      sboMins: w.sbo,
    });
  }
  await batch.commit();
}
console.log(`\nAPPLIED ${writes.length} update(s).`);
process.exit(0);
