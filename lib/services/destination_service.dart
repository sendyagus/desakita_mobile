import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desa_wisata/config/app_categories.dart';

/// CRUD destinasi wisata di Firestore (`destinations`).
/// Map yang dikembalikan memakai key snake_case agar kompatibel dengan kode lama.
class DestinationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _col = 'destinations';

  /// Map dokumen Firestore ke format form admin (snake_case).
  Map<String, dynamic> docDataToFormMap(String id, Map<String, dynamic> d) {
    return _docToMap(id, d);
  }

  Map<String, dynamic> _docToMap(String id, Map<String, dynamic> d) {
    final c = d['createdAt'];
    final u = d['updatedAt'];
    String iso(dynamic v) {
      if (v is Timestamp) return v.toDate().toIso8601String();
      if (v is String) return v;
      return DateTime.now().toIso8601String();
    }

    return {
      'id': id,
      'name': d['name'] ?? '',
      'category': d['category'] ?? '',
      'location': d['location'] ?? '',
      'description': d['description'] ?? '',
      'rating': (d['rating'] as num?)?.toDouble() ?? 0.0,
      'price': d['price'] ?? '',
      'image_url': d['imageUrl'],
      'facilities': d['facilities'] ?? '',
      'mapsUrl': d['mapsUrl'] ?? '',
      'contact': d['contact'] ?? '',
      'openingHours': d['openingHours'] ?? '',
      'bookable': d['bookable'] ?? false,
      'stock': (d['stock'] as num?)?.toInt() ?? 0,
      'status': d['status'] ?? true,
      'created_at': iso(c),
      'updated_at': iso(u),
    };
  }

  Map<String, dynamic> _inputToFirestore({
    required String name,
    required String category,
    required String location,
    required double rating,
    required String price,
    String? description,
    String? imageUrl,
    String? facilities,
    String? mapsUrl,
    String? contact,
    String? openingHours,
    bool bookable = false,
    int stock = 0,
    bool status = true,
  }) {
    return {
      'name': name,
      'category': category,
      'location': location,
      'rating': rating,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'facilities': facilities,
      'mapsUrl': mapsUrl,
      'contact': contact,
      'openingHours': openingHours,
      'bookable': bookable,
      'stock': stock,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Destinasi yang bisa dibooking: Penginapan + wisata (Alam), stok > 0.
  Future<List<Map<String, dynamic>>> getBookableDestinations() async {
    final snap = await _db
        .collection(_col)
        .where('status', isEqualTo: true)
        .where('bookable', isEqualTo: true)
        .get();
    final list = snap.docs
        .map((d) => _docToMap(d.id, d.data()))
        .where((row) {
          final cat = AppCategories.normalize(row['category'] as String?);
          final stock = (row['stock'] as num?)?.toInt() ?? 0;
          return AppCategories.isBookableCategory(cat) && stock > 0;
        })
        .toList();
    list.sort((a, b) {
      final ca = AppCategories.normalize(a['category'] as String?);
      final cb = AppCategories.normalize(b['category'] as String?);
      if (ca == 'Penginapan' && cb != 'Penginapan') return -1;
      if (cb == 'Penginapan' && ca != 'Penginapan') return 1;
      return (a['name'] as String).compareTo(b['name'] as String);
    });
    return list;
  }

  Future<List<Map<String, dynamic>>> getAllDestinations() async {
    final snap = await _db
        .collection(_col)
        .where('status', isEqualTo: true)
        .get();
    final list = snap.docs.map((d) => _docToMap(d.id, d.data())).toList();
    list.sort((a, b) {
      final ra = (a['rating'] as num?)?.toDouble() ?? 0;
      final rb = (b['rating'] as num?)?.toDouble() ?? 0;
      return rb.compareTo(ra);
    });
    return list;
  }

  Future<List<Map<String, dynamic>>> getDestinationsByCategory(
    String category,
  ) async {
    final snap = await _db
        .collection(_col)
        .where('category', isEqualTo: category)
        .where('status', isEqualTo: true)
        .get();
    final list = snap.docs
        .map((d) => _docToMap(d.id, d.data()))
        .toList()
      ..sort((a, b) {
        final ra = (a['rating'] as num?)?.toDouble() ?? 0;
        final rb = (b['rating'] as num?)?.toDouble() ?? 0;
        return rb.compareTo(ra);
      });
    return list;
  }

  Future<Map<String, dynamic>?> getDestinationById(String id) async {
    final doc = await _db.collection(_col).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return _docToMap(doc.id, doc.data()!);
  }

  Future<List<Map<String, dynamic>>> searchDestinations(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAllDestinations();
    final all = await getAllDestinations();
    return all.where((row) {
      final name = (row['name'] as String? ?? '').toLowerCase();
      final loc = (row['location'] as String? ?? '').toLowerCase();
      return name.contains(q) || loc.contains(q);
    }).toList();
  }

  Future<Map<String, dynamic>> addDestination({
    required String name,
    required String category,
    required String location,
    required double rating,
    required String price,
    String? description,
    String? imageUrl,
    String? facilities,
    String? mapsUrl,
    String? contact,
    String? openingHours,
    bool bookable = false,
    int stock = 0,
  }) async {
    final now = FieldValue.serverTimestamp();
    final ref = await _db.collection(_col).add({
      ..._inputToFirestore(
        name: name,
        category: category,
        location: location,
        rating: rating,
        price: price,
        description: description,
        imageUrl: imageUrl,
        facilities: facilities,
        mapsUrl: mapsUrl,
        contact: contact,
        openingHours: openingHours,
        bookable: bookable,
        stock: stock,
        status: true,
      ),
      'createdAt': now,
    });
    final doc = await ref.get();
    return _docToMap(doc.id, doc.data()!);
  }

  Future<Map<String, dynamic>> updateDestination({
    required String id,
    String? name,
    String? category,
    String? location,
    double? rating,
    String? price,
    String? description,
    String? imageUrl,
    String? facilities,
    String? mapsUrl,
    String? contact,
    String? openingHours,
    bool? bookable,
    int? stock,
    bool? status,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (name != null) updates['name'] = name;
    if (category != null) updates['category'] = category;
    if (location != null) updates['location'] = location;
    if (rating != null) updates['rating'] = rating;
    if (price != null) updates['price'] = price;
    if (description != null) updates['description'] = description;
    if (imageUrl != null) updates['imageUrl'] = imageUrl;
    if (facilities != null) updates['facilities'] = facilities;
    if (mapsUrl != null) updates['mapsUrl'] = mapsUrl;
    if (contact != null) updates['contact'] = contact;
    if (openingHours != null) updates['openingHours'] = openingHours;
    if (bookable != null) updates['bookable'] = bookable;
    if (stock != null) updates['stock'] = stock;
    if (status != null) updates['status'] = status;

    await _db.collection(_col).doc(id).update(updates);
    final doc = await _db.collection(_col).doc(id).get();
    return _docToMap(doc.id, doc.data()!);
  }

  Future<void> deleteDestination(String id) async {
    await _db.collection(_col).doc(id).delete();
  }

  Future<void> toggleDestinationStatus(String id, bool newStatus) async {
    await _db.collection(_col).doc(id).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
