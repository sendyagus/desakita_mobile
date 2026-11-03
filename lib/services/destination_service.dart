import 'package:cloud_firestore/cloud_firestore.dart';

/// CRUD destinasi wisata di Firestore (`destinations`).
/// Map yang dikembalikan memakai key snake_case agar kompatibel dengan kode lama.
class DestinationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _col = 'destinations';

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
      'description': d['description'],
      'rating': (d['rating'] as num?)?.toDouble() ?? 0.0,
      'price': d['price'] ?? '',
      'image_url': d['imageUrl'],
      'status': d['status'] ?? true,
      'created_at': iso(c),
      'updated_at': iso(u),
    };
  }

  /// Public: konversi dokumen Firestore ke map tampilan (snake_case) yang
  /// dipakai layar favorit/detail lama.
  Map<String, dynamic> docDataToFormMap(String id, Map<String, dynamic> d) {
    return _docToMap(id, d);
  }

  Map<String, dynamic> _inputToFirestore({
    required String name,
    required String category,
    required String location,
    required double rating,
    required String price,
    String? description,
    String? imageUrl,
    bool status = true,
    String? facilities,
    String? mapsUrl,
    String? contact,
    String? openingHours,
    bool bookable = false,
    int stock = 0,
  }) {
    return {
      'name': name,
      'category': category,
      'location': location,
      'rating': rating,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'status': status,
      'facilities': facilities,
      'mapsUrl': mapsUrl,
      'contact': contact,
      'openingHours': openingHours,
      'bookable': bookable,
      'stock': stock,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<List<Map<String, dynamic>>> getAllDestinations() async {
    final snap = await _db
        .collection(_col)
        .where('status', isEqualTo: true)
        .get();
    final list = snap.docs.map((d) => _docToMap(d.id, d.data())).toList()
      ..sort((a, b) {
        final ca =
            DateTime.tryParse(a['created_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final cb =
            DateTime.tryParse(b['created_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return cb.compareTo(ca);
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
    final list = snap.docs.map((d) => _docToMap(d.id, d.data())).toList()
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
        status: true,
        facilities: facilities,
        mapsUrl: mapsUrl,
        contact: contact,
        openingHours: openingHours,
        bookable: bookable,
        stock: stock,
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
    bool? status,
    String? facilities,
    String? mapsUrl,
    String? contact,
    String? openingHours,
    bool? bookable,
    int? stock,
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
    if (status != null) updates['status'] = status;
    if (facilities != null) updates['facilities'] = facilities;
    if (mapsUrl != null) updates['mapsUrl'] = mapsUrl;
    if (contact != null) updates['contact'] = contact;
    if (openingHours != null) updates['openingHours'] = openingHours;
    if (bookable != null) updates['bookable'] = bookable;
    if (stock != null) updates['stock'] = stock;

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
