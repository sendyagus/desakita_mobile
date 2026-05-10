import 'package:cloud_firestore/cloud_firestore.dart';

/// Service untuk mendapatkan statistik dashboard admin
class StatsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get total users count
  Future<int> getTotalUsers() async {
    final snap = await _db.collection('users').count().get();
    return snap.count ?? 0;
  }

  /// Get new users today
  Future<int> getNewUsersToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final snap = await _db
        .collection('users')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// Get total destinations count
  Future<int> getTotalDestinations() async {
    final snap = await _db.collection('destinations').count().get();
    return snap.count ?? 0;
  }

  /// Get active destinations count
  Future<int> getActiveDestinations() async {
    final snap = await _db
        .collection('destinations')
        .where('status', isEqualTo: true)
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// Get total bookings count
  Future<int> getTotalBookings() async {
    final snap = await _db.collection('bookings').count().get();
    return snap.count ?? 0;
  }

  /// Get active bookings count (pending + confirmed)
  Future<int> getActiveBookings() async {
    final snap = await _db
        .collection('bookings')
        .where('status', whereIn: ['pending', 'confirmed'])
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// Get total events count
  Future<int> getTotalEvents() async {
    final snap = await _db.collection('events').count().get();
    return snap.count ?? 0;
  }

  /// Get upcoming events count
  Future<int> getUpcomingEvents() async {
    final now = Timestamp.now();
    final snap = await _db
        .collection('events')
        .where('startDate', isGreaterThanOrEqualTo: now)
        .where('status', isEqualTo: true)
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// Get total revenue (sum of all confirmed bookings)
  Future<String> getTotalRevenue() async {
    final snap = await _db
        .collection('bookings')
        .where('status', isEqualTo: 'confirmed')
        .get();
    
    int total = 0;
    for (var doc in snap.docs) {
      final priceStr = doc.data()['totalPrice'] as String? ?? '0';
      // Extract numbers from price string (e.g., "Rp 450.000" -> 450000)
      final numStr = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
      total += int.tryParse(numStr) ?? 0;
    }

    // Format to Indonesian currency
    if (total >= 1000000) {
      final juta = (total / 1000000).toStringAsFixed(1);
      return 'Rp $juta Jt';
    } else if (total >= 1000) {
      final ribu = (total / 1000).toStringAsFixed(0);
      return 'Rp $ribu Rb';
    } else {
      return 'Rp $total';
    }
  }

  /// Get all stats at once
  Future<Map<String, dynamic>> getAllStats() async {
    final results = await Future.wait([
      getTotalUsers(),
      getNewUsersToday(),
      getTotalDestinations(),
      getActiveDestinations(),
      getTotalBookings(),
      getActiveBookings(),
      getTotalEvents(),
      getUpcomingEvents(),
      getTotalRevenue(),
    ]);

    return {
      'totalUsers': results[0],
      'newUsersToday': results[1],
      'totalDestinations': results[2],
      'activeDestinations': results[3],
      'totalBookings': results[4],
      'activeBookings': results[5],
      'totalEvents': results[6],
      'upcomingEvents': results[7],
      'totalRevenue': results[8],
    };
  }

  /// Get recent activities (last 10)
  Future<List<Map<String, dynamic>>> getRecentActivities() async {
    final List<Map<String, dynamic>> activities = [];

    // Get recent users
    final usersSnap = await _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(3)
        .get();
    
    for (var doc in usersSnap.docs) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      activities.add({
        'type': 'user',
        'icon': 'person_add_outlined',
        'title': 'User baru terdaftar',
        'subtitle': '${data['fullName']} bergabung',
        'time': _formatTime(createdAt),
        'timestamp': createdAt,
      });
    }

    // Get recent bookings
    final bookingsSnap = await _db
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .limit(3)
        .get();
    
    for (var doc in bookingsSnap.docs) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      activities.add({
        'type': 'booking',
        'icon': 'bookmark_added_outlined',
        'title': 'Booking baru',
        'subtitle': '${data['destinationName']} - ${data['guestCount']} tamu',
        'time': _formatTime(createdAt),
        'timestamp': createdAt,
      });
    }

    // Get recent destinations
    final destSnap = await _db
        .collection('destinations')
        .orderBy('createdAt', descending: true)
        .limit(2)
        .get();
    
    for (var doc in destSnap.docs) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      activities.add({
        'type': 'destination',
        'icon': 'place_outlined',
        'title': 'Destinasi ditambahkan',
        'subtitle': data['name'],
        'time': _formatTime(createdAt),
        'timestamp': createdAt,
      });
    }

    // Get recent events
    final eventsSnap = await _db
        .collection('events')
        .orderBy('createdAt', descending: true)
        .limit(2)
        .get();
    
    for (var doc in eventsSnap.docs) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      activities.add({
        'type': 'event',
        'icon': 'event_outlined',
        'title': 'Event ditambahkan',
        'subtitle': data['name'],
        'time': _formatTime(createdAt),
        'timestamp': createdAt,
      });
    }

    // Sort by timestamp and take last 10
    activities.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    return activities.take(10).toList();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
