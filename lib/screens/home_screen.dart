import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desa_wisata/models/user_model.dart';
import 'package:desa_wisata/screens/agent_screen.dart';
import 'package:desa_wisata/screens/explore_screen.dart';
import 'package:desa_wisata/screens/profile_screen.dart';
import 'package:desa_wisata/screens/trip_screen.dart';
import 'package:desa_wisata/screens/umkm_detail_screen.dart';
import 'package:desa_wisata/screens/destination_detail_screen.dart';
import 'package:desa_wisata/screens/user/user_booking_history_screen.dart';
import 'package:desa_wisata/services/booking_service.dart';
import 'package:desa_wisata/services/user_service.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';
import 'package:desa_wisata/widgets/destination_photo.dart';
import 'package:desa_wisata/widgets/kita_ai_mascot.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  int _exploreInitialType = 0;
  // Prompt awal untuk KITA AI saat dibuka lewat "Aksi Cepat". [_agentNonce]
  // dinaikkan tiap tap agar AgentScreen dibangun ulang dan prompt terkirim lagi.
  String? _agentInitialPrompt;
  int _agentNonce = 0;
  final UserService _userService = UserService();
  final BookingService _bookingService = BookingService();
  UserModel? _currentUser;
  bool _isLoadingUser = true;
  // Riwayat perjalanan (booking user) untuk section paling bawah beranda.
  List<Map<String, dynamic>> _tripHistory = [];

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _destinationsStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _umkmStream;

  // Favorit hanya disimpan pada state halaman (belum terhubung ke database).
  final Set<String> _favorites = {};

  void _toggleFavorite(String id) {
    if (id.isEmpty) return;
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _destinationsStream = FirebaseFirestore.instance
        .collection('destinations')
        .where('status', isEqualTo: true)
        .snapshots();
    _umkmStream = FirebaseFirestore.instance
        .collection('umkm')
        .where('status', isEqualTo: true)
        .snapshots();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final user = userId == null
          ? null
          : await _userService.getUserById(userId);
      final history = userId == null
          ? <Map<String, dynamic>>[]
          : await _bookingService.getUserBookings(userId);
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _tripHistory = history;
        _isLoadingUser = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _buildHomeContent(),
      ExploreScreen(
        key: ValueKey(_exploreInitialType),
        initialType: _exploreInitialType,
      ),
      AgentScreen(
        key: ValueKey(_agentNonce),
        initialPrompt: _agentInitialPrompt,
      ),
      const TripScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: DesaKitaColors.background,
      body: IndexedStack(index: _selectedNavIndex, children: pages),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHomeContent() {
    // Overlap amount panel Aksi Cepat terhadap hero
    const overlapAmount = 54.0;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHero()),
        // Spasi setelah hero diperhitungkan dengan overlap panel Aksi Cepat (+22px visual gap)
        const SliverToBoxAdapter(child: SizedBox(height: overlapAmount + 22)),
        SliverToBoxAdapter(
          child: _buildDestinationSection(
            title: 'Destinasi Populer',
            isUmkm: false,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: _buildDestinationSection(
            title: 'Rekomendasi UMKM Lokal',
            isUmkm: true,
          ),
        ),
        if (_tripHistory.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(child: _buildTripHistorySection()),
        ],
        // Extra padding agar konten tidak terpotong bottom nav
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }

  Widget _buildHero() {
    // Proportional hero height mengikuti frame Figma
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final heroHeight = (screenWidth * 1.05).clamp(390.0, 460.0);
        const quickActionsHeight = 130.0;
        const overlapAmount = 54.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Hero image slideshow + gradient
            SizedBox(
              height: heroHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _HeroBackgroundSlideshow(
                    images: [
                      'assets/img/cs1.jpg',
                      'assets/img/cs2.jpg',
                      'assets/img/cs3.jpg',
                    ],
                  ),
                  // Dark overlay di atas untuk keterbacaan greeting bar
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x70000000), Color(0x00000000)],
                        stops: [0.0, 0.35],
                      ),
                    ),
                  ),
                  // Bottom gradient fading halus ke background warna (#F9FAF7)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          DesaKitaColors.background,
                          DesaKitaColors.background.withValues(alpha: 0.85),
                          const Color(0x00F9FAF7),
                        ],
                        stops: const [0.0, 0.16, 0.42],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Header greeting bar — positioned at top
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: _buildGreetingBar(),
            ),
            // Headline text — tepat di atas panel Aksi Cepat dengan gap rapi
            Positioned(
              left: 20,
              right: 20,
              bottom: (quickActionsHeight - overlapAmount) + 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nikmati perjalanan liburan kamu\ntanpa batas',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 21,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      shadows: const [
                        Shadow(
                          color: Color(0x80000000),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Temukan akomodasi dan berbagai pengalaman menyenangkan',
                    textAlign: TextAlign.left,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      shadows: const [
                        Shadow(
                          color: Color(0x60000000),
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Quick Actions panel — overlaps hero bottom
            Positioned(
              left: 16,
              right: 16,
              bottom: -overlapAmount,
              child: _buildQuickActions(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGreetingBar() {
    final displayName = (_currentUser?.fullName.trim().isNotEmpty ?? false)
        ? _currentUser!.fullName.trim()
        : 'Rizky Pratama';

    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x401A2714), // Frosted dark translucent
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x20000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF2D4A27),
                  backgroundImage:
                      (_currentUser?.avatarUrl?.isNotEmpty ?? false)
                      ? NetworkImage(_currentUser!.avatarUrl!)
                      : null,
                  child: (_currentUser?.avatarUrl?.isNotEmpty ?? false)
                      ? null
                      : const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isLoadingUser ? 'Halo, Petualang' : 'Halo, $displayName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Mau pergi kemana hari ini?',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wb_sunny_outlined,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '28\u00b0C',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: IconButton(
                  tooltip: 'Notifikasi',
                  padding: EdgeInsets.zero,
                  onPressed: () => _showNotice(
                    'Notifikasi akan ditampilkan di pembaruan berikutnya.',
                  ),
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white, // Crisp White Container
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Aksi Cepat',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: DesaKitaColors.text,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  title: 'Minta AI\nRekomendasi',
                  iconWidget: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 22,
                  ),
                  gradient: const LinearGradient(
                    colors: [DesaKitaColors.darkGreen, Color(0xFF94A81D)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  shadowColor: const Color(0x4D145E1E),
                  onTap: () =>
                      _openAgentWithPrompt('Rekomendasikan tempat wisata'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  title: 'Perjalanan\nBaru',
                  iconWidget: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add,
                        color: DesaKitaColors.primary,
                        size: 16,
                      ),
                    ),
                  ),
                  gradient: const LinearGradient(
                    colors: [DesaKitaColors.primary, DesaKitaColors.primary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  shadowColor: const Color(0x4D1C7A28),
                  onTap: () =>
                      _openAgentWithPrompt('Buatkan rencana perjalanan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationSection({
    required String title,
    required bool isUmkm,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: isUmkm ? _umkmStream : _destinationsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(title, () => _openExplore(isUmkm: isUmkm)),
              const SizedBox(height: 12),
              _sectionFallback(
                isUmkm
                    ? 'Rekomendasi UMKM belum dapat dimuat saat ini.'
                    : 'Destinasi belum dapat dimuat saat ini.',
                compact: true,
              ),
            ],
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(title, () => _openExplore(isUmkm: isUmkm)),
              const SizedBox(height: 12),
              const SizedBox(
                height: 174,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ],
          );
        }

        final rows =
            snapshot.data?.docs.map((doc) {
              final data = doc.data();
              return <String, dynamic>{
                'id': doc.id,
                'name': (data['name'] ?? '').toString(),
                'location': (data['location'] ?? '').toString(),
                'category': (data['category'] ?? '').toString(),
                'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
                'price': (data['price'] ?? '').toString(),
                'description': (data['description'] ?? '').toString(),
                'imageUrl': (data['imageUrl'] ?? data['image_url'])?.toString(),
                'reviewCount': data['reviewCount'] ?? data['review_count'] ?? 0,
                'openingHours': (data['openingHours'] ?? data['opening_hours'])
                    ?.toString(),
                'facilities': data['facilities'],
                'products': data['products'],
                'status': data['status'] ?? true,
              };
            }).toList() ??
            <Map<String, dynamic>>[];

        final filtered =
            rows.where((row) {
              if (isUmkm) return true;
              final category = (row['category'] as String).toLowerCase();
              return !category.contains('kuliner');
            }).toList()..sort(
              (a, b) =>
                  (b['rating'] as double).compareTo(a['rating'] as double),
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(title, () => _openExplore(isUmkm: isUmkm)),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              _sectionFallback(
                isUmkm
                    ? "Data UMKM belum tersedia. Profil usaha akan tampil setelah koleksi 'umkm' di Firestore diisi."
                    : 'Destinasi aktif akan tampil di sini setelah tersedia.',
                compact: true,
              )
            else
              SizedBox(
                height: 205,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: filtered.length > 8 ? 8 : filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, index) => _PopularDestinationCard(
                    destination: filtered[index],
                    isUmkm: isUmkm,
                    isFavorite: _favorites.contains(
                      filtered[index]['id'].toString(),
                    ),
                    onToggleFavorite: () =>
                        _toggleFavorite(filtered[index]['id'].toString()),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => isUmkm
                            ? UmkmDetailScreen(umkm: filtered[index])
                            : DestinationDetailScreen(
                                destination: filtered[index],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: DesaKitaColors.text,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'Lihat semua',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF42493E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section Riwayat Perjalanan di bagian paling bawah beranda.
  Widget _buildTripHistorySection() {
    if (_tripHistory.isEmpty) return const SizedBox.shrink();
    final items = _tripHistory.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Riwayat Perjalanan', _openTripHistory),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              for (final b in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _tripHistoryCard(b),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _openTripHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserBookingHistoryScreen()),
    );
  }

  static const _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  static const _monthNames = [
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

  String _formatTripDate(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    if (d == null) return '-';
    return '${_dayNames[d.weekday - 1]}, ${d.day} ${_monthNames[d.month - 1]} ${d.year}';
  }

  Widget _tripHistoryCard(Map<String, dynamic> booking) {
    final dest = (booking['destinations'] as Map<String, dynamic>?) ?? {};
    final name = (dest['name'] ?? 'Perjalanan').toString();
    final location = (dest['location'] ?? '-').toString();
    final imageUrl = dest['image_url']?.toString();

    final checkIn = DateTime.tryParse(booking['check_in'] as String? ?? '');
    final checkOut = DateTime.tryParse(booking['check_out'] as String? ?? '');
    final status = (booking['status'] ?? '').toString();
    final now = DateTime.now();
    final ongoing =
        status != 'cancelled' &&
        checkIn != null &&
        checkOut != null &&
        !now.isBefore(checkIn) &&
        now.isBefore(checkOut.add(const Duration(days: 1)));

    return GestureDetector(
      onTap: _openTripHistory,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DestinationPhoto(
                imageUrl: imageUrl,
                fallbackAsset: 'assets/img/cs1.jpg',
                width: 56,
                height: 56,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: DesaKitaColors.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 11,
                        color: Color(0xFF2D5016),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: const Color(0xFF7A8272),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              ongoing
                  ? 'Sedang\nberlangsung'
                  : _formatTripDate(booking['check_in'] as String?),
              textAlign: TextAlign.end,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: ongoing ? FontWeight.w700 : FontWeight.w600,
                color: ongoing
                    ? const Color(0xFF2D5016)
                    : const Color(0xFF42493E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionFallback(String message, {bool compact = false}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, compact ? 0 : 10, 18, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DesaKitaColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.eco_outlined, color: DesaKitaColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF42493E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openExplore({required bool isUmkm}) {
    setState(() {
      _exploreInitialType = isUmkm ? 1 : 0;
      _selectedNavIndex = 1;
    });
  }

  /// Buka tab KITA AI (indeks 2) dan kirim [prompt] sebagai pesan pertama.
  void _openAgentWithPrompt(String prompt) {
    setState(() {
      _agentInitialPrompt = prompt;
      _agentNonce++; // paksakan AgentScreen dibangun ulang agar prompt terkirim
      _selectedNavIndex = 2;
    });
  }

  Widget _buildBottomNavigation() {
    const labels = ['Beranda', 'Explorasi', 'KITA AI', 'Trip', 'Profil'];
    const icons = [
      Icons.home_outlined,
      Icons.explore_outlined,
      Icons.smart_toy_outlined,
      Icons.route_outlined,
      Icons.person_outline_rounded,
    ];
    const activeIcons = [
      Icons.home_rounded,
      Icons.explore_rounded,
      Icons.smart_toy_rounded,
      Icons.route_rounded,
      Icons.person_rounded,
    ];
    const activeGreen = DesaKitaColors.primary;
    const inactiveGray = Color(0xFF42493E);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(labels.length, (index) {
              final selected = _selectedNavIndex == index;
              // Center tab — KITA AI with animated mascot
              if (index == 2) {
                return InkWell(
                  onTap: () => setState(() => _selectedNavIndex = index),
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    width: 60,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFD6EAD4),
                            border: Border.all(
                              color: selected ? activeGreen : Colors.white,
                              width: selected ? 2 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: selected
                                    ? activeGreen.withValues(alpha: 0.3)
                                    : const Color(0x14000000),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/img/navbar_kita_ai.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                    child: KitaAiMascot(
                                      size: 22,
                                      color: selected
                                          ? activeGreen
                                          : DesaKitaColors.primary,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          labels[index],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: selected ? activeGreen : inactiveGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedNavIndex = index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? activeIcons[index] : icons[index],
                        size: 22,
                        color: selected ? activeGreen : inactiveGray,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        labels[index],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected ? activeGreen : inactiveGray,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final String title;
  final Widget iconWidget;
  final Gradient gradient;
  final Color shadowColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.title,
    required this.iconWidget,
    required this.gradient,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    // Target sentuh lebih besar (64dp) + umpan balik skala saat ditekan
    // agar tombol Aksi Cepat terasa mudah diklik.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withValues(alpha: 0.18),
        highlightColor: Colors.white.withValues(alpha: 0.10),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Ink(
            height: 64,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.iconWidget,
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.left,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 12.5,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PopularDestinationCard extends StatelessWidget {
  final Map<String, dynamic> destination;
  final bool isUmkm;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  const _PopularDestinationCard({
    required this.destination,
    required this.isUmkm,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = (destination['category'] ?? '').toString().toLowerCase();
    final name = destination['name']?.toString() ?? '';
    final String fallback;
    if (isUmkm) {
      // Pemetaan foto lokal per kategori usaha agar tidak memakai
      // gambar yang tidak relevan untuk produk kerajinan/makanan.
      if (category.contains('kuliner') ||
          category.contains('kopi') ||
          category.contains('makanan') ||
          category.contains('minuman')) {
        fallback = 'assets/img/cs3.jpg';
      } else if (category.contains('kerajinan') ||
          category.contains('tapis') ||
          category.contains('fashion') ||
          category.contains('batik')) {
        fallback = 'assets/img/desakita.jpg';
      } else {
        // Agrowisata & lainnya.
        fallback = 'assets/img/cs2.jpg';
      }
    } else {
      fallback = category.contains('budaya')
          ? 'assets/img/cs2.jpg'
          : 'assets/img/cs1.jpg';
    }

    return SizedBox(
      width: 172,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        elevation: 1.5,
        shadowColor: const Color(0x18000000),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  DestinationPhoto(
                    imageUrl: destination['imageUrl']?.toString(),
                    fallbackAsset: fallback,
                    height: 122,
                    width: double.infinity,
                    borderRadius: BorderRadius.zero,
                    fallbackBuilder: isUmkm
                        ? (context) => _UmkmPhotoFallback(
                            name: name,
                            assetPath: fallback,
                            height: 122,
                          )
                        : null,
                  ),
                  // Bookmark icon — top-right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onToggleFavorite,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 16,
                          color: isFavorite
                              ? DesaKitaColors.primary
                              : const Color(0xFF1B1C16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination['name']?.toString().isNotEmpty == true
                          ? destination['name'].toString()
                          : 'Destinasi lokal',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: DesaKitaColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: DesaKitaColors.primary,
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            destination['location']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder foto UMKM yang disengaja secara visual: foto lokal dengan
/// overlay brand + inisial usaha, dipakai saat URL gambar gagal/tidak ada.
class _UmkmPhotoFallback extends StatelessWidget {
  final String name;
  final String assetPath;
  final double height;

  const _UmkmPhotoFallback({
    required this.name,
    required this.assetPath,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(assetPath, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  DesaKitaColors.primary.withValues(alpha: 0.78),
                  DesaKitaColors.darkGreen.withValues(alpha: 0.88),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: DesaKitaColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Background slideshow yang terisolasi dalam state-nya sendiri sehingga
/// timer pergantian foto (2 detik) TIDAK menyebabkan rebuild pada keseluruhan
/// halaman beranda (mencegah flickering / refresh pada komponen lain).
class _HeroBackgroundSlideshow extends StatefulWidget {
  final List<String> images;

  const _HeroBackgroundSlideshow({required this.images});

  @override
  State<_HeroBackgroundSlideshow> createState() =>
      _HeroBackgroundSlideshowState();
}

class _HeroBackgroundSlideshowState extends State<_HeroBackgroundSlideshow> {
  static const _interval = Duration(seconds: 2);
  static const _transitionDuration = Duration(milliseconds: 650);

  int _currentIndex = 0;
  Timer? _timer;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.images.length;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      for (final img in widget.images) {
        precacheImage(AssetImage(img), context);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _transitionDuration,
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[...previousChildren, ?currentChild],
        );
      },
      child: Image.asset(
        widget.images[_currentIndex],
        key: ValueKey<int>(_currentIndex),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
      ),
    );
  }
}
