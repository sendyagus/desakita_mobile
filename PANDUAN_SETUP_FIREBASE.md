# 🚀 PANDUAN SETUP FIREBASE - LANGKAH DEMI LANGKAH

## ✅ STATUS: Aplikasi Sudah Terhubung Firebase!

Aplikasi Anda **SUDAH TERHUBUNG** dengan Firebase. Sekarang tinggal **aktifkan fitur-fiturnya**.

---

## 📋 CHECKLIST SETUP

### ✅ Yang Sudah Selesai:
- [x] Firebase Core sudah terintegrasi
- [x] Firebase Authentication sudah dikonfigurasi
- [x] Cloud Firestore sudah dikonfigurasi
- [x] File `firebase_options.dart` sudah ada
- [x] File `google-services.json` sudah ada (Android)
- [x] Security rules sudah dibuat
- [x] Service & Model sudah dibuat
- [x] UI Login & Register sudah ada
- [x] UI Admin Dashboard sudah ada

### ⚠️ Yang Perlu Anda Lakukan:
- [ ] **Aktifkan Email Authentication** (WAJIB!)
- [ ] Deploy Firestore Security Rules
- [ ] Buat user admin pertama
- [ ] (Opsional) Tambah data destinasi sample

---

## 🔥 LANGKAH 1: AKTIFKAN EMAIL AUTHENTICATION (WAJIB!)

**Kenapa harus diaktifkan?**  
Tanpa ini, registrasi user baru akan gagal dengan error "Email signups are disabled".

### Cara Aktivasi:

1. **Buka Firebase Console**
   - Kunjungi: https://console.firebase.google.com/
   - Login dengan akun Google Anda

2. **Pilih Project**
   - Cari dan klik project: **my-application222-4fe42**

3. **Buka Menu Authentication**
   - Di sidebar kiri, klik **Authentication**
   - Atau klik **Build** → **Authentication**

4. **Buka Tab Sign-in Method**
   - Klik tab **Sign-in method** di bagian atas

5. **Aktifkan Email/Password**
   - Cari **Email/Password** di daftar providers
   - Klik pada baris **Email/Password**
   - Toggle **Enable** menjadi **ON** (warna biru)
   - Klik tombol **Save**

6. **Verifikasi**
   - Pastikan status Email/Password berubah menjadi **Enabled**
   - Sekarang registrasi sudah bisa berfungsi!

---

## 🔐 LANGKAH 2: DEPLOY FIRESTORE SECURITY RULES

**Kenapa harus di-deploy?**  
Agar database Anda aman dan hanya user yang berhak yang bisa akses data.

### Cara Deploy:

#### Opsi A: Via Firebase Console (Mudah)

1. **Buka Firebase Console**
   - https://console.firebase.google.com/
   - Pilih project: **my-application222-4fe42**

2. **Buka Firestore Database**
   - Klik **Firestore Database** di sidebar

3. **Buka Tab Rules**
   - Klik tab **Rules** di bagian atas

4. **Copy-Paste Rules**
   - Buka file `firestore.rules` di project Anda
   - Copy semua isinya
   - Paste ke editor di Firebase Console
   - Klik **Publish**

#### Opsi B: Via Firebase CLI (Otomatis)

```bash
# 1. Install Firebase CLI (jika belum)
npm install -g firebase-tools

# 2. Login ke Firebase
firebase login

# 3. Initialize Firebase (jika belum)
firebase init firestore

# 4. Deploy rules
firebase deploy --only firestore:rules
```

---

## 👤 LANGKAH 3: BUAT USER ADMIN PERTAMA

### Cara 1: Registrasi Normal, Lalu Ubah Role

1. **Jalankan Aplikasi**
   ```bash
   flutter run
   ```

2. **Registrasi User Baru**
   - Buka halaman Register
   - Isi form:
     - Nama: Admin Desa
     - Email: admin@desakita.com
     - No. Telepon: +628123456789
     - Password: admin123
   - Klik **Daftar**

3. **Ubah Role Menjadi Admin**
   - Buka Firebase Console
   - Klik **Firestore Database**
   - Buka collection **users**
   - Cari dokumen dengan email "admin@desakita.com"
   - Klik dokumen tersebut
   - Edit field **role** dari "user" menjadi "admin"
   - Klik **Update**

4. **Login Ulang**
   - Logout dari aplikasi
   - Login dengan email: admin@desakita.com
   - Sekarang akan masuk ke Admin Dashboard!

### Cara 2: Buat Manual di Firebase Console

1. **Buka Firestore Database**
   - Firebase Console → Firestore Database

2. **Buat Collection "users"**
   - Klik **Start collection**
   - Collection ID: `users`
   - Klik **Next**

3. **Tambah Dokumen Admin**
   - Document ID: (biarkan auto-generate atau isi manual)
   - Tambah fields:
     ```
     fullName: "Admin Desa" (string)
     email: "admin@desakita.com" (string)
     phone: "+628123456789" (string)
     avatarUrl: null
     role: "admin" (string)
     isActive: true (boolean)
     createdAt: (timestamp - klik "Add field" → pilih timestamp)
     updatedAt: (timestamp - klik "Add field" → pilih timestamp)
     ```
   - Klik **Save**

4. **Buat User di Authentication**
   - Klik **Authentication** di sidebar
   - Klik **Add user**
   - Email: admin@desakita.com
   - Password: admin123
   - Klik **Add user**
   - **PENTING:** Copy User UID yang muncul

5. **Update Document ID**
   - Kembali ke Firestore Database
   - Hapus dokumen admin yang tadi dibuat
   - Buat lagi dengan Document ID = User UID yang tadi di-copy
   - Isi semua field yang sama
   - Klik **Save**

