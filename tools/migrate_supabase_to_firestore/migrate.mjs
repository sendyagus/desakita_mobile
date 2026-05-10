/**
 * Contoh impor batch ke Firestore dari file export.json.
 * Format export.json: { "destinations": [...], "events": [...] }
 * Sesuaikan mapper dengan export Supabase kamu.
 */
import admin from 'firebase-admin';
import { readFileSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('Set GOOGLE_APPLICATION_CREDENTIALS ke path serviceAccountKey.json');
  process.exit(1);
}

admin.initializeApp();
const db = admin.firestore();

const exportPath = join(__dirname, 'export.json');
if (!existsSync(exportPath)) {
  console.error('Buat export.json dari data Supabase (lihat README.md).');
  process.exit(1);
}

const raw = JSON.parse(readFileSync(exportPath, 'utf8'));

async function batchWrite(collection, docs, idField = 'id') {
  let batch = db.batch();
  let n = 0;
  for (const doc of docs) {
    const id = doc[idField] || doc.id;
    if (!id) continue;
    const { [idField]: _drop, id: _id2, ...data } = doc;
    const ref = db.collection(collection).doc(String(id));
    batch.set(ref, data, { merge: true });
    n++;
    if (n % 400 === 0) {
      await batch.commit();
      batch = db.batch();
    }
  }
  if (n % 400 !== 0) await batch.commit();
  console.log(`Wrote ${n} docs to ${collection}`);
}

async function main() {
  if (raw.destinations?.length) {
    await batchWrite(
      'destinations',
      raw.destinations.map((d) => ({
        id: d.id,
        name: d.name,
        category: d.category,
        location: d.location,
        description: d.description ?? null,
        rating: Number(d.rating) || 0,
        price: d.price ?? '',
        imageUrl: d.image_url ?? d.imageUrl ?? null,
        status: d.status !== false,
        createdAt: d.created_at ? admin.firestore.Timestamp.fromDate(new Date(d.created_at)) : admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: d.updated_at ? admin.firestore.Timestamp.fromDate(new Date(d.updated_at)) : admin.firestore.FieldValue.serverTimestamp(),
      })),
    );
  }
  if (raw.events?.length) {
    await batchWrite(
      'events',
      raw.events.map((e) => ({
        id: e.id,
        title: e.title,
        description: e.description ?? null,
        eventDate: e.event_date ?? e.eventDate,
        eventTime: e.event_time ?? e.eventTime ?? null,
        location: e.location,
        imageUrl: e.image_url ?? e.imageUrl ?? null,
        status: e.status !== false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      })),
    );
  }
  console.log('Selesai.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
