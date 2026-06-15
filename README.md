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

# Setup env (sekali saja, jika env.json belum ada)
copy env.example.json env.json
# Edit env.json → isi GEMINI_API_KEY

# Jalankan dengan secrets dari env.json (tidak masuk Git)
flutter run --dart-define-from-file=env.json
```

Di **VS Code / Cursor**, pilih launch config **"DesaKita (env.json)"** — sudah dikonfigurasi otomatis.

## Gemini AI (Agent Kita) — keamanan API key

| File | Di-commit ke Git? | Isi |
|------|-------------------|-----|
| `env.example.json` | ✅ Ya (template) | Placeholder saja |
| `env.json` | ❌ **Tidak** (.gitignore) | API key asli Anda |

**Aturan:**
- Jangan taruh API key di file `.dart` yang di-commit
- Jangan commit `env.json`
- Jangan kirim API key lewat chat, screenshot, atau issue GitHub

Buat/revoke key: [Google AI Studio → API Keys](https://aistudio.google.com/apikey)

Key Gemini biasanya diawali `AIzaSy...`. Jika key Anda format lain, pastikan memang **API key Gemini**, bukan token OAuth.

## Upload foto destinasi (Admin)

1. Login admin (email/password) di Firebase.
2. Buka **Kelola Destinasi** → Tambah/Edit.
3. Klik **Hubungkan Google Drive** → selesaikan login Google.
4. Pilih foto → **Simpan Destinasi**.

OAuth Web Client ID: `lib/config/app_config.dart` dan `web/index.html`.

## Admin

Set `role: "admin"` pada dokumen user di Firestore Console.
