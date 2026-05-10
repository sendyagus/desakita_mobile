# Firebase setup (wajib sebelum menjalankan app)

## 1. Buat project Firebase

1. Buka [Firebase Console](https://console.firebase.google.com/)
2. **Add project** → isi nama (mis. `desa-wisata`)
3. Setelah project jadi, klik ikon **Web**, **Android**, dan/atau **iOS** untuk mendaftarkan app (sesuai target build kamu).

## 2. Aktifkan Authentication

1. **Build → Authentication → Get started**
2. Tab **Sign-in method** → aktifkan **Email/Password**

## 3. Buat Cloud Firestore

1. **Build → Firestore Database → Create database**
2. Mode: **Production** (rules sudah disediakan di `firestore.rules` di root repo — salin ke Console **Rules** setelah deploy pertama kali).

## 4. Konfigurasi Flutter (disarankan)

Dari folder project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Pilih project Firebase dan platform yang dipakai. Ini akan **menimpa** `lib/firebase_options.dart` dengan nilai asli.

## 5. Android: `google-services.json`

- Setelah register app Android di Console, unduh `google-services.json`
- Letakkan di: `android/app/google-services.json`

Gradle sudah memakai plugin `com.google.gms.google-services` di `android/settings.gradle.kts` dan `android/app/build.gradle.kts`.

## 6. iOS: `GoogleService-Info.plist`

- Unduh dari Console → letakkan di `ios/Runner/GoogleService-Info.plist`
- Buka Xcode jika perlu untuk sinkronisasi bundle id.

## 7. Firestore Security Rules

Salin isi file [`firestore.rules`](firestore.rules) ke **Firestore → Rules** di Firebase Console, lalu **Publish**.

## 8. (Opsional) Data awal

- Jalankan skrip seed: `tools/seed_firestore/README.md`
- Atau migrasi dari Supabase: `tools/migrate_supabase_to_firestore/README.md`

## Catatan admin

- User pertama biasanya `role: user`. Untuk menjadikan admin, di Console Firestore edit dokumen `users/{uid}` → field `role` = `admin`.
