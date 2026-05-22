import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_categories.dart';
import '../../services/destination_service.dart';
import '../../services/google_drive_service.dart';
import '../../widgets/app_network_image.dart';

class DestinationFormScreen extends StatefulWidget {
  final Map<String, dynamic>? destination;

  const DestinationFormScreen({super.key, this.destination});

  @override
  State<DestinationFormScreen> createState() => _DestinationFormScreenState();
}

class _DestinationFormScreenState extends State<DestinationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DestinationService _destinationService = DestinationService();
  final GoogleDriveService _googleDriveService = GoogleDriveService.instance;

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _ratingController;
  late final TextEditingController _priceController;
  late final TextEditingController _facilitiesController;
  late final TextEditingController _mapsUrlController;
  late final TextEditingController _contactController;
  late final TextEditingController _openingHoursController;
  late final TextEditingController _stockController;

  String _selectedCategory = 'Alam';
  final List<String> _categoryOptions = AppCategories.all;
  bool _bookable = false;

  XFile? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;
  bool _isConnectingGoogle = false;
  bool _googleDriveConnected = false;
  String? _googleEmail;

  @override
  void initState() {
    super.initState();
    _checkGoogleConnection();
    final dest = widget.destination;
    _nameController = TextEditingController(text: dest?['name'] ?? '');
    _locationController = TextEditingController(text: dest?['location'] ?? '');
    _descriptionController = TextEditingController(text: dest?['description'] ?? '');
    _ratingController = TextEditingController(text: dest?['rating']?.toString() ?? '4.0');
    _priceController = TextEditingController(text: dest?['price'] ?? '');
    _facilitiesController = TextEditingController(text: dest?['facilities'] ?? '');
    _mapsUrlController = TextEditingController(text: dest?['mapsUrl'] ?? '');
    _contactController = TextEditingController(text: dest?['contact'] ?? '');
    _openingHoursController = TextEditingController(text: dest?['openingHours'] ?? '');
    _stockController = TextEditingController(
      text: dest?['stock']?.toString() ?? '0',
    );
    _selectedCategory = AppCategories.normalize(dest?['category'] as String?) == ''
        ? 'Alam'
        : AppCategories.normalize(dest?['category'] as String?);
    _bookable = dest?['bookable'] as bool? ??
        (_selectedCategory == 'Penginapan');
    _existingImageUrl = dest?['image_url'];
  }

  Future<void> _checkGoogleConnection() async {
    final connected = await _googleDriveService.isSignedIn();
    if (mounted) {
      setState(() {
        _googleDriveConnected = connected;
        _googleEmail = _googleDriveService.signedInEmail;
      });
    }
  }

  Future<void> _connectGoogleDrive() async {
    setState(() => _isConnectingGoogle = true);
    try {
      await _googleDriveService.connectGoogleAccount();
      if (mounted) {
        setState(() {
          _googleDriveConnected = true;
          _googleEmail = _googleDriveService.signedInEmail;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Google Drive terhubung${_googleEmail != null ? ' ($_googleEmail)' : ''}',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: const Color(0xFF2D5016),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnectingGoogle = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _ratingController.dispose();
    _priceController.dispose();
    _facilitiesController.dispose();
    _mapsUrlController.dispose();
    _contactController.dispose();
    _openingHoursController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _googleDriveService.pickImageFromGallery();
      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveDestination() async {
    if (_selectedImage != null && !_googleDriveConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hubungkan Google Drive dulu sebelum upload foto',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: Colors.orange[800],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _existingImageUrl;

      // Upload gambar ke Google Drive jika ada gambar baru
      if (_selectedImage != null) {
        debugPrint('🔄 Mulai upload gambar ke Google Drive...');
        debugPrint('📄 File: ${_selectedImage!.name}');
        
        // Upload ke Google Drive dan dapatkan link
        imageUrl = await _googleDriveService.uploadToGoogleDrive(_selectedImage!);
        
        debugPrint('✅ Upload ke Google Drive berhasil!');
        debugPrint('🔗 Link: $imageUrl');
      } else {
        debugPrint('ℹ️ Tidak ada gambar baru untuk di-upload');
      }

      final name = _nameController.text.trim().isEmpty
          ? 'Destinasi Baru'
          : _nameController.text.trim();
      final rating = double.tryParse(_ratingController.text.trim()) ?? 0;
      final stock = int.tryParse(_stockController.text.trim()) ?? 0;
      final bookable = _bookable && AppCategories.isBookableCategory(_selectedCategory);

      final data = {
        'name': name,
        'category': _selectedCategory,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'rating': rating,
        'price': _priceController.text.trim(),
        'facilities': _facilitiesController.text.trim(),
        'mapsUrl': _mapsUrlController.text.trim(),
        'contact': _contactController.text.trim(),
        'openingHours': _openingHoursController.text.trim(),
        'imageUrl': imageUrl,
        'bookable': bookable,
        'stock': bookable ? stock : 0,
      };

      debugPrint('💾 Menyimpan data ke Firestore...');
      debugPrint('🖼️ Image URL: $imageUrl');

      if (widget.destination == null) {
        // Tambah baru
        await _destinationService.addDestination(
          name: data['name'] as String,
          category: data['category'] as String,
          location: data['location'] as String,
          rating: data['rating'] as double,
          price: data['price'] as String,
          description: data['description'] as String,
          imageUrl: imageUrl,
          facilities: data['facilities'] as String,
          mapsUrl: data['mapsUrl'] as String,
          contact: data['contact'] as String,
          openingHours: data['openingHours'] as String,
          bookable: data['bookable'] as bool,
          stock: data['stock'] as int,
        );
        debugPrint('✅ Destinasi baru berhasil ditambahkan');
      } else {
        // Update
        await _destinationService.updateDestination(
          id: widget.destination!['id'] as String,
          name: data['name'] as String,
          category: data['category'] as String,
          location: data['location'] as String,
          rating: data['rating'] as double,
          price: data['price'] as String,
          description: data['description'] as String,
          imageUrl: imageUrl,
          facilities: data['facilities'] as String,
          mapsUrl: data['mapsUrl'] as String,
          contact: data['contact'] as String,
          openingHours: data['openingHours'] as String,
          bookable: data['bookable'] as bool,
          stock: data['stock'] as int,
        );
        debugPrint('✅ Destinasi berhasil diperbarui');
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.destination == null ? 'Destinasi berhasil ditambahkan' : 'Destinasi berhasil diperbarui',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: const Color(0xFF2D5016),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error saat menyimpan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D5016)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.destination == null ? 'Tambah Destinasi' : 'Edit Destinasi',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upload Gambar
              _buildImagePicker(),
              const SizedBox(height: 12),
              _buildGoogleDriveConnect(),
              const SizedBox(height: 24),

              // Nama Destinasi
              _buildTextField(
                'Nama Destinasi',
                _nameController,
                Icons.place_outlined,
                'Masukkan nama destinasi (opsional)',
                required: false,
              ),
              const SizedBox(height: 16),

              // Kategori
              _buildCategorySelector(),
              const SizedBox(height: 16),
              _buildBookingOptions(),
              const SizedBox(height: 16),

              // Lokasi
              _buildTextField(
                'Lokasi',
                _locationController,
                Icons.location_on_outlined,
                'Contoh: Desa Pujon Kidul, Malang',
                required: false,
              ),
              const SizedBox(height: 16),

              // Deskripsi
              _buildTextArea(
                'Deskripsi',
                _descriptionController,
                'Jelaskan tentang destinasi ini...',
              ),
              const SizedBox(height: 16),

              // Rating & Harga
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Rating',
                      _ratingController,
                      Icons.star_outlined,
                      '0.0 - 5.0',
                      keyboardType: TextInputType.number,
                      required: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      'Harga',
                      _priceController,
                      Icons.attach_money_outlined,
                      'Rp 10.000',
                      required: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Fasilitas
              _buildTextField(
                'Fasilitas',
                _facilitiesController,
                Icons.local_parking_outlined,
                'Parkir, Toilet, Mushola, dll',
                required: false,
              ),
              const SizedBox(height: 16),

              // Jam Buka
              _buildTextField(
                'Jam Buka',
                _openingHoursController,
                Icons.access_time_outlined,
                '08:00 - 17:00',
                required: false,
              ),
              const SizedBox(height: 16),

              // Kontak
              _buildTextField(
                'Kontak',
                _contactController,
                Icons.phone_outlined,
                '+62 812-3456-7890',
                required: false,
              ),
              const SizedBox(height: 16),

              // Google Maps URL
              _buildTextField(
                'Link Google Maps',
                _mapsUrlController,
                Icons.map_outlined,
                'https://maps.google.com/...',
                required: false,
              ),
              const SizedBox(height: 32),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDestination,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5016),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Simpan Destinasi',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto Destinasi',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: kIsWeb
                        ? FutureBuilder<Uint8List>(
                            future: _selectedImage!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                );
                              }
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF2D5016),
                                ),
                              );
                            },
                          )
                        : Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                          ),
                  )
                : _existingImageUrl != null && _existingImageUrl!.isNotEmpty
                    ? AppNetworkImage(
                        imageUrl: _existingImageUrl,
                        width: double.infinity,
                        height: 200,
                        borderRadius: BorderRadius.circular(14),
                        placeholderLabel: 'Foto destinasi',
                      )
                    : _buildImagePlaceholder(),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildGoogleDriveConnect() {
    final connected = _googleDriveConnected;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: connected ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: connected ? Colors.green[300]! : Colors.orange[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                connected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                size: 20,
                color: connected ? Colors.green[800] : Colors.orange[800],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  connected
                      ? 'Google Drive terhubung${_googleEmail != null ? '\n$_googleEmail' : ''}'
                      : 'Hubungkan Google Drive untuk upload foto',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: connected ? Colors.green[900] : Colors.orange[900],
                  ),
                ),
              ),
            ],
          ),
          if (_selectedImage != null && !connected) ...[
            const SizedBox(height: 8),
            Text(
              'Wajib hubungkan Google Drive sebelum menyimpan dengan foto baru.',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.orange[900]),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isConnectingGoogle
                  ? null
                  : connected
                      ? _checkGoogleConnection
                      : _connectGoogleDrive,
              icon: _isConnectingGoogle
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(connected ? Icons.refresh : Icons.login, size: 18),
              label: Text(
                _isConnectingGoogle
                    ? 'Menghubungkan...'
                    : connected
                        ? 'Periksa koneksi'
                        : 'Hubungkan Google Drive',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2D5016),
                side: const BorderSide(color: Color(0xFF2D5016)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          'Pilih Foto',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap untuk memilih dari galeri',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categoryOptions.map((cat) {
            final isSelected = cat == _selectedCategory;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedCategory = cat;
                if (cat == 'Penginapan') _bookable = true;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2D5016) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2D5016) : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  cat,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBookingOptions() {
    final canBook = AppCategories.isBookableCategory(_selectedCategory);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Booking & Stok',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _bookable && canBook,
          onChanged: canBook
              ? (v) => setState(() => _bookable = v)
              : null,
          title: Text(
            'Bisa dibooking (Penginapan / Wisata Alam)',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          activeThumbColor: const Color(0xFF2D5016),
        ),
        if (!canBook)
          Text(
            'Kategori Kuliner/Edukasi tidak ditampilkan di menu booking.',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
          ),
        if (_bookable && canBook) ...[
          const SizedBox(height: 8),
          _buildTextField(
            'Stok tersedia',
            _stockController,
            Icons.inventory_2_outlined,
            'Contoh: 10',
            keyboardType: TextInputType.number,
            required: false,
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    TextInputType? keyboardType,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2D5016), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: required
              ? (v) => v == null || v.isEmpty ? '$label tidak boleh kosong' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildTextArea(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 5,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2D5016), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
