import 'package:cloud_firestore/cloud_firestore.dart';

/// Hasil satu halaman query Firestore beserta cursor untuk halaman berikutnya.
class PagedResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  const PagedResult({
    required this.items,
    this.lastDoc,
    required this.hasMore,
  });
}

/// Helper untuk menjalankan query paginasi berbasis cursor di Firestore.
///
/// Contoh pakai:
/// ```dart
/// final page = await FirestorePager.queryMap(
///   collection: FirebaseFirestore.instance.collection('destinations'),
///   pageSize: 20,
///   startAfter: previousLastDoc, // null untuk halaman pertama
///   mapper: (id, data) => {'id': id, ...data},
/// );
/// ```
class FirestorePager {
  FirestorePager._();

  /// Query koleksi Firestore dengan paginasi cursor-based.
  ///
  /// - [collection]: Query yang sudah di-filter (bisa juga CollectionReference).
  /// - [pageSize]: Jumlah dokumen per halaman.
  /// - [startAfter]: Dokumen terakhir dari halaman sebelumnya (null = halaman pertama).
  /// - [mapper]: Fungsi konversi dokumen Firestore ke tipe [T].
  static Future<PagedResult<T>> queryMap<T>({
    required Query<Map<String, dynamic>> collection,
    required int pageSize,
    DocumentSnapshot? startAfter,
    required T Function(String id, Map<String, dynamic> data) mapper,
  }) async {
    Query<Map<String, dynamic>> q = collection.limit(pageSize + 1);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    final snap = await q.get();
    final docs = snap.docs;

    final hasMore = docs.length > pageSize;
    final pageDocs = hasMore ? docs.sublist(0, pageSize) : docs;

    final items = pageDocs.map((d) => mapper(d.id, d.data())).toList();
    final lastDoc = pageDocs.isNotEmpty ? pageDocs.last : null;

    return PagedResult<T>(
      items: items,
      lastDoc: lastDoc,
      hasMore: hasMore,
    );
  }
}
