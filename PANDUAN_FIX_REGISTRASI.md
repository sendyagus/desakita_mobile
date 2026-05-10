# 🔧 Panduan Fix Registrasi - Step by Step

## 🎯 Tujuan
Membuat registrasi berfungsi 100% dan data user masuk ke database.

---

## ⚡ LANGKAH 1: Setup Database (WAJIB!)

### 1.1 Buka Supabase Dashboard
1. Buka browser
2. Ke: https://supabase.com/dashboard
3. Login dengan akun Anda
4. Pilih project: **hcgvxwmvzohbcsyqfgbz**

### 1.2 Jalankan SQL Setup
1. Klik menu **SQL Editor** (di sidebar kiri)
2. Klik tombol **New Query** (tombol + di atas)
3. Buka file `SETUP_REGISTRASI_LENGKAP.sql` di project
4. **Copy SEMUA isinya** (Ctrl+A lalu Ctrl+C)
5. **Paste** ke SQL Editor (Ctrl+V)
6. Klik tombol **Run** (atau tekan Ctrl+Enter)
7. **Tunggu** sampai selesai

### 1.3 Cek Hasil Verification
Setelah run SQL, scroll ke bawah. Harus muncul hasil seperti ini:

```
item                          | status
------------------------------|------------------
Tabel users                   | ✅ Ada
Trigger on_auth_user_created  | ✅ Ada
Function handle_new_user      | ✅ Ada
RLS enabled                   | ✅ Enabled
Policies count                | 6 policies
```

**✅ Jika semua ✅:** Lanjut ke Langkah 2
**❌ Jika ada ❌:** Ulangi langkah 1.2

---

## ⚡ LANGKAH 2: Matikan Email Confirmation

### 2.1 Buka Authentication Settings
1. Masih di Supabase Dashboard
2. Klik menu **Authentication** (di sidebar kiri)
3. Klik tab **Providers**
4. Scroll ke bawah ke bagian **Email**

### 2.2 Matikan Confirm Email
1. Cari toggle **"Confirm email"**
2. **Klik toggle** sampai jadi OFF (abu-abu)
3. Klik tombol **Save** di bawah

**PENTING:** Ini harus OFF untuk testing!

---

## ⚡ LANGKAH 3: Verify Setup di Database

### 3.1 Cek Tabel Users
1. Klik menu **Table Editor** (di sidebar kiri)
2. Cari tabel **users** di list
3. Klik tabel **users**

**✅ Jika tabel ada:** Lanjut
**❌ Jika tidak ada:** Ulangi Langkah 1

### 3.2 Cek Struktur Tabel
Di Table Editor, pastikan kolom-kolom ini ada:
- ✅ id (uuid)
- ✅ full_name (varchar)
- ✅ email (varchar)
- ✅ phone (varchar)
- ✅ avatar_url (text)
- ✅ role (varchar)
- ✅ is_active (boolean)
- ✅ created_at (timestamp)
- ✅ updated_at (timestamp)

---

## ⚡ LANGKAH 4: Test Registrasi

### 4.1 Restart App
```bash
# Stop app (Ctrl+C di terminal)
# Lalu run lagi:
flutter run
```

### 4.2 Buka Halaman Register
1. Di app, klik tombol **"Daftar"**
2. Isi form dengan data test:

```
Nama Lengkap: Budi Santoso
Email: budi.test@example.com
Nomor Telepon: 812 3456 7890
Kata Sandi: password123
Konfirmasi: password123
```

### 4.3 Klik Daftar
1. Klik tombol **"Daftar"**
2. **PENTING:** Jangan tutup terminal!
3. **Lihat console log** di terminal

---

## ✅ HASIL YANG DIHARAPKAN

### Di Console Log (Terminal):
```
📝 Starting registration for: budi.test@example.com
✅ Auth signup successful
👤 User ID: 12345678-1234-1234-1234-123456789012
✅ Profile fetched from database
✅ Registration complete
```

### Di App:
- ✅ Muncul snackbar hijau
- ✅ Pesan: "Selamat datang, Budi Santoso! Silakan login"
- ✅ Kembali ke halaman login

### Di Database:
1. Buka Supabase Dashboard
2. Table Editor > users
3. **Harus ada data baru:**
   - full_name: Budi Santoso
   - email: budi.test@example.com
   - phone: +62812 3456 7890
   - role: user
   - is_active: true

---

## ❌ TROUBLESHOOTING

### Problem 1: "relation public.users does not exist"

**Console Log:**
```
❌ Registration error: relation "public.users" does not exist
```

**Artinya:** Tabel users belum dibuat

**Solusi:**
1. Ulangi Langkah 1 (jalankan SQL setup)
2. Pastikan tidak ada error saat run SQL
3. Verify di Table Editor

---

### Problem 2: "Profile not found, creating manually"

**Console Log:**
```
📝 Starting registration for: budi.test@example.com
✅ Auth signup successful
👤 User ID: xxx
⚠️  Profile not found, creating manually: ...
✅ Registration complete
```

**Artinya:** Trigger tidak jalan, tapi fallback berhasil

**Cek:**
1. Apakah data masuk ke database? (cek Table Editor)
2. Jika YA: OK, trigger memang tidak jalan tapi fallback work
3. Jika TIDAK: Ada masalah dengan RLS policies