---

## 📊 LANGKAH 4: TAMBAH DATA DESTINASI SAMPLE (OPSIONAL)

### Via Firebase Console:

1. **Buka Firestore Database**

2. **Buat Collection "destinations"**
   - Klik **Start collection**
   - Collection ID: `destinations`

3. **Tambah Destinasi Pertama**
   ```
   name: "Bukit Sakura" (string)
   category: "Alam" (string)
   location: "Langkapura" (string)
   description: "Pemandangan perbukitan dengan bunga sakura yang indah" (string)
   rating: 4.3 (number)
   price: "Rp 50.000" (string)
   imageUrl: null
   status: true (boolean)
   createdAt: (timestamp - now)
   updatedAt: (timestamp - now)
   ```

4. **Tambah Destinasi Lainnya**
   - Camp 91 Outbound (Alam)
   - Rumah Adat Lampung (Budaya)
   - Warung Kopi Desa (Kuliner)
   - Homestay Desa Wisata (Penginapan)

---

## 🧪 LANGKAH 5: TEST APLIKASI

### Test 1: Registrasi User Baru

1. Jalankan aplikasi: `flutter run`
2. Klik **Daftar**
3. Isi form registrasi
4. Klik **Daftar**
5. **Expected:** Berhasil registrasi dan masuk ke HomeScreen
6. **Cek Firebase Console:** User baru muncul di Authentication & Firestore

### Test 2: Login User

1. Logout dari aplikasi
2. Klik **Masuk**
3. Isi email & password
4. Klik **Masuk**
5. **Expected:** Berhasil login dan masuk ke HomeScreen

### Test 3: Login Admin

1. Logout dari aplikasi
2. Login dengan akun admin
3. **Expected:** Masuk ke Admin Dashboard (bukan HomeScreen)
4. **Cek:** Bisa lihat statistik, kelola user, kelola destinasi

### Test 4: Lihat Destinasi

1. Login sebagai user biasa
2. Klik tab **Explorasi**
3. **Expected:** Muncul list destinasi yang sudah ditambahkan
4. **Cek:** Bisa filter by kategori, bisa search

### Test 5: Booking Destinasi

1. Pilih salah satu destinasi
2. Klik **Pesan Sekarang**
3. Isi form booking (tanggal, jumlah tamu)
4. Klik **Konfirmasi Booking**
5. **Expected:** Booking berhasil dibuat
6. **Cek Firebase Console:** Booking muncul di collection "bookings"

---

## 🐛 TROUBLESHOOTING

### ❌ Error: "Email signups are disabled"
**Penyebab:** Email Authentication belum diaktifkan  
**Solusi:** Ikuti LANGKAH 1 di atas

### ❌ Error: "Permission denied" saat registrasi
**Penyebab:** Firestore Security Rules belum di-deploy  
**Solusi:** Ikuti LANGKAH 2 di atas

### ❌ Error: "User document not found" setelah login
**Penyebab:** Dokumen user tidak dibuat di Firestore  
**Solusi:** 
1. Cek console log untuk error
2. Pastikan AuthService.signUp() berjalan sempurna
3. Cek Firestore Console apakah dokumen user ada

### ❌ Admin tidak masuk ke Admin Dashboard
**Penyebab:** Role user masih "user", bukan "admin"  
**Solusi:** Ubah field "role" di Firestore menjadi "admin"

### ❌ Destinasi tidak muncul di halaman Explorasi
**Penyebab:** Belum ada data destinasi di Firestore  
**Solusi:** Tambah data destinasi manual (LANGKAH 4)

### ❌ Error: "Firebase not initialized"
**Penyebab:** Firebase.initializeApp() belum dipanggil  
**Solusi:** Sudah ada di main.dart, pastikan tidak ada error saat init

---

## 📱 STRUKTUR DATABASE YANG SUDAH SIAP

### Collections:

1. **users** - Data user & admin
   - Otomatis dibuat saat registrasi
   - Field: fullName, email, phone, role, isActive, dll

2. **destinations** - Destinasi wisata
   - Perlu ditambah manual atau via Admin Dashboard
   - Field: name, category, location, rating, price, dll

3. **bookings** - Pemesanan user
   - Otomatis dibuat saat user booking
   - Field: userId, destinationId, checkIn, checkOut, status, dll

4. **reviews** - Review destinasi
   - Belum diimplementasi (coming soon)

5. **favorites** - Favorit user
   - Belum diimplementasi (coming soon)

6. **events** - Event/acara
   - Belum diimplementasi (coming soon)

---

## ✅ CHECKLIST AKHIR

Setelah semua langkah di atas selesai, cek:

- [ ] Email Authentication sudah **Enabled**
- [ ] Firestore Rules sudah di-**deploy**
- [ ] User admin pertama sudah dibuat
- [ ] Bisa registrasi user baru tanpa error
- [ ] Bisa login sebagai user biasa
- [ ] Bisa login sebagai admin
- [ ] Admin bisa akses Admin Dashboard
- [ ] (Opsional) Ada data destinasi sample

---

## 🎉 SELESAI!

Aplikasi Anda sekarang sudah siap digunakan!

**Next Steps:**
1. Tambah lebih banyak destinasi via Admin Dashboard
2. Test booking & payment flow
3. Implementasi fitur reviews & favorites
4. Tambah foto real untuk destinasi
5. Deploy ke Play Store / App Store

---

**Dibuat:** 7 Mei 2026  
**Status:** ✅ Ready to Use  
**Support:** Baca FIREBASE_CONNECTION_STATUS.md untuk detail lengkap
