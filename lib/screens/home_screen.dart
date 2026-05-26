import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:desa_wisata/screens/explore_screen.dart';
import 'package:desa_wisata/screens/profile_screen.dart';
import 'package:desa_wisata/screens/agent_screen.dart';
import 'package:desa_wisata/screens/destination_detail_screen.dart';
import 'package:desa_wisata/services/user_service.dart';
import 'package:desa_wisata/services/destination_service.dart';
import 'package:desa_wisata/services/event_service.dart';
import 'package:desa_wisata/models/user_model.dart';
import 'package:desa_wisata/config/app_categories.dart';
import 'package:desa_wisata/widgets/app_network_image.dart';
import 'package:desa_wisata/screens/notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBannerIndex = 0;
  int _selectedCategoryIndex = 0;
  int _selectedNavIndex = 0;

  final PageController _bannerController = PageController();
  final UserService _userService = UserService();
  final DestinationService _destinationService = DestinationService();
  final EventService _eventService = EventService();

  UserModel? _currentUser;
  bool _isLoadingUser = true;

  List<Map<String, dynamic>> _allDestinations = [];
  bool _isLoadingDestinations = true;
  List<Map<String, dynamic>> _events = [];
  bool _isLoadingEvents = true;

  final List<Map<String, String>> _categories = [
    {'icon': 'semua', 'label': 'Semua'},
    {'icon': 'alam', 'label': 'Alam'},
    {'icon': 'penginapan', 'label': 'Penginapan'},
    {'icon': 'kuliner', 'label': 'Kuliner'},
    {'icon': 'edukasi', 'label': 'Edukasi'},
  ];

  List<Map<String, dynamic>> get _filteredRecommendations {
    if (_selectedCategoryIndex == 0) {
      return _allDestinations.take(8).toList();
    }
    final label = _categories[_selectedCategoryIndex]['label']!;
    return _allDestinations
        .where(
          (d) => AppCategories.normalize(d['category'] as String?) == label,
        )
        .take(8)
        .toList();
  }

  final List<String> banners = [
    'assets/img/cs1.jpg',
    'assets/img/cs2.jpg',
    'assets/img/cs3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDestinations();
    _loadEvents();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final user = await _userService.getUserById(userId);
        if (mounted) {
          setState(() {
            _currentUser = user;
            _isLoadingUser = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingUser = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  Future<void> _loadDestinations() async {
    try {
      final destinations = await _destinationService.getAllDestinations();
      if (mounted) {
        setState(() {
          _allDestinations = destinations;
          _isLoadingDestinations = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading destinations: $e');
      if (mounted) {
        setState(() => _isLoadingDestinations = false);
      }
    }
  }

  Future<void> _loadEvents() async {
    try {
      final events = await _eventService.getHomeEvents();
      if (mounted) {
        setState(() {
          _events = events.take(5).toList();
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading events: $e');
      if (mounted) {
        setState(() => _isLoadingEvents = false);
      }
    }
  }

  static String _eventMonthLabel(String? isoDate) {
    final date = DateTime.tryParse(isoDate ?? '');
    if (date == null) return '---';
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MEI',
      'JUN',
      'JUL',
      'AGU',
      'SEP',
      'OKT',
      'NOV',
      'DES',
    ];
    return months[date.month - 1];
  }

  static String _eventDayLabel(String? isoDate) {
    final date = DateTime.tryParse(isoDate ?? '');
    if (date == null) return '--';
    return date.day.toString().padLeft(2, '0');
  }

  static String _eventTimeLabel(Map<String, dynamic> event) {
    final start = DateTime.tryParse(event['start_date'] as String? ?? '');
    final end = DateTime.tryParse(event['end_date'] as String? ?? '');
    if (start == null) return '';
    final startTime =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    if (end == null) return '$startTime - Selesai';
    final endTime =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$startTime - $endTime';
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Widget _buildBerandaContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBannerSlider(),
                const SizedBox(height: 20),
                _buildCategories(),
                const SizedBox(height: 20),
                _buildSectionTitle('Rekomendasi Untukmu'),
                const SizedBox(height: 12),
                _buildRecommendations(),
                const SizedBox(height: 20),
                _buildSectionTitle('Acara Mendatang'),
                const SizedBox(height: 12),
                _buildEvents(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: IndexedStack(
        index: _selectedNavIndex,
        children: [
          SafeArea(bottom: false, child: _buildBerandaContent()),
          const SafeArea(bottom: false, child: ExploreScreen()),
          const AgentScreen(), // AgentScreen manages its own SafeArea internally for full-bleed header
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const ProfileScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        const begin = Offset(-1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        var tween = Tween(
                          begin: begin,
                          end: end,
                        ).chain(CurveTween(curve: curve));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                ),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
                border: Border.all(color: const Color(0xFF2D5016), width: 2),
              ),
              child: ClipOval(
                child: _isLoadingUser
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFF2D5016),
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : _currentUser?.avatarUrl != null &&
                          _currentUser!.avatarUrl!.isNotEmpty
                    ? Image.network(
                        _currentUser!.avatarUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 24,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Color(0xFF2D5016),
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                      )
                    : const Icon(Icons.person, color: Colors.grey, size: 24),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Sapaan - tappable to open ProfileScreen
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isLoadingUser
                        ? 'Halo, Pengguna!'
                        : 'Halo, ${_currentUser?.fullName ?? 'Pengguna'}!',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2D5016),
                    ),
                  ),
                  Text(
                    'Mau pergi kemana hari ini ?',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ikon notifikasi
          _headerIconButton(
            Icons.notifications_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // Ikon headset / support
          _headerIconButton(
            Icons.headset_mic_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Fitur bantuan Hubungi Admin sedang dikembangkan',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: const Color(0xFF2D5016),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE8EDE3),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF2D5016)),
      ),
    );
  }

  // ─── Banner Slider ─────────────────────────────────────────────────────────

  Widget _buildBannerSlider() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: 3,
            onPageChanged: (index) {
              setState(() => _currentBannerIndex = index);
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Image.asset(
                  banners[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Dot indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final isActive = index == _currentBannerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF2D5016)
                    : const Color(0xFFCCCCCC),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ─── Kategori ──────────────────────────────────────────────────────────────

  Widget _buildCategories() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = index == _selectedCategoryIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(0xFF2D5016)
                          : const Color(0xFFE8EDE3),
                    ),
                    child: Icon(
                      _categoryIcon(cat['icon']!),
                      size: 22,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF2D5016),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat['label']!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? const Color(0xFF2D5016)
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _categoryIcon(String key) {
    switch (key) {
      case 'semua':
        return Icons.apps_rounded;
      case 'alam':
        return Icons.landscape_outlined;
      case 'penginapan':
        return Icons.hotel_outlined;
      case 'kuliner':
        return Icons.restaurant_outlined;
      case 'edukasi':
        return Icons.menu_book_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  // ─── Section Title ─────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  // ─── Rekomendasi ───────────────────────────────────────────────────────────

  Widget _buildRecommendations() {
    if (_isLoadingDestinations) {
      return SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(color: const Color(0xFF2D5016)),
        ),
      );
    }

    final recommendations = _filteredRecommendations;

    if (recommendations.isEmpty) {
      return Container(
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Belum ada destinasi wisata',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: recommendations.length,
        itemBuilder: (context, index) {
          final item = recommendations[index];
          return _RecommendationCard(
            destinationId: item['id'] as String? ?? '',
            name: item['name'] as String? ?? 'Destinasi',
            location: item['location'] as String? ?? 'Lokasi',
            rating: (item['rating'] as num?)?.toDouble() ?? 0.0,
            imageUrl: item['image_url'] as String?,
          );
        },
      ),
    );
  }

  // ─── Acara Mendatang ───────────────────────────────────────────────────────

  Widget _buildEvents() {
    if (_isLoadingEvents) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF2D5016)),
        ),
      );
    }

    if (_events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              'Belum ada acara mendatang',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _events.map((event) {
          final start = event['start_date'] as String?;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _EventCard(
              month: _eventMonthLabel(start),
              day: _eventDayLabel(start),
              title: event['name'] as String? ?? 'Acara',
              time: _eventTimeLabel(event),
              location: event['location'] as String? ?? '',
              phase: EventService.eventPhaseLabel(event),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Bottom Navigation ─────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Beranda'},
      {'icon': Icons.explore_outlined, 'label': 'Explorasi'},
      {'icon': Icons.smart_toy_outlined, 'label': 'Agent'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = index == _selectedNavIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedNavIndex = index),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width / items.length - 8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: isSelected ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          items[index]['icon'] as IconData,
                          size: 24,
                          color: isSelected
                              ? const Color(0xFF2D5016)
                              : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        items[index]['label'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? const Color(0xFF2D5016)
                              : Colors.grey[500],
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
}

// ─── Recommendation Card ──────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  final String destinationId;
  final String name;
  final String location;
  final double rating;
  final String? imageUrl;

  const _RecommendationCard({
    required this.destinationId,
    required this.name,
    required this.location,
    required this.rating,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (destinationId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DestinationDetailScreen(destinationId: destinationId),
            ),
          );
        }
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto dari database atau wireframe
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: AppNetworkImage(
                    imageUrl: imageUrl,
                    height: 120,
                    width: 170,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    placeholderLabel: name,
                  ),
                ),
                // Rating badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Color(0x20000000), blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: Color(0xFFE8A020),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          location,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 28,
                      child: ElevatedButton(
                        onPressed: () {
                          if (destinationId.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DestinationDetailScreen(
                                  destinationId: destinationId,
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D5016),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Lihat Detail',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Event Card ───────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final String month;
  final String day;
  final String title;
  final String time;
  final String location;
  final String phase;

  const _EventCard({
    required this.month,
    required this.day,
    required this.title,
    required this.time,
    required this.location,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Tanggal
          Container(
            width: 52,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF2D5016),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  month,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  day,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Info acara
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: phase == 'Sedang Berjalan'
                            ? const Color(0xFF2D5016)
                            : const Color(0xFFE8A020),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        phase,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_outlined,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tombol panah
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2D5016), width: 1.5),
            ),
            child: const Icon(
              Icons.arrow_forward,
              size: 16,
              color: Color(0xFF2D5016),
            ),
          ),
        ],
      ),
    );
  }
}
