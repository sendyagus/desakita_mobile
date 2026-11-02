# ⚡ Quick Start - Admin Dashboard Firebase Integration

## 🚀 Langkah Cepat

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
```

### 3. Jalankan Aplikasi
```bash
flutter run
```

### 4. Login sebagai Admin
- Email: `admin@desakita.com`
- Password: `12345678`

### 5. Test Dashboard
✅ Lihat statistik real-time
✅ Pull-to-refresh untuk update data
✅ Lihat aktivitas terbaru

---

## 📊 Yang Sudah Berfungsi

### Admin Dashboard:
- ✅ Total Users (+ new users today)
- ✅ Total Destinations (+ active)
- ✅ Total Bookings (+ active)
- ✅ Total Revenue
- ✅ Recent Activities (real-time)
- ✅ Pull-to-refresh

### Destination Management:
- ✅ CRUD destinations
- ✅ Real-time sync
- ✅ Search & filter
- ✅ Toggle status

---

## 🔄 Yang Perlu Dilakukan

### Priority 1: Upload Gambar Destinasi
1. Buka `lib/screens/admin/destination_management_screen.dart`
2. Tambah button "Upload Gambar" di form
3. Gunakan `StorageService`:
```dart
final storageService = StorageService();
final image = await storageService.pickImageFromGallery();
if (image != null) {
  final imageUrl = await storageService.uploadImage(
    folder: 'destinations',
    file: image,
  );
  // Save imageUrl to Firestore
}
```

### Priority 2: Update User Management
1. Buka `lib/screens/admin/user_management_screen.dart`
2. Ganti dummy data dengan `UserService`
3. Tambah StreamBuilder untuk real-time sync

### Priority 3: Buat Event Management
1. Buat `lib/screens/admin/event_management_screen.dart`
2. Gunakan `EventService` untuk CRUD
3. Tambah upload gambar event

### Priority 4: Buat Booking Management
1. Buat `lib/screens/admin/booking_management_screen.dart`
2. Gunakan `BookingService` untuk view & update
3. Tambah filter by status

---

## 📁 File Penting

### Services (Sudah Siap):
- `lib/services/event_service.dart`
- `lib/services/user_service.dart`
- `lib/services/storage_service.dart`
- `lib/services/stats_service.dart`

### Screens (Perlu Update):
- `lib/screens/admin/admin_dashboard_screen.dart` ✅ Done
- `lib/screens/admin/destination_management_screen.dart` ✅ Done
- `lib/screens/admin/user_management_screen.dart` 🔄 Need update
- `lib/screens/admin/event_management_screen.dart` 🔄 Need create
- `lib/screens/admin/booking_management_screen.dart` 🔄 Need create

---

## 🧪 Testing Checklist

- [ ] Dashboard statistics muncul dari Firebase
- [ ] Pull-to-refresh berfungsi
- [ ] Recent activities muncul
- [ ] Destination CRUD berfungsi
- [ ] Upload gambar destinasi (setelah implementasi)
- [ ] User management real-time (setelah update)
- [ ] Event management (setelah dibuat)
- [ ] Booking management (setelah dibuat)

---

## 🐛 Troubleshooting

### Error: "Missing or insufficient permissions"
```bash
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
```

### Error: Image picker not working (iOS)
Tambahkan di `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Aplikasi memerlukan akses ke galeri</string>
<key>NSCameraUsageDescription</key>
<string>Aplikasi memerlukan akses ke kamera</string>
```

### Dashboard tidak load data
1. Cek internet connection
2. Cek Firebase Console → Firestore → pastikan ada data
3. Restart aplikasi

---

## 📚 Dokumentasi Lengkap

- `SUMMARY_ADMIN_INTEGRATION.md` - Summary singkat
- `ADMIN_FIREBASE_INTEGRATION.md` - Dokumentasi detail
- `FIREBASE_CRUD_INTEGRATION.md` - Dokumentasi destinasi CRUD

---

## ✅ Status

**Backend:** ✅ 100% READY
**Frontend:** 🔄 40% DONE

**Next:** Implementasi UI untuk upload gambar, user management, events, dan bookings.

---

**Happy Coding! 🚀**
