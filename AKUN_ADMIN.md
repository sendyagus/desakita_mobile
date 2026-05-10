# 👤 AKUN ADMIN - DESA WISATA

## 🔐 KREDENSIAL ADMIN DEFAULT

Aplikasi akan **otomatis membuat akun admin** saat pertama kali dijalankan.

### Kredensial Login:

```
Email    : admin@desakita.com
Password : 12345678
Role     : admin
```

**PENTING:** 
- Login menggunakan **EMAIL**, bukan username
- Email: `admin@desakita.com`
- Password: `12345678`

---

## 🚀 CARA MENGGUNAKAN

### 1. Jalankan Aplikasi

```bash
flutter run
```

### 2. Tunggu Akun Admin Dibuat

Saat aplikasi pertama kali dijalankan, akan muncul log di console:

```
🔧 Membuat akun admin dengan username: admin
📝 Membuat user di Firebase Auth...
📝 Membuat dokumen di Firestore...
✅ Akun admin berhasil dibuat!

═══════════════════════════════════════
   AKUN ADMIN BERHASIL DIBUAT
═══════════════════════════════════════
   Username : admin
   Email    : admin@desakita.com
   Password : 12345678
   Role     : admin
═══════════════════════════════════════

Silakan login dengan email: admin@desakita.com
```

### 3. Login sebagai Admin

1. Buka aplikasi
2. Di halaman login, masukkan:
   - **Email:** `admin@desakita.com`
   - **Password:** `12345678`
3. Klik **Masuk**
4. Anda akan diarahkan ke **Admin Dashboard**

---

## 🎯 FITUR ADMIN DASHBOARD

Setelah login sebagai admin, Anda bisa:

### ✅ Kelola User
- Lihat semua user terdaftar
- Edit role user (user ↔ admin)
- Aktifkan/nonaktifkan user
- Hapus user

### ✅ Kelola Destinasi Wisata
- Tambah destinasi baru
- Edit destinasi existing
- Hapus destinasi
- Aktifkan/nonaktifkan destinasi

### ✅ Kelola Booking
- Lihat semua booking
- Update status booking
- Filter booking by status

### ✅ Kelola Acara (Coming Soon)
- Tambah event baru
- Edit event
- Hapus event

### ✅ Laporan & Analitik (Coming Soon)
- Statistik user
- Statistik booking
- Pendapatan

---

## 🔄 FLOW LOGIN ADMIN

```
1. User buka aplikasi
   ↓
2. AuthGate cek status login
   ↓
3. Jika belum login → LoginScreen
   ↓
4. User input email & password admin
   ↓
5. AuthService.signIn()
   ↓
6. Firebase Auth verifikasi kredensial
   ↓
7. AuthService ambil profil dari Firestore
   ↓
8. Cek role:
   ├─ role = "admin" → AdminDashboardScreen ✅
   └─ role = "user"  → HomeScreen
```

---

## 🔧 CARA MEMBUAT ADMIN TAMBAHAN

### Opsi 1: Via Registrasi + Edit Manual

1. **Registrasi user baru** via aplikasi
2. **Buka Firebase Console**
   - https://console.firebase.google.com/
   - Pilih project: my-application222-4fe42
3. **Buka Firestore Database**
4. **Buka collection `users`**
5. **Cari user yang ingin dijadikan admin**
6. **Edit field `role`** dari "user" menjadi "admin"
7. **Klik Update**
8. **User tersebut sekarang admin!**

### Opsi 2: Via Script (Programmatic)

Tambahkan kode ini di `main.dart` (setelah Firebase.initializeApp):

```dart
// Buat admin tambahan
await CreateAdmin.createAdminWithUsername(
  username: 'admin2',
  password: 'password123',
  fullName: 'Admin Kedua',
  phone: '+6281234567891',
);
```

Atau panggil langsung:

```dart
await CreateAdmin.createAdminAccount(); // Buat admin default
```

---

## 🔐 KEAMANAN

### Password Default

⚠️ **PENTING:** Password default (`12345678`) hanya untuk development!

**Untuk production:**
1. Ganti password admin setelah login pertama
2. Atau buat admin baru dengan password yang kuat
3. Hapus admin default

### Cara Ganti Password Admin:

**Via Firebase Console:**
1. Buka Firebase Console → Authentication
2. Cari user dengan email `admin@desakita.com`
3. Klik icon edit (pensil)
4. Klik "Reset password"
5. Masukkan password baru
6. Klik "Save"

**Via Aplikasi (Coming Soon):**
- Fitur "Ubah Password" di Profile Admin

---

## 🐛 TROUBLESHOOTING

### ❌ Admin tidak bisa login

**Penyebab:** Email Authentication belum diaktifkan

**Solusi:**
1. Buka Firebase Console
2. Authentication → Sign-in method
3. Enable Email/Password
4. Save

### ❌ Admin masuk ke HomeScreen, bukan AdminDashboard

**Penyebab:** Role di Firestore bukan "admin"

**Solusi:**
1. Buka Firebase Console → Firestore
2. Collection `users` → cari user admin
3. Pastikan field `role` = "admin" (lowercase)
4. Update jika perlu
5. Logout dan login ulang

### ❌ Error "email-already-in-use"

**Penyebab:** Admin sudah dibuat sebelumnya

**Solusi:**
- Ini normal! Admin hanya dibuat sekali
- Langsung login dengan kredensial yang ada
- Email: admin@desakita.com
- Password: 12345678

### ❌ Admin tidak muncul di Firestore

**Penyebab:** Script create admin gagal

**Solusi:**
1. Cek console log untuk error
2. Pastikan Firebase sudah terinisialisasi
3. Pastikan Email Auth sudah diaktifkan
4. Jalankan ulang aplikasi

---

## 📊 STRUKTUR DATA ADMIN

### Di Firebase Authentication:

```
UID: (auto-generated)
Email: admin@desakita.com
Email Verified: false
Display Name: Administrator
Created: (timestamp)
```

### Di Firestore (`users/{userId}`):

```javascript
{
  "fullName": "Administrator",
  "email": "admin@desakita.com",
  "phone": "+6281234567890",
  "avatarUrl": null,
  "role": "admin",        // PENTING!
  "isActive": true,
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

---

## 📝 CATATAN PENTING

1. **Email vs Username:**
   - Firebase Auth menggunakan EMAIL untuk login
   - Username "admin" hanya untuk identifikasi
   - Login harus pakai email: `admin@desakita.com`

2. **Role Detection:**
   - Role dicek dari field `role` di Firestore
   - Bukan dari Firebase Auth custom claims
   - Pastikan field `role` = "admin" (lowercase)

3. **Auto-Creation:**
   - Admin dibuat otomatis saat app pertama kali run
   - Jika sudah ada, tidak akan dibuat lagi
   - Aman untuk dijalankan berkali-kali

4. **Multiple Admins:**
   - Bisa buat banyak admin
   - Setiap admin punya email unik
   - Semua admin punya akses yang sama

---

## 🎉 SELESAI!

Sekarang Anda punya akun admin yang bisa:
- ✅ Login ke Admin Dashboard
- ✅ Kelola user
- ✅ Kelola destinasi
- ✅ Kelola booking
- ✅ Lihat statistik

**Kredensial Admin:**
- Email: `admin@desakita.com`
- Password: `12345678`

**Selamat mengelola aplikasi DesaKita!** 🚀

---

**Dibuat:** 7 Mei 2026  
**Status:** ✅ Akun Admin Siap Digunakan  
**Support:** Baca PANDUAN_SETUP_FIREBASE.md untuk setup lengkap
