import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desa_wisata/services/destination_service.dart';
import 'package:desa_wisata/services/user_service.dart';
import 'package:desa_wisata/screens/destination_detail_screen.dart';
import 'package:desa_wisata/widgets/app_network_image.dart';

class FavoriteDestinationsScreen extends StatefulWidget {
  const FavoriteDestinationsScreen({super.key});

  @override
  State<FavoriteDestinationsScreen> createState() =>
      _FavoriteDestinationsScreenState();
}

class _FavoriteDestinationsScreenState
    extends State<FavoriteDestinationsScreen> {
  final UserService _userService = UserService();
  final DestinationService _destinationService = DestinationService();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F0),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF2D5016)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Destinasi Favorit',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            'Silakan login terlebih dahulu',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF2D5016)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Destinasi Favorit',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D5016)),
            );
          }

          if (userSnap.hasError || !userSnap.hasData || !userSnap.data!.exists) {
            return Center(
              child: Text(
                'Gagal memuat data',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            );
          }

          final userData = userSnap.data!.data() as Map<String, dynamic>;
          final List<String> favoriteIds =
              List<String>.from(userData['favorites'] ?? []);

          if (favoriteIds.isEmpty) {
            return _buildEmptyState();
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('destinations')
                .where(FieldPath.documentId, whereIn: favoriteIds)
                .snapshots(),
            builder: (context, destSnap) {
              if (destSnap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2D5016)),
                );
              }

              if (destSnap.hasError) {
                return Center(
                  child: Text(
                    'Terjadi kesalahan',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                );
              }

              final docs = destSnap.data?.docs ?? [];
              final favoritedDestinations = docs
                  .map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return _destinationService.docDataToFormMap(doc.id, d);
                  })
                  .where((d) => d['status'] == true) // hanya tampilkan yang aktif
                  .toList();

              if (favoritedDestinations.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favoritedDestinations.length,
                itemBuilder: (context, index) {
                  final item = favoritedDestinations[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _FavoriteDestinationCard(
                      destination: item,
                      onUnfavorite: () async {
                        try {
                          await _userService.toggleFavorite(userId, item['id']);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Dihapus dari favorit',
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                                backgroundColor: const Color(0xFF2D5016),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('Error removing favorite: $e');
                        }
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEEF2E8),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 48,
                color: Color(0xFF2D5016),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Favorit',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Simpan destinasi wisata favoritmu untuk memudahkan perencanaan liburan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5016),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Cari Destinasi',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

class _FavoriteDestinationCard extends StatelessWidget {
  final Map<String, dynamic> destination;
  final VoidCallback onUnfavorite;

  const _FavoriteDestinationCard({
    required this.destination,
    required this.onUnfavorite,
  });

  @override
  Widget build(BuildContext context) {
    final name = destination['name'] as String? ?? '';
    final location = destination['location'] as String? ?? '';
    final rating = (destination['rating'] as num?)?.toDouble() ?? 0.0;
    final price = destination['price'] as String? ?? '';
    final imageUrl = destination['image_url'] as String?;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DestinationDetailScreen(
              destinationId: destination['id'] as String,
            ),
          ),
        );
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Kiri: Foto
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: AppNetworkImage(
                imageUrl: imageUrl,
                height: 120,
                width: 120,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                placeholderLabel: name,
              ),
            ),
            const SizedBox(width: 12),
            // Tengah: Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
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
                    const Spacer(),
                    Row(
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
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            price,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2D5016),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Kanan: Tombol Unfavorite
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: onUnfavorite,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
