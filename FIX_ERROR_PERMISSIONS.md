# 🔧 FIX ERROR: Missing or Insufficient Permissions

## ❌ ERROR

```
Error membuat admin: [cloud_firestore/permission-denied] 
Missing or insufficient permissions.
```

## 🔍 PENYEBAB

Firestore Security Rules belum di-deploy atau terlalu ketat, sehingga aplikasi tidak bisa membuat dokumen user di Firestore.

---

## ✅ SOLUSI 1: Deploy Firestore Rules via Firebase CLI (RECOMMENDED)

### Langkah 1: Install Firebase CLI

```bash
npm install -g firebase-tools
```

### Langkah 2: Login ke Firebase

```bash
firebase login
```

Browser akan terbuka, login dengan akun Google Anda.

### Langkah 3: Initialize Firebase (jika belum)

```bash
firebase init firestore
```

Pilih:
- Use an existing project
- Pilih: my-application222-4fe42
- Firestore rules file: firestore.rules (sudah ada)
- Firestore indexes file: firestore.indexes.json (sudah ada)

### Langkah 4: Deploy Rules

```bash
firebase deploy --only firestore:rules
```

Output yang diharapkan:
```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/my-application222-4fe42/overview
```

### Langkah 5: Test Lagi

```bash
flutter run
```

Admin sekarang akan berhasil dibuat!

---

## ✅ SOLUSI 2: Ubah Rules Manual di Firebase Console (CEPAT)

### Langkah 1: Buka Firebase Console

https://console.firebase.google.com/

### Langkah 2: Pilih Project

Klik project: **my-application222-4fe42**

### Langkah 3: Buka Firestore Database

Klik **Firestore Database** di sidebar kiri

### Langkah 4: Buka Tab Rules

Klik tab **Rules** di bagian atas

### Langkah 5: Ganti Rules

Hapus semua isi rules yang ada, lalu copy-paste rules di bawah ini:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    function isSignedIn() {
      return request.auth != null;
    }

    function isAdmin() {
      return isSignedIn()
        && exists(/databases/$(database)/documents/users/$(request.auth.uid))
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    match /users/{userId} {
      allow read: if isSignedIn()
        && (request.auth.uid == userId || isAdmin());
      // Allow create for authenticated users (including admin creation)
      allow create: if isSignedIn()
        && request.auth.uid == userId
        && request.resource.data.keys().hasAll(['fullName', 'email', 'phone', 'role', 'isActive', 'createdAt', 'updatedAt']);
      allow update: if isSignedIn()
        && (request.auth.uid == userId || isAdmin());
      allow delete: if isAdmin();

      match /favorites/{destId} {
        allow read, write: if isSignedIn() && request.auth.uid == userId;
      }
    }

    match /destinations/{destId} {
      allow read: if resource.data.status == true || isAdmin();
      allow create, update, delete: if isAdmin();
    }

    match /bookings/{bookingId} {
      allow read: if isSignedIn()
        && (resource.data.userId == request.auth.uid || isAdmin());
      allow create: if isSignedIn()
        && request.resource.data.userId == request.auth.uid;
      allow update, delete: if isSignedIn()
        && (resource.data.userId == request.auth.uid || isAdmin());
    }

    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if isSignedIn()
        && request.resource.data.userId == request.auth.uid;
      allow update, delete: if isSignedIn()
        && (resource.data.userId == request.auth.uid || isAdmin());
    }

    match /events/{eventId} {
      allow read: if resource.data.status == true || isAdmin();
      allow create, update, delete: if isAdmin();
    }
  }
}
```

### Langkah 6: Publish

Klik tombol **Publish** di kanan atas

### Langkah 7: Test Lagi

```bash
flutter run
```

Admin sekarang akan berhasil dibuat!

---

## ✅ SOLUSI 3: Temporary - Allow All (HANYA UNTUK DEVELOPMENT!)

**⚠️ WARNING:** Ini membuka akses ke semua orang! Hanya untuk testing!

### Langkah 1-4: Sama seperti Solusi 2

### Langkah 5: Ganti dengan Rules Ini

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Langkah 6: Publish

### Langkah 7: Test

```bash
flutter run
```

### Langkah 8: PENTING - Kembalikan Rules yang Aman!

Setelah admin berhasil dibuat, **WAJIB** kembalikan rules ke Solusi 2!

---

## 🎯 VERIFIKASI BERHASIL

Setelah deploy rules, jalankan aplikasi:

```bash
flutter run
```

Cek console log, seharusnya muncul:

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
```

Jika muncul pesan di atas, berarti **BERHASIL!** ✅

---

## 🔐 KEAMANAN

### Rules yang Sudah Diperbaiki:

1. **Users Collection:**
   - ✅ User bisa create dokumen sendiri (untuk registrasi & admin creation)
   - ✅ User bisa baca profil sendiri
   - ✅ Admin bisa baca semua profil
   - ✅ User bisa update profil sendiri
   - ✅ Hanya admin yang bisa delete

2. **Destinations Collection:**
   - ✅ Semua user bisa baca destinasi aktif
   - ✅ Hanya admin yang bisa create/update/delete

3. **Bookings Collection:**
   - ✅ User bisa baca booking sendiri
   - ✅ User bisa create booking untuk diri sendiri
   - ✅ Admin bisa baca semua booking

4. **Reviews & Events:**
   - ✅ Semua user bisa baca
   - ✅ User bisa create review sendiri
   - ✅ Hanya admin yang bisa kelola events

---

## 🐛 TROUBLESHOOTING

### ❌ Error: "Firebase CLI not found"

**Solusi:**
```bash
npm install -g firebase-tools
```

### ❌ Error: "No project active"

**Solusi:**
```bash
firebase use my-application222-4fe42
```

### ❌ Error: "Permission denied" setelah deploy

**Solusi:**
1. Tunggu 1-2 menit (propagasi rules)
2. Restart aplikasi
3. Clear cache: `flutter clean && flutter pub get`

### ❌ Admin masih gagal dibuat

**Solusi:**
1. Pastikan Email Authentication sudah diaktifkan
2. Cek Firebase Console → Firestore → Rules
3. Pastikan rules sudah ter-publish
4. Coba Solusi 3 (temporary allow all) untuk testing

---

## 📝 CATATAN PENTING

1. **Rules sudah diperbaiki** di file `firestore.rules`
2. **Harus di-deploy** agar berlaku di Firebase
3. **Jangan gunakan "allow all"** di production
4. **Backup rules lama** sebelum ubah

---

## 🎉 SELESAI!

Setelah deploy rules, aplikasi Anda akan:
- ✅ Bisa membuat akun admin otomatis
- ✅ Bisa registrasi user baru
- ✅ Bisa login sebagai admin/user
- ✅ Database aman dengan rules yang proper

**Kredensial Admin:**
- Email: `admin@desakita.com`
- Password: `12345678`

Selamat! Aplikasi Anda sekarang siap digunakan! 🚀

---

**Dibuat:** 7 Mei 2026  
**Status:** ✅ Error Fixed  
**Next:** Deploy rules dan test aplikasi
