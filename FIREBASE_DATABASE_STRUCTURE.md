# 🔥 Firebase Database Structure - DesaKita App

## ✅ STATUS: Aplikasi SUDAH Terhubung dengan Firebase!

Aplikasi Anda sudah menggunakan:
- ✅ **Firebase Authentication** - untuk login/register
- ✅ **Cloud Firestore** - untuk database
- ✅ **Firebase Core** - sudah terintegrasi

---

## 📊 Struktur Database Firestore

### 1. Collection: `users`

**Path:** `/users/{userId}`

**Schema:**
```javascript
{
  "fullName": "string",      // Nama lengkap user
  "email": "string",          // Email user
  "phone": "string",          // Nomor telepon (+62xxx)
  "avatarUrl": "string|null", // URL foto profil
  "role": "string",           // "user" atau "admin"
  "isActive": "boolean",      // Status aktif/nonaktif
  "createdAt": "timestamp",   // Waktu dibuat
  "updatedAt": "timestamp"    // Waktu update terakhir
}
```

**Example Document:**
```javascript
// Document ID: "abc123xyz" (auto dari Firebase Auth UID)
{
  "fullName": "Budi Santoso",
  "email": "budi@example.com",
  "phone": "+62812345678",
  "avatarUrl": null,
  "role": "user",
  "isActive": true,
  "createdAt": Timestamp(2026, 5, 6, 10, 30, 0),
  "updatedAt": Timestamp(2026, 5, 6, 10, 30, 0)
}
```

**Indexes:**
- `email` (untuk query by email)
- `role` (untuk filter admin/user)
- `createdAt` (untuk sorting)

---

### 2. Collection: `destinations`

**Path:** `/destinations/{destinationId}`

