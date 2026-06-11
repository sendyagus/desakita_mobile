import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:desa_wisata/config/app_categories.dart';
import 'package:desa_wisata/services/user_service.dart';
import 'package:desa_wisata/screens/login_screen.dart';
import 'package:desa_wisata/widgets/app_network_image.dart';
import 'package:desa_wisata/screens/destination_detail_screen.dart';

enum _ExploreSortOption {
  ratingHigh,
  newest,
  locationAz,
}

extension on _ExploreSortOption {
  String get label {
    switch (this) {
      case _ExploreSortOption.ratingHigh:
        return 'Rating Tertinggi';
      case _ExploreSortOption.newest:
        return 'Terbaru';
      case _ExploreSortOption.locationAz:
        return 'Terdekat';
    }
  }
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int _selectedFilterIndex = 0;
  _ExploreSortOption _sortOption = _ExploreSortOption.ratingHigh;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = AppCategories.exploreFilters;
  final UserService _userService = UserService();
  StreamSubscription? _authSub;
  StreamSubscription? _favSub;
  Set<String> _favoriteIds = {};

  DateTime _parseCreatedAt(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime(1970);
    return DateTime(1970);
  }

  List<Map<String, dynamic>> _filterAndSortDestinations(
    List<Map<String, dynamic>> allDestinations,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final selectedFilter = _filters[_selectedFilterIndex];

    final filtered = allDestinations.where((item) {
      final name = (item['name'] as String? ?? '').toLowerCase();
      final location = (item['location'] as String? ?? '').toLowerCase();
      final category = item['category'] as String? ?? '';

      final matchCategory = AppCategories.matchesFilter(category, selectedFilter);
      final matchSearch =
          query.isEmpty || name.contains(query) || location.contains(query);
      return matchCategory && matchSearch;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortOption) {
        case _ExploreSortOption.ratingHigh:
          final ra = (a['rating'] as num?)?.toDouble() ?? 0;
          final rb = (b['rating'] as num?)?.toDouble() ?? 0;
          final cmp = rb.compareTo(ra);
          if (cmp != 0) return cmp;
          return (a['name'] as String? ?? '')
              .compareTo(b['name'] as String? ?? '');
        case _ExploreSortOption.newest:
          final ta = _parseCreatedAt(a['createdAt']);
          final tb = _parseCreatedAt(b['createdAt']);
          final cmp = tb.compareTo(ta);
          if (cmp != 0) return cmp;
          return (a['name'] as String? ?? '')
              .compareTo(b['name'] as String? ?? '');
        case _ExploreSortOption.locationAz:
          final la = (a['location'] as String? ?? '').toLowerCase();
          final lb = (b['location'] as String? ?? '').toLowerCase();
          final cmp = la.compareTo(lb);
          if (cmp != 0) return cmp;
          return (a['name'] as String? ?? '')
              .compareTo(b['name'] as String? ?? '');
      }
    });

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.userChanges().listen((user) {
      _subscribeToFavorites(user?.uid);
    });
  }

  void _subscribeToFavorites(String? uid) {
    _favSub?.cancel();
    if (uid != null) {
      _favSub = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists) {
          final favs = List<String>.from(doc.data()?['favorites'] ?? []);
          if (mounted) {
            setState(() {
              _favoriteIds = favs.toSet();
            });
          }
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _favoriteIds = {};
        });
      }
    }
  }

  Future<void> _handleFavoriteToggle(String destinationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan login terlebih dahulu untuk menyimpan favorit',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF2D5016),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'Login',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    try {
      await _userService.toggleFavorite(user.uid, destinationId);
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _favSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('destinations')
              .where('status', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 56, color: Colors.red[300]),
                    const SizedBox(height: 12),
                    Text('Terjadi kesalahan', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF2D5016)));
            }

            final allDestinations = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id,
                'name': data['name'] ?? '',
                'location': data['location'] ?? '',
                'category': AppCategories.normalize(data['category'] as String?),
                'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
                'price': data['price'] ?? '',
                'imageUrl': data['imageUrl'],
                'createdAt': data['createdAt'],
                'raw_data': {'id': doc.id, ...data},
              };
            }).toList();

            final filteredDestinations =
                _filterAndSortDestinations(allDestinations);

            return Column(
              children: [
                // Search bar + filter icon
                _buildSearchBar(),

                const SizedBox(height: 12),

                // Filter chips
                _buildFilterChips(),

                const SizedBox(height: 16),

                // Daftar destinasi
                Expanded(
                  child: _buildDestinationList(filteredDestinations),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Search Bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // Input pencarian
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari destinasi...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Tombol urutkan
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _sortOption != _ExploreSortOption.ratingHigh
                  ? const Color(0xFF3D6B1E)
                  : const Color(0xFF2D5016),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _showFilterSheet,
              icon: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter Chips ──────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedFilterIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilterIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2D5016)
                    : const Color(0xFFE8EDE3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _filters[index],
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Destination List ──────────────────────────────────────────────────────

  Widget _buildDestinationList(List<Map<String, dynamic>> destinations) {
    if (destinations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Destinasi tidak ditemukan',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: destinations.length,
      itemBuilder: (context, index) {
        final item = destinations[index];
        final destinationId = item['id'] as String;
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DestinationDetailScreen(
                    destinationId: destinationId,
                  ),
                ),
              );
            },
            child: _DestinationCard(
              name: item['name'] as String,
              location: item['location'] as String,
              category: item['category'] as String,
              rating: item['rating'] as double,
              price: item['price'] as String,
              imageUrl: item['imageUrl'] as String?,
              isFavorite: _favoriteIds.contains(destinationId),
              onFavoriteTap: () => _handleFavoriteToggle(destinationId),
              onDetailTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DestinationDetailScreen(
                      destinationId: destinationId,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ─── Filter Bottom Sheet ───────────────────────────────────────────────────

  void _showFilterSheet() {
    var tempSort = _sortOption;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Urutkan Destinasi',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kategori dipilih lewat chip di atas daftar.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Urutkan berdasarkan',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _ExploreSortOption.values.map((option) {
                      final isSelected = tempSort == option;
                      return ChoiceChip(
                        label: Text(
                          option.label,
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF2D5016),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                        onSelected: (_) =>
                            setSheetState(() => tempSort = option),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(
                              () => tempSort = _ExploreSortOption.ratingHigh,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2D5016),
                            side: const BorderSide(color: Color(0xFF2D5016)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(0, 48),
                          ),
                          child: Text(
                            'Reset',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _sortOption = tempSort);
                            Navigator.pop(sheetContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D5016),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            minimumSize: const Size(0, 48),
                          ),
                          child: Text(
                            'Terapkan',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Destination Card ─────────────────────────────────────────────────────────

class _DestinationCard extends StatelessWidget {
  final String name;
  final String location;
  final String category;
  final double rating;
  final String price;
  final String? imageUrl;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onDetailTap;

  const _DestinationCard({
    required this.name,
    required this.location,
    required this.category,
    required this.rating,
    required this.price,
    this.imageUrl,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
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
              AppNetworkImage(
                imageUrl: imageUrl,
                height: 200,
                width: double.infinity,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                placeholderLabel: name,
              ),

              // Rating badge kiri atas
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                          size: 14, color: Color(0xFFE8A020)),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Favorite button kanan atas
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: onFavoriteTap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x20000000),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: isFavorite ? Colors.red : const Color(0xFF2D5016),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Info bawah
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Lokasi
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        location,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Kategori
                    Icon(
                      _categoryIcon(category),
                      size: 14,
                      color: const Color(0xFF2D5016),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      category,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2D5016),
                      ),
                    ),
                    const Spacer(),
                    // Harga
                    Text(
                      price,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2D5016),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: onDetailTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5016),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Lihat Detail',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Alam':
        return Icons.landscape_outlined;
      case 'Edukasi':
        return Icons.account_balance_outlined;
      case 'Kuliner':
        return Icons.fastfood_outlined;
      case 'Penginapan':
        return Icons.hotel_outlined;
      default:
        return Icons.place_outlined;
    }
  }
}

