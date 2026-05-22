import 'package:cloud_firestore/cloud_firestore.dart';

/// Service untuk mengelola events/acara desa di Firestore
class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _col = 'events';

  Map<String, dynamic> _docToMap(String id, Map<String, dynamic> d) {
    final start = d['startDate'];
    final end = d['endDate'];
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
      'description': d['description'] ?? '',
      'location': d['location'] ?? '',
      'category': d['category'] ?? '',
      'start_date': iso(start),
      'end_date': iso(end),
      'price': d['price'] ?? '',
      'image_url': d['imageUrl'],
      'organizer': d['organizer'] ?? '',
      'contact': d['contact'] ?? '',
      'max_participants': d['maxParticipants'] ?? 0,
      'current_participants': d['currentParticipants'] ?? 0,
      'status': d['status'] ?? true,
      'created_at': iso(c),
      'updated_at': iso(u),
    };
  }

  Future<List<Map<String, dynamic>>> getAllEvents() async {
    final snap = await _db
        .collection(_col)
        .where('status', isEqualTo: true)
        .get();
    final list = snap.docs
        .map((d) => _docToMap(d.id, d.data()))
        .toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(a['start_date'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final db = DateTime.tryParse(b['start_date'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return da.compareTo(db); // Sort by start date ascending
      });
    return list;
  }

  Future<List<Map<String, dynamic>>> getUpcomingEvents() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final all = await getAllEvents();
    return all.where((event) {
      final start = DateTime.tryParse(event['start_date'] as String? ?? '');
      return start != null && !DateTime(start.year, start.month, start.day).isBefore(today);
    }).toList();
  }

  /// Acara mendatang atau sedang berjalan — untuk tampilan beranda.
  Future<List<Map<String, dynamic>>> getHomeEvents() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final all = await getAllEvents();
    return all.where((event) {
      final end = DateTime.tryParse(event['end_date'] as String? ?? '');
      final start = DateTime.tryParse(event['start_date'] as String? ?? '');
      final endDay = end != null
          ? DateTime(end.year, end.month, end.day)
          : (start != null
              ? DateTime(start.year, start.month, start.day)
              : today);
      return !endDay.isBefore(today);
    }).toList();
  }

  static String eventPhaseLabel(Map<String, dynamic> event) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime.tryParse(event['start_date'] as String? ?? '');
    final end = DateTime.tryParse(event['end_date'] as String? ?? '');
    if (start == null) return 'Akan Datang';
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = end != null
        ? DateTime(end.year, end.month, end.day)
        : startDay;
    if (today.isBefore(startDay)) return 'Akan Datang';
    if (!today.isAfter(endDay)) return 'Sedang Berjalan';
    return 'Selesai';
  }

  Future<Map<String, dynamic>?> getEventById(String id) async {
    final doc = await _db.collection(_col).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return _docToMap(doc.id, doc.data()!);
  }

  Future<Map<String, dynamic>> addEvent({
    required String name,
    required String description,
    required String location,
    required String category,
    required DateTime startDate,
    required DateTime endDate,
    required String price,
    required String organizer,
    required String contact,
    int maxParticipants = 0,
    String? imageUrl,
  }) async {
    final now = FieldValue.serverTimestamp();
    final ref = await _db.collection(_col).add({
      'name': name,
      'description': description,
      'location': location,
      'category': category,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'price': price,
      'organizer': organizer,
      'contact': contact,
      'maxParticipants': maxParticipants,
      'currentParticipants': 0,
      'imageUrl': imageUrl,
      'status': true,
      'createdAt': now,
      'updatedAt': now,
    });
    final doc = await ref.get();
    return _docToMap(doc.id, doc.data()!);
  }

  Future<Map<String, dynamic>> updateEvent({
    required String id,
    String? name,
    String? description,
    String? location,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? price,
    String? organizer,
    String? contact,
    int? maxParticipants,
    String? imageUrl,
    bool? status,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (location != null) updates['location'] = location;
    if (category != null) updates['category'] = category;
    if (startDate != null) updates['startDate'] = Timestamp.fromDate(startDate);
    if (endDate != null) updates['endDate'] = Timestamp.fromDate(endDate);
    if (price != null) updates['price'] = price;
    if (organizer != null) updates['organizer'] = organizer;
    if (contact != null) updates['contact'] = contact;
    if (maxParticipants != null) updates['maxParticipants'] = maxParticipants;
    if (imageUrl != null) updates['imageUrl'] = imageUrl;
    if (status != null) updates['status'] = status;

    await _db.collection(_col).doc(id).update(updates);
    final doc = await _db.collection(_col).doc(id).get();
    return _docToMap(doc.id, doc.data()!);
  }

  Future<void> deleteEvent(String id) async {
    await _db.collection(_col).doc(id).delete();
  }

  Future<void> toggleEventStatus(String id, bool newStatus) async {
    await _db.collection(_col).doc(id).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> registerParticipant(String eventId) async {
    await _db.collection(_col).doc(eventId).update({
      'currentParticipants': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unregisterParticipant(String eventId) async {
    await _db.collection(_col).doc(eventId).update({
      'currentParticipants': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