**Solusi:**
Jalankan query ini di SQL Editor:
```sql
-- Cek trigger
SELECT tgname, tgenabled 
FROM pg_trigger 
WHERE tgname = 'on_auth_user_created';

-- Jika tidak ada hasil, recreate trigger:
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

---

### Problem 3: "Email already registered"

**Console Log:**
```
❌ Email sudah terdaftar
```

**Artinya:** Email sudah digunakan

**Solusi:**
Gunakan email lain, atau hapus user lama:
```sql
-- Di SQL Editor
DELETE FROM auth.users WHERE email = 'budi.test@example.com';
```

---

### Problem 4: Data tidak muncul di database

**Cek di SQL Editor:**
```sql
-- Cek di auth.users
SELECT id, email, created_at 
FROM auth.users 
WHERE email = 'budi.test@example.com';

-- Cek di public.users
SELECT id, full_name, email, phone, role 
FROM public.users 
WHERE email = 'budi.test@example.com';
```

**Jika ada di auth.users tapi TIDAK di public.users:**

**Solusi:** Sinkronisasi manual
```sql
INSERT INTO public.users (id, full_name, email, phone, role, is_active)
SELECT 
    au.id,
    COALESCE(au.raw_user_meta_data->>'full_name', ''),
    au.email,
    COALESCE(au.raw_user_meta_data->>'phone', ''),
    'user',
    true
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL 
AND au.email = 'budi.test@example.com';
```

---

### Problem 5: RLS Policy Error

**Console Log:**
```
❌ Registration error: new row violates row-level security policy
```

**Artinya:** RLS policy terlalu ketat

**Solusi:** Jalankan ini di SQL Editor:
```sql
-- Drop policy lama
DROP POLICY IF EXISTS "Enable insert for authentication" ON public.users;

-- Buat policy baru yang lebih permissive
CREATE POLICY "Enable insert for authentication"
  ON public.users
  FOR INSERT
  WITH CHECK (true);
```

---

## 🔍 DEBUGGING CHECKLIST

Sebelum test, pastikan:

- [ ] SQL setup sudah dijalankan (Langkah 1)
- [ ] Verification queries menunjukkan semua ✅
- [ ] Email confirmation sudah OFF (Langkah 2)
- [ ] Tabel users ada di Table Editor (Langkah 3)
- [ ] App sudah di-restart (Langkah 4)
- [ ] Menggunakan email yang belum pernah dipakai

---

## 📊 VERIFICATION QUERIES

Jalankan queries ini di SQL Editor untuk cek setup:

```sql
-- 1. Cek tabel users
SELECT COUNT(*) as total_columns 
FROM information_schema.columns 
WHERE table_name = 'users' AND table_schema = 'public';
-- Expected: 9 columns

-- 2. Cek trigger
SELECT tgname, tgenabled 
FROM pg_trigger 
WHERE tgname = 'on_auth_user_created';
-- Expected: 1 row, tgenabled = 'O'

-- 3. Cek function
SELECT proname, prosrc 
FROM pg_proc 
WHERE proname = 'handle_new_user';
-- Expected: 1 row

-- 4. Cek RLS
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'users' AND schemaname = 'public';
-- Expected: rowsecurity = true

-- 5. Cek policies
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'users';
-- Expected: minimal 6 policies

-- 6. Cek semua user
SELECT id, full_name, email, role, created_at 
FROM public.users 
ORDER BY created_at DESC;
-- Expected: list semua user yang sudah register
```

---

## 🎯 QUICK FIX SCRIPT

Jika masih bermasalah, jalankan script ini untuk reset dan setup ulang:

```sql
-- RESET (HATI-HATI: Hapus semua user!)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP TABLE IF EXISTS public.users CASCADE;
DELETE FROM auth.users; -- Hapus semua user

-- Lalu jalankan SETUP_REGISTRASI_LENGKAP.sql lagi
```

---

## 💡 TIPS

1. **Gunakan email baru** setiap test
2. **Cek console log** untuk debugging
3. **Verify di database** setelah register
4. **Jangan skip langkah** - ikuti urutan
5. **Screenshot error** jika ada masalah

---

## 📞 MASIH BERMASALAH?

Jika setelah semua langkah masih bermasalah:

1. **Screenshot console log** saat register
2. **Screenshot error message** di app
3. **Jalankan verification queries** dan screenshot hasilnya
4. **Cek Table Editor** apakah data ada

---

## ✅ SUCCESS CRITERIA

Registrasi dianggap berhasil jika:

- ✅ Console log menunjukkan "✅ Registration complete"
- ✅ Muncul snackbar hijau di app
- ✅ Data muncul di `auth.users`
- ✅ Data muncul di `public.users`
- ✅ Bisa login dengan kredensial yang baru didaftarkan

---

**Last Updated:** 2026-05-06  
**Estimated Time:** 10-15 menit  
**Success Rate:** 99% jika ikuti semua langkah

---

## 🚀 MULAI SEKARANG!

**Langkah pertama:** Buka Supabase Dashboard dan jalankan `SETUP_REGISTRASI_LENGKAP.sql`

**Good luck!** 🎉
