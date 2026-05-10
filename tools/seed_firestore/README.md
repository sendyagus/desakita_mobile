# Seed data awal Firestore

Untuk mengisi contoh destinasi & event tanpa migrasi dari Supabase.

## Langkah

```bash
cd tools/seed_firestore
npm install
set GOOGLE_APPLICATION_CREDENTIALS=path\to\serviceAccountKey.json
node seed.mjs
```

Pastikan **Firestore Rules** sudah publish. Untuk seed pertama kali, sementara izinkan write admin saja atau jalankan skrip dengan service account (bypass rules).
