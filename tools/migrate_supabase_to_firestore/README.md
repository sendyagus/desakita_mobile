# Migrasi data Supabase → Firestore

## Prasyarat

1. Export data dari Supabase (Table Editor → Export CSV, atau gunakan SQL `COPY` / API).
2. Service account Firebase: **Project settings → Service accounts → Generate new private key** → simpan sebagai `serviceAccountKey.json` (jangan commit ke git).

## Langkah

```bash
cd tools/migrate_supabase_to_firestore
npm install
```

1. Salin `export.example.json` menjadi `export.json` dan isi dengan array dokumen dari Supabase (sesuaikan field ke camelCase seperti di app).
2. Set env:

```bash
set GOOGLE_APPLICATION_CREDENTIALS=path\to\serviceAccountKey.json
node migrate.mjs
```

Skrip `migrate.mjs` akan menulis ke koleksi `destinations`, `events`, `users`, `bookings`, `reviews` sesuai struktur di `lib/services/`.

**Catatan:** UID di `users` harus cocok dengan UID di Firebase Auth jika user harus bisa login. Untuk data lama, lebih aman membuat user baru di Firebase Auth lalu map manual, atau gunakan [Firebase Auth import](https://firebase.google.com/docs/auth/admin/import-users).
