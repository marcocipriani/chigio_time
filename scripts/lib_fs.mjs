// Shared Firestore admin bootstrap for one-off maintenance scripts.
//
// Credentials: pass the service-account key path as the SA_KEY env var, e.g.
//   SA_KEY=/path/to/key.json node scripts/inspect_user.mjs <email>
//
// The key file is NEVER committed — keep it outside the repo or add it to
// .gitignore. These scripts are throwaway maintenance tooling, not app code.

import { readFileSync } from 'node:fs';
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

const keyPath = process.env.SA_KEY;
if (!keyPath) {
  console.error('Missing SA_KEY env var (path to service-account JSON).');
  process.exit(1);
}

const serviceAccount = JSON.parse(readFileSync(keyPath, 'utf8'));
initializeApp({
  credential: cert(serviceAccount),
  projectId: serviceAccount.project_id,
});

export const db = getFirestore();
export const auth = getAuth();

// Resolve a user's uid from an email (Firebase Auth lookup).
export async function uidForEmail(email) {
  const user = await auth.getUserByEmail(email);
  return user.uid;
}

// minutes "HH:MM" helpers
export const toMins = (hhmm) => {
  const [h, m] = String(hhmm).split(':');
  return (parseInt(h, 10) || 0) * 60 + (parseInt(m, 10) || 0);
};
export const fmtHM = (mins) => {
  const a = Math.abs(mins);
  const h = Math.floor(a / 60);
  const m = a % 60;
  return `${mins < 0 ? '-' : ''}${h}h${String(m).padStart(2, '0')}`;
};
