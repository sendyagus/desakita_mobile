import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'payment_screen.dart';

class CreateBookingScreen extends StatefulWidget {
  final Map<String, dynamic> destination;

  const CreateBookingScreen({super.key, required this.destination});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _guestCount = 1;

  String get _destinationName => widget.destination['name'] as String? ?? '';
  String get _destinationLocation => widget.destination['location'] as String? ?? '';
  String get _destinationPrice => widget.destination['price'] as String? ?? 'Rp 0';

  int get _numberOfDays {
    if (_checkInDate == null || _checkOutDate == null) return 0;
    return _checkOutDate!.difference(_checkInDate!).inDays;
  }

  double get _pricePerDay {
    final priceStr = _destinationPrice.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(priceStr) ?? 0;
  }

  double get _totalPrice {
    if (_numberOfDays <= 0) return 0;
    return _pricePerDay * _numberOfDays * _guestCount;
  }

  String get _formattedTotalPrice {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(_totalPrice);
  }

  Future<void> _selectCheckInDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2D5016),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _checkInDate = picked;
        // Reset check-out if it's before check-in
        if (_checkOutDate != null && _checkOutDate!.isBefore(picked)) {
          _checkOutDate = null;
        }
      });
    }
  }

  Future<void> _selectCheckOutDate() async {
    if (_checkInDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pilih tanggal check-in terlebih dahulu', style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: Colors.orange[800],
        ),
      );
      return;
    }

    final minDate = _checkInDate!.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate ?? minDate,
      firstDate: minDate,
      lastDate: _checkInDate!.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2D5016),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _checkOutDate = picked);
    }
  }

  Future<void> _goToPayment() async {
    if (_checkInDate == null || _checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pilih tanggal check-in dan check-out', style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login dulu untuk melanjutkan pembayaran', style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: Colors.orange[800],
        ),
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          destination: widget.destination,
          checkIn: _checkInDate!,
          checkOut: _checkOutDate!,
          guestCount: _guestCount,
          totalPrice: _formattedTotalPrice,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
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
          'Buat Booking',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Destination Info
                    _buildDestinationInfo(),
                    const SizedBox(height: 24),

                    // Check-in Date
                    _buildDateSelector(
                      label: 'Tanggal Check-in',
                      date: _checkInDate,
                      onTap: _selectCheckInDate,
                    ),
                    const SizedBox(height: 16),

                    // Check-out Date
                    _buildDateSelector(
                      label: 'Tanggal Check-out',
                      date: _checkOutDate,
                      onTap: _selectCheckOutDate,
                    ),
                    const SizedBox(height: 16),

                    // Guest Count
                    _buildGuestCounter(),
                    const SizedBox(height: 24),

                    // Price Summary
                    _buildPriceSummary(),
                  ],
                ),
              ),
            ),

            // Bottom Button
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            _destinationName,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _destinationLocation,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$_destinationPrice / hari',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D5016),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
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
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  date != null ? DateFormat('dd MMMM yyyy', 'id_ID').format(date) : 'Pilih tanggal',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: date != null ? const Color(0xFF1A1A1A) : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestCounter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jumlah Tamu',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.people_outline, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$_guestCount orang',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
              IconButton(
                onPressed: _guestCount > 1 ? () => setState(() => _guestCount--) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: const Color(0xFF2D5016),
              ),
              Text(
                '$_guestCount',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _guestCount++),
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFF2D5016),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D5016).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Harga',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          _buildPriceRow('Harga per hari', _destinationPrice),
          const SizedBox(height: 8),
          _buildPriceRow('Jumlah hari', '$_numberOfDays hari'),
          const SizedBox(height: 8),
          _buildPriceRow('Jumlah tamu', '$_guestCount orang'),
          const Divider(height: 24, color: Color(0xFF2D5016)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Text(
                _formattedTotalPrice,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D5016),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _goToPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5016),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Lanjut ke Pembayaran',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
