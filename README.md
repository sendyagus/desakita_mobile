# 🌿 DesaKita — Aplikasi Wisata Desa

> Jelajahi, booking, dan nikmati keindahan destinasi wisata desa — semua dalam satu aplikasi.

Aplikasi Flutter lintas platform untuk eksplorasi destinasi wisata desa, dilengkapi **AI Assistant** berbasis Groq LLM, fitur booking, dan panel admin lengkap.

---

## 📱 Fitur Utama

### Untuk Pengguna
| Fitur | Deskripsi |
|-------|-----------|
| 🗺️ **Jelajahi Destinasi** | Browse destinasi wisata desa dengan foto, detail, dan ulasan |
| 🔍 **Pencarian & Filter** | Cari berdasarkan nama, kategori, atau lokasi |
| 📅 **Booking** | Reservasi kunjungan langsung dari aplikasi |
| 🤖 **AI Assistant "Kita"** | Tanya rekomendasi wisata via chat teks atau suara (STT/TTS Bahasa Indonesia) |
| 🎭 **Acara & Event** | Lihat jadwal event budaya dan kegiatan desa |
| ❤️ **Favorit** | Simpan destinasi favorit |
| 🔔 **Notifikasi** | Informasi status booking dan update terbaru |
| 👤 **Profil** | Kelola akun dan foto profil |

### Untuk Admin
| Fitur | Deskripsi |
|-------|-----------|
| 📊 **Dashboard** | Statistik kunjungan, booking, dan pendapatan |
| 🏡 **Kelola Destinasi** | Tambah, edit, hapus destinasi wisata |
| 📸 **Upload Foto via Google Drive** | Hubungkan Google Drive untuk upload foto destinasi |
| 🎪 **Kelola Event** | Manajemen acara dan kegiatan desa |
| 📋 **Manajemen Booking** | Terima, tolak, atau selesaikan booking pengguna |
| 📈 **Analitik Booking** | Laporan performa dan ekspor PDF |
| 👥 **Manajemen Pengguna** | Kelola akun dan role pengguna |
| 🛠️ **Admin Tools** | Utilitas tambahan untuk administrator |

---

## 🏗️ Arsitektur

```
lib/
├── app/            # App-level configuration & assets
├── config/         # App config (OAuth client ID, dll.)
├── features/       # Fitur mandiri (agent AI, dll.)
│   └── agent/      # AI chat agent
├── models/         # Data model
├── screens/        # Layar UI
│   ├── admin/      # Layar khusus admin (10 screen)
│   └── user/       # Layar pengguna biasa
├── services/       # Business logic & API calls
├── utils/          # Helper & utilities
└── widgets/        # Shared widget components
```

### Stack Teknologi

| Komponen | Teknologi |
|----------|-----------|
| Framework | Flutter (Dart SDK ^3.11.1) |
| Autentikasi | Firebase Auth (email/password + Google Sign-In) |
| Database | Cloud Firestore |
| Penyimpanan foto profil | Firebase Storage |
| Foto destinasi | Google Drive → URL disimpan di Firestore |
| AI Assistant | Groq LLM API (via `groq_service.dart`) |
| Speech-to-Text | `speech_to_text` (mobile) + Web Speech API (web) |
| Text-to-Speech | `flutter_tts` — suara Bahasa Indonesia |
| Grafik & laporan | `fl_chart` + `pdf` + `printing` |

---

## ⚡ Memulai

### Prasyarat

