import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:desa_wisata/config/app_config.dart';
import 'package:desa_wisata/models/trip_plan.dart';
import 'package:desa_wisata/screens/ticket_confirmation_screen.dart';
import 'package:desa_wisata/screens/trip_itinerary_screen.dart';
import 'package:desa_wisata/services/booking_service.dart';
import 'package:desa_wisata/services/trip_plan_service.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';
import 'package:desa_wisata/utils/price_helper.dart';

/// Halaman "Perjalanan Saya": pemesanan tiket (dan jadwal yang dibuatkan
/// KITA AI) dikelompokkan per tanggal kunjungan menjadi kartu rute.
class TripScreen extends StatefulWidget {
  const TripScreen({super.key});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  final BookingService _bookingService = BookingService();

  /// 0 = Sedang Berlangsung, 1 = Riwayat.
  int _selectedTab = 0;

  List<Map<String, dynamic>> _bookings = const [];
  List<TripPlan> _plans = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setStateIfMounted(() {
        _bookings = const [];
        _plans = const [];
        _loading = false;
        _error = null;
      });
      return;
    }
    try {
      final results = await Future.wait([
        _bookingService.getUserBookings(uid),
        TripPlanService.instance.load(),
      ]);
      setStateIfMounted(() {
        _bookings = results.first as List<Map<String, dynamic>>;
        _plans = results.last as List<TripPlan>;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      setStateIfMounted(() {
        _loading = false;
        _error = 'Perjalanan belum dapat dimuat';
      });
    }
  }

  void setStateIfMounted(VoidCallback callback) {
    if (mounted) setState(callback);
  }

  /// Pemesanan dianggap masuk Riwayat bila dibatalkan, selesai, atau
  /// tanggal kunjungannya sudah lewat.
  bool _isHistory(Map<String, dynamic> booking) {
    final status = (booking['status'] ?? '').toString().toLowerCase();
    final end = DateTime.tryParse((booking['check_out'] ?? '').toString());
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    return status == 'cancelled' ||
        status == 'completed' ||
        status == 'selesai' ||
        (end != null && end.isBefore(todayStart));
  }

  Future<void> _refresh() async {
    setStateIfMounted(() => _loading = true);
    await _load();
  }

  /// Booking → satu perjalanan per tanggal kunjungan.
  List<_Trip> get _trips {
    final groups = <DateTime, List<Map<String, dynamic>>>{};
    for (final booking in _bookings) {
      if (_isHistory(booking) != (_selectedTab == 1)) continue;
      final checkIn = DateTime.tryParse((booking['check_in'] ?? '').toString());
      final now = DateTime.now();
      final day = checkIn == null
          ? DateTime(now.year, now.month, now.day)
          : DateTime(checkIn.year, checkIn.month, checkIn.day);
      groups.putIfAbsent(day, () => []).add(booking);
    }

    final days = groups.keys.toList()
      ..sort((a, b) => _selectedTab == 1 ? b.compareTo(a) : a.compareTo(b));

    return [
      for (final day in days)
        _Trip(
          date: day,
          isHistory: _selectedTab == 1,
          bookings: groups[day]!,
          plans: [
            for (final booking in groups[day]!)
              TripPlanService.instance.planForBooking(booking, _plans),
          ],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesaKitaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 20, 18, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Perjalanan Saya',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: DesaKitaColors.text,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: DesaKitaColors.divider),
                ),
                child: Row(
                  children: [_tab('Sedang Berlangsung', 0), _tab('Riwayat', 1)],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: DesaKitaColors.primary),
      );
    }
    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _refresh,
        color: DesaKitaColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          children: [
            _emptyState(
              Icons.cloud_off_outlined,
              _error!,
              'Periksa koneksi dan izin Firestore, lalu tarik layar untuk '
              'mencoba kembali.',
            ),
          ],
        ),
      );
    }

    final trips = _trips;
    if (trips.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        color: DesaKitaColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          children: [
            if (_selectedTab == 0) ...[
              // Contoh susunan perjalanan sesuai desain, dipakai selama belum
              // ada pemesanan pada akun ini.
              _TripCard(trip: _Trip.demo(), isDemo: true),
              const SizedBox(height: 18),
              _emptyState(
                Icons.route_outlined,
                'Belum ada perjalanan aktif',
                'Buat jadwal lewat KITA AI lalu selesaikan pemesanan tiket; '
                    'perjalanan akan otomatis muncul di sini.',
              ),
            ] else
              _emptyState(
                Icons.history_rounded,
                'Riwayat masih kosong',
                'Perjalanan yang sudah selesai atau dibatalkan akan muncul '
                    'di sini.',
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: DesaKitaColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        itemCount: trips.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) => _TripCard(trip: trips[index]),
      ),
    );
  }

  Widget _tab(String label, int index) {
    final selected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? DesaKitaColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : DesaKitaColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: DesaKitaColors.mutedGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: DesaKitaColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: DesaKitaColors.text,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              height: 1.55,
              color: DesaKitaColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MODEL TAMPILAN
// ---------------------------------------------------------------------------

/// Satu kartu perjalanan: gabungan pemesanan pada tanggal yang sama.
class _Trip {
  final DateTime date;
  final bool isHistory;
  final List<Map<String, dynamic>> bookings;
  final List<TripPlan> plans;

  const _Trip({
    required this.date,
    required this.isHistory,
    required this.bookings,
    required this.plans,
  });

  factory _Trip.demo() => _Trip(
    date: DateTime.now(),
    isHistory: false,
    bookings: const [],
    plans: TripPlanService.demoPlans(),
  );

  bool get isDemo => bookings.isEmpty;

  /// Nama destinasi unik pada tanggal ini (pesan ganda tidak dobel dibaca).
  List<String> get names {
    final unique = <String>[];
    for (final plan in plans) {
      final name = plan.destinationName.trim();
      if (name.isNotEmpty && !unique.contains(name)) unique.add(name);
    }
    return unique;
  }

  /// "Bukit Sakura & Puncak Mas", bertambah banyak dipotong "+N lagi".
  String get title {
    if (names.isEmpty) return 'Perjalanan wisata';
    if (names.length <= 2) return names.join(' & ');
    return '${names.take(2).join(' & ')} +${names.length - 2} lagi';
  }

  int get totalPrice =>
      bookings.fold(0, (sum, b) => sum + PriceHelper.toInt(b['total_price']));

  int get guestCount => bookings.fold(
    0,
    (sum, b) => sum + ((b['guest_count'] as num?)?.toInt() ?? 1),
  );

  bool get isCancelled => bookings.any(
    (b) => (b['status'] ?? '').toString().toLowerCase() == 'cancelled',
  );

  /// Semua pemesanan pada tanggal ini belum lunas.
  bool get isPending =>
      bookings.isNotEmpty &&
      bookings.every(
        (b) => (b['payment_status'] ?? '').toString() == 'awaiting_payment',
      );

  int get dayDelta {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.difference(today).inDays;
  }

  String get statusLabel {
    if (isCancelled) return 'Dibatalkan';
    if (isHistory) return 'Selesai';
    if (isPending) return 'Menunggu pembayaran';
    if (dayDelta == 0) return 'Sedang Berlangsung';
    if (dayDelta > 0) return 'Terjadwal';
    return 'Selesai';
  }

  Color get statusColor {
    if (isCancelled) return const Color(0xFFB42318);
    if (isPending) return const Color(0xFF8A5B00);
    return DesaKitaColors.primary;
  }

  String get dateLabel {
    if (isDemo) return 'Hari ini';
    if (dayDelta == 0) return 'Hari ini';
    if (dayDelta == 1) return 'Besok';
    if (dayDelta > 1) return '$dayDelta hari lagi';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String get description {
    if (isDemo) {
      return 'Perjalanan menjelajahi Bukit Sakura dan Puncak Mas serta '
          'budaya lokal di kawasan Kemiling.';
    }
    if (names.isEmpty) {
      return 'Perjalanan pada ${dateLabel.toLowerCase()} di kawasan Kemiling.';
    }
    final places = names.length <= 1
        ? names.first
        : '${names.take(names.length - 1).join(', ')} dan '
              '${names.last}';
    final price = totalPrice > 0
        ? ' Estimasi total ${PriceHelper.format(totalPrice)} untuk '
              '$guestCount pengunjung.'
        : '';
    return 'Rute kunjungan $places di kawasan Kemiling.$price';
  }

  /// Linimasa gabungan seluruh destinasi pada tanggal yang sama.
  TripPlan get mergedPlan {
    if (plans.length == 1) return plans.first;
    final stops = plans.expand((p) => p.stops).toList()
      ..sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));
    return TripPlan(
      id: 'trip-${date.millisecondsSinceEpoch}',
      title: title,
      destinationId: plans.first.destinationId,
      destinationName: title,
      imageUrl: plans.first.imageUrl,
      destination: plans.first.destination,
      visitDate: date,
      costPerPerson: totalPrice,
      bookingId: bookings.isEmpty ? null : bookings.first['id']?.toString(),
      stops: stops,
    );
  }

  /// Titik rute untuk pratinjau peta.
  List<LatLng> get route {
    final points = <LatLng>[];
    for (final stop in mergedPlan.stops) {
      if (!stop.hasPosition) continue;
      final point = LatLng(stop.lat!, stop.lng!);
      if (points.isEmpty || points.last != point) points.add(point);
    }
    if (points.length < 2) return TripPlanService.fallbackRoute;
    return points;
  }
}

