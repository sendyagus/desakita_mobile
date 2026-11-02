# 📸 Panduan Upload Foto Profil

## 🎯 Untuk User Biasa

### Langkah-langkah Upload Foto:

1. **Login ke Aplikasi**
   - Gunakan email dan password Anda
   - Atau gunakan "Lewati" untuk guest mode (tidak bisa upload foto)

2. **Buka Halaman Profil**
   - Tap icon **Profil** di bottom navigation (icon paling kanan)
   - Atau dari menu hamburger pilih "Profil"

3. **Upload Foto**
   ```
   ┌─────────────────────┐
   │                     │
   │    ┌─────────┐      │
   │    │  [📷]   │      │  ← Klik icon kamera ini
   │    │ Avatar  │      │
   │    └─────────┘      │
   │                     │
   │   Nama Lengkap      │
   │   email@user.com    │
   └─────────────────────┘
   ```
   - Klik **icon kamera** di pojok kanan bawah avatar
   - Pilih foto dari galeri HP Anda
   - Tunggu proses upload (loading muncul)
   - Foto baru akan langsung tampil
   - Notifikasi "Foto profil berhasil diperbarui" muncul

4. **Cek Hasil**
   - Foto Anda sekarang tampil di halaman profil
   - Foto tersimpan di database Firebase
   - Logout dan login lagi, foto masih ada

---

## 👨‍💼 Untuk Admin

### Langkah-langkah Upload Foto Admin:

1. **Login sebagai Admin**
   - Email: `admin@desakita.com`
   - Password: `12345678`

2. **Lihat Dashboard Admin**
   - Setelah login, langsung masuk ke Dashboard Admin
   - Header menampilkan nama dan email admin dari database
   ```
   ┌──────────────────────────────────────┐
   │ [Foto]  Nama Admin          🔔  🚪   │
   │         admin@desakita.com           │
   └──────────────────────────────────────┘
   ```

3. **Upload Foto Admin**
   - Buka halaman **Profil** (dari menu atau navigasi)
   - Klik **icon kamera** di avatar
   - Pilih foto dari galeri
   - Tunggu upload selesai
   - Foto akan tampil di:
     * Halaman profil
     * Header dashboard admin

4. **Verifikasi**
   - Kembali ke Dashboard Admin
   - Foto dan nama admin sekarang tampil di header
   - Refresh halaman, data masih tersimpan

---

## 📋 Informasi Penting

### Format Foto yang Didukung:
- ✅ JPG / JPEG
- ✅ PNG
- ✅ WebP
- ✅ Ukuran maksimal: Otomatis dikompres ke 1920x1080
- ✅ Kualitas: 85% (balance antara ukuran & kualitas)

### Lokasi Penyimpanan:
- **Firebase Storage**: `/users/{userId}/timestamp_filename.jpg`
- **Firestore**: URL foto disimpan di field `avatarUrl`

### Keamanan:
- ✅ Hanya user yang login bisa upload foto
- ✅ User hanya bisa upload foto untuk akun mereka sendiri
- ✅ Foto lama tidak otomatis terhapus (hemat history)

---

## ❓ Troubleshooting

### Foto tidak muncul setelah upload:
1. Cek koneksi internet Anda
2. Tunggu beberapa detik, mungkin masih loading
3. Refresh halaman (pull down)
4. Logout dan login lagi

### Upload gagal:
1. Cek koneksi internet
2. Cek ukuran foto tidak terlalu besar (>10MB)
3. Coba foto lain
4. Pastikan sudah login

### Nama tidak tampil:
1. Pastikan sudah login
2. Cek data profil sudah lengkap saat registrasi
3. Logout dan login lagi

### Error "Permission Denied":
1. Pastikan Firestore Rules sudah di-deploy
2. Pastikan Firebase Storage Rules sudah di-deploy
3. Hubungi developer untuk cek konfigurasi

---

## 🎨 Tips Foto Profil yang Bagus

### Untuk User:
- ✅ Gunakan foto wajah yang jelas
- ✅ Background yang bersih
- ✅ Pencahayaan yang baik
- ✅ Foto terbaru (bukan foto lama)
- ✅ Ukuran file tidak terlalu besar

### Untuk Admin:
- ✅ Foto profesional
- ✅ Wajah terlihat jelas
- ✅ Background netral
- ✅ Representatif untuk admin

---

## 📱 Tampilan Sebelum & Sesudah

### Sebelum Upload:
```
┌─────────────┐
│   [👤]      │  ← Icon default
│             │
│ Nama User   │
│ email@...   │
└─────────────┘
```

### Sesudah Upload:
```
┌─────────────┐
│   [📷]      │  ← Foto user
│             │
│ Nama User   │
│ email@...   │
└─────────────┘
```

---

## 🔄 Update Foto

### Cara Ganti Foto:
1. Buka halaman Profil
2. Klik icon kamera lagi
3. Pilih foto baru
4. Foto lama akan diganti dengan foto baru
5. URL baru disimpan ke database

### Foto Lama:
- Foto lama masih tersimpan di Firebase Storage
- Tidak otomatis terhapus (untuk history/backup)
- Bisa dihapus manual dari Firebase Console jika perlu

---

## 📞 Bantuan

Jika masih ada masalah:
1. Cek dokumentasi lengkap di `PROFILE_PHOTO_UPDATE.md`
2. Cek Firebase Console untuk logs
3. Hubungi developer/admin sistem

---

**Status**: ✅ Fitur Aktif & Siap Digunakan
**Last Updated**: 2024
