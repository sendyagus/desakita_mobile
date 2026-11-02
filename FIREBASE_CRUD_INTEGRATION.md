# Integrasi Firebase CRUD untuk Destinasi Wisata

## 📋 Ringkasan Perubahan

Halaman admin untuk CRUD destinasi wisata dan halaman explore user sekarang **terhubung langsung ke Firebase Firestore** dengan **sinkronisasi real-time**.

### ✅ Fitur yang Sudah Diimplementasikan

1. **Admin Dashboard - Kelola Destinasi**
   - ✅ Tambah destinasi baru → langsung tersimpan ke Firestore
   - ✅ Edit destinasi → update real-time di database
   - ✅ Hapus destinasi → terhapus dari database
   - ✅ Toggle status aktif/nonaktif → update status di database
   - ✅ Search dan filter → bekerja dengan data dari Firestore
   - ✅ Real-time updates → perubahan langsung terlihat tanpa refresh

2. **User - Halaman Explore**
   - ✅ Menampilkan semua destinasi dari Firestore (hanya yang status=true)
   - ✅ Real-time sync → ketika admin menambah/edit/hapus, user langsung melihat perubahan
   - ✅ Search destinasi → mencari berdasarkan nama dan lokasi
   - ✅ Filter kategori → Semua, Alam, Budaya, Kuliner, Penginapan
   - ✅ Tampilan card dengan rating, lokasi, kategori, dan harga

---

## 🔧 Perubahan Teknis

### 1. Admin - `destination_management_screen.dart`

**Sebelum:**
- Menggunakan dummy data lokal (`List<_DestinationModel>`)
- Perubahan hanya di memori, tidak tersimpan

**Sesudah:**
- Menggunakan `StreamBuilder<QuerySnapshot>` untuk listen ke Firestore
- Semua operasi CRUD menggunakan `DestinationService`:
  - `addDestination()` - Tambah destinasi baru
  - `updateDestination()` - Update destinasi
  - `deleteDestination()` - Hapus destinasi
  - `toggleDestinationStatus()` - Ubah status aktif/nonaktif
- Data otomatis refresh ketika ada perubahan di database

**Kode Penting:**
```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance.collection('destinations').snapshots(),
  builder: (context, snapshot) {
    // Otomatis rebuild ketika data berubah
    final allDestinations = snapshot.data!.docs.map((doc) { ... }).toList();
    final filteredDestinations = _filterDestinations(allDestinations);
    return _buildDestinationList(filteredDestinations);
  },
)
```

### 2. User - `explore_screen.dart`

**Sebelum:**
- Menggunakan dummy data lokal (`_allDestinations`)
- Kategori: Semua, Alam, Budaya, Resto, Kuliner, Edukasi
- Menampilkan jarak dan bookmark

**Sesudah:**
- Menggunakan `StreamBuilder<QuerySnapshot>` untuk listen ke Firestore
- Kategori disesuaikan dengan admin: Semua, Alam, Budaya, Kuliner, Penginapan
- Menampilkan lokasi, kategori, rating, dan harga (sesuai data dari admin)
- Hanya menampilkan destinasi dengan `status: true`
- Fitur bookmark dihapus (bisa ditambahkan nanti jika diperlukan)

**Kode Penting:**
```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('destinations')
      .where('status', isEqualTo: true)
      .snapshots(),
  builder: (context, snapshot) {
    // Otomatis rebuild ketika admin mengubah data
    final allDestinations = snapshot.data!.docs.map((doc) { ... }).toList();
    final filteredDestinations = _filterDestinations(allDestinations);
    return _buildDestinationList(filteredDestinations);
  },
)
```

---

## 🎯 Cara Kerja Real-Time Sync

### Skenario 1: Admin Menambah Destinasi Baru
1. Admin klik "Tambah Destinasi"
2. Isi form (nama, kategori, lokasi, rating, harga)
3. Klik "Simpan"
4. Data tersimpan ke Firestore collection `destinations`
5. **User di halaman Explore langsung melihat destinasi baru** (tanpa refresh)

### Skenario 2: Admin Mengedit Destinasi
1. Admin klik tombol edit (ikon pensil)
2. Ubah data (misal: ubah harga dari Rp 50.000 → Rp 75.000)
3. Klik "Simpan"
4. Data di Firestore ter-update
5. **User langsung melihat harga baru** (tanpa refresh)

### Skenario 3: Admin Menonaktifkan Destinasi
1. Admin klik toggle status (dari Aktif → Nonaktif)
2. Status di Firestore berubah menjadi `status: false`
3. **Destinasi langsung hilang dari halaman Explore user** (karena filter `status: true`)

### Skenario 4: Admin Menghapus Destinasi
1. Admin klik tombol hapus (ikon tempat sampah)
2. Konfirmasi hapus
3. Data terhapus dari Firestore
4. **Destinasi langsung hilang dari halaman Explore user**

---

## 📊 Struktur Data Firestore