**Schema:**
```javascript
{
  "name": "string",           // Nama destinasi
  "category": "string",       // "Alam", "Budaya", "Kuliner", "Penginapan"
  "location": "string",       // Lokasi destinasi
  "description": "string",    // Deskripsi lengkap
  "rating": "number",         // Rating 0.0 - 5.0
  "price": "string",          // Harga (format: "Rp 50.000")
  "imageUrl": "string|null",  // URL gambar
  "status": "boolean",        // Aktif/nonaktif
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Example Document:**
```javascript
// Document ID: auto-generated
{
  "name": "Bukit Sakura",
  "category": "Alam",
  "location": "Langkapura",
  "description": "Pemandangan perbukitan dengan bunga sakura.",
  "rating": 4.3,
  "price": "Rp 50.000",
  "imageUrl": null,
  "status": true,
  "createdAt": Timestamp(2026, 5, 6, 10, 0, 0),
  "updatedAt": Timestamp(2026, 5, 6, 10, 0, 0)
}
```

**Indexes:**
- `category` (untuk filter by kategori)
- `status` (untuk filter aktif/nonaktif)
- `rating` (untuk sorting)

---

### 3. Collection: `bookings`

**Path:** `/bookings/{bookingId}`

**Schema:**
```javascript
{
  "userId": "string",         // Reference ke user ID
  "destinationId": "string",  // Reference ke destination ID
  "destinationName": "string",// Snapshot nama destinasi
  "checkIn": "timestamp",     // Tanggal check-in
  "checkOut": "timestamp",    // Tanggal check-out
  "guestCount": "number",     // Jumlah tamu
  "totalPrice": "string",     // Total harga
  "status": "string",         // "pending", "confirmed", "cancelled", "completed"
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Example Document:**
```javascript
{
  "userId": "abc123xyz",
  "destinationId": "dest001",
  "destinationName": "Bukit Sakura",
  "checkIn": Timestamp(2026, 6, 1, 0, 0, 0),
  "checkOut": Timestamp(2026, 6, 3, 0, 0, 0),
  "guestCount": 2,
  "totalPrice": "Rp 100.000",
  "status": "pending",
  "createdAt": Timestamp(2026, 5, 6, 10, 0, 0),
  "updatedAt": Timestamp(2026, 5, 6, 10, 0, 0)
}
```

**Indexes:**
- `userId` (untuk query booking by user)
- `destinationId` (untuk query booking by destination)
- `status` (untuk filter by status)
- `createdAt` (untuk sorting)

---

### 4. Collection: `reviews`

**Path:** `/reviews/{reviewId}`

**Schema:**
```javascript
{
  "userId": "string",         // Reference ke user ID
  "userName": "string",       // Snapshot nama user
  "destinationId": "string",  // Reference ke destination ID
  "rating": "number",         // Rating 1-5
  "comment": "string",        // Komentar review
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Example Document:**
```javascript
{
  "userId": "abc123xyz",
  "userName": "Budi Santoso",
  "destinationId": "dest001",
  "rating": 5,
  "comment": "Tempat yang sangat indah!",
  "createdAt": Timestamp(2026, 5, 6, 10, 0, 0),
  "updatedAt": Timestamp(2026, 5, 6, 10, 0, 0)
}
```

**Indexes:**
- `destinationId` (untuk query reviews by destination)
- `userId` (untuk query reviews by user)
- `createdAt` (untuk sorting)

---

### 5. Collection: `favorites`

**Path:** `/favorites/{favoriteId}`

**Schema:**
```javascript
{
  "userId": "string",         // Reference ke user ID
  "destinationId": "string",  // Reference ke destination ID
  "createdAt": "timestamp"
}
```

**Example Document:**
```javascript
{
  "userId": "abc123xyz",
  "destinationId": "dest001",
  "createdAt": Timestamp(2026, 5, 6, 10, 0, 0)
}
```

**Indexes:**
- `userId` (untuk query favorites by user)
- Composite: `userId` + `destinationId` (untuk cek duplikat)

---

### 6. Collection: `events`

**Path:** `/events/{eventId}`

**Schema:**
```javascript
{
  "title": "string",          // Judul event
  "description": "string",    // Deskripsi event
  "eventDate": "timestamp",   // Tanggal event
  "eventTime": "string",      // Waktu event (format: "08:00 - Selesai")
  "location": "string",       // Lokasi event
  "imageUrl": "string|null",  // URL gambar
  "status": "boolean",        // Aktif/nonaktif
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Example Document:**
```javascript
{
  "title": "Festival Panen Raya",
  "description": "Perayaan panen raya dengan kegiatan budaya dan kuliner.",
  "eventDate": Timestamp(2025, 10, 24, 0, 0, 0),
  "eventTime": "08:00 - Selesai",
  "location": "Desa Pujon Kidul, Malang",
  "imageUrl": null,
  "status": true,
  "createdAt": Timestamp(2026, 5, 6, 10, 0, 0),
  "updatedAt": Timestamp(2026, 5, 6, 10, 0, 0)
}
```

**Indexes:**
- `eventDate` (untuk sorting by tanggal)
- `status` (untuk filter aktif/nonaktif)

---

## 🔐 Firestore Security Rules

**File:** `firestore.rules`

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Users collection
    match /users/{userId} {
      // User bisa baca profil sendiri, admin bisa baca semua
      allow read: if isOwner(userId) || isAdmin();
      
      // User bisa update profil sendiri, admin bisa update semua
      allow update: if isOwner(userId) || isAdmin();
      
      // Hanya admin yang bisa delete
      allow delete: if isAdmin();
      
      // Create otomatis dari auth service
      allow create: if isAuthenticated();
    }
    
    // Destinations collection
    match /destinations/{destinationId} {
      // Semua user bisa baca destination yang aktif
      allow read: if resource.data.status == true || isAdmin();
      
      // Hanya admin yang bisa create, update, delete
      allow create, update, delete: if isAdmin();
    }
    
    // Bookings collection
    match /bookings/{bookingId} {
      // User bisa baca booking sendiri, admin bisa baca semua
      allow read: if isOwner(resource.data.userId) || isAdmin();
      
      // User bisa create booking untuk diri sendiri
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      
      // User bisa update booking sendiri, admin bisa update semua
      allow update: if isOwner(resource.data.userId) || isAdmin();
      
      // Hanya admin yang bisa delete
      allow delete: if isAdmin();
    }
    
    // Reviews collection
    match /reviews/{reviewId} {
      // Semua user bisa baca reviews
      allow read: if true;
      
      // User bisa create review untuk diri sendiri
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      
      // User bisa update/delete review sendiri
      allow update, delete: if isOwner(resource.data.userId);
    }
    
    // Favorites collection
    match /favorites/{favoriteId} {
      // User bisa baca, create, delete favorite sendiri
      allow read, create, delete: if isAuthenticated() && 
                                     (resource.data.userId == request.auth.uid || 
                                      request.resource.data.userId == request.auth.uid);
    }
    
    // Events collection
    match /events/{eventId} {
      // Semua user bisa baca events yang aktif
      allow read: if resource.data.status == true || isAdmin();
      
      // Hanya admin yang bisa create, update, delete
      allow create, update, delete: if isAdmin();
    }
  }
}
```

---

## 📝 Firestore Indexes

**File:** `firestore.indexes.json`

```json
{
  "indexes": [
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "role", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "destinations",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "rating", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "destinations",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "bookings",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "bookings",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "destinationId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "favorites",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "destinationId", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "eventDate", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

---

## 🚀 Cara Setup Firebase

### 1. Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### 2. Configure Firebase
```bash
flutterfire configure
```

Pilih:
- Project: DesaKita (atau buat baru)
- Platforms: Android, iOS, Web

### 3. File yang Akan Dibuat:
- `lib/firebase_options.dart` - Config otomatis
- `android/app/google-services.json` - Android config
- `ios/Runner/GoogleService-Info.plist` - iOS config

### 4. Initialize di main.dart
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const DesaKitaApp());
}
```

---

## 📊 Sample Data untuk Testing

Jalankan script ini di Firebase Console > Firestore > Import:

```javascript
// Sample Destinations
{
  "destinations": [
    {
      "name": "Bukit Sakura",
      "category": "Alam",
      "location": "Langkapura",
      "description": "Pemandangan perbukitan dengan bunga sakura.",
      "rating": 4.3,
      "price": "Rp 50.000",
      "imageUrl": null,
      "status": true
    },
    {
      "name": "Camp 91 Outbound",
      "category": "Alam",
      "location": "Kemiling",
      "description": "Camping dengan fasilitas lengkap di tengah alam.",
      "rating": 4.3,
      "price": "Rp 75.000",
      "imageUrl": null,
      "status": true
    },
    {
      "name": "Rumah Adat Lampung",
      "category": "Budaya",
      "location": "Desa Pujon",
      "description": "Kekayaan budaya Lampung melalui rumah adat.",
      "rating": 4.6,
      "price": "Rp 25.000",
      "imageUrl": null,
      "status": true
    }
  ]
}
```

---

## ✅ Checklist Setup

- [ ] Firebase project sudah dibuat
- [ ] FlutterFire CLI sudah diinstall
- [ ] `flutterfire configure` sudah dijalankan
- [ ] `firebase_options.dart` sudah ada
- [ ] `google-services.json` sudah ada (Android)
- [ ] Firebase.initializeApp() sudah di main.dart
- [ ] Firestore Security Rules sudah di-deploy
- [ ] Indexes sudah dibuat
- [ ] Sample data sudah diimport

---

**Last Updated:** 2026-05-06  
**Status:** ✅ Complete Documentation  
**Backend:** Firebase (Auth + Firestore)
