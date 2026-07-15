// Run with: node scripts/upload_licenses.js
// Uploads Pro license codes to Firestore

const admin = require('firebase-admin');
const path = require('path');

// Initialize with default credentials (uses firebase CLI login)
process.env.FIRESTORE_EMULATOR_HOST = ''; // ensure we hit production
const app = admin.initializeApp({
  projectId: 'catchtales-prod',
});
const db = admin.firestore();

const codes = [
  'PRO-6RNL-CSBK-489H',
  'PRO-ZTQK-ZENL-QTFG',
  'PRO-PJA9-6UT8-AQCH',
  'PRO-USSA-KBQT-ZSDY',
  'PRO-379Q-F9ZE-74LS',
];

const batch = 'pro-batch-2026-07';

async function upload() {
  for (const code of codes) {
    const ref = db.collection('pro_licenses').doc(code);
    const snap = await ref.get();
    if (snap.exists) {
      console.log(`⏭️  ${code} — already exists, skipping`);
    } else {
      await ref.set({
        code: code,
        batch: batch,
        used: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`✅ ${code} — uploaded`);
    }
  }
  console.log('\nAll codes uploaded. Share them with users!');
}

upload().catch(console.error);
