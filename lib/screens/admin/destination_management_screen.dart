import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/destination_service.dart';
import '../../services/google_drive_service.dart';
import '../../widgets/app_network_image.dart';
import 'destination_form_screen.dart';

class DestinationManagementScreen extends StatefulWidget {
  const DestinationManagementScreen({super.key});

  @override
  State<DestinationManagementScreen> createState() => _DestinationManagementScreenState();
}

class _DestinationManagementScreenState extends State<DestinationManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DestinationService _destinationService = DestinationService();
  final GoogleDriveService _googleDriveService = GoogleDriveService.instance;
  String _selectedCategory = 'Semua';
  final List<String> _categories = ['Semua', 'Alam', 'Budaya', 'Kuliner', 'Penginapan'];

  List<_DestinationModel> _filterDestinations(List<Map<String, dynamic>> allDestinations) {
    final query = _searchController.text.toLowerCase();
    return allDestinations.where((d) {
      final matchSearch = query.isEmpty || 
          (d['name'] as String).toLowerCase().contains(query) || 
          (d['location'] as String).toLowerCase().contains(query);
      final matchCategory = _selectedCategory == 'Semua' || d['category'] == _selectedCategory;
      return matchSearch && matchCategory;
    }).map((d) => _DestinationModel(
      id: d['id'] as String,
      name: d['name'] as String,
      category: d['category'] as String,
      location: d['location'] as String,
      rating: (d['rating'] as num).toDouble(),
      price: d['price'] as String,
      status: d['status'] as bool,
      imageUrl: d['imageUrl'] as String?,
      rawData: d,
    )).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: _buildAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('destinations').snapshots(),
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
              ...data,
            };
          }).toList();

          final filteredDestinations = _filterDestinations(allDestinations);

          return Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 8),
              _buildCategoryChips(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text('${filteredDestinations.length} destinasi ditemukan', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Expanded(child: _buildDestinationList(filteredDestinations)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDestinationForm(context, null),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_outlined),
        label: Text('Tambah Destinasi', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF2D5016)), onPressed: () => Navigator.pop(context)),
      title: Text('Kelola Destinasi Wisata', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))]),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Cari destinasi atau lokasi...',
            hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _categories[index] == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = _categories[index]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(color: isSelected ? const Color(0xFF2D5016) : const Color(0xFFE8EDE3), borderRadius: BorderRadius.circular(20)),
              child: Text(_categories[index], style: GoogleFonts.poppins(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? Colors.white : Colors.grey[700])),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDestinationList(List<_DestinationModel> destinations) {
    if (destinations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.place_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Tidak ada destinasi', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: destinations.length,
      itemBuilder: (context, index) {
        final dest = destinations[index];
        return _DestinationCard(
          destination: dest,
          onEdit: () => _showDestinationForm(context, dest),
          onDelete: () => _confirmDelete(dest),
          onToggleStatus: () => _toggleStatus(dest),
        );
      },
    );
  }

  void _showDestinationForm(BuildContext context, _DestinationModel? destination) async {
    Map<String, dynamic>? formData;
    if (destination != null) {
      formData = _destinationService.docDataToFormMap(
        destination.id,
        destination.rawData,
      );
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DestinationFormScreen(destination: formData),
      ),
    );

    // Refresh jika ada perubahan
    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _toggleStatus(_DestinationModel dest) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _destinationService.toggleDestinationStatus(dest.id, !dest.status);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Status ${dest.name} diubah', style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: const Color(0xFF2D5016),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah status: $e', style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _confirmDelete(_DestinationModel dest) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Destinasi', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A))),
        content: Text('Yakin ingin menghapus ${dest.name}?', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey[600]))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                final imageUrl = dest.imageUrl;
                await _destinationService.deleteDestination(dest.id);
                if (imageUrl != null && imageUrl.isNotEmpty) {
                  try {
                    await _googleDriveService.deleteFromGoogleDrive(imageUrl);
                  } catch (_) {
                    // Firestore sudah terhapus; gagal hapus Drive tidak memblokir UI
                  }
                }
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('${dest.name} dihapus', style: GoogleFonts.poppins(fontSize: 13)),
                    backgroundColor: const Color(0xFFE53935),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus: $e', style: GoogleFonts.poppins(fontSize: 13)),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: Text('Hapus', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _DestinationModel {
  final String id;
  final String name;
  final String category;
  final String location;
  final double rating;
  final String price;
  final bool status;
  final String? imageUrl;
  final Map<String, dynamic> rawData;

  _DestinationModel({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.rating,
    required this.price,
    required this.status,
    this.imageUrl,
    required this.rawData,
  });
}

class _DestinationCard extends StatelessWidget {
  final _DestinationModel destination;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _DestinationCard({required this.destination, required this.onEdit, required this.onDelete, required this.onToggleStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AppNetworkImage(
                  imageUrl: destination.imageUrl,
                  width: 56,
                  height: 56,
                  placeholderLabel: destination.name,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(destination.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: _getCategoryColor(destination.category).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(destination.category, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _getCategoryColor(destination.category))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Text(destination.location, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                        const SizedBox(width: 10),
                        const Icon(Icons.star_rounded, size: 12, color: Color(0xFFE8A020)),
                        const SizedBox(width: 2),
                        Text(destination.rating.toString(), style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Harga', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500])),
                    Text(destination.price, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF2D5016))),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: destination.status ? const Color(0xFF4CAF50) : Colors.grey)),
                  const SizedBox(width: 6),
                  Text(destination.status ? 'Aktif' : 'Nonaktif', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: destination.status ? const Color(0xFF4CAF50) : Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(onPressed: onToggleStatus, icon: Icon(destination.status ? Icons.toggle_on : Icons.toggle_off, color: destination.status ? const Color(0xFF4CAF50) : Colors.grey, size: 32), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, color: Color(0xFF2196F3), size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 8),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Color(0xFFE53935), size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Alam':
        return const Color(0xFF4CAF50);
      case 'Budaya':
        return const Color(0xFF9C27B0);
      case 'Kuliner':
        return const Color(0xFFFF9800);
      case 'Penginapan':
        return const Color(0xFF2196F3);
      default:
        return Colors.grey;
    }
  }
}