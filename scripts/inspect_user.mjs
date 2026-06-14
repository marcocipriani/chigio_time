// Read-only dump of a user's profile + timesheet overtime fields.
// Usage: SA_KEY=/path/key.json node scripts/inspect_user.mjs <email> [YYYY-MM]
//
// Prints the user doc (onboarding-relevant fields) and, per timesheet day,
// the overtime split (extraMins / sliMins / sboMins) so we can see how the
// SBO/SLI allocation is stored vs. what it should be.

import { db, uidForEmail, fmtHM } from './lib_fs.mjs';

const email = process.argv[2];
const monthFilter = process.argv[3]; // optional "YYYY-MM"
if (!email) {
  console.error('Usage: node scripts/inspect_user.mjs <email> [YYYY-MM]');
  process.exit(1);
}

const uid = await uidForEmail(email);
console.log(`uid: ${uid}\n`);

const userSnap = await db.doc(`users/${uid}`).get();
if (!userSnap.exists) {
  console.error('user doc does NOT exist');
  process.exit(1);
}
const u = userSnap.data();

console.log('── profile (onboarding-relevant) ──────────────────────────');
for (const k of [
  'hasCompletedOnboarding',
  'name',
  'employmentType',
  'standardDailyMins',
  'monthlyArt9Hours',
  'monthlySliHours',
  'monthlySboHours',
  'monthlyOvertimeHours',
]) {
  console.log(`  ${k.padEnd(22)} = ${JSON.stringify(u[k])}`);
}

console.log('\n── timesheets (overtime split) ────────────────────────────');
let q = db.collection(`users/${uid}/timesheets`);
const snap = await q.get();
const rows = [];
snap.forEach((d) => {
  if (monthFilter && !d.id.startsWith(monthFilter)) return;
  const t = d.data();
  const extra = t.extraMins ?? 0;
  if (extra <= 0 && (t.sliMins ?? 0) === 0 && (t.sboMins ?? 0) === 0) return;
  rows.push({
    date: d.id,
    extra,
    sli: t.sliMins ?? 0,
    sbo: t.sboMins ?? 0,
  });
});
rows.sort((a, b) => a.date.localeCompare(b.date));

let totExtra = 0,
  totSli = 0,
  totSbo = 0;
for (const r of rows) {
  totExtra += r.extra;
  totSli += r.sli;
  totSbo += r.sbo;
  console.log(
    `  ${r.date}  extra=${fmtHM(r.extra).padStart(7)}  sli=${fmtHM(r.sli).padStart(7)}  sbo=${fmtHM(r.sbo).padStart(7)}`,
  );
}
console.log(
  `\n  TOTAL  extra=${fmtHM(totExtra)}  sli=${fmtHM(totSli)}  sbo=${fmtHM(totSbo)}  (rows: ${rows.length})`,
);
process.exit(0);
