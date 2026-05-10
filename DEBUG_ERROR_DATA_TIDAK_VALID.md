# 🔍 Debug: "Data tidak valid. Periksa kembali input Anda"

## ❌ Error yang Muncul

**Pesan Error:**
```
Data tidak valid. Periksa kembali input Anda
```

**Screenshot:** Error muncul di snackbar merah setelah klik tombol "Daftar"

---

## 🔍 Penyebab Kemungkinan

### 1. **Supabase Belum Dikonfigurasi**
Error ini muncul dari `ErrorHandler.getAuthErrorMessage()` dengan status code 400.

**Kemungkinan:**
- SQL setup belum dijalankan
- Tabel `users` belum dibuat
- Trigger belum dibuat
- RLS policies belum di-setup

### 2. **Email Confirmation Masih Aktif**
Jika email confirmation ON, Supabase akan reject registrasi.

### 3. **Password Terlalu Pendek**
Supabase default minimal 6 karakter, tapi app kita set 8 karakter.

### 4. **Email Format Salah**
Meskipun sudah ada validasi, bisa jadi ada karakter yang tidak valid.

---

## 🧪 Langkah Debug

### Step 1: Cek Console Log

Setelah saya tambahkan logging, jalankan app lagi dan cek console:

```bash
flutter run
```

Saat klik "Daftar", console akan menampilkan:

```
🔍 Form validated, starting registration...
📧 Email: asasq@gmail.com
👤 Name: asds
📱 Phone: +62089
📝 Starting registration for: asasq@gmail.com
```

**Lalu akan ada salah satu dari ini:**

#### Scenario A: Supabase Error
```
❌ AuthException: Invalid API key
❌ Status Code: 401
```
→ **Solusi:** API key salah

#### Scenario B: Database Error
```
❌ AuthException: relation "public.users" does not exist
❌ Status Code: 400
```
→ **Solusi:** Jalankan SQL setup

#### Scenario C: Email Confirmation
```
❌ AuthException: Email confirmation required
❌ Status Code: 400
```
→ **Solusi:** Matikan email confirmation

#### Scenario D: Password Error
```
❌ AuthException: Password should be at least 6 characters
❌ Status Code: 400
```
→ **Solusi:** Password terlalu pendek

---

### Step 2: Verifikasi Supabase Setup

Jalankan query ini di SQL Editor:

```sql
-- 1. Cek tabel users
SELECT COUNT(*) as exists 
FROM information_schema.tables 
WHERE table_name = 'users' AND table_schema = 'public';
-- Expected: 1

-- 2. Cek trigger
SELECT COUNT(*) as exists 
FROM pg_trigger 
WHERE tgname = 'on_auth_user_created';
-- Expected: 1

-- 3. Cek RLS
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'users' AND schemaname = 'public';
-- Expected: rowsecurity = true

-- 4. Cek policies
SELECT COUNT(*) as policy_count 
FROM pg_policies 
WHERE tablename = 'users';
-- Expected: >= 6
```

**Jika ada yang 0 atau tidak sesuai:**
→ Jalankan `SETUP_REGISTRASI_LENGKAP.sql`

---

### Step 3: Cek Email Confirmation

1. Buka Supabase Dashboard
2. Authentication → Providers
3. Scroll ke Email
4. **Pastikan "Confirm email" = OFF**

---

### Step 4: Test dengan Data Valid

Gunakan data ini untuk test:

```
Nama Lengkap: Test User
Email: test123@example.com
Nomor Telepon: 812 3456 7890
Kata Sandi: password123
Konfirmasi: password123
```

**PENTING:**
- Email harus format valid
- Password minimal 8 karakter
- Phone harus angka saja (tanpa spasi atau karakter lain)

---

## 🔧 Solusi Berdasarkan Error

### Solusi 1: Jalankan SQL Setup

**File:** `SETUP_REGISTRASI_LENGKAP.sql`

1. Buka Supabase Dashboard
2. SQL Editor → New Query
3. Copy SEMUA isi `SETUP_REGISTRASI_LENGKAP.sql`
4. Paste dan Run
5. Cek verification queries (harus semua ✅)

---

### Solusi 2: Matikan Email Confirmation

1. Dashboard → Authentication → Providers
2. Email section
3. Toggle OFF "Confirm email"
4. Save

---

### Solusi 3: Fix API Key

**File:** `lib/services/supabase_config.dart`

Pastikan API key lengkap:

```dart
static const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjZ3Z4d212em9oYmNzeXFmZ2J6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY1MTI4NzksImV4cCI6MjA2MjA4ODg3OX0.sb_publishable_X8FN205s7DWfXLxj8SrFzg_VnQaerQ4';
```

---

### Solusi 4: Restart App

Setelah perubahan config:

```bash
# Stop app (Ctrl+C)
flutter clean
flutter pub get
flutter run
```

---

## 📊 Expected Console Output (Berhasil)

```
🔍 Form validated, starting registration...
📧 Email: test123@example.com
👤 Name: Test User
📱 Phone: +62812 3456 7890
📝 Starting registration for: test123@example.com
✅ Auth signup successful
👤 User ID: 12345678-1234-1234-1234-123456789012
✅ Profile fetched from database
✅ Registration complete
```

**Di App:**
- ✅ Snackbar hijau: "Selamat datang, Test User! Silakan login"
- ✅ Kembali ke halaman login

---

## 🎯 Checklist Sebelum Test Ulang

- [ ] SQL setup sudah dijalankan (`SETUP_REGISTRASI_LENGKAP.sql`)
- [ ] Verification queries menunjukkan semua ✅
- [ ] Email confirmation sudah OFF
- [ ] API key sudah benar dan lengkap
- [ ] App sudah di-restart
- [ ] Menggunakan email yang belum pernah dipakai
- [ ] Password minimal 8 karakter
- [ ] Nomor telepon hanya angka

---

## 💡 Tips Debug

### 1. Selalu Cek Console Log
Console log sekarang lebih detail dengan emoji:
- 🔍 = Debug info
- 📧 = Email
- 👤 = User info
- 📱 = Phone
- ✅ = Success
- ❌ = Error
- ⚠️ = Warning

### 2. Test Step by Step
1. Cek console log saat app start
2. Isi form dengan data valid
3. Klik Daftar
4. Lihat console log untuk error detail
5. Cek database apakah data masuk

### 3. Gunakan Email Baru
Setiap test, gunakan email baru:
- test1@example.com
- test2@example.com
- test3@example.com

### 4. Screenshot Error
Jika masih error, screenshot:
- Console log lengkap
- Error message di app
- Verification queries result

---

## 🔄 Quick Fix Script

Jika masih bermasalah, jalankan ini di SQL Editor:

```sql
-- Reset semua (HATI-HATI!)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP TABLE IF EXISTS public.users CASCADE;

-- Lalu jalankan SETUP_REGISTRASI_LENGKAP.sql
```

---

## 📞 Masih Error?

Jika setelah semua langkah masih error:

1. **Copy console log lengkap** (dari app start sampai error)
2. **Screenshot error** di app
3. **Jalankan verification queries** dan screenshot hasilnya
4. **Cek Supabase Dashboard → Logs** untuk error detail

---

## ✅ Success Criteria

Registrasi berhasil jika:

- ✅ Console log menunjukkan "✅ Registration complete"
- ✅ Snackbar hijau muncul
- ✅ Data ada di `auth.users`
- ✅ Data ada di `public.users`
- ✅ Bisa login dengan kredensial baru

---

**Last Updated:** 2026-05-06  
**Status:** ✅ Enhanced Logging Added

**Next Step:** Jalankan app dan cek console log untuk error detail!
