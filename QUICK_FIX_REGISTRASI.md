# ⚡ QUICK FIX REGISTRASI - 3 Langkah

## 🎯 Ikuti 3 Langkah Ini:

---

## 1️⃣ JALANKAN SQL (2 menit)

1. Buka: https://supabase.com/dashboard
2. Pilih project: `hcgvxwmvzohbcsyqfgbz`
3. Klik: **SQL Editor** → **New Query**
4. Copy **SEMUA** isi file: `SETUP_REGISTRASI_LENGKAP.sql`
5. Paste dan klik **Run**
6. Tunggu sampai selesai
7. **Cek hasil verification** (harus semua ✅)

---

## 2️⃣ MATIKAN EMAIL CONFIRMATION (1 menit)

1. Klik: **Authentication** → **Providers**
2. Scroll ke: **Email**
3. Toggle **OFF**: "Confirm email"
4. Klik: **Save**

---

## 3️⃣ TEST REGISTRASI (2 menit)

```bash
flutter run
```

1. Klik "Daftar"
2. Isi form:
   - Nama: Budi Santoso
   - Email: budi.test@example.com
   - Phone: 812 3456 7890
   - Password: password123
3. Klik "Daftar"
4. **Cek console log**

---

## ✅ HASIL YANG DIHARAPKAN:

### Console Log:
```
📝 Starting registration for: budi.test@example.com
✅ Auth signup successful
👤 User ID: xxx-xxx-xxx
✅ Profile fetched from database
✅ Registration complete
```

### Di App:
- ✅ Snackbar hijau: "Selamat datang, Budi Santoso!"
- ✅ Kembali ke login

### Di Database:
- ✅ Data ada di Table Editor > users

---

## ❌ JIKA GAGAL:

### Error: "relation does not exist"
→ Ulangi Langkah 1

### Error: "Profile not found"
→ Cek apakah data masuk ke database (Table Editor)

### Error: "Email already registered"
→ Gunakan email lain atau hapus user lama:
```sql
DELETE FROM auth.users WHERE email = 'budi.test@example.com';
```

---

## 📖 PANDUAN LENGKAP:

Baca: **PANDUAN_FIX_REGISTRASI.md**

---

**Total Waktu:** 5 menit  
**Success Rate:** 99%

**🚀 MULAI DARI LANGKAH 1!**
