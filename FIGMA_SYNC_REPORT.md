# Laporan Sinkronisasi DesaKita Mobile dengan Figma — DESAIN FIX

## Cakupan perubahan

Perubahan ini adalah tahap sinkronisasi UI dan alur dasar pada proyek Flutter yang sudah ada. Struktur Firebase Authentication, Firestore, layanan pengguna, dan halaman admin yang sudah ada tetap dipertahankan.

### Perubahan yang sudah diterapkan

1. **Design system**
   - Warna primer hijau `#006C04`, hijau gelap `#154212`, aksen `#10B981`, aksen amber `#F59E0B`, latar `#F9FAF7`.
   - Tipografi tema diarahkan ke Plus Jakarta Sans.
   - Warna pada beberapa halaman autentikasi, profil, admin, dan asisten diselaraskan dengan token tersebut.

2. **Beranda**
   - Hero bergambar, sapaan pengguna, aksi cepat, kartu destinasi populer, rekomendasi UMKM, serta navigasi bawah lima tab.
   - Destinasi dibaca langsung dari koleksi `destinations` Firestore.
   - Rekomendasi usaha dipisahkan dan dibaca dari koleksi `umkm`.

3. **Eksplorasi**
   - Pencarian, filter kategori, pemisah Wisata/UMKM, kartu foto, rating, lokasi, dan navigasi ke halaman detail.
   - Tombol peta dan pencarian suara diberi pemberitahuan karena layanan peta/STT belum dikonfigurasi.

4. **Onboarding preferensi**
   - Empat langkah: usia, anggaran, gaya liburan, dan teman perjalanan.
   - Preferensi disimpan pada `users/{uid}` melalui `preferencesCompleted` dan `travelPreferences`.
   - Pengguna dapat melewati onboarding.

5. **Detail destinasi dan UMKM**
   - Detail destinasi mencakup foto, lokasi, rating, jam operasional, deskripsi, fasilitas, harga, dan tombol pemesanan.
   - Detail UMKM baru menampilkan profil usaha dan katalog produk dari field `products`.

6. **Pemesanan tiket dan Trip**
   - Alur tiga tahap: jadwal/sesi, identitas, dan pilihan metode pembayaran.
   - Jumlah pengunjung dan ringkasan harga dihitung di aplikasi.
   - Pesanan disimpan di koleksi `bookings` dengan status `pending` dan `paymentStatus: awaiting_payment`.
   - Tab Trip membaca pesanan pengguna dan memisahkan rencana/aktif dari riwayat.

7. **Kita AI — mode demo berbasis data aplikasi**
   - Tampilan percakapan dipertahankan dan teksnya diselaraskan dengan konsep Kita AI.
   - Jawaban untuk rekomendasi membaca katalog `destinations`, `umkm`, atau `events` bila data tersedia.
   - UI menjelaskan bahwa ini belum terhubung ke model AI generatif.

## Catatan penting sebelum dipakai

- File `firestore.rules` lokal telah disesuaikan untuk koleksi `umkm` (dokumen aktif dapat dibaca, tulis hanya admin), serta membatasi agar akun biasa tidak dapat mengubah `role` atau `isActive` miliknya sendiri. Perubahan ini belum diterapkan ke Firebase remote. Pastikan membandingkan file dengan aturan aktif sebelum deployment.

- **Koleksi `umkm` belum ditemukan di implementasi awal.** Halaman UMKM akan kosong sampai koleksi tersebut dibuat dan diisi di Firestore. Format datanya ada di `FIRESTORE_UMKM_SCHEMA.md`. File lokal `firestore.rules` kini mengizinkan baca dokumen UMKM aktif dan membatasi tulis ke admin. `firebase.json` telah dikaitkan dengan file rules/indexes; tinjau aturan yang sedang live di Firebase Console sebelum menjalankan deployment.
- Tidak ada integrasi gateway pembayaran. Pilihan QRIS/transfer/e-wallet di UI hanya menyimpan metode pilihan dan status menunggu pembayaran; tidak memproses transaksi.
- Kode referensi pesanan bukan QR tiket masuk yang dapat dipindai. Penerbitan QR e-tiket aktif perlu dikembangkan.
- Integrasi peta, koordinat/rute, navigasi kamera/AR, cuaca langsung, notifikasi push, dan pengenalan suara belum dibuat.
- Kita AI masih berbasis aturan sederhana dan data Firestore, bukan LLM atau AI generatif.
- Menu sekunder pada profil selain Riwayat Pesanan masih berupa placeholder.
- Biaya pemesanan memakai satu harga `price` per pengunjung; belum ada pemisahan tarif dewasa dan anak seperti pada sebagian layar Figma.

## Langkah verifikasi lokal

Flutter SDK/Dart tidak tersedia pada lingkungan penyuntingan ini sehingga analyzer, test runner, dan emulator tidak dapat dijalankan di sini. Pemeriksaan yang dilakukan terbatas pada inventaris file, referensi import lokal, dan pemeriksaan struktur tanda kurung/kawat Dart; ini bukan pengganti `flutter analyze`. Setelah ZIP diekstrak pada mesin pengembangan, jalankan dari direktori proyek:

```bash
flutter pub get
dart format lib
flutter analyze
flutter test
flutter run
```

Jika `flutter analyze` melaporkan isu, periksa pesan beserta nomor barisnya sebelum dipakai untuk demo. Widget test juga diselaraskan dengan alur aplikasi saat ini yang dimulai dari Splash Screen.

## Urutan pengembangan yang disarankan berikutnya

1. Tambahkan CRUD UMKM di dashboard admin.
2. Seed data UMKM dan lengkapi foto, fasilitas, jam operasional, serta harga destinasi di Firestore.
3. Integrasikan gateway pembayaran dan QR tiket yang diverifikasi di backend.
4. Integrasikan peta, layanan cuaca, serta API AI untuk Kita AI.
5. Implementasikan notifikasi, bahasa, dan menu profil yang saat ini masih placeholder.
