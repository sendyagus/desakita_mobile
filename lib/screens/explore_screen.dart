import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desa_wisata/screens/destination_detail_screen.dart';
import 'package:desa_wisata/screens/umkm_detail_screen.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';
import 'package:desa_wisata/widgets/destination_photo.dart';

class ExploreScreen extends StatefulWidget {
  final int initialType;
  const ExploreScreen({super.key, this.initialType = 0});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  int _selectedTypeIndex = 0; // 0 = wisata, 1 = UMKM lokal

  static const _destinationCategories = [
    'Semua',
    'Alam',
    'Budaya',
    'Kuliner',
    'Penginapan',
  ];
  static const _umkmCategories = [
    'Semua',
    'Kuliner',
    'Kerajinan',
    'Oleh-oleh',
    'Budaya',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTypeIndex = widget.initialType.clamp(0, 1).toInt();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesaKitaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildTypeSwitcher(),
            const SizedBox(height: 12),
            _buildCategoryFilters(),
            const SizedBox(height: 12),
            Expanded(child: _buildDestinationResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: DesaKitaColors.text,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari destinasi tujuan kamu...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: DesaKitaColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: DesaKitaColors.darkGreen,
                    size: 21,
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Cari dengan suara',
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Pencarian suara belum terhubung. Gunakan kolom pencarian.',
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.mic_none_rounded,
                      size: 20,
                      color: DesaKitaColors.primary,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Material(
            color: DesaKitaColors.primary,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _showMapNotice,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.map_outlined, color: Colors.white, size: 23),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: DesaKitaColors.divider),
        ),
        child: Row(
          children: [_typeButton('Wisata', 0), _typeButton('UMKM', 1)],
        ),
      ),
    );
  }

  Widget _typeButton(String label, int index) {
    final selected = _selectedTypeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedTypeIndex = index;
          _selectedCategoryIndex = 0;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? DesaKitaColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : DesaKitaColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = _selectedTypeIndex == 1
        ? _umkmCategories
        : _destinationCategories;
    return SizedBox(
      height: 34,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final selected = _selectedCategoryIndex == index;
          return ChoiceChip(
            label: Text(categories[index]),
            selected: selected,
            onSelected: (_) => setState(() => _selectedCategoryIndex = index),
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : DesaKitaColors.textSecondary,
            ),
            selectedColor: DesaKitaColors.darkGreen,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected
                  ? DesaKitaColors.darkGreen
                  : DesaKitaColors.divider,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildDestinationResults() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(_selectedTypeIndex == 1 ? 'umkm' : 'destinations')
          .where('status', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyState(
            Icons.cloud_off_outlined,
            'Data belum dapat dimuat',
            'Periksa koneksi atau izin Firestore, lalu coba lagi.',
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: DesaKitaColors.primary),
          );
        }

        final query = _searchController.text.trim().toLowerCase();
        final categories = _selectedTypeIndex == 1
            ? _umkmCategories
            : _destinationCategories;
        final selectedCategory =
            categories[_selectedCategoryIndex
                .clamp(0, categories.length - 1)
                .toInt()];
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
                'status': data['status'] ?? true,
                'facilities': data['facilities'],
                'openingHours': (data['openingHours'] ?? data['opening_hours'])
                    ?.toString(),
                'reviewCount': data['reviewCount'] ?? data['review_count'] ?? 0,
                'products': data['products'],
              };
            }).toList() ??
            <Map<String, dynamic>>[];

        final filtered =
            rows.where((item) {
              final name = (item['name'] as String).toLowerCase();
              final location = (item['location'] as String).toLowerCase();
              final category = (item['category'] as String).toLowerCase();
              final matchesQuery =
                  query.isEmpty ||
                  name.contains(query) ||
                  location.contains(query);
              final matchesCategory =
                  selectedCategory == 'Semua' ||
                  category == selectedCategory.toLowerCase();
              return matchesQuery && matchesCategory;
            }).toList()..sort(
              (a, b) =>
                  (b['rating'] as double).compareTo(a['rating'] as double),
            );

        if (filtered.isEmpty) {
          final message = _selectedTypeIndex == 1
              ? "Belum ada profil usaha yang cocok. Koleksi 'umkm' perlu diisi di Firestore terlebih dahulu."
              : 'Coba ubah kata kunci atau kategori pencarianmu.';
          return _emptyState(
            Icons.search_off_rounded,
            'Belum ada hasil',
            message,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) => _DestinationListCard(
            destination: filtered[index],
            isUmkm: _selectedTypeIndex == 1,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _selectedTypeIndex == 1
                    ? UmkmDetailScreen(umkm: filtered[index])
                    : DestinationDetailScreen(destination: filtered[index]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState(IconData icon, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: DesaKitaColors.mutedGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 31, color: DesaKitaColors.primary),
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
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                height: 1.5,
                color: DesaKitaColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMapNotice() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DesaKitaColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Icon(
              Icons.map_outlined,
              size: 32,
              color: DesaKitaColors.primary,
            ),
            const SizedBox(height: 10),
            Text(
              'Peta destinasi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: DesaKitaColors.text,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Tampilan peta pada desain Figma memerlukan integrasi peta dan koordinat lokasi. Versi ini belum menghubungkan layanan peta; lokasi teks tetap tersedia di detail destinasi.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                height: 1.5,
                color: DesaKitaColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Mengerti'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationListCard extends StatelessWidget {
  final Map<String, dynamic> destination;
  final bool isUmkm;
  final VoidCallback onTap;

  const _DestinationListCard({
    required this.destination,
    required this.isUmkm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = (destination['category'] ?? '').toString().toLowerCase();
    final fallback =
        isUmkm || category.contains('kuliner') || category.contains('budaya')
        ? 'assets/img/cs2.jpg'
        : 'assets/img/cs1.jpg';
    final rating = (destination['rating'] as num?)?.toDouble() ?? 0.0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shadowColor: const Color(0x10000000),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                DestinationPhoto(
                  imageUrl:
                      (destination['imageUrl'] ?? destination['image_url'])
                          ?.toString(),
                  fallbackAsset: fallback,
                  width: double.infinity,
                  height: 184,
                  borderRadius: BorderRadius.zero,
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: DesaKitaColors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: DesaKitaColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: DesaKitaColors.darkGreen.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isUmkm
                          ? 'UMKM Lokal'
                          : (destination['category']?.toString() ?? 'Wisata'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 13),
              child: Row(
                children: [
                  Expanded(
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
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: DesaKitaColors.text,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: DesaKitaColors.primary,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                destination['location']?.toString() ??
                                    'Lokasi belum tersedia',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: DesaKitaColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(94, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Lihat detail',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
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
