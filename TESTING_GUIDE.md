# 🧪 Panduan Testing - Integrasi Firebase CRUD

## Persiapan

1. **Pastikan Firebase sudah terkonfigurasi:**
   ```bash
   # Cek apakah file ini ada:
   # - android/app/google-services.json
   # - lib/firebase_options.dart
   ```

2. **Deploy Firestore Rules:**
   ```bash
   firebase deploy --only firestore:rules
   ```

3. **Jalankan aplikasi:**
   ```bash
   flutter run
   ```

---

## 🔐 Test 1: Login sebagai Admin

### Langkah:
1. Buka aplikasi
2. Klik "Lewati" di halaman login (atau login dengan akun admin)
3. **Akun Admin:**
   - Email: `admin@desakita.com`
   - Password: `12345678`
4. Setelah login, akan otomatis masuk ke **Admin Dashboard**

### Expected Result:
✅ Masuk ke halaman Admin Dashboard dengan menu:
- Kelola Pengguna
- Kelola Destinasi Wisata
- Kelola Booking
- Laporan & Statistik

---

## ➕ Test 2: Tambah Destinasi Baru (Admin)

### Langkah:
1. Di Admin Dashboard, klik **"Kelola Destinasi Wisata"**
2. Klik tombol **"Tambah Destinasi"** (floating button hijau)
3. Isi form:
   - **Nama Destinasi:** Air Terjun Pelangi
   - **Lokasi:** Desa Suka Maju
   - **Rating:** 4.5
   - **Harga:** Rp 30.000
   - **Kategori:** Alam
4. Klik **"Simpan"**

### Expected Result:
✅ Muncul snackbar hijau: "Air Terjun Pelangi berhasil ditambahkan"
✅ Destinasi baru langsung muncul di list
✅ **Buka tab "Explorasi"** → destinasi baru juga muncul di sana (real-time sync!)

### Cek di Firebase Console:
1. Buka Firebase Console → Firestore Database
2. Collection `destinations`
3. Cari document dengan nama "Air Terjun Pelangi"
4. ✅ Data tersimpan dengan field: name, category, location, rating, price, status, createdAt, updatedAt

---

## ✏️ Test 3: Edit Destinasi (Admin)

### Langkah:
1. Di halaman "Kelola Destinasi Wisata"
2. Cari destinasi "Air Terjun Pelangi"
3. Klik tombol **edit** (ikon pensil biru)
4. Ubah:
   - **Harga:** Rp 50.000 (dari Rp 30.000)
   - **Rating:** 4.8 (dari 4.5)
5. Klik **"Simpan"**

### Expected Result:
✅ Snackbar: "Air Terjun Pelangi berhasil diperbarui"
✅ Harga dan rating berubah di list admin
✅ **Buka tab "Explorasi"** → harga dan rating juga berubah (real-time!)

---

## 🔄 Test 4: Toggle Status Aktif/Nonaktif (Admin)

### Langkah:
1. Di halaman "Kelola Destinasi Wisata"
2. Cari destinasi "Air Terjun Pelangi"
3. Klik **toggle status** (ikon toggle hijau)
4. Status berubah dari **Aktif** → **Nonaktif**

### Expected Result:
✅ Snackbar: "Status Air Terjun Pelangi diubah"
✅ Status di admin berubah menjadi "Nonaktif" (toggle abu-abu)
✅ **Buka tab "Explorasi"** → destinasi "Air Terjun Pelangi" **HILANG** (karena status=false)

### Test Balik:
1. Klik toggle lagi (Nonaktif → Aktif)
2. ✅ Destinasi muncul kembali di tab Explorasi

---

## 🗑️ Test 5: Hapus Destinasi (Admin)

### Langkah:
1. Di halaman "Kelola Destinasi Wisata"
2. Cari destinasi "Air Terjun Pelangi"
3. Klik tombol **hapus** (ikon tempat sampah merah)
4. Konfirmasi: Klik **"Hapus"**

### Expected Result:
✅ Snackbar merah: "Air Terjun Pelangi dihapus"
✅ Destinasi hilang dari list admin
✅ **Buka tab "Explorasi"** → destinasi juga hilang
✅ **Cek Firebase Console** → document terhapus dari collection `destinations`

---

## 🔍 Test 6: Search Destinasi (Admin)

### Langkah:
1. Di halaman "Kelola Destinasi Wisata"
2. Ketik di search bar: **"Bukit"**

### Expected Result:
✅ Hanya destinasi dengan nama atau lokasi mengandung "Bukit" yang muncul
✅ Counter: "X destinasi ditemukan" (sesuai hasil search)

### Test Lagi:
1. Hapus search → semua destinasi muncul kembali
2. Ketik "Lampung" → destinasi dengan lokasi "Lampung" muncul

---

## 🏷️ Test 7: Filter Kategori (Admin)

### Langkah:
1. Di halaman "Kelola Destinasi Wisata"
2. Klik chip **"Alam"**

### Expected Result:
✅ Hanya destinasi kategori "Alam" yang muncul
✅ Chip "Alam" berwarna hijau (selected)

### Test Kategori Lain:
1. Klik "Budaya" → hanya destinasi budaya
2. Klik "Kuliner" → hanya destinasi kuliner
3. Klik "Penginapan" → hanya destinasi penginapan
4. Klik "Semua" → semua destinasi muncul

---

## 👤 Test 8: View Destinasi sebagai User

### Langkah:
1. **Logout dari admin:**
   - Klik tab "Profil"
   - Klik "Keluar"
2. **Login sebagai user biasa** (atau register akun baru)
3. Masuk ke tab **"Explorasi"**

### Expected Result:
✅ Muncul semua destinasi dengan status=true
✅ Tampilan card dengan:
   - Foto wireframe
   - Rating (badge kiri atas)
   - Nama destinasi
   - Lokasi
   - Kategori
   - Harga

