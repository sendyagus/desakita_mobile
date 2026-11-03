import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:desa_wisata/config/app_config.dart';
import 'package:desa_wisata/screens/ticket_confirmation_screen.dart';
import 'package:desa_wisata/screens/trip_itinerary_screen.dart';
import 'package:desa_wisata/services/booking_service.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';
import 'package:desa_wisata/widgets/destination_photo.dart';

class TripScreen extends StatefulWidget {
  const TripScreen({super.key});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  final BookingService _bookingService = BookingService();
  int _selectedTab = 0;
  Future<List<Map<String, dynamic>>>? _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    setStateIfMounted(() {
      _bookingsFuture = uid == null
          ? Future.value(<Map<String, dynamic>>[])
          : _bookingService.getUserBookings(uid);
    });
  }

  void setStateIfMounted(VoidCallback callback) {
    if (mounted) setState(callback);
  }

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
    _reload();
    try {
      await _bookingsFuture;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesaKitaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Perjalanan Saya',
                  style: GoogleFonts.plusJakartaSans(
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
                  children: [_tab('Rencana & Aktif', 0), _tab('Riwayat', 1)],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _bookingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: DesaKitaColors.primary,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _emptyState(
                      Icons.cloud_off_outlined,
                      'Perjalanan belum dapat dimuat',
                      'Periksa koneksi dan izin Firestore, lalu tarik layar untuk mencoba kembali.',
                    );
                  }
                  final all = snapshot.data ?? <Map<String, dynamic>>[];
                  final filtered = all
                      .where(
                        (booking) => _selectedTab == 1
                            ? _isHistory(booking)
                            : !_isHistory(booking),
                      )
                      .toList();
                  if (filtered.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      color: DesaKitaColors.primary,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                        children: [
                          // Kartu demo (hanya tab aktif) sesuai desain.
                          if (_selectedTab == 0)
                            _DemoTripCard(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const TripItineraryScreen(),
                                ),
                              ),
                            ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.12,
                           ),
                          // _emptyState(
                          //   Icons.route_outlined,
                          //   _selectedTab == 0
                          //       ? 'Belum ada rencana perjalanan'
                          //       : 'Riwayat masih kosong',
                          //   _selectedTab == 0
                          //       ? 'Pesan tiket destinasi untuk melihat rencana kunjunganmu di sini.'
                          //       : 'Perjalanan yang sudah selesai atau dibatalkan akan muncul di sini.',
                          // ),
                        ],
                      ),
                    );
                  }
                  final showDemo = _selectedTab == 0;
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    color: DesaKitaColors.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                      itemCount: filtered.length + (showDemo ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        if (showDemo && index == 0) {
                          return _DemoTripCard(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TripItineraryScreen(),
                              ),
                            ),
                          );
                        }
                        final booking = filtered[showDemo ? index - 1 : index];
                        return _TripCard(
                          booking: booking,
                          onTap: () => _openBooking(booking),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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

  void _openBooking(Map<String, dynamic> booking) {
    final destination =
        (booking['destinations'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
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

class _TripCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onTap;

  const _TripCard({required this.booking, required this.onTap});

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'Tanggal belum ditentukan';
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

  @override
  Widget build(BuildContext context) {
    final destination =
        (booking['destinations'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final name = (destination['name'] ?? 'Perjalanan wisata').toString();
    final location = (destination['location'] ?? '').toString();
    final imageUrl = (destination['image_url'] ?? destination['imageUrl'])
        ?.toString();
    final status = (booking['status'] ?? 'pending').toString();
    final normalized = status.toLowerCase();
    final statusText = normalized == 'cancelled'
        ? 'Dibatalkan'
        : normalized == 'completed'
        ? 'Selesai'
        : 'Menunggu pembayaran';
    final statusFg = normalized == 'cancelled'
        ? const Color(0xFFB42318)
        : normalized == 'completed'
        ? DesaKitaColors.primary
        : const Color(0xFF8A5B00);

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
              DestinationPhoto(
                imageUrl: imageUrl,
                fallbackAsset: 'assets/img/desakita.jpg',
                width: double.infinity,
                height: 155,
                borderRadius: BorderRadius.zero,
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
                          color: statusFg,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: statusFg,
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
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: DesaKitaColors.text,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: DesaKitaColors.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: DesaKitaColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 14,
                      color: DesaKitaColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatDate(booking['check_in']),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: DesaKitaColors.text,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      (booking['total_price'] ?? '').toString(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: DesaKitaColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.receipt_long_outlined, size: 16),
                    label: Text(
                      'Lihat Detail',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
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
}

/// Kartu demo "Bukit Sakura & Puncak Mas" sesuai desain — klik Lihat Detail
/// membuka layar Susunan Perjalanan (demo, tanpa fungsi nyata).
class _DemoTripCard extends StatelessWidget {
  final VoidCallback onTap;
  const _DemoTripCard({required this.onTap});

  // Rute demo: Rumah -> Bukit Sakura -> Puncak Mas (Kemiling).
  static const _route = <LatLng>[
    LatLng(-5.4290, 105.2530),
    LatLng(-5.4210, 105.2430),
    LatLng(-5.4150, 105.2330),
    LatLng(-5.4100, 105.2260),
    LatLng(-5.4043, 105.2202),
    LatLng(-5.4120, 105.2190),
    LatLng(-5.4206, 105.2225),
  ];

  @override
  Widget build(BuildContext context) {
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
          // ===== PREVIEW PETA RUTE =====
          Stack(
            children: [
              SizedBox(
                height: 155,
                child: IgnorePointer(
                  child: FlutterMap(
                    options: const MapOptions(
                      initialCenter: LatLng(-5.4140, 105.2330),
                      initialZoom: 11.6,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: tileUrl,
                        userAgentPackageName: 'com.desakita.desa_wisata',
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _route,
                            strokeWidth: 4,
                            color: const Color(0xFF4F3DF0),
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: const [
                          Marker(
                            point: _bukitSakura,
                            width: 24,
                            height: 24,
                            child: Icon(
                              Icons.circle,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                          Marker(
                            point: _puncakMas,
                            width: 28,
                            height: 28,
                            child: Icon(
                              Icons.place,
                              size: 18,
                              color: Color(0xFFD53030),
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
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sedang Berjalan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: DesaKitaColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // ===== ISI KARTU =====
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Bukit Sakura & Puncak Mas',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: DesaKitaColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: DesaKitaColors.mutedGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        size: 18,
                        color: DesaKitaColors.primary,
                      ),
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
                      'Hari ini',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: DesaKitaColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  'Perjalanan menjelajahi Bukit Sakura dan Puncak Mas serta '
                  'budaya lokal di kawasan Kemiling.',
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
                    onPressed: onTap,
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

  static const _bukitSakura = LatLng(-5.4043, 105.2202);
  static const _puncakMas = LatLng(-5.4206, 105.2225);
}
