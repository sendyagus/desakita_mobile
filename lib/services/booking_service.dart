import 'package:cloud_firestore/cloud_firestore.dart';

/// Booking di Firestore (`bookings`) dengan snapshot destinasi untuk ganti join SQL.
class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _bookings = 'bookings';
  static const _destinations = 'destinations';
  static const _users = 'users';

  Map<String, dynamic> _nestedDestination(Map<String, dynamic> b) {
    return {
      'id': b['destinationId'],
      'name': b['destinationName'] ?? '',
      'category': b['destinationCategory'],
      'location': b['destinationLocation'],
      'description': null,
      'rating': b['destinationRating'],
      'price': b['destinationPrice'],
      'image_url': b['destinationImageUrl'],
      'status': true,
      'created_at': null,
      'updated_at': null,
    };
  }

  Map<String, dynamic> _nestedUser(Map<String, dynamic> b) {
    return {
      'id': b['userId'],
      'full_name': b['userFullName'] ?? '',
      'email': b['userEmail'] ?? '',
      'phone': b['userPhone'] ?? '',
      'role': 'user',
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _docToBookingMap(String id, Map<String, dynamic> b) {
    final ci = b['checkIn'];
    final co = b['checkOut'];
    final cr = b['createdAt'];
    final up = b['updatedAt'];
    String iso(dynamic v) {
      if (v is Timestamp) return v.toDate().toIso8601String();
      if (v is String) return v;
      return DateTime.now().toIso8601String();
    }

    return {
      'id': id,
      'destination_id': b['destinationId'],
      'user_id': b['userId'],
      'check_in': iso(ci),
      'check_out': iso(co),
      'guest_count': b['guestCount'] ?? 1,
      'total_price': b['totalPrice'] ?? '',
      'status': b['status'] ?? 'pending',
      'payment_method': b['paymentMethod'] ?? '',
      'payment_status': b['paymentStatus'] ?? 'awaiting_payment',
      'visitor_name': b['visitorName'] ?? b['userFullName'] ?? '',
      'visitor_phone': b['visitorPhone'] ?? b['userPhone'] ?? '',
      'visitor_email': b['visitorEmail'] ?? b['userEmail'] ?? '',
      'created_at': iso(cr),
      'updated_at': iso(up),
      'destinations': _nestedDestination(b),
      'users': _nestedUser(b),
    };
  }

  Future<Map<String, dynamic>> createBooking({
    required String destinationId,
    required String userId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guestCount,
    required String totalPrice,
    String? visitorName,
    String? visitorPhone,
    String? visitorEmail,
    String? paymentMethod,
    String paymentStatus = 'awaiting_payment',
  }) async {
    final destSnap = await _db
        .collection(_destinations)
        .doc(destinationId)
        .get();
    final dest = destSnap.data() ?? {};
    final userSnap = await _db.collection(_users).doc(userId).get();
    final user = userSnap.data() ?? {};

    final now = FieldValue.serverTimestamp();
    final ref = _db.collection(_bookings).doc();
    await ref.set({
      'destinationId': destinationId,
      'userId': userId,
      'checkIn': Timestamp.fromDate(checkIn),
      'checkOut': Timestamp.fromDate(checkOut),
      'guestCount': guestCount,
      'totalPrice': totalPrice,
      'status': 'pending',
      'paymentMethod': paymentMethod ?? '',
      'paymentStatus': paymentStatus,
      'visitorName': visitorName ?? user['fullName'] ?? '',
      'visitorPhone': visitorPhone ?? user['phone'] ?? '',
      'visitorEmail': visitorEmail ?? user['email'] ?? '',
      'destinationName': dest['name'] ?? '',
      'destinationCategory': dest['category'],
      'destinationLocation': dest['location'],
      'destinationRating': dest['rating'],
      'destinationPrice': dest['price'],
      'destinationImageUrl': dest['imageUrl'],
      'userFullName': user['fullName'] ?? '',
      'userEmail': user['email'] ?? '',
      'userPhone': user['phone'] ?? '',
      'createdAt': now,
      'updatedAt': now,
    });

    final doc = await ref.get();
    return _docToBookingMap(doc.id, doc.data()!);
  }

  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    final snap = await _db
        .collection(_bookings)
        .where('userId', isEqualTo: userId)
        .get();
    final list = snap.docs.map((d) => _docToBookingMap(d.id, d.data())).toList()
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

  Future<List<Map<String, dynamic>>> getAllBookings() async {
    final snap = await _db.collection(_bookings).get();
    final list = snap.docs.map((d) => _docToBookingMap(d.id, d.data())).toList()
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

  /// Stream reaksi langsung semua booking (dipakai layar admin & analitik).
  Stream<List<Map<String, dynamic>>> watchAllBookings() {
    return _db.collection(_bookings).snapshots().map((snap) {
      final list =
          snap.docs.map((d) => _docToBookingMap(d.id, d.data())).toList()
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
    });
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _db.collection(_bookings).doc(bookingId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelBooking(String bookingId) async {
    await updateBookingStatus(bookingId, 'cancelled');
  }
}
