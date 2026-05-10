# 📊 DIAGRAM DATABASE FIRESTORE - DESA WISATA

## 🗂️ STRUKTUR COLLECTIONS

```
Firebase Project: my-application222-4fe42
│
├── 📁 users/
│   ├── {userId1}/
│   │   ├── fullName: "Budi Santoso"
│   │   ├── email: "budi@example.com"
│   │   ├── phone: "+62812345678"
│   │   ├── avatarUrl: null
│   │   ├── role: "user"
│   │   ├── isActive: true
│   │   ├── createdAt: Timestamp
│   │   └── updatedAt: Timestamp
│   │
│   └── {userId2}/
│       ├── fullName: "Admin Desa"
│       ├── email: "admin@desakita.com"
│       ├── phone: "+628123456789"
│       ├── avatarUrl: null
│       ├── role: "admin" ⭐
│       ├── isActive: true
│       ├── createdAt: Timestamp
│       └── updatedAt: Timestamp
│
├── 📁 destinations/
│   ├── {destId1}/
│   │   ├── name: "Bukit Sakura"
│   │   ├── category: "Alam"
│   │   ├── location: "Langkapura"
│   │   ├── description: "Pemandangan perbukitan..."
│   │   ├── rating: 4.3
│   │   ├── price: "Rp 50.000"
│   │   ├── imageUrl: null
│   │   ├── status: true
│   │   ├── createdAt: Timestamp
│   │   └── updatedAt: Timestamp
│   │
│   ├── {destId2}/
│   │   ├── name: "Camp 91 Outbound"
│   │   ├── category: "Alam"
│   │   ├── location: "Kemiling"
│   │   ├── description: "Camping dengan fasilitas..."
│   │   ├── rating: 4.3
│   │   ├── price: "Rp 75.000"
│   │   ├── imageUrl: null
│   │   ├── status: true
│   │   ├── createdAt: Timestamp
│   │   └── updatedAt: Timestamp
│   │
│   └── {destId3}/
│       ├── name: "Rumah Adat Lampung"
│       ├── category: "Budaya"
│       ├── location: "Desa Pujon"
│       ├── description: "Kekayaan budaya..."
│       ├── rating: 4.6
│       ├── price: "Rp 25.000"
│       ├── imageUrl: null
│       ├── status: true
│       ├── createdAt: Timestamp
│       └── updatedAt: Timestamp
│
├── 📁 bookings/
│   ├── {bookingId1}/
│   │   ├── userId: "userId1" → 🔗 users/userId1
│   │   ├── destinationId: "destId1" → 🔗 destinations/destId1
│   │   ├── destinationName: "Bukit Sakura" (snapshot)
│   │   ├── destinationCategory: "Alam" (snapshot)
│   │   ├── destinationLocation: "Langkapura" (snapshot)
│   │   ├── destinationRating: 4.3 (snapshot)
│   │   ├── destinationPrice: "Rp 50.000" (snapshot)
│   │   ├── destinationImageUrl: null (snapshot)
│   │   ├── userFullName: "Budi Santoso" (snapshot)
│   │   ├── userEmail: "budi@example.com" (snapshot)
│   │   ├── userPhone: "+62812345678" (snapshot)
│   │   ├── checkIn: Timestamp(2026-06-01)
│   │   ├── checkOut: Timestamp(2026-06-03)
│   │   ├── guestCount: 2
│   │   ├── totalPrice: "Rp 100.000"
│   │   ├── status: "pending"
│   │   ├── createdAt: Timestamp
│   │   └── updatedAt: Timestamp
│   │
│   └── {bookingId2}/
│       ├── userId: "userId1"
│       ├── destinationId: "destId2"
│       ├── ... (same structure)
│       └── status: "confirmed"
│
├── 📁 reviews/ (Coming Soon)
│   └── {reviewId}/
│       ├── userId: "userId1" → 🔗 users/userId1
│       ├── userName: "Budi Santoso" (snapshot)
│       ├── destinationId: "destId1" → 🔗 destinations/destId1
│       ├── rating: 5
│       ├── comment: "Tempat yang sangat indah!"
│       ├── createdAt: Timestamp
│       └── updatedAt: Timestamp
│
├── 📁 favorites/ (Coming Soon)
│   └── {favoriteId}/
│       ├── userId: "userId1" → 🔗 users/userId1
│       ├── destinationId: "destId1" → 🔗 destinations/destId1
│       └── createdAt: Timestamp
│
└── 📁 events/ (Coming Soon)
    └── {eventId}/
        ├── title: "Festival Panen Raya"
        ├── description: "Perayaan panen raya..."
        ├── eventDate: Timestamp(2025-10-24)
        ├── eventTime: "08:00 - Selesai"
        ├── location: "Desa Pujon Kidul, Malang"
        ├── imageUrl: null
        ├── status: true
        ├── createdAt: Timestamp
        └── updatedAt: Timestamp
```

---

## 🔗 RELASI ANTAR COLLECTIONS

### 1. Users ↔ Bookings (One-to-Many)
```
users/{userId}
    ↓ (1 user bisa punya banyak booking)
bookings/{bookingId}.userId
```

