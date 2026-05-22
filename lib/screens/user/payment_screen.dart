import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/booking_service.dart';
import 'booking_ticket_screen.dart';

/// Tampilan pembayaran DesaKita (UI simulasi, tanpa integrasi nyata).
class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> destination;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestCount;
  final String totalPrice;

  const PaymentScreen({
    super.key,
    required this.destination,
    required this.checkIn,
    required this.checkOut,
    required this.guestCount,
    required this.totalPrice,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final BookingService _bookingService = BookingService();
  int _selectedMethod = 0;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _methods = [
    {'id': 'gopay', 'label': 'GoPay', 'icon': Icons.account_balance_wallet_outlined, 'color': Color(0xFF00AA5B)},
    {'id': 'shopeepay', 'label': 'ShopeePay', 'icon': Icons.shopping_bag_outlined, 'color': Color(0xFFEE4D2D)},
    {'id': 'bank', 'label': 'Transfer Bank', 'icon': Icons.account_balance_outlined, 'color': Color(0xFF1A73E8)},
    {'id': 'card', 'label': 'Kartu Kredit/Debit', 'icon': Icons.credit_card_outlined, 'color': Color(0xFF5C6BC0)},
    {'id': 'qris', 'label': 'QRIS', 'icon': Icons.qr_code_2_outlined, 'color': Color(0xFF212121)},
  ];

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User tidak terautentikasi');

      final booking = await _bookingService.createBooking(
        destinationId: widget.destination['id'] as String,
        userId: userId,
        checkIn: widget.checkIn,
        checkOut: widget.checkOut,
        guestCount: widget.guestCount,
        totalPrice: widget.totalPrice,
      );

      if (!mounted) return;
      final goToTicket = await _showSuccessDialog();
      if (!mounted) return;

      Navigator.pop(context, true);
      Navigator.pop(context, true);

      if (goToTicket == true && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingTicketScreen(booking: booking),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pembayaran gagal: $e', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<bool?> _showSuccessDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8F5E9),
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'Pembayaran Berhasil',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Tiket booking tersimpan.\nCek kapan saja di menu Riwayat Booking.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.confirmation_number_outlined, size: 20),
                  label: Text(
                    'Lihat Tiket Booking',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5016),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Nanti Saja',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destName = widget.destination['name'] as String? ?? 'Destinasi';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildPaymentHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderCard(destName),
                  const SizedBox(height: 20),
                  Text(
                    'Pilih Metode Pembayaran',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_methods.length, (i) {
                    final m = _methods[i];
                    final selected = _selectedMethod == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => setState(() => _selectedMethod = i),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF2D5016)
                                  : Colors.grey[300]!,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: (m['color'] as Color).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  m['icon'] as IconData,
                                  color: m['color'] as Color,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  m['label'] as String,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: selected
                                    ? const Color(0xFF2D5016)
                                    : Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: Color(0xFFF57C00)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ini hanya simulasi tampilan pembayaran. Tidak ada transaksi nyata.',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[800]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildPayButton(),
        ],
      ),
    );
  }

  Widget _buildPaymentHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D5016), Color(0xFF6B9E45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DesaKita',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Pembayaran Aman & Terpercaya',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(String destName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Pesanan',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          const Divider(height: 20),
          _orderRow('Destinasi', destName),
          const SizedBox(height: 8),
          _orderRow('Tamu', '${widget.guestCount} orang'),
          const SizedBox(height: 8),
          _orderRow('Metode', _methods[_selectedMethod]['label'] as String),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Bayar',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                widget.totalPrice,
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

  Widget _orderRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x15000000), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5016),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Bayar Sekarang',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }
}
