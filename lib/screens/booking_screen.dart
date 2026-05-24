import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desa_wisata/config/app_categories.dart';
import 'package:desa_wisata/services/destination_service.dart';
import 'package:desa_wisata/screens/user/create_booking_screen.dart';
import 'package:desa_wisata/screens/user/user_booking_history_screen.dart';
import 'package:desa_wisata/widgets/app_network_image.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _selectedTabIndex = 0;
  final DestinationService _destinationService = DestinationService();

  final List<String> _tabs = ['Semua', 'Penginapan', 'Wisata'];

  List<Map<String, dynamic>> _filterList(List<Map<String, dynamic>> all) {
    final selected = _tabs[_selectedTabIndex];
    if (selected == 'Semua') return all;
    if (selected == 'Penginapan') {
      return all
          .where((d) => AppCategories.normalize(d['category'] as String?) == 'Penginapan')
          .toList();
    }
    // Wisata = kategori Alam yang bisa dibooking
    return all
        .where((d) => AppCategories.normalize(d['category'] as String?) == 'Alam')
        .toList();
  }

  IconData _categoryIcon(String category) {
    switch (AppCategories.normalize(category)) {
      case 'Penginapan':
        return Icons.bed_outlined;
      case 'Alam':
        return Icons.landscape_outlined;
      default:
        return Icons.place_outlined;
    }
  }

  String _priceUnit(String category) {
    return AppCategories.normalize(category) == 'Penginapan'
        ? '/ malam'
        : '/ orang';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),

            const SizedBox(height: 16),

            // Tab filter
            _buildTabs(),

            const SizedBox(height: 16),

            Expanded(child: _buildServiceList()),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Eksplorasi Layanan',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D5016),
              ),
            ),
          ),
          // Tombol Riwayat Booking
          GestureDetector(
            onTap: () {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Login dulu untuk melihat riwayat booking',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    backgroundColor: Colors.orange[800],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UserBookingHistoryScreen(),
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE8EDE3),
              ),
              child: const Icon(
                Icons.history_outlined,
                size: 20,
                color: Color(0xFF2D5016),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Tombol customer service (headset)
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Fitur bantuan Hubungi Admin sedang dikembangkan',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF2D5016),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE8EDE3),
              ),
              child: const Icon(
                Icons.headset_mic_outlined,
                size: 20,
                color: Color(0xFF2D5016),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tabs ──────────────────────────────────────────────────────────────────

  Widget _buildTabs() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedTabIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2D5016)
                    : const Color(0xFFE8EDE3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _tabs[index],
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color:
                      isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Service List ──────────────────────────────────────────────────────────

  Widget _buildServiceList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _destinationService.getBookableDestinations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2D5016)),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Gagal memuat data booking',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          );
        }

        final filtered = _filterList(snapshot.data ?? []);
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'Belum ada tempat booking.\nAdmin dapat menambah di Kelola Destinasi\n(aktifkan "Bisa dibooking" + stok).',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final item = filtered[index];
            final category = AppCategories.normalize(item['category'] as String?);
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _ServiceCard(
                name: item['name'] as String? ?? 'Destinasi',
                description: (item['description'] as String?)?.isNotEmpty == true
                    ? item['description'] as String
                    : item['location'] as String? ?? '',
                category: category == 'Alam' ? 'Wisata' : category,
                categoryIcon: _categoryIcon(category),
                price: item['price'] as String? ?? 'Rp 0',
                priceUnit: _priceUnit(category),
                rating: (item['rating'] as num?)?.toDouble() ?? 0,
                stock: (item['stock'] as num?)?.toInt() ?? 0,
                imageUrl: item['image_url'] as String?,
                onTap: () => _openBooking(context, item),
              ),
            );
          },
        );
      },
    );
  }

  void _openBooking(BuildContext context, Map<String, dynamic> destination) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Login dulu untuk melakukan booking',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: Colors.orange[800],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateBookingScreen(destination: destination),
      ),
    );
  }
}

// ─── Service Card ─────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final String name;
  final String description;
  final String category;
  final IconData categoryIcon;
  final String price;
  final String priceUnit;
  final double rating;
  final int stock;
  final String? imageUrl;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.name,
    required this.description,
    required this.category,
    required this.categoryIcon,
    required this.price,
    required this.priceUnit,
    required this.rating,
    required this.stock,
    this.imageUrl,
    required this.onTap,
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
          // Foto
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: AppNetworkImage(
                  imageUrl: imageUrl,
                  height: 200,
                  width: double.infinity,
                  placeholderLabel: name,
                ),
              ),

              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: stock > 0 ? const Color(0xFF2D5016) : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Stok: $stock',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(categoryIcon, size: 13, color: const Color(0xFF2D5016)),
                      const SizedBox(width: 4),
                      Text(
                        category,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2D5016),
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
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama + rating
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: Color(0xFFE8A020)),
                        const SizedBox(width: 3),
                        Text(
                          rating.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Deskripsi
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 12),

                // Harga + tombol
                Row(
                  children: [
                    // Harga
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mulai dari',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              price,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2D5016),
                              ),
                            ),
                            Text(
                              priceUnit,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Tombol Cek Ketersediaan
                    SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D5016),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(
                          'Booking Sekarang',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }
}
