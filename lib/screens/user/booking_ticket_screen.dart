import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Tiket / bukti booking untuk ditampilkan setelah pembayaran atau dari riwayat.
class BookingTicketScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingTicketScreen({super.key, required this.booking});

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'confirmed':
        return 'Disetujui';
      case 'cancelled':
        return 'Dibatalkan';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return const Color(0xFF2196F3);
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    if (d == null) return '-';
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final dest = booking['destinations'] as Map<String, dynamic>? ?? {};
    final status = booking['status'] as String? ?? 'pending';
    final bookingId = booking['id'] as String? ?? '-';
    final ticketCode = bookingId.length > 8
        ? 'DK-${bookingId.substring(0, 8).toUpperCase()}'
        : 'DK-$bookingId';
    final user = FirebaseAuth.instance.currentUser;

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
          'Tiket Booking',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D5016), Color(0xFF6B9E45)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x20000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      children: [
                        Text(
                          'DesaKita',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabel(status),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              const Icon(Icons.confirmation_number_outlined,
                                  size: 40, color: Color(0xFF2D5016)),
                              const SizedBox(height: 8),
                              Text(
                                ticketCode,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2D5016),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                'Kode Tiket',
                                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 28),
                        _ticketRow(Icons.place_outlined, 'Destinasi',
                            dest['name'] as String? ?? 'Destinasi'),
                        _ticketRow(Icons.location_on_outlined, 'Lokasi',
                            dest['location'] as String? ?? '-'),
                        _ticketRow(Icons.calendar_today_outlined, 'Check-in',
                            _formatDate(booking['check_in'] as String?)),
                        _ticketRow(Icons.event_outlined, 'Check-out',
                            _formatDate(booking['check_out'] as String?)),
                        _ticketRow(Icons.people_outline, 'Tamu',
                            '${booking['guest_count']} orang'),
                        _ticketRow(Icons.payments_outlined, 'Total Bayar',
                            booking['total_price'] as String? ?? '-'),
                        if (user?.email != null)
                          _ticketRow(Icons.email_outlined, 'Email', user!.email!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Text(
                      'Simpan tiket ini. Status akan diperbarui setelah admin menyetujui booking.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.history_outlined, color: Color(0xFF2D5016)),
                label: Text(
                  'Kembali ke Riwayat',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D5016),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2D5016)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ticketRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2D5016)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