### Collection: `destinations`

```json
{
  "name": "Bukit Sakura",
  "category": "Alam",
  "location": "Langkapura",
  "rating": 4.3,
  "price": "Rp 50.000",
  "description": null,
  "imageUrl": null,
  "status": true,
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

**Field Wajib:**
- `name` (string) - Nama destinasi
- `category` (string) - Kategori: Alam, Budaya, Kuliner, Penginapan
- `location` (string) - Lokasi destinasi
- `rating` (number) - Rating 0.0 - 5.0
- `price` (string) - Harga dalam format "Rp X.XXX"
- `status` (boolean) - true = aktif, false = nonaktif

**Field Opsional:**
- `description` (string) - Deskripsi destinasi
- `imageUrl` (string) - URL foto destinasi (saat ini masih wireframe)

---

## 🧪 Testing

### Test 1: Tambah Destinasi dari Admin
1. Login sebagai admin (admin@desakita.com / 12345678)
2. Masuk ke "Kelola Destinasi Wisata"
3. Klik "Tambah Destinasi"
4. Isi form:
   - Nama: "Air Terjun Pelangi"
   - Lokasi: "Desa Suka Maju"
   - Rating: 4.5
   - Harga: "Rp 30.000"
   - Kategori: Alam
5. Klik "Simpan"
6. **Cek halaman Explore (user)** → destinasi baru muncul

### Test 2: Edit Destinasi
1. Di halaman admin, klik edit pada destinasi
2. Ubah harga menjadi "Rp 100.000"
3. Klik "Simpan"
4. **Cek halaman Explore** → harga berubah

### Test 3: Nonaktifkan Destinasi
1. Di halaman admin, klik toggle status (Aktif → Nonaktif)
2. **Cek halaman Explore** → destinasi hilang

### Test 4: Hapus Destinasi
1. Di halaman admin, klik tombol hapus
2. Konfirmasi hapus
3. **Cek halaman Explore** → destinasi terhapus

### Test 5: Search dan Filter
1. Di halaman Explore, ketik "Bukit" di search bar
2. Hanya destinasi dengan nama/lokasi "Bukit" yang muncul
3. Klik filter "Alam"
4. Hanya destinasi kategori Alam yang muncul

---

## 🔐 Firestore Security Rules

Pastikan Firestore rules sudah di-deploy:

```bash
firebase deploy --only firestore:rules
```

**Rules yang digunakan:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Destinasi: semua user bisa baca, hanya admin yang bisa edit
    match /destinations/{destinationId} {
      allow read: if request.auth != null;
      allow create, update, delete: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

---

## 🐛 Troubleshooting

### Error: "Missing or insufficient permissions"
**Solusi:**
1. Deploy Firestore rules: `firebase deploy --only firestore:rules`
2. Atau update manual di Firebase Console → Firestore Database → Rules

### Destinasi tidak muncul di Explore
**Cek:**
1. Apakah `status: true`? (hanya destinasi aktif yang muncul)
2. Apakah user sudah login?
3. Cek Firebase Console → Firestore → collection `destinations`

### Perubahan tidak real-time
**Cek:**
1. Apakah menggunakan `StreamBuilder`? (bukan `FutureBuilder`)
2. Apakah internet connection aktif?
3. Restart aplikasi

---

## 📝 Catatan Penting

1. **Kategori yang Valid:**
   - Alam
   - Budaya
   - Kuliner
   - Penginapan

2. **Format Harga:**
   - Gunakan format "Rp X.XXX" (contoh: "Rp 50.000")
   - Bisa juga "Gratis" untuk destinasi gratis

3. **Rating:**
   - Nilai antara 0.0 - 5.0
   - Default: 4.0

4. **Status:**
   - `true` = Aktif (muncul di Explore)
   - `false` = Nonaktif (tidak muncul di Explore)

5. **Image URL:**
   - Saat ini masih wireframe placeholder
   - Nanti bisa diisi dengan URL foto dari Firebase Storage

---

## 🚀 Next Steps (Opsional)

1. **Upload Foto Destinasi**
   - Integrasi Firebase Storage
   - Upload foto dari admin panel
   - Tampilkan foto di Explore screen

2. **Fitur Bookmark**
   - User bisa bookmark destinasi favorit
   - Simpan di collection `favorites`

3. **Detail Destinasi**
   - Halaman detail ketika user klik destinasi
   - Tampilkan deskripsi lengkap, foto, review, dll

4. **Review & Rating**
   - User bisa kasih review dan rating
   - Rating otomatis ter-update berdasarkan review

---

## ✅ Status Implementasi

- ✅ Admin CRUD terhubung ke Firebase
- ✅ User Explore terhubung ke Firebase
- ✅ Real-time sync antara admin dan user
- ✅ Search dan filter berfungsi
- ✅ Error handling
- ✅ Loading state
- ✅ Firestore Security Rules

**Semua fitur sudah berfungsi dengan baik!** 🎉
