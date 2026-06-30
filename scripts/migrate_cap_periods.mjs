// One-off: seed users/{uid}/capPeriods from the existing flat cap fields.
// Creates a single OPEN period (toMonth=null) starting at the user's first
// timesheet month (or current month if none). Idempotent: skips users that
// already have at least one capPeriod. See ADR-0009.
//
// DRY-RUN by default. Pass --apply to write.
//   SA_KEY=/path/key.json node scripts/migrate_cap_periods.mjs [email] [--apply]
//   (omit email to process ALL users)

import { db, uidForEmail } from './lib_fs.mjs';

const args = process.argv.slice(2).filter((a) => a !== '--apply');
const apply = process.argv.includes('--apply');
const email = args[0];

function thisMonthId() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
}

async function firstTimesheetMonth(uid) {
  const snap = await db
    .collection(`users/${uid}/timesheets`)
    .get();
  let min = null;
  snap.forEach((d) => {
    const mo = d.id.slice(0, 7); // YYYY-MM
    if (!min || mo < min) min = mo;
  });
  return min || thisMonthId();
}

async function migrateUser(uid) {
  const existing = await db.collection(`users/${uid}/capPeriods`).limit(1).get();
  if (!existing.empty) return { uid, skipped: 'already has periods' };

  const u = (await db.doc(`users/${uid}`).get()).data() || {};
  const period = {
    fromMonth: await firstTimesheetMonth(uid),
    toMonth: null,
    inquadramento: u.employmentType ?? '',
    standardDailyMins: u.standardDailyMins ?? 456,
    mealVoucherThresholdMins: u.mealVoucherThresholdMins ?? 380,
    monthlyArt9Hours: u.monthlyArt9Hours ?? 0,
    monthlySliHours: u.monthlySliHours ?? 0,
    monthlySboHours: u.monthlySboHours ?? 0,
    scheduleVariant: u.scheduleVariant ?? 'uniform',
    longWorkDays: Array.isArray(u.longWorkDays) ? u.longWorkDays : [],
  };

  if (apply) {
    await db.collection(`users/${uid}/capPeriods`).add(period);
  }
  return { uid, period };
}

let uids = [];
if (email) {
  uids = [await uidForEmail(email)];
} else {
  const snap = await db.collection('users').get();
  uids = snap.docs.map((d) => d.id);
}

console.log(`${apply ? 'APPLY' : 'DRY-RUN'} — ${uids.length} user(s)\n`);
for (const uid of uids) {
  const r = await migrateUser(uid);
  if (r.skipped) {
    console.log(`  ${uid}  SKIP (${r.skipped})`);
  } else {
    const p = r.period;
    console.log(
      `  ${uid}  -> from ${p.fromMonth} open | ${p.inquadramento} std=${p.standardDailyMins} art9=${p.monthlyArt9Hours} sli=${p.monthlySliHours} sbo=${p.monthlySboHours}`,
    );
  }
}
if (!apply) console.log('\nDRY-RUN: no writes. Re-run with --apply.');
process.exit(0);
