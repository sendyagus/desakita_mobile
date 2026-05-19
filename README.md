# DesaKita — Aplikasi Wisata Desa

Aplikasi Flutter untuk eksplorasi dan booking destinasi wisata desa.

## Arsitektur

| Komponen | Teknologi |
|----------|-----------|
| Autentikasi & data | Firebase Auth + Cloud Firestore |
| Foto profil | Firebase Storage |
| Foto destinasi (admin) | Google Drive → URL di Firestore |

## Menjalankan

```bash
flutter pub get
flutter run -d chrome
```

## Upload foto destinasi (Admin)

1. Login admin (email/password) di Firebase.
2. Buka **Kelola Destinasi** → Tambah/Edit.
3. Klik **Hubungkan Google Drive** → selesaikan login Google.
4. Pilih foto → **Simpan Destinasi**.

OAuth Web Client ID: `lib/config/app_config.dart` dan `web/index.html`.

## Admin

Set `role: "admin"` pada dokumen user di Firestore Console.
