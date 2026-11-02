import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desa_wisata/screens/ticket_booking_screen.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';
import 'package:desa_wisata/widgets/destination_photo.dart';

class DestinationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> destination;

  const DestinationDetailScreen({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    final category = (destination['category'] ?? '').toString();
    final categoryLower = category.toLowerCase();
    final fallback =
        categoryLower.contains('kuliner') || categoryLower.contains('budaya')
        ? 'assets/img/cs2.jpg'
        : 'assets/img/cs1.jpg';
    final name = (destination['name'] ?? 'Destinasi DesaKita').toString();
    final location = (destination['location'] ?? 'Lokasi belum tersedia')
        .toString();
    final description = (destination['description'] ?? '').toString().trim();
    final rating = (destination['rating'] as num?)?.toDouble() ?? 0.0;
    final price = (destination['price'] ?? '').toString().trim();
    final openingHours = (destination['openingHours'] ?? '').toString().trim();
    final facilities = destination['facilities'];
    final facilityList = facilities is List
        ? facilities
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList()
        : <String>[];

    return Scaffold(
      backgroundColor: DesaKitaColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 278,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DestinationPhoto(
                    imageUrl: destination['imageUrl']?.toString(),
                    fallbackAsset: fallback,
                    width: double.infinity,
                    height: 278,
                    borderRadius: BorderRadius.zero,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x55000000),
                          Colors.transparent,
                          Color(0x66000000),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: MediaQuery.of(context).padding.top + 8,
                    child: _RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    right: 14,
                    top: MediaQuery.of(context).padding.top + 8,
                    child: _RoundIconButton(
                      icon: Icons.bookmark_border_rounded,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Fitur destinasi tersimpan belum terhubung ke penyimpanan akun.',
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 23,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category.isEmpty ? 'Wisata lokal' : category,
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
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.15,
                            shadows: const [
                              Shadow(color: Color(0x66000000), blurRadius: 10),
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
              offset: const Offset(0, -16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
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
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoPill(
                          icon: Icons.star_rounded,
                          label: rating > 0
                              ? rating.toStringAsFixed(1)
                              : 'Belum ada rating',
                          iconColor: DesaKitaColors.amber,
                        ),
                        if (openingHours.isNotEmpty)
                          _InfoPill(
                            icon: Icons.schedule_rounded,
                            label: openingHours,
                          ),
                        if (price.isNotEmpty)
                          _InfoPill(
                            icon: Icons.confirmation_number_outlined,
                            label: price,
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tentang Destinasi',
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
                          : 'Informasi lengkap mengenai destinasi ini belum ditambahkan. Kamu tetap dapat melihat nama dan lokasi yang tersedia, atau menghubungi pengelola setempat untuk informasi lebih lanjut.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        height: 1.65,
                        color: DesaKitaColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Fasilitas & Layanan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: DesaKitaColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (facilityList.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: DesaKitaColors.divider),
                        ),
                        child: Text(
                          'Informasi fasilitas belum ditambahkan oleh pengelola.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: DesaKitaColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: facilityList
                            .map(
                              (facility) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: DesaKitaColors.mutedGreen,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      size: 14,
                                      color: DesaKitaColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      facility,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: DesaKitaColors.darkGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'Lokasi',
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
                              Icons.place_outlined,
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
                    const SizedBox(height: 14),
                    Text(
                      'Catatan: rute peta langsung belum terhubung pada versi ini.',
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
          12,
          18,
          MediaQuery.of(context).padding.bottom + 12,
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Harga mulai dari',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: DesaKitaColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    price.isEmpty ? 'Cek harga di lokasi' : price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: DesaKitaColors.darkGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TicketBookingScreen(destination: destination),
                    ),
                  );
                },
                icon: const Icon(Icons.confirmation_number_outlined, size: 17),
                label: Text(
                  'Pesan Tiket',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: DesaKitaColors.darkGreen, size: 21),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  const _InfoPill({
    required this.icon,
    required this.label,
    this.iconColor = DesaKitaColors.primary,
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
          Icon(icon, size: 14, color: iconColor),
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