- Flutter SDK (sesuai `.metadata`)
- Dart SDK `^3.11.1`
- Akun Firebase (project sudah dikonfigurasi di `google-services.json` / `firebase_options.dart`)
- Akun [Groq](https://console.groq.com/) untuk API key AI

### Instalasi

```bash
# 1. Clone repositori
git clone <url-repo>
cd desakita_mobile

# 2. Install dependensi
flutter pub get

# 3. Setup environment (sekali saja)
copy env.example.json env.json
# Buka env.json dan isi GROQ_API_KEY Anda
```

### Konfigurasi `env.json`

```json
{
  "GROQ_API_KEY": "gsk_xxxxxxxxxxxxxxxxxxxx"
}
```

> **⚠️ Penting:** `env.json` **tidak boleh** di-commit ke Git. File ini sudah masuk `.gitignore`.

### Menjalankan Aplikasi

```bash
# Jalankan dengan environment dari env.json
flutter run --dart-define-from-file=env.json
```

**Di VS Code / Cursor:** Pilih launch config **"DesaKita (env.json)"** — sudah dikonfigurasi otomatis di `.vscode/`.

---

## 🔐 Keamanan API Key

| File | Di-commit ke Git? | Isi |
|------|:-----------------:|-----|
| `env.example.json` | ✅ Ya (template) | Placeholder — tidak ada key asli |
| `env.json` | ❌ **Tidak** (.gitignore) | API key Groq asli Anda |

**Aturan wajib:**
- ❌ Jangan taruh API key di file `.dart` yang di-commit
- ❌ Jangan commit `env.json`
- ❌ Jangan kirim API key lewat chat, screenshot, atau GitHub issue

Buat / revoke Groq API key: [console.groq.com](https://console.groq.com/keys)

---

## 🤖 AI Assistant "Kita"

Asisten virtual bernama **Kita** menggunakan Groq LLM untuk menjawab pertanyaan seputar wisata desa secara kontekstual (data destinasi & event diambil langsung dari Firestore).

**Kemampuan:**
- 💬 Chat teks dengan riwayat percakapan (multi-turn)
- 🎤 Input suara (Speech-to-Text) dalam Bahasa Indonesia
- 🔊 Baca-ulang jawaban (Text-to-Speech) dengan suara natural `id-ID`
- 📍 Konteks otomatis dari data destinasi & event di database

**Platform speech:**
- **Mobile (Android/iOS):** `speech_to_text` package + izin mikrofon
- **Web:** Web Speech API bawaan browser (Chrome, Edge, Safari)

---

## 📸 Upload Foto Destinasi (Admin)

Foto destinasi dikelola via Google Drive, URL-nya disimpan di Firestore.

1. Login sebagai admin di aplikasi.
2. Buka **Kelola Destinasi** → Tambah / Edit destinasi.
3. Ketuk **Hubungkan Google Drive** → selesaikan alur login Google.
4. Pilih foto dari Drive → **Simpan Destinasi**.

**Konfigurasi OAuth:**
- Web Client ID diatur di `lib/config/app_config.dart` dan `web/index.html`.

---

## 👑 Akses Admin

Untuk memberikan akses admin kepada pengguna:

1. Buka [Firebase Console](https://console.firebase.google.com/) → Firestore Database.
2. Navigasi ke koleksi `users` → dokumen pengguna yang dituju.
3. Set field `role` menjadi `"admin"`.

Pengguna tersebut akan langsung mendapat akses panel admin setelah login ulang.

---

## 🔒 Firestore Security Rules

Akses data dikendalikan oleh Firestore Rules (`firestore.rules`):

| Koleksi | Pengguna | Admin |
|---------|----------|-------|
| `users` | Baca & edit profil sendiri | Akses penuh |
| `users/{id}/favorites` | Baca & tulis favorit sendiri | — |
| `destinations` | Baca destinasi aktif saja | CRUD penuh |
| `bookings` | Baca & kelola booking sendiri | Akses penuh |
| `reviews` | Baca semua, tulis milik sendiri | Edit & hapus semua |
| `events` | Baca event aktif saja | CRUD penuh |

---

## 📦 Dependensi Utama

| Package | Versi | Kegunaan |
|---------|-------|----------|
| `firebase_core` | ^3.8.1 | Firebase core |
| `firebase_auth` | ^5.3.4 | Autentikasi |
| `cloud_firestore` | ^5.5.1 | Database realtime |
| `firebase_storage` | ^12.3.6 | Penyimpanan foto profil |
| `google_sign_in` | ^6.2.1 | Login dengan Google |
| `googleapis` | ^13.2.0 | Google Drive API |
| `speech_to_text` | ^7.4.0 | Input suara (mobile) |
| `flutter_tts` | ^4.2.5 | Text-to-speech |
| `fl_chart` | ^0.69.2 | Grafik statistik |
| `pdf` + `printing` | ^3 / ^5 | Ekspor laporan PDF |
| `google_fonts` | ^6.2.1 | Tipografi |
| `image_picker` | ^1.1.2 | Pilih foto dari galeri |
| `shared_preferences` | ^2.3.3 | Penyimpanan lokal |
| `intl` | ^0.20.2 | Format tanggal & angka |

---

## 🗂️ Struktur Layar

```
screens/
├── opening_screen.dart          # Splash screen
├── onboarding_screen.dart       # Onboarding awal
├── login_screen.dart            # Login
├── register_screen.dart         # Registrasi
├── home_screen.dart             # Halaman utama
├── explore_screen.dart          # Jelajahi destinasi
├── destination_detail_screen.dart  # Detail destinasi
├── booking_screen.dart          # Form booking
├── agent_screen.dart            # AI Chat Assistant
├── notification_screen.dart     # Notifikasi
├── profile_screen.dart          # Profil pengguna
└── admin/
    ├── admin_dashboard_screen.dart       # Dashboard admin
    ├── destination_management_screen.dart # Kelola destinasi
    ├── destination_form_screen.dart       # Form tambah/edit destinasi
    ├── booking_management_screen.dart     # Manajemen booking
    ├── booking_analytics_screen.dart      # Analitik booking
    ├── event_management_screen.dart       # Kelola event
    ├── event_form_screen.dart             # Form tambah/edit event
    ├── user_management_screen.dart        # Kelola pengguna
    ├── admin_tools_screen.dart            # Tools admin
    └── admin_wisata_screen.dart           # Overview wisata
```

---

## 🚀 Build & Deploy

```bash
# Android APK (debug)
flutter build apk --dart-define-from-file=env.json

# Android APK (release)
flutter build apk --release --dart-define-from-file=env.json

# Android App Bundle (untuk Play Store)
flutter build appbundle --dart-define-from-file=env.json

# iOS (membutuhkan macOS & Xcode)
flutter build ios --dart-define-from-file=env.json

# Web
flutter build web --dart-define-from-file=env.json
```

---

## 🤝 Kontribusi

1. Fork repositori ini
2. Buat branch fitur: `git checkout -b feature/nama-fitur`
3. Commit perubahan: `git commit -m 'feat: tambah fitur X'`
4. Push branch: `git push origin feature/nama-fitur`
5. Buka Pull Request

---

*DesaKita — Menghubungkan wisatawan dengan keindahan desa Indonesia 🌾*
