import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _selectedTabIndex = 0;

  final List<String> _tabs = ['Semua', 'Penginapan', 'Wisata', 'Kuliner'];

  final List<Map<String, dynamic>> _services = [
    {
      'name': 'Jukung Villa Lampung',
      'description': 'Nikmati pemandangan perbukitan yang memukau.',
      'category': 'Penginapan',
      'categoryIcon': Icons.bed_outlined,
      'price': 'Rp 450.000',
      'priceUnit': '/ malam',
      'rating': 4.8,
      'isMultiPhoto': false,
    },
    {
      'name': 'Lembah Durian Farm Stable',
      'description': 'Pengalaman menginap yang menyatu dengan alam.',
      'category': 'Penginapan & Glamping',
      'categoryIcon': Icons.bed_outlined,
      'price': 'Rp 350.000',
      'priceUnit': '/ malam',
      'rating': 4.6,
      'isMultiPhoto': true,
    },
    {
      'name': 'Homestay Desa Pujon',
      'description': 'Rasakan kehidupan desa yang autentik dan nyaman.',
      'category': 'Penginapan',
      'categoryIcon': Icons.bed_outlined,
      'price': 'Rp 200.000',
      'priceUnit': '/ malam',
      'rating': 4.4,
      'isMultiPhoto': false,
    },
    {
      'name': 'Wisata Kebun Teh Kemuning',
      'description': 'Jelajahi hamparan kebun teh yang hijau dan segar.',
      'category': 'Wisata',
      'categoryIcon': Icons.landscape_outlined,
      'price': 'Rp 75.000',
      'priceUnit': '/ orang',
      'rating': 4.7,
      'isMultiPhoto': false,
    },
    {
      'name': 'Paket Kuliner Desa Sade',
      'description': 'Cicipi cita rasa masakan tradisional Lombok.',
      'category': 'Kuliner',
      'categoryIcon': Icons.restaurant_outlined,
      'price': 'Rp 120.000',
      'priceUnit': '/ paket',
      'rating': 4.5,
      'isMultiPhoto': true,
    },
  ];

  List<Map<String, dynamic>> get _filteredServices {
    final selected = _tabs[_selectedTabIndex];
    if (selected == 'Semua') return _services;
    return _services
        .where((s) => (s['category'] as String).contains(selected))
        .toList();
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

            // Daftar layanan
            Expanded(
              child: _buildServiceList(),
            ),
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
          // Ikon headset
          Container(
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
    final services = _filteredServices;

    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Belum ada layanan tersedia',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final item = services[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _ServiceCard(
            name: item['name'] as String,
            description: item['description'] as String,
            category: item['category'] as String,
            categoryIcon: item['categoryIcon'] as IconData,
            price: item['price'] as String,
            priceUnit: item['priceUnit'] as String,
            rating: item['rating'] as double,
            isMultiPhoto: item['isMultiPhoto'] as bool,
            onTap: () => _showBookingSheet(context, item),
          ),
        );
      },
    );
  }

  // ─── Booking Bottom Sheet ──────────────────────────────────────────────────

  void _showBookingSheet(
      BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _BookingSheet(item: item),
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
  final bool isMultiPhoto;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.name,
    required this.description,
    required this.category,
    required this.categoryIcon,
    required this.price,
    required this.priceUnit,
    required this.rating,
    required this.isMultiPhoto,
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
                child: isMultiPhoto
                    ? _MultiPhotoWireframe(name: name)
                    : _WireframeImage(label: name, height: 200),
              ),

              // Badge kategori kanan atas
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(categoryIcon,
                          size: 13, color: const Color(0xFF2D5016)),
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
                          'Cek Ketersediaan',
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

// ─── Booking Bottom Sheet ─────────────────────────────────────────────────────

class _BookingSheet extends StatefulWidget {
  final Map<String, dynamic> item;

  const _BookingSheet({required this.item});

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _guestCount = 1;

  Future<void> _pickDate(bool isCheckIn) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2D5016),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (_checkOut != null && _checkOut!.isBefore(picked)) {
            _checkOut = null;
          }
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Pilih tanggal';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
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

              // Judul
              Text(
                widget.item['name'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      size: 14, color: Color(0xFFE8A020)),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.item['rating']}  •  ${widget.item['category']}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 20),

              // Check-in & Check-out
              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: 'Check-in',
                      value: _formatDate(_checkIn),
                      onTap: () => _pickDate(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePickerField(
                      label: 'Check-out',
                      value: _formatDate(_checkOut),
                      onTap: () => _pickDate(false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Jumlah tamu
              Text(
                'Jumlah Tamu',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$_guestCount Tamu',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                    // Kurang
                    IconButton(
                      onPressed: _guestCount > 1
                          ? () => setState(() => _guestCount--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: const Color(0xFF2D5016),
                      iconSize: 22,
                    ),
                    // Tambah
                    IconButton(
                      onPressed: _guestCount < 20
                          ? () => setState(() => _guestCount++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: const Color(0xFF2D5016),
                      iconSize: 22,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Ringkasan harga
              if (_checkIn != null && _checkOut != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2E8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total estimasi',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        widget.item['price'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D5016),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Tombol Pesan
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Pemesanan ${widget.item['name']} berhasil dikirim!',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        backgroundColor: const Color(0xFF2D5016),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5016),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Pesan Sekarang',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Date Picker Field ────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 15, color: Color(0xFF2D5016)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: value == 'Pilih tanggal'
                          ? Colors.grey[400]
                          : const Color(0xFF1A1A1A),
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

// ─── Multi Photo Wireframe ────────────────────────────────────────────────────

class _MultiPhotoWireframe extends StatelessWidget {
  final String name;

  const _MultiPhotoWireframe({required this.name});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          // Foto besar kiri
          Expanded(
            flex: 2,
            child: _WireframeImage(label: name, height: 200),
          ),
          const SizedBox(width: 2),
          // Dua foto kecil kanan
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: _WireframeImage(label: '', height: 99),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: _WireframeImage(label: '', height: 99),
                ),
              ],
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

  const _WireframeImage({
    required this.label,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      color: const Color(0xFFD8DDD0),
      child: Stack(
        children: [
          CustomPaint(
            size: Size(double.infinity, height),
            painter: _WireframePainter(),
          ),
          if (label.isNotEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined,
                      size: 28, color: Colors.grey[500]),
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
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