**Query:**
```dart
// Ambil semua booking user tertentu
bookings
  .where('userId', isEqualTo: userId)
  .orderBy('createdAt', descending: true)
```

---

### 2. Destinations ↔ Bookings (One-to-Many)
```
destinations/{destId}
    ↓ (1 destinasi bisa punya banyak booking)
bookings/{bookingId}.destinationId
```

**Query:**
```dart
// Ambil semua booking untuk destinasi tertentu
bookings
  .where('destinationId', isEqualTo: destId)
  .orderBy('createdAt', descending: true)
```

**Note:** Data destinasi di-snapshot ke booking untuk performa (tidak perlu join)

---

### 3. Users ↔ Reviews (One-to-Many)
```
users/{userId}
    ↓ (1 user bisa punya banyak review)
reviews/{reviewId}.userId
```

**Query:**
```dart
// Ambil semua review user tertentu
reviews
  .where('userId', isEqualTo: userId)
  .orderBy('createdAt', descending: true)
```

---

### 4. Destinations ↔ Reviews (One-to-Many)
```
destinations/{destId}
    ↓ (1 destinasi bisa punya banyak review)
reviews/{reviewId}.destinationId
```

**Query:**
```dart
// Ambil semua review untuk destinasi tertentu
reviews
  .where('destinationId', isEqualTo: destId)
  .orderBy('createdAt', descending: true)
```

---

### 5. Users ↔ Favorites (Many-to-Many)
```
users/{userId}
    ↕ (1 user bisa favorit banyak destinasi)
favorites/{favoriteId}
    ↕ (1 destinasi bisa difavorit banyak user)
destinations/{destId}
```

**Query:**
```dart
// Ambil semua favorit user
favorites
  .where('userId', isEqualTo: userId)
  .orderBy('createdAt', descending: true)

// Cek apakah user sudah favorit destinasi tertentu
favorites
  .where('userId', isEqualTo: userId)
  .where('destinationId', isEqualTo: destId)
  .limit(1)
```

---

## 📈 FLOW DATA

### Flow 1: Registrasi User Baru
```
1. User isi form registrasi
   ↓
2. AuthService.signUp()
   ↓
3. Firebase Auth: createUserWithEmailAndPassword()
   ↓ (dapat userId)
4. Firestore: create document users/{userId}
   ├── fullName: dari form
   ├── email: dari form
   ├── phone: dari form
   ├── role: "user" (default)
   ├── isActive: true (default)
   └── timestamps
   ↓
5. Login otomatis
   ↓
6. Redirect ke HomeScreen
```

---

### Flow 2: Login User
```
1. User isi email & password
   ↓
2. AuthService.signIn()
   ↓
3. Firebase Auth: signInWithEmailAndPassword()
   ↓ (dapat userId)
4. Firestore: get document users/{userId}
   ↓
5. Cek role:
   ├── role = "admin" → AdminDashboardScreen
   └── role = "user" → HomeScreen
```

---

### Flow 3: Booking Destinasi
```
1. User pilih destinasi
   ↓
2. User isi form booking (tanggal, jumlah tamu)
   ↓
3. BookingService.createBooking()
   ↓
4. Firestore: get destinations/{destId} (untuk snapshot)
   ↓
5. Firestore: get users/{userId} (untuk snapshot)
   ↓
6. Firestore: create document bookings/{bookingId}
   ├── userId: dari auth
   ├── destinationId: dari pilihan
   ├── destinationName: snapshot dari destinations
   ├── destinationCategory: snapshot
   ├── destinationLocation: snapshot
   ├── destinationRating: snapshot
   ├── destinationPrice: snapshot
   ├── userFullName: snapshot dari users
   ├── userEmail: snapshot
   ├── userPhone: snapshot
   ├── checkIn: dari form
   ├── checkOut: dari form
   ├── guestCount: dari form
   ├── totalPrice: kalkulasi
   ├── status: "pending" (default)
   └── timestamps
   ↓
7. Tampilkan konfirmasi booking
```

**Kenapa pakai snapshot?**
- Performa lebih cepat (tidak perlu join)
- Data booking tetap konsisten meski destinasi/user berubah
- Cocok untuk data historis

---

### Flow 4: Admin Kelola Destinasi
```
1. Admin login
   ↓
2. Masuk ke Admin Dashboard
   ↓
3. Klik "Kelola Destinasi"
   ↓
4. DestinationService.getAllDestinations()
   ↓
5. Firestore: get all documents destinations/
   ↓
6. Tampilkan list destinasi
   ↓
7. Admin bisa:
   ├── Tambah destinasi baru
   ├── Edit destinasi
   ├── Hapus destinasi
   └── Aktifkan/nonaktifkan destinasi
```

---

## 🔐 SECURITY RULES DIAGRAM

