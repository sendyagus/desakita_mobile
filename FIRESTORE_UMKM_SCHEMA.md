# Skema Firestore untuk UMKM DesaKita

Buat koleksi **`umkm`**. Setiap dokumen mewakili satu usaha lokal. Field `status: true` diperlukan agar usaha muncul pada tab UMKM dan beranda.

Contoh dokumen:

```json
{
  "name": "ALYN Tapis",
  "category": "Kerajinan",
  "location": "Sumber Agung, Kemiling, Bandar Lampung",
  "description": "Kerajinan tapis Lampung. Tambahkan deskripsi asli usaha di sini.",
  "rating": 4.8,
  "reviewCount": 120,
  "openingHours": "08:00 - 17:00 WIB",
  "imageUrl": "",
  "status": true,
  "products": [
    {
      "name": "Peci Tapis Premium",
      "price": "Rp 150.000",
      "imageUrl": ""
    },
    {
      "name": "Tas Sulam Etnik",
      "price": "Rp 275.000",
      "imageUrl": ""
    }
  ]
}
```

Catatan:

- `imageUrl` dan `products[].imageUrl` boleh kosong untuk memakai gambar fallback lokal; unggah foto asli dan isi URL Firebase Storage ketika sudah tersedia.
- Kategori yang disediakan pada filter UI: `Kuliner`, `Kerajinan`, `Oleh-oleh`, dan `Budaya`.
- Gunakan angka untuk `rating` dan `reviewCount`.
- `products` harus berupa array berisi objek dengan `name`, `price`, dan opsional `imageUrl`.
- Gunakan data usaha nyata dan terverifikasi. Angka rating/jumlah ulasan pada contoh hanyalah contoh format, bukan klaim faktual tentang usaha tertentu.
- Aturan keamanan Firestore tetap perlu mengizinkan pembacaan untuk pengguna aplikasi. Jangan membuka izin tulis publik hanya supaya data tampil.


## Aturan akses Firestore

Aturan proyek telah ditambahkan pada `firestore.rules` untuk memberi akses baca pada dokumen UMKM aktif (`status: true`) dan membatasi pembuatan/perubahan/penghapusan dokumen UMKM kepada admin. `firebase.json` juga menunjuk ke file aturan dan indeks tersebut.

Sebelum menerapkan aturan ke proyek Firebase, bandingkan dengan aturan aktif di Firebase Console karena deployment mengganti rules yang sedang berjalan. Untuk menerapkan setelah ditinjau, gunakan `firebase deploy --only firestore:rules` dari root proyek.
