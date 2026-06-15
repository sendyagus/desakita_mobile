import 'package:intl/intl.dart';

/// Utility untuk menangani harga yang bisa berupa String ("Rp 450.000")
/// maupun angka (450000) di Firestore.
///
/// Memberikan satu titik konversi sehingga semua perhitungan numerik
/// menggunakan fungsi yang sama, bukan parse manual di setiap file.
class PriceHelper {
  PriceHelper._();

  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Mengubah harga (String atau num) menjadi angka [double].
  ///
  /// - `"Rp 450.000"` → `450000`
  /// - `450000` (int/double) → `450000.0`
  /// - `null` / kosong → `0`
  static double toNumber(dynamic price) {
    if (price == null) return 0;
    if (price is num) return price.toDouble();
    if (price is String) {
      if (price.trim().isEmpty) return 0;
      final cleaned = price.replaceAll(RegExp(r'[^0-9]'), '');
      return double.tryParse(cleaned) ?? 0;
    }
    return 0;
  }

  /// Mengubah harga (String atau num) menjadi [int].
  static int toInt(dynamic price) => toNumber(price).round();

  /// Format angka menjadi string Rupiah: `450000` → `"Rp 450.000"`.
  static String format(num amount) => _formatter.format(amount);

  /// Format dari dynamic (String/num) langsung ke string Rupiah.
  static String formatAny(dynamic price) => format(toNumber(price));
}
