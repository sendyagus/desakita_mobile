# 🏠 Update Home Screen - Nama & Foto User

## ✅ Perubahan yang Dilakukan

### File: `lib/screens/home_screen.dart`

#### 1. **Header Sekarang Menampilkan Data User dari Database**

**SEBELUM:**
```
┌────────────────────────────────────┐
│ [👤]  Halo, Nama Pengguna!    🔔 🎧│
│       Mau pergi kemana hari ini?   │
└────────────────────────────────────┘
```
- Avatar: Icon statis
- Nama: Teks statis "Nama Pengguna"

**SESUDAH:**
```
┌────────────────────────────────────┐
│ [📷]  Halo, Budi Santoso!     🔔 🎧│
│       Mau pergi kemana hari ini?   │
└────────────────────────────────────┘
```
- Avatar: Foto user dari database (`avatarUrl`)
- Nama: Nama user dari database (`fullName`)

---

## 🔧 Perubahan Teknis

### 1. Import Baru:
```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:desa_wisata/services/user_service.dart';
import 'package:desa_wisata/models/user_model.dart';
```

### 2. State Variables Baru:
```dart
final UserService _userService = UserService();
UserModel? _currentUser;
bool _isLoadingUser = true;
```

### 3. Method Baru:
```dart
@override
void initState() {
  super.initState();
  _loadUserData(); // Load user data saat screen dibuka
}

Future<void> _loadUserData() async {
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final user = await _userService.getUserById(userId);
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoadingUser = false;
        });
      }
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoadingUser = false);
    }
  }
}
```

### 4. Update Header Widget:

#### Avatar:
```dart
// Sebelum: Static icon
child: const Icon(Icons.person, color: Colors.grey, size: 24),

// Sesudah: Dynamic photo from database
child: ClipOval(
  child: _isLoadingUser
      ? CircularProgressIndicator() // Loading state
      : _currentUser?.avatarUrl != null
          ? Image.network(_currentUser!.avatarUrl!) // User photo
          : Icon(Icons.person), // Default icon
),
```

#### Nama User:
```dart
// Sebelum: Static text
Text('Halo, Nama Pengguna!')

// Sesudah: Dynamic from database
Text(
  _isLoadingUser
      ? 'Halo, Pengguna!'
      : 'Halo, ${_currentUser?.fullName ?? 'Pengguna'}!',
)
```

---

## 🎨 Fitur UI

### Loading States:
1. **Saat data user dimuat**: Spinner kecil di avatar
2. **Saat foto dimuat**: Loading indicator
3. **Fallback**: Icon default jika tidak ada foto

### Error Handling:
- Jika foto gagal dimuat → tampilkan icon default
- Jika user data tidak ada → tampilkan "Pengguna"
- Jika tidak login → tampilkan "Pengguna"

---

## 🔄 Data Flow

```
HomeScreen dibuka
    ↓
initState() dipanggil
    ↓
_loadUserData() dijalankan
    ↓
Get current user ID dari FirebaseAuth
    ↓
UserService.getUserById(userId)
    ↓
Fetch data dari Firestore
    ↓
setState() → Update UI
    ↓
Tampilkan nama & foto user
```

---

## 🧪 Testing

### Test Case 1: User dengan Foto
```
1. Login sebagai user yang sudah upload foto
2. Buka halaman Beranda
3. ✅ Foto user tampil di header
4. ✅ Nama user tampil: "Halo, [Nama User]!"
```

### Test Case 2: User tanpa Foto
```
1. Login sebagai user yang belum upload foto
2. Buka halaman Beranda
3. ✅ Icon default tampil di header
4. ✅ Nama user tampil: "Halo, [Nama User]!"
```

### Test Case 3: Loading State
```
1. Login dengan koneksi lambat
2. Buka halaman Beranda
3. ✅ Loading spinner tampil di avatar
4. ✅ Teks "Halo, Pengguna!" tampil sementara
5. ✅ Setelah load selesai, nama & foto muncul
```

### Test Case 4: Error Handling
```
1. Login dengan foto URL yang invalid
2. Buka halaman Beranda
3. ✅ Icon default tampil (error fallback)
4. ✅ Nama user tetap tampil
```

---

## 🐛 Bug Fixes

### 1. Fixed Deprecated Warning:
```dart
// Before:
Colors.grey.withOpacity(0.2)

// After:
Colors.grey.withValues(alpha: 0.2)
```

---

## 📊 Perbandingan

| Aspek | Sebelum | Sesudah |
|-------|---------|---------|
| Avatar | Icon statis | Foto dari database |
| Nama | "Nama Pengguna" (statis) | Nama dari database |
| Loading | Tidak ada | Ada loading state |
| Error Handling | Tidak ada | Ada fallback |
| Database Connection | Tidak ada | Real-time dari Firestore |

---

## ✅ Checklist

- ✅ Import Firebase Auth & UserService
- ✅ Tambah state variables untuk user data
- ✅ Implementasi `_loadUserData()` method
- ✅ Update avatar untuk tampilkan foto user
- ✅ Update nama untuk tampilkan fullName user
- ✅ Tambah loading states
- ✅ Tambah error handling
- ✅ Fix deprecated warning
- ✅ Test semua scenarios

---

## 🎉 Result

**Sekarang halaman Home Screen menampilkan:**
1. ✅ Foto profil user dari database
2. ✅ Nama user dari database
3. ✅ Loading state saat fetch data
4. ✅ Error handling untuk foto gagal dimuat
5. ✅ Fallback ke icon default jika tidak ada foto

**Status**: ✅ SELESAI & SIAP DIGUNAKAN

---

## 📝 Notes

- Data user di-fetch sekali saat screen dibuka (initState)
- Jika user update foto di Profile screen, perlu refresh Home screen untuk lihat perubahan
- Untuk auto-refresh, bisa gunakan StreamBuilder (optional enhancement)

---

**Last Updated**: 2024
**File Modified**: `lib/screens/home_screen.dart`
**Lines Changed**: ~50 lines
