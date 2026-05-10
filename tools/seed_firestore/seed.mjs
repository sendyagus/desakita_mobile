import admin from 'firebase-admin';

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('Set GOOGLE_APPLICATION_CREDENTIALS');
  process.exit(1);
}

admin.initializeApp();
const db = admin.firestore();
const ts = admin.firestore.FieldValue.serverTimestamp();

const destinations = [
  {
    name: 'Bukit Sakura',
    category: 'Alam',
    location: 'Langkapura',
    description: 'Pemandangan perbukitan.',
    rating: 4.3,
    price: 'Rp 50.000',
    imageUrl: null,
    status: true,
    createdAt: ts,
    updatedAt: ts,
  },
  {
    name: 'Jukung Villa Lampung',
    category: 'Penginapan',
    location: 'Langkapura',
    description: 'Penginapan nyaman.',
    rating: 4.8,
    price: 'Rp 450.000',
    imageUrl: null,
    status: true,
    createdAt: ts,
    updatedAt: ts,
  },
];

const events = [
  {
    title: 'Festival Panen Raya',
    description: 'Perayaan panen raya.',
    eventDate: '2025-10-24',
    eventTime: '08:00 - Selesai',
    location: 'Desa Pujon Kidul',
    imageUrl: null,
    status: true,
    createdAt: ts,
    updatedAt: ts,
  },
];

async function main() {
  const batch = db.batch();
  for (const d of destinations) {
    const ref = db.collection('destinations').doc();
    batch.set(ref, d);
  }
  for (const e of events) {
    const ref = db.collection('events').doc();
    batch.set(ref, e);
  }
  await batch.commit();
  console.log('Seed selesai.');
}

main().catch(console.error);