---

## 🔍 Test 9: Search Destinasi (User)

### Langkah:
1. Di tab "Explorasi"
2. Ketik di search bar: **"Sakura"**

### Expected Result:
✅ Hanya destinasi dengan nama/lokasi "Sakura" yang muncul
✅ Jika tidak ada → muncul icon dan text "Destinasi tidak ditemukan"

---

## 🏷️ Test 10: Filter Kategori (User)

### Langkah:
1. Di tab "Explorasi"
2. Klik chip **"Alam"**

### Expected Result:
✅ Hanya destinasi kategori "Alam" yang muncul
✅ Chip "Alam" berwarna hijau (selected)

### Test Kategori Lain:
1. Klik "Budaya" → hanya destinasi budaya
2. Klik "Kuliner" → hanya destinasi kuliner
3. Klik "Penginapan" → hanya destinasi penginapan
4. Klik "Semua" → semua destinasi muncul

---

## 🔄 Test 11: Real-Time Sync (Admin ↔ User)

### Setup:
1. **Device 1:** Login sebagai admin
2. **Device 2:** Login sebagai user (atau gunakan 2 emulator)

### Test Scenario:

#### Scenario A: Admin Tambah Destinasi
1. **Admin (Device 1):** Tambah destinasi baru "Pantai Indah"
2. **User (Device 2):** Buka tab Explorasi
3. ✅ Destinasi "Pantai Indah" **langsung muncul** tanpa refresh

#### Scenario B: Admin Edit Harga
1. **Admin:** Edit harga "Pantai Indah" dari Rp 20.000 → Rp 50.000
2. **User:** Lihat tab Explorasi
3. ✅ Harga **langsung berubah** menjadi Rp 50.000

#### Scenario C: Admin Nonaktifkan Destinasi
1. **Admin:** Toggle status "Pantai Indah" → Nonaktif
2. **User:** Lihat tab Explorasi
3. ✅ Destinasi "Pantai Indah" **langsung hilang**

#### Scenario D: Admin Hapus Destinasi
1. **Admin:** Hapus destinasi "Pantai Indah"
2. **User:** Lihat tab Explorasi
3. ✅ Destinasi **langsung hilang**

---

## 🚨 Test 12: Error Handling

### Test A: Firestore Rules Belum Deploy
1. Jangan deploy Firestore rules
2. Coba tambah destinasi
3. ✅ Muncul snackbar merah: "Gagal menyimpan: [error message]"

### Test B: Internet Mati
1. Matikan internet/WiFi
2. Buka halaman Kelola Destinasi
3. ✅ Muncul loading indicator
4. ✅ Setelah timeout → error message

### Test C: Data Kosong
1. Hapus semua destinasi dari Firestore
2. Buka tab Explorasi
3. ✅ Muncul icon dan text "Destinasi tidak ditemukan"

---

## 📊 Test 13: Loading State

### Langkah:
1. Buka halaman "Kelola Destinasi Wisata"
2. Perhatikan saat pertama kali load

### Expected Result:
✅ Muncul **CircularProgressIndicator** (loading spinner hijau)
✅ Setelah data load → spinner hilang, muncul list destinasi

---

## ✅ Checklist Testing

### Admin CRUD:
- [ ] Tambah destinasi → tersimpan ke Firestore
- [ ] Edit destinasi → ter-update di Firestore
- [ ] Hapus destinasi → terhapus dari Firestore
- [ ] Toggle status → status berubah di Firestore
- [ ] Search destinasi → filter berdasarkan nama/lokasi
- [ ] Filter kategori → filter berdasarkan kategori

### User Explore:
- [ ] Tampil semua destinasi (status=true)
- [ ] Search destinasi → filter berdasarkan nama/lokasi
- [ ] Filter kategori → filter berdasarkan kategori
- [ ] Tampilan card lengkap (rating, lokasi, kategori, harga)

### Real-Time Sync:
- [ ] Admin tambah → user langsung lihat
- [ ] Admin edit → user langsung lihat perubahan
- [ ] Admin nonaktifkan → destinasi hilang dari user
- [ ] Admin hapus → destinasi hilang dari user

### Error Handling:
- [ ] Error message muncul jika gagal
- [ ] Loading state saat fetch data
- [ ] Empty state jika tidak ada data

---

## 🐛 Troubleshooting

### Problem: "Missing or insufficient permissions"
**Solution:**
```bash
firebase deploy --only firestore:rules
```

### Problem: Destinasi tidak muncul di Explore
**Check:**
1. Apakah `status: true`?
2. Apakah user sudah login?
3. Cek Firebase Console → Firestore → `destinations`

### Problem: Perubahan tidak real-time
**Check:**
1. Apakah internet aktif?
2. Restart aplikasi
3. Cek Firebase Console → Firestore → pastikan data berubah

---

## 📝 Test Report Template

```
# Test Report - Firebase CRUD Integration

**Tanggal:** [DD/MM/YYYY]
**Tester:** [Nama]
**Device:** [Android/iOS, Version]

## Test Results:

### Admin CRUD:
- [ ] ✅ Tambah destinasi
- [ ] ✅ Edit destinasi
- [ ] ✅ Hapus destinasi
- [ ] ✅ Toggle status
- [ ] ✅ Search
- [ ] ✅ Filter kategori

### User Explore:
- [ ] ✅ Tampil destinasi
- [ ] ✅ Search
- [ ] ✅ Filter kategori

### Real-Time Sync:
- [ ] ✅ Admin → User sync

### Issues Found:
[Tulis issue jika ada]

### Notes:
[Catatan tambahan]
```

---

**Happy Testing! 🎉**