```
┌─────────────────────────────────────────────────────────┐
│                    FIRESTORE RULES                      │
└─────────────────────────────────────────────────────────┘

📁 users/
├── READ:
│   ├── ✅ User bisa baca profil sendiri
│   └── ✅ Admin bisa baca semua profil
├── CREATE:
│   └── ✅ User baru otomatis (dari AuthService)
├── UPDATE:
│   ├── ✅ User bisa update profil sendiri
│   └── ✅ Admin bisa update semua profil
└── DELETE:
    └── ✅ Hanya admin

📁 destinations/
├── READ:
│   ├── ✅ Semua user bisa baca destinasi aktif (status=true)
│   └── ✅ Admin bisa baca semua (termasuk nonaktif)
├── CREATE:
│   └── ✅ Hanya admin
├── UPDATE:
│   └── ✅ Hanya admin
└── DELETE:
    └── ✅ Hanya admin

📁 bookings/
├── READ:
│   ├── ✅ User bisa baca booking sendiri
│   └── ✅ Admin bisa baca semua booking
├── CREATE:
│   └── ✅ User bisa create booking untuk diri sendiri
├── UPDATE:
│   ├── ✅ User bisa update booking sendiri
│   └── ✅ Admin bisa update semua booking
└── DELETE:
    └── ✅ Hanya admin

📁 reviews/
├── READ:
│   └── ✅ Semua user bisa baca reviews
├── CREATE:
│   └── ✅ User bisa create review untuk diri sendiri
├── UPDATE:
│   └── ✅ User bisa update review sendiri
└── DELETE:
    └── ✅ User bisa delete review sendiri

📁 favorites/
├── READ:
│   └── ✅ User bisa baca favorit sendiri
├── CREATE:
│   └── ✅ User bisa create favorit untuk diri sendiri
└── DELETE:
    └── ✅ User bisa delete favorit sendiri

📁 events/
├── READ:
│   ├── ✅ Semua user bisa baca events aktif (status=true)
│   └── ✅ Admin bisa baca semua
├── CREATE:
│   └── ✅ Hanya admin
├── UPDATE:
│   └── ✅ Hanya admin
└── DELETE:
    └── ✅ Hanya admin
```

---

## 📊 INDEXES YANG DIPERLUKAN

### 1. Users Collection
```
Index: role + createdAt (descending)
Untuk: Admin dashboard - list users by role, sorted by newest
```

### 2. Destinations Collection
```
Index 1: category + rating (descending)
Untuk: Filter by kategori, sorted by rating tertinggi

Index 2: status + createdAt (descending)
Untuk: Admin - list all destinations, sorted by newest
```

### 3. Bookings Collection
```
Index 1: userId + createdAt (descending)
Untuk: User - list booking sendiri, sorted by newest

Index 2: status + createdAt (descending)
Untuk: Admin - filter booking by status, sorted by newest

Index 3: destinationId + createdAt (descending)
Untuk: Admin - list booking per destinasi
```

### 4. Reviews Collection
```
Index 1: destinationId + createdAt (descending)
Untuk: Tampil reviews di detail destinasi, sorted by newest

Index 2: userId + createdAt (descending)
Untuk: User - list review sendiri
```

### 5. Favorites Collection
```
Index: userId + destinationId
Untuk: Cek apakah user sudah favorit destinasi tertentu
```

### 6. Events Collection
```
Index: status + eventDate (ascending)
Untuk: List events aktif, sorted by tanggal terdekat
```

---

## 💾 ESTIMASI UKURAN DATA

### Per Document:

| Collection | Avg Size | Max Size |
|------------|----------|----------|
| users | ~500 bytes | 1 KB |
| destinations | ~1 KB | 5 KB |
| bookings | ~2 KB | 10 KB |
| reviews | ~500 bytes | 2 KB |
| favorites | ~200 bytes | 500 bytes |
| events | ~1 KB | 5 KB |

### Estimasi untuk 1000 Users:

| Collection | Documents | Total Size |
|------------|-----------|------------|
| users | 1,000 | ~500 KB |
| destinations | 100 | ~100 KB |
| bookings | 5,000 | ~10 MB |
| reviews | 2,000 | ~1 MB |
| favorites | 3,000 | ~600 KB |
| events | 50 | ~50 KB |
| **TOTAL** | **11,150** | **~12 MB** |

**Firebase Free Tier:**
- Storage: 1 GB (cukup untuk ~80,000 users!)
- Reads: 50,000/day
- Writes: 20,000/day
- Deletes: 20,000/day

---

## 🚀 OPTIMASI PERFORMA

### 1. Snapshot Data (Denormalization)
✅ **Sudah diimplementasi di bookings**
- Snapshot data destinasi & user
- Tidak perlu join saat query
- Performa lebih cepat

### 2. Pagination
⚠️ **Belum diimplementasi**
```dart
// TODO: Implementasi pagination
final query = destinations
  .where('status', isEqualTo: true)
  .orderBy('createdAt', descending: true)
  .limit(20); // Load 20 per page

// Next page
final nextQuery = query.startAfterDocument(lastDocument);
```

### 3. Caching
⚠️ **Belum diimplementasi**
```dart
// TODO: Enable offline persistence
FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

### 4. Composite Indexes
✅ **Sudah dibuat di firestore.indexes.json**
- Otomatis dibuat saat deploy

---

**Dibuat:** 7 Mei 2026  
**Status:** ✅ Complete Database Design  
**Backend:** Firebase Cloud Firestore
