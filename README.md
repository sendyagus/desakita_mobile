# 🏞️ DesaKita - Aplikasi Wisata Desa

Aplikasi mobile untuk eksplorasi dan booking destinasi wisata desa di Indonesia.

## ✨ Status Project

**Backend:** Firebase (Authentication + Cloud Firestore). Lihat **[FIREBASE_SETUP.md](FIREBASE_SETUP.md)**.

## 🚀 Quick Start (5 Menit)

### Bahasa Indonesia
👉 **Baca: [MULAI_DISINI.md](MULAI_DISINI.md)**

### English
👉 **Read: [START_HERE.md](START_HERE.md)**

## 📚 Dokumentasi Lengkap

### 🎯 Untuk Pemula
| File | Deskripsi | Waktu Baca |
|------|-----------|------------|
| **[MULAI_DISINI.md](MULAI_DISINI.md)** | Panduan setup cepat (Bahasa Indonesia) | 5 menit |
| **[START_HERE.md](START_HERE.md)** | Complete setup guide (English) | 5 menit |
| **[CHECKLIST_SETUP.md](CHECKLIST_SETUP.md)** | Setup checklist lengkap | 10 menit |

### 📖 Panduan Detail
| File | Deskripsi | Waktu Baca |
|------|-----------|------------|
| **[PANDUAN_SETUP_LENGKAP.md](PANDUAN_SETUP_LENGKAP.md)** | Setup detail + troubleshooting | 20 menit |
| **[QUICK_TEST_GUIDE.md](QUICK_TEST_GUIDE.md)** | Test scenarios lengkap | 15 menit |
| **[FAQ.md](FAQ.md)** | Frequently Asked Questions | 15 menit |

### 🏗️ Arsitektur & Teknis
| File | Deskripsi | Waktu Baca |
|------|-----------|------------|
| **[ARCHITECTURE_FLOW.md](ARCHITECTURE_FLOW.md)** | Diagram arsitektur & flow | 20 menit |
| **[VISUAL_GUIDE.md](VISUAL_GUIDE.md)** | Visual diagrams | 15 menit |
| **[README_DOKUMENTASI.md](README_DOKUMENTASI.md)** | Overview dokumentasi | 10 menit |

### 📊 Referensi
| File | Deskripsi | Kapan Digunakan |
|------|-----------|-----------------|
| **[INDEX_DOKUMENTASI.md](INDEX_DOKUMENTASI.md)** | Index semua dokumentasi | Cari file tertentu |
| **[RINGKASAN_PERBAIKAN.md](RINGKASAN_PERBAIKAN.md)** | Ringkasan perbaikan | Review perubahan |

### 🗄️ SQL Scripts
| File | Deskripsi | Kapan Digunakan |
|------|-----------|-----------------|
| **[supabase_setup.sql](supabase_setup.sql)** | Setup database lengkap | Setup awal (wajib) |
| **[verify_and_fix.sql](verify_and_fix.sql)** | Verifikasi & auto-fix | Jika ada masalah |
| **[useful_queries.sql](useful_queries.sql)** | 30+ query berguna | Debugging & monitoring |

## 🎯 Fitur Aplikasi

### ✅ User Features
- Register & Login
- Browse destinasi wisata
- Filter & Search
- Booking destinasi
- Review & Rating
- Favorit
- Chat Bot (Agent)
- Profile management

### ✅ Admin Features
- Dashboard admin
- User management (CRUD)
- Destination management (CRUD)
- Booking management
- Statistics & monitoring

## 🛠️ Tech Stack

- **Frontend:** Flutter 3.x
- **Backend:** Firebase Auth + Cloud Firestore
- **State Management:** StatefulWidget (simple)
- **UI:** Material Design 3
- **Fonts:** Google Fonts (Poppins)

## 📱 Screenshots

> Wireframe placeholders - Tambahkan screenshot setelah testing

## 🔧 Setup

### Prerequisites
- Flutter SDK (latest stable)
- Android Studio / VS Code
- Android Emulator atau Physical Device
- Akun Supabase (gratis)

### Installation

1. **Clone repository**
```bash
git clone <repository-url>
cd desa_wisata
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Setup database**
- Buka [Supabase Dashboard](https://supabase.com/dashboard)
- Pilih project: `hcgvxwmvzohbcsyqfgbz`
- SQL Editor → New Query
- Copy-paste isi `supabase_setup.sql`
- Run

4. **Nonaktifkan email confirmation** (untuk testing)
- Dashboard → Authentication → Providers → Email
- Toggle OFF: "Confirm email"
- Save

5. **Run app**
```bash
flutter run
```

## 🧪 Testing

Baca: **[QUICK_TEST_GUIDE.md](QUICK_TEST_GUIDE.md)**

Test credentials:
```
Email: test@example.com
Password: password123
```

## 📞 Support

**Ada masalah?**
1. Cek console log
2. Baca [FAQ.md](FAQ.md)
3. Jalankan `verify_and_fix.sql`
4. Baca [PANDUAN_SETUP_LENGKAP.md](PANDUAN_SETUP_LENGKAP.md)

## 🤝 Contributing

Contributions are welcome! Please read the documentation first.

## 📄 License

[Your License Here]

## 👥 Team

- Developer: [Your Name]
- Project: DesaKita App
- Year: 2026

## 🎉 Acknowledgments

- Flutter Team
- Supabase Team
- Google Fonts

---

**Last Updated:** 2026-05-06  
**Version:** 1.0  
**Status:** ✅ Production Ready

---

## 🔗 Quick Links

- **Supabase Dashboard:** https://supabase.com/dashboard
- **Project URL:** https://hcgvxwmvzohbcsyqfgbz.supabase.co
- **Flutter Docs:** https://flutter.dev/docs
- **Supabase Docs:** https://supabase.com/docs

---

**🎯 MULAI SEKARANG:** Baca [MULAI_DISINI.md](MULAI_DISINI.md) atau [START_HERE.md](START_HERE.md)
