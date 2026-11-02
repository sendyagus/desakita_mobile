import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';
import 'package:desa_wisata/widgets/destination_photo.dart';

/// Detail usaha lokal terpisah dari detail destinasi wisata.
/// Data dibaca dari dokumen koleksi Firestore `umkm`.
class UmkmDetailScreen extends StatefulWidget {
  final Map<String, dynamic> umkm;

  const UmkmDetailScreen({super.key, required this.umkm});

  @override
  State<UmkmDetailScreen> createState() => _UmkmDetailScreenState();
}

class _UmkmDetailScreenState extends State<UmkmDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _productsKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _text(dynamic value, {String fallback = ''}) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  double _rating(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;

  List<Map<String, dynamic>> _products() {
    final raw = widget.umkm['products'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((product) => Map<String, dynamic>.from(product))
        .toList();
  }

  void _scrollToProducts() {
    final target = _productsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _text(widget.umkm['name'], fallback: 'Usaha Lokal');
    final location = _text(
      widget.umkm['location'],
      fallback: 'Lokasi belum tersedia',
    );
    final category = _text(widget.umkm['category'], fallback: 'UMKM Lokal');
    final description = _text(widget.umkm['description']);
    final imageUrl = _text(widget.umkm['imageUrl'] ?? widget.umkm['image_url']);
    final openingHours = _text(
      widget.umkm['openingHours'] ?? widget.umkm['opening_hours'],
    );
    final rating = _rating(widget.umkm['rating']);
    final reviewCount = _text(
      widget.umkm['reviewCount'] ?? widget.umkm['review_count'],
      fallback: '0',
    );
    final products = _products();

    return Scaffold(
      backgroundColor: DesaKitaColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 270,
            pinned: true,
            backgroundColor: DesaKitaColors.background,
            foregroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(7),
              child: _RoundButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14, top: 7, bottom: 7),
                child: _RoundButton(
                  icon: Icons.share_outlined,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Fitur berbagi profil UMKM belum dihubungkan.',
                      ),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  DestinationPhoto(
                    imageUrl: imageUrl,
                    fallbackAsset: 'assets/img/cs2.jpg',
                    borderRadius: BorderRadius.zero,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x55000000),
                          Color(0x00000000),
                          Color(0x99000000),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: DesaKitaColors.darkGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 25,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Color(0x88000000), blurRadius: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -14),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 34),
                decoration: const BoxDecoration(
                  color: DesaKitaColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 17,
                          color: DesaKitaColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            location,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: DesaKitaColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoPill(
                          icon: Icons.star_rounded,
                          label: rating > 0
                              ? rating.toStringAsFixed(1)
                              : 'Belum ada rating',
                          color: DesaKitaColors.amber,
                        ),
                        _InfoPill(
                          icon: Icons.rate_review_outlined,
                          label: '$reviewCount ulasan',
                        ),
                        if (openingHours.isNotEmpty)
                          _InfoPill(
                            icon: Icons.schedule_rounded,
                            label: openingHours,
                          ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Text(
                      'Tentang UMKM',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: DesaKitaColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description.isNotEmpty
                          ? description
                          : 'Informasi usaha ini belum dilengkapi. Pengelola dapat menambahkan cerita usaha, produk unggulan, dan informasi lainnya pada data UMKM.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        height: 1.65,
                        color: DesaKitaColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      key: _productsKey,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Katalog Produk',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: DesaKitaColors.text,
                              ),
                            ),
                          ),
                          Text(
                            '${products.length} produk',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: DesaKitaColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (products.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: DesaKitaColors.divider),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 30,
                              color: DesaKitaColors.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Produk belum ditambahkan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: DesaKitaColors.text,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Tambahkan daftar produk pada field products di dokumen UMKM untuk menampilkannya di sini.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                height: 1.5,
                                color: DesaKitaColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.76,
                            ),
                        itemBuilder: (context, index) =>
                            _ProductCard(product: products[index]),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'Lokasi UMKM',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: DesaKitaColors.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: DesaKitaColors.divider),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: DesaKitaColors.mutedGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.storefront_outlined,
                              color: DesaKitaColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              location,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                height: 1.4,
                                color: DesaKitaColors.text,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.map_outlined,
                            size: 20,
                            color: DesaKitaColors.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Peta dan petunjuk arah akan tersedia setelah layanan peta diintegrasikan.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: DesaKitaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          18,
          11,
          18,
          MediaQuery.of(context).padding.bottom + 11,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 12,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _scrollToProducts,
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: Text(
              'Lihat Katalog Produk',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductCard({required this.product});

  String _value(dynamic value, {String fallback = ''}) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  @override
  Widget build(BuildContext context) {
    final name = _value(product['name'], fallback: 'Produk Lokal');
    final price = _value(product['price'], fallback: 'Harga belum tersedia');
    final imageUrl = _value(product['imageUrl'] ?? product['image_url']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesaKitaColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DestinationPhoto(
              imageUrl: imageUrl,
              fallbackAsset: 'assets/img/cs2.jpg',
              borderRadius: BorderRadius.zero,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: DesaKitaColors.text,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  price,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: DesaKitaColors.primary,
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

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: DesaKitaColors.darkGreen, size: 20),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoPill({
    required this.icon,
    required this.label,
    this.color = DesaKitaColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: DesaKitaColors.mutedGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: DesaKitaColors.darkGreen,
            ),
          ),
        ],
      ),
    );
  }
}
