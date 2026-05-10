import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/destination_service.dart';

class DestinationManagementScreen extends StatefulWidget {
  const DestinationManagementScreen({super.key});

  @override
  State<DestinationManagementScreen> createState() => _DestinationManagementScreenState();
}

class _DestinationManagementScreenState extends State<DestinationManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DestinationService _destinationService = DestinationService();
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
              'name': data['name'] ?? '',
              'category': data['category'] ?? '',
              'location': data['location'] ?? '',
              'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
              'price': data['price'] ?? '',
              'status': data['status'] ?? true,
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

  void _showDestinationForm(BuildContext context, _DestinationModel? destination) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DestinationFormSheet(
        destination: destination,
        onSave: (data) async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          try {
            if (destination == null) {
              // Tambah destinasi baru
              await _destinationService.addDestination(
                name: data['name']!,
                category: data['category']!,
                location: data['location']!,
                rating: double.parse(data['rating']!),
                price: data['price']!,
              );
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('${data['name']} berhasil ditambahkan', style: GoogleFonts.poppins(fontSize: 13)),
                  backgroundColor: const Color(0xFF2D5016),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            } else {
              // Update destinasi
              await _destinationService.updateDestination(
                id: destination.id,
                name: data['name']!,
                category: data['category']!,
                location: data['location']!,
                rating: double.parse(data['rating']!),
                price: data['price']!,
              );
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('${data['name']} berhasil diperbarui', style: GoogleFonts.poppins(fontSize: 13)),
                  backgroundColor: const Color(0xFF2D5016),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          } catch (e) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Gagal menyimpan: $e', style: GoogleFonts.poppins(fontSize: 13)),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
      ),
    );
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
                await _destinationService.deleteDestination(dest.id);
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

  _DestinationModel({required this.id, required this.name, required this.category, required this.location, required this.rating, required this.price, required this.status});
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
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFFD8DDD0)),
                child: Icon(Icons.image_outlined, color: Colors.grey[500], size: 28),
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

class _DestinationFormSheet extends StatefulWidget {
  final _DestinationModel? destination;
  final Function(Map<String, String>) onSave;

  const _DestinationFormSheet({this.destination, required this.onSave});

  @override
  State<_DestinationFormSheet> createState() => _DestinationFormSheetState();
}

class _DestinationFormSheetState extends State<_DestinationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _ratingController;
  late final TextEditingController _priceController;
  String _selectedCategory = 'Alam';
  final List<String> _categoryOptions = ['Alam', 'Budaya', 'Kuliner', 'Penginapan'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.destination?.name ?? '');
    _locationController = TextEditingController(text: widget.destination?.location ?? '');
    _ratingController = TextEditingController(text: widget.destination?.rating.toString() ?? '4.0');
    _priceController = TextEditingController(text: widget.destination?.price ?? '');
    _selectedCategory = widget.destination?.category ?? 'Alam';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _ratingController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text(widget.destination == null ? 'Tambah Destinasi Baru' : 'Edit Destinasi', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A))),
                const SizedBox(height: 20),
                _buildTextField('Nama Destinasi', _nameController, Icons.place_outlined),
                const SizedBox(height: 14),
                _buildTextField('Lokasi', _locationController, Icons.location_on_outlined),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Rating', _ratingController, Icons.star_outlined, keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField('Harga', _priceController, Icons.attach_money_outlined)),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Kategori', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF333333))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _categoryOptions.map((cat) {
                    final isSelected = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: isSelected ? const Color(0xFF2D5016) : const Color(0xFFF5F5F0), borderRadius: BorderRadius.circular(12)),
                        child: Text(cat, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.grey[600])),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.onSave({'name': _nameController.text, 'category': _selectedCategory, 'location': _locationController.text, 'rating': _ratingController.text, 'price': _priceController.text});
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5016), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    child: Text('Simpan', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF333333))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
            filled: true,
            fillColor: const Color(0xFFF5F5F0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (v) => v == null || v.isEmpty ? '$label tidak boleh kosong' : null,
        ),
      ],
    );
  }
}
