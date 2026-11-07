import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:desa_wisata/models/ai_chat_models.dart';
import 'package:desa_wisata/models/trip_plan.dart';

/// Ringkasan angka yang tampil pada bilah statistik "Susunan Perjalanan".
class TripStats {
  final String duration;
  final double distanceKm;
  final int placeCount;

  const TripStats({
    required this.duration,
    required this.distanceKm,
    required this.placeCount,
  });

  String get distanceLabel =>
      '${distanceKm.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} KM';
}

/// Penyimpanan rencana perjalanan (itinerary) di perangkat.
///
/// Jadwal hasil KITA AI dan booking yang sudah selesai dihubungkan lewat
/// collection lokal `trip_plans_<uid>` (SharedPreferences), sehingga halaman
/// Trip bisa menampilkan susunan perjalanan walau dokumen booking Firestore
/// hanya menyimpan satu destinasi per pesanan.
class TripPlanService {
  TripPlanService._();

  static final TripPlanService instance = TripPlanService._();

  /// Titik keberangkatan demo (perumahan di kawasan Kemiling).
  static const home = LatLng(-5.4290, 105.2530);

  /// Rute cadangan bila data belum punya koordinat sama sekali.
  static const fallbackRoute = <LatLng>[
    LatLng(-5.4290, 105.2530),
    LatLng(-5.4210, 105.2430),
    LatLng(-5.4150, 105.2330),
    LatLng(-5.4100, 105.2260),
    LatLng(-5.4043, 105.2202),
    LatLng(-5.4120, 105.2190),
    LatLng(-5.4206, 105.2225),
  ];

  /// Koordinat contoh untuk destinasi katalog yang belum punya field
  /// latitude/longitude (sama dengan tabel pada halaman Explorasi).
  static const _demoCoordinates = <String, LatLng>{
    'puncak mas': LatLng(-5.4205801, 105.2224986),
    'bukit sakura': LatLng(-5.404013, 105.222813),
    'saung agrowisata': LatLng(-5.4018431, 105.2052365),
    'lembah durian': LatLng(-5.419488, 105.197188),
    'kampoeng vietnam': LatLng(-5.410988, 105.192813),
    'farm day': LatLng(-5.407458, 105.1937542),
    'lengkung langit': LatLng(-5.4178442, 105.1815289),
  };