// ---------------------------------------------------------------------------
// KARTU PERJALANAN
// ---------------------------------------------------------------------------

/// Kartu rute sesuai desain: pratinjau peta satelit, penanda status, judul
/// destinasi, tanggal, deskripsi, dan tombol "Lihat Detail".
class _TripCard extends StatelessWidget {
  final _Trip trip;
  final bool isDemo;

  const _TripCard({required this.trip, this.isDemo = false});

  @override
  Widget build(BuildContext context) {
    final route = trip.route;
    final tileUrl = AppConfig.isMapboxConfigured
        ? 'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12'
              '/tiles/256/{z}/{x}/{y}?access_token='
              '${AppConfig.mapboxAccessToken}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesaKitaColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 155,
                child: IgnorePointer(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCameraFit: CameraFit.coordinates(
                        coordinates: route,
                        padding: const EdgeInsets.all(30),
                        maxZoom: 14.5,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: tileUrl,
                        userAgentPackageName: 'com.desakita.desa_wisata',
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: route,
                            strokeWidth: 4,
                            color: const Color(0xFF4F3DF0),
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          for (var i = 0; i < route.length; i++)
                            Marker(
                              point: route[i],
                              width: 28,
                              height: 28,
                              child: Icon(
                                i == route.length - 1
                                    ? Icons.place
                                    : Icons.circle,
                                size: i == route.length - 1 ? 18 : 10,
                                color: i == route.length - 1
                                    ? const Color(0xFFD53030)
                                    : Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: trip.statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        trip.statusLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: trip.statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        trip.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: DesaKitaColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _circleButton(
                      icon: trip.isDemo
                          ? Icons.directions_car_rounded
                          : Icons.confirmation_number_outlined,
                      tooltip: trip.isDemo
                          ? 'Contoh perjalanan'
                          : 'Lihat e-ticket',
                      onTap: trip.isDemo ? null : () => _openTicket(context),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 14,
                      color: DesaKitaColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      trip.dateLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: DesaKitaColors.text,
                      ),
                    ),
                    const Spacer(),
                    if (trip.totalPrice > 0)
                      Text(
                        PriceHelper.format(trip.totalPrice),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: DesaKitaColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  trip.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    height: 1.55,
                    color: DesaKitaColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 13),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _openItinerary(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesaKitaColors.buttonGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Lihat Detail',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: DesaKitaColors.mutedGreen,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 18, color: DesaKitaColors.primary),
          ),
        ),
      ),
    );
  }

  /// Buka halaman "Susunan Perjalanan" dengan jadwal nyata.
  void _openItinerary(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripItineraryScreen(
          plan: trip.mergedPlan,
          persistChanges: !trip.isDemo,
        ),
      ),
    );
  }

  /// E-ticket pemesanan pertama pada tanggal ini.
  void _openTicket(BuildContext context) {
    final booking = trip.bookings.first;
    final destination = booking['destinations'] is Map
        ? Map<String, dynamic>.from(booking['destinations'] as Map)
        : <String, dynamic>{};
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TicketConfirmationScreen(
          booking: booking,
          destination: destination,
        ),
      ),
    );
  }
}
