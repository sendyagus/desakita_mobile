import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:desa_wisata/screens/explore_screen.dart';
import 'package:desa_wisata/screens/booking_screen.dart';
import 'package:desa_wisata/screens/profile_screen.dart';
import 'package:desa_wisata/screens/agent_screen.dart';
import 'package:desa_wisata/services/user_service.dart';
import 'package:desa_wisata/models/user_model.dart';

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
  UserModel? _currentUser;
  bool _isLoadingUser = true;

  final List<Map<String, String>> _categories = [
    {'icon': 'alam', 'label': 'Alam'},
    {'icon': 'sekitar', 'label': 'Sekitar'},
    {'icon': 'budaya', 'label': 'Budaya'},
    {'icon': 'kuliner', 'label': 'Kuliner'},
    {'icon': 'edukasi', 'label': 'Edukasi'},
  ];

  final List<Map<String, dynamic>> _recommendations = [
    {
      'name': 'Bukit Sakura',
      'location': 'Langkapura',
      'rating': 4.3,
    },
    {
      'name': 'Camp 9',
      'location': 'Kemiling',
      'rating': 4.1,
    },
    {
      'name': 'Danau Hijau',
      'location': 'Sukarame',
      'rating': 4.5,
    },
  ];

  final List<Map<String, dynamic>> _events = [
    {
      'month': 'OKT',
      'day': '24',
      'title': 'Festival Panen Raya',
      'time': '08:00 - Selesai',
      'location': 'Desa Pujon Kidul, Malang',
    },
    {
      'month': 'NOV',
      'day': '05',
      'title': 'Pasar Budaya Nusantara',
      'time': '09:00 - 17:00',
      'location': 'Desa Sade, Lombok',
    },
    {
      'month': 'NOV',
      'day': '12',
      'title': 'Festival Kuliner Desa',
      'time': '10:00 - Selesai',
      'location': 'Desa Penglipuran, Bali',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Widget _buildBerandaContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
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
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _selectedNavIndex,
                children: [
                  _buildBerandaContent(),
                  const ExploreScreen(),
                  const AgentScreen(),
                  const BookingScreen(),
                  // Tab 4: Profil
                  const ProfileScreen(),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // Avatar
          Container(
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
                  : _currentUser?.avatarUrl != null && _currentUser!.avatarUrl!.isNotEmpty
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

          const SizedBox(width: 12),

          // Sapaan
          Expanded(
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

          // Ikon notifikasi
          _headerIconButton(Icons.notifications_outlined),
          const SizedBox(width: 8),
          // Ikon headset / support
          _headerIconButton(Icons.headset_mic_outlined),
        ],
      ),
    );
  }

  Widget _headerIconButton(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE8EDE3),
      ),
      child: Icon(icon, size: 20, color: const Color(0xFF2D5016)),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _WireframeImage(
                    label: 'Banner ${index + 1}\n(Foto Wisata Desa)',
                    height: 180,
                  ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = index == _selectedCategoryIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
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
      case 'alam':
        return Icons.landscape_outlined;
      case 'sekitar':
        return Icons.location_on_outlined;
      case 'budaya':
        return Icons.account_balance_outlined;
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
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _recommendations.length,
        itemBuilder: (context, index) {
          final item = _recommendations[index];
          return _RecommendationCard(
            name: item['name'] as String,
            location: item['location'] as String,
            rating: item['rating'] as double,
          );
        },
      ),
    );
  }

  // ─── Acara Mendatang ───────────────────────────────────────────────────────

  Widget _buildEvents() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _events.map((event) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _EventCard(
              month: event['month'] as String,
              day: event['day'] as String,
              title: event['title'] as String,
              time: event['time'] as String,
              location: event['location'] as String,
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
      {'icon': Icons.smart_toy_outlined, 'label': 'agent'},
      {'icon': Icons.confirmation_number_outlined, 'label': 'Booking'},
      {'icon': Icons.person_outline, 'label': 'Profil'},
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = index == _selectedNavIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedNavIndex = index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[index]['icon'] as IconData,
                      size: 24,
                      color: isSelected
                          ? const Color(0xFF2D5016)
                          : Colors.grey[500],
                    ),
                    const SizedBox(height: 3),
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
  final String name;
  final String location;
  final double rating;

  const _RecommendationCard({
    required this.name,
    required this.location,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Foto wireframe
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: _WireframeImage(
                  label: name,
                  height: 120,
                  width: 170,
                ),
              ),
              // Rating badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x20000000),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: Color(0xFFE8A020)),
                      const SizedBox(width: 3),
                      Text(
                        rating.toString(),
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
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 2),
                    Text(
                      location,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
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
                      onPressed: () {},
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
                        'BUKA',
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

  const _EventCard({
    required this.month,
    required this.day,
    required this.title,
    required this.time,
    required this.location,
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
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined,
                        size: 12, color: Colors.grey),
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
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: Colors.grey),
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

// ─── Wireframe Image ──────────────────────────────────────────────────────────

class _WireframeImage extends StatelessWidget {
  final String label;
  final double height;
  final double? width;

  const _WireframeImage({
    required this.label,
    required this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      color: const Color(0xFFD8DDD0),
      child: Stack(
        children: [
          // Grid pattern
          CustomPaint(
            size: Size(width ?? double.infinity, height),
            painter: _WireframePainter(),
          ),
          // Label
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 28,
                  color: Colors.grey[500],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
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

class _WireframePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    // Garis diagonal kiri-atas ke kanan-bawah
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    // Garis diagonal kanan-atas ke kiri-bawah
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