  String get _storageKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return 'trip_plans_$uid';
  }

  // ---------------- penyimpanan ----------------

  Future<List<TripPlan>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return TripPlan.decodeList(prefs.getString(_storageKey));
    } catch (_) {
      return const [];
    }
  }

  /// Simpan; plan dengan id yang sama menimpa yang lama.
  Future<void> save(TripPlan plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plans = TripPlan.decodeList(prefs.getString(_storageKey));
      plans.removeWhere((p) => p.id == plan.id);
      plans.add(plan);
      plans.sort((a, b) => b.visitDate.compareTo(a.visitDate));
      await prefs.setString(_storageKey, TripPlan.encodeList(plans));
    } catch (_) {
      // Penyimpanan lokal bukan jalur kritis; biarkan tetap di memori.
    }
  }

  /// Simpan plan hasil booking. Jadwal KITA AI yang sebelumnya disimpan
  /// "untuk nanti" pada destinasi yang sama diganti supaya tidak dobel.
  Future<void> saveForBooking(TripPlan plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plans = TripPlan.decodeList(prefs.getString(_storageKey));
      plans.removeWhere(
        (p) =>
            p.id == plan.id ||
            (plan.bookingId != null && p.bookingId == plan.bookingId),
      );
      if (plan.destinationId.isNotEmpty) {
        plans.removeWhere(
          (p) => p.destinationId == plan.destinationId && p.bookingId == null,
        );
      }
      plans.add(plan);
      plans.sort((a, b) => b.visitDate.compareTo(a.visitDate));
      await prefs.setString(_storageKey, TripPlan.encodeList(plans));
    } catch (_) {}
  }

  Future<void> delete(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plans = TripPlan.decodeList(prefs.getString(_storageKey));
      plans.removeWhere((p) => p.id == id);
      await prefs.setString(_storageKey, TripPlan.encodeList(plans));
    } catch (_) {}
  }

  /// Plan tersimpan yang paling cocok untuk satu booking.
  TripPlan? matchBooking(Map<String, dynamic> booking, List<TripPlan> plans) {
    final bookingId = booking['id']?.toString();
    for (final plan in plans) {
      if (bookingId != null && plan.bookingId == bookingId) return plan;
    }
    final destinationId = booking['destination_id']?.toString();
    final checkIn = DateTime.tryParse((booking['check_in'] ?? '').toString());
    if (destinationId == null || checkIn == null) return null;
    for (final plan in plans) {
      if (plan.destinationId == destinationId &&
          _sameDay(plan.visitDate, checkIn)) {
        return plan;
      }
    }
    return null;
  }

  /// Booking belum punya plan KITA AI: susunkan jadwal standar dari sesi
  /// kunjungan agar halaman Trip tetap punya isi.
  TripPlan planForBooking(Map<String, dynamic> booking, List<TripPlan> plans) {
    final saved = matchBooking(booking, plans);
    if (saved != null) return saved;

    final destination = booking['destinations'] is Map
        ? Map<String, dynamic>.from(booking['destinations'] as Map)
        : <String, dynamic>{};
    final name = (destination['name'] ?? 'Destinasi').toString();
    final checkIn =
        DateTime.tryParse((booking['check_in'] ?? '').toString()) ??
        DateTime.now();
    final startHour = checkIn.hour == 0 ? 8 : checkIn.hour;
    final position = positionOf(name, destination);

    TripStop stop(int hourOffset, String title, TripStopKind kind) {
      final hour = math.min(23, math.max(5, startHour + hourOffset));
      return TripStop(
        time: '${hour.toString().padLeft(2, '0')}:00',
        title: title,
        note: kind == TripStopKind.destination
            ? (destination['location'] ?? 'Factual location').toString()
            : 'Factual location',
        kind: kind,
        lat: kind == TripStopKind.destination
            ? position?.latitude
            : home.latitude,
        lng: kind == TripStopKind.destination
            ? position?.longitude
            : home.longitude,
        imageUrl: kind == TripStopKind.destination
            ? (destination['image_url'] ?? destination['imageUrl'])?.toString()
            : null,
        rating: (destination['rating'] as num?)?.toDouble(),
      );
    }

    return TripPlan(
      id: 'booking-${booking['id'] ?? destination['id'] ?? name}',
      title: 'Perjalanan ke $name',
      destinationId:
          (destination['id'] ?? booking['destination_id'])?.toString() ?? '',
      destinationName: name,
      imageUrl:
          (destination['image_url'] ?? destination['imageUrl'])?.toString() ??
          '',
      destination: destination,
      visitDate: DateTime(checkIn.year, checkIn.month, checkIn.day),
      costPerPerson:
          _priceOf(booking['total_price']) ~/
          math.max(1, (booking['guest_count'] as num?)?.toInt() ?? 1),
      bookingId: booking['id']?.toString(),
      stops: [
        stop(-1, 'Berangkat dari Rumah', TripStopKind.departure),
        stop(0, 'Sampai ke $name', TripStopKind.destination),
        stop(3, 'Makan Siang di area $name', TripStopKind.meal),
        stop(5, 'Kembali ke Rumah', TripStopKind.returnHome),
      ],
    );
  }

  /// Ubah itinerary KITA AI menjadi rencana perjalanan yang tersimpan.
  TripPlan planFromItinerary(
    AiItinerary itinerary, {
    required DateTime visitDate,
    int? startHour,
    String? bookingId,
  }) {
    final name = itinerary.destinationName;
    final position = positionOf(name, itinerary.destination);
    final stops = itinerary.stops;
    final departHour =
        startHour ??
        int.tryParse(
          stops.isEmpty ? '08' : stops.first.time.split(RegExp(r'[:.]')).first,
        ) ??
        8;

    TripStopKind kindFor(int index, String activity) {
      final text = activity.toLowerCase();
      if (index == 0) return TripStopKind.departure;
      if (index == stops.length - 1) return TripStopKind.returnHome;
      if (text.contains('makan') ||
          text.contains('jajan') ||
          text.contains('minum') ||
          text.contains('istirahat') ||
          text.contains('kuliner')) {
        return TripStopKind.meal;
      }
      if (index == 1) return TripStopKind.destination;
      return TripStopKind.spot;
    }

    final mapped = <TripStop>[];
    for (var i = 0; i < stops.length; i++) {
      final kind = kindFor(i, stops[i].activity);
      final atDestination = kind == TripStopKind.destination;
      mapped.add(
        TripStop(
          time: _normalizeTime(stops[i].time, index: i, departHour: departHour),
          title: _titleFor(stops[i].activity, kind, name),
          note: atDestination
              ? (itinerary.destination['location'] ?? 'Factual location')
                    .toString()
              : 'Factual location',
          kind: kind,
          lat: atDestination
              ? (position?.latitude ?? home.latitude)
              : home.latitude,
          lng: atDestination
              ? (position?.longitude ?? home.longitude)
              : home.longitude,
          imageUrl: atDestination ? itinerary.imageUrl : null,
          rating: (itinerary.destination['rating'] as num?)?.toDouble(),
        ),
      );
    }

    final destinationId = itinerary.destination['id']?.toString() ?? '';
    return TripPlan(
      id: bookingId ?? 'ai-$destinationId-${_dayKey(visitDate)}',
      title: itinerary.title.replaceFirst('Trip Heading: ', ''),
      destinationId: destinationId,
      destinationName: name,
      imageUrl: itinerary.imageUrl,
      destination: itinerary.destination,
      visitDate: DateTime(visitDate.year, visitDate.month, visitDate.day),
      costPerPerson: itinerary.costPerPerson,
      bookingId: bookingId,
      stops: startHour == null ? mapped : _shiftHours(mapped, startHour),
    );
  }

  // ---------------- perhitungan tampilan ----------------

  /// Koordinat destinasi: field eksplisit pada dokumen, lalu tabel contoh.
  static LatLng? positionOf(String name, Map<String, dynamic> doc) {
    final lat = _coord(doc['latitude'] ?? doc['lat']);
    final lng = _coord(doc['longitude'] ?? doc['lng']);
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    if (doc['position'] is GeoPoint) {
      final p = doc['position'] as GeoPoint;
      return LatLng(p.latitude, p.longitude);
    }
    return _demoCoordinates[name.trim().toLowerCase()];
  }

  static double? _coord(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }

  /// Titik rute untuk peta: koordinat baris jadwal yang memiliki posisi.
  static List<LatLng> routeOf(TripPlan plan) {
    final points = plan.stops
        .where((s) => s.hasPosition)
        .map((s) => LatLng(s.lat!, s.lng!))
        .toList();
    if (points.length < 2) return fallbackRoute;
    // Rute pulang-pergi: kembali ke titik keberangkatan di akhir.
    if (points.first != points.last) points.add(points.first);
    return points;
  }

  /// Durasi, jarak total, dan jumlah tempat pada bilah statistik.
  static TripStats statsOf(TripPlan plan) {
    if (plan.stops.isEmpty) {
      return const TripStats(duration: '0 Jam', distanceKm: 0, placeCount: 0);
    }
    final first = plan.stops.first.minutesOfDay;
    final last = plan.stops.last.minutesOfDay;
    final minutes = math.max(0, last - first);
    final hours = (minutes / 60).round().clamp(1, 24);

    var meters = 0.0;
    final points = plan.stops
        .where((s) => s.hasPosition)
        .map((s) => LatLng(s.lat!, s.lng!))
        .toList();
    for (var i = 1; i < points.length; i++) {
      meters += _haversine(points[i - 1], points[i]);
    }

    return TripStats(
      duration: '$hours Jam',
      distanceKm: meters / 1000,
      placeCount: plan.stops
          .where(
            (s) =>
                s.kind == TripStopKind.destination ||
                s.kind == TripStopKind.spot,
          )
          .length,
    );
  }

  static double _haversine(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = math.pi / 180 * (b.latitude - a.latitude);
    final dLng = math.pi / 180 * (b.longitude - a.longitude);
    final lat1 = math.pi / 180 * a.latitude;
    final lat2 = math.pi / 180 * b.latitude;
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLng / 2) *
            math.sin(dLng / 2) *
            math.cos(lat1) *
            math.cos(lat2);
    return 2 * earthRadius * math.asin(math.min(1, math.sqrt(h)));
  }

  /// Tanggal saran untuk jadwal yang disimpan "untuk nanti": Sabtu terdekat,
  /// karena akhir pekan adalah waktu kunjungan paling ramai.
  static DateTime suggestedVisitDate([DateTime? from]) {
    final base = from ?? DateTime.now();
    final today = DateTime(base.year, base.month, base.day);
    final delta = (DateTime.saturday - today.weekday + 7) % 7;
    return today.add(Duration(days: delta));
  }

  /// Jadwal contoh "Bukit Sakura & Puncak Mas" untuk akun yang belum punya
  /// pemesanan, agar halaman Trip tetap menampilkan susunan sesuai desain.
  static List<TripPlan> demoPlans() {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);
    final bukit = _demoCoordinates['bukit sakura']!;
    final puncak = _demoCoordinates['puncak mas']!;

    TripStop destinationStop(
      String time,
      String name,
      LatLng point,
      String image,
      double rating,
    ) {
      return TripStop(
        time: time,
        title: 'Sampai ke $name',
        note: 'Kemiling, Bandar Lampung',
        kind: TripStopKind.destination,
        lat: point.latitude,
        lng: point.longitude,
        imageUrl: image,
        rating: rating,
      );
    }

    return [
      TripPlan(
        id: 'demo-bukit-sakura',
        title: 'Bukit Sakura',
        destinationName: 'Bukit Sakura',
        imageUrl: 'assets/img/desakita.jpg',
        visitDate: date,
        costPerPerson: 315000,
        stops: [
          const TripStop(
            time: '08:00',
            title: 'Berangkat dari Rumah',
            kind: TripStopKind.departure,
            lat: -5.4290,
            lng: 105.2530,
          ),
          const TripStop(
            time: '08:20',
            title: 'Terdapat UMKM di Sekitar sini',
            kind: TripStopKind.spot,
            lat: -5.4290,
            lng: 105.2530,
          ),
          destinationStop(
            '09:00',
            'Bukit Sakura',
            bukit,
            'assets/img/desakita.jpg',
            4.8,
          ),
          TripStop(
            time: '12:00',
            title: 'Makan Siang',
            kind: TripStopKind.meal,
            lat: bukit.latitude,
            lng: bukit.longitude,
          ),
          TripStop(
            time: '17:00',
            title: 'Kembali ke Rumah',
            kind: TripStopKind.returnHome,
            lat: puncak.latitude,
            lng: puncak.longitude,
          ),
        ],
      ),
      TripPlan(
        id: 'demo-puncak-mas',
        title: 'Puncak Mas',
        destinationName: 'Puncak Mas',
        imageUrl: 'assets/img/banner1.png',
        visitDate: date,
        costPerPerson: 0,
        stops: [
          destinationStop(
            '14:00',
            'Puncak Mas',
            puncak,
            'assets/img/banner1.png',
            4.9,
          ),
        ],
      ),
    ];
  }

  // ---------------- bantuan internal ----------------

  static String _normalizeTime(
    String raw, {
    required int index,
    required int departHour,
  }) {
    final cleaned = raw.replaceAll('.', ':');
    final parts = cleaned.split(':');
    final hour = int.tryParse(parts.first) ?? (departHour + index);
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return '${hour.clamp(0, 23).toString().padLeft(2, '0')}:'
        '${minute.clamp(0, 59).toString().padLeft(2, '0')}';
  }

  /// Judul baris linimasa; baris destinasi selalu menyebut nama tempat.
  static String _titleFor(String activity, TripStopKind kind, String name) {
    switch (kind) {
      case TripStopKind.departure:
        return 'Berangkat dari Rumah';
      case TripStopKind.returnHome:
        return 'Kembali ke Rumah';
      case TripStopKind.destination:
        return 'Sampai ke $name';
      case TripStopKind.meal:
        return activity.isEmpty ? 'Makan Siang' : activity;
      case TripStopKind.spot:
        return activity.isEmpty ? 'Terdapat UMKM di Sekitar sini' : activity;
    }
  }

  /// Geser seluruh jam jadwal agar pemberangkatan jatuh pada jam sesi
  /// tiket yang dipesan (mis. sesi pagi mulai 08.00).
  static List<TripStop> _shiftHours(List<TripStop> stops, int targetStart) {
    if (stops.isEmpty) return stops;
    final delta = targetStart - TripStop.hourOf(stops.first.time);
    if (delta == 0) return stops;
    return [for (final s in stops) s.copyWith(time: _shiftTime(s.time, delta))];
  }

  static String _shiftTime(String time, int delta) {
    final hour = math.min(23, math.max(5, TripStop.hourOf(time) + delta));
    final minute = TripStop.minuteOf(time);
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _dayKey(DateTime value) =>
      '${value.year}${value.month.toString().padLeft(2, '0')}'
      '${value.day.toString().padLeft(2, '0')}';

  static int _priceOf(dynamic value) {
    final digits = (value ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }
}
