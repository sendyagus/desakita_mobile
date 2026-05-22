import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/booking_service.dart';
import 'booking_ticket_screen.dart';

class UserBookingHistoryScreen extends StatefulWidget {
  const UserBookingHistoryScreen({super.key});

  @override
  State<UserBookingHistoryScreen> createState() => _UserBookingHistoryScreenState();
}

class _UserBookingHistoryScreenState extends State<UserBookingHistoryScreen> {
  final BookingService _bookingService = BookingService();
  String _filter = 'Semua';
  final _filters = ['Semua', 'Menunggu', 'Disetujui', 'Dibatalkan', 'Selesai'];

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> list) {
    switch (_filter) {
      case 'Menunggu':
        return list.where((b) => b['status'] == 'pending').toList();
      case 'Disetujui':
        return list.where((b) => b['status'] == 'confirmed').toList();
      case 'Dibatalkan':
        return list.where((b) => b['status'] == 'cancelled').toList();
      case 'Selesai':
        return list.where((b) => b['status'] == 'completed').toList();
      default:
        return list;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
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
    return DateFormat('dd MMM yyyy', 'id_ID').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

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
          'Riwayat Booking',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: userId == null
          ? _buildNotLoggedIn()
          : Column(
              children: [
                _buildFilterChips(),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _bookingService.getUserBookings(userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF2D5016)),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Gagal memuat riwayat',
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                          ),
                        );
                      }

                      final filtered = _applyFilter(snapshot.data ?? []);
                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 56, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada riwayat booking',
                                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final b = filtered[index];
                          final dest = b['destinations'] as Map<String, dynamic>? ?? {};
                          final status = b['status'] as String? ?? 'pending';
                          return _BookingHistoryCard(
                            destName: dest['name'] as String? ?? 'Destinasi',
                            statusLabel: _statusLabel(status),
                            statusColor: _statusColor(status),
                            dateRange:
                                '${_formatDate(b['check_in'] as String?)} — ${_formatDate(b['check_out'] as String?)}',
                            guestPrice:
                                '${b['guest_count']} tamu • ${b['total_price']}',
                            onViewTicket: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingTicketScreen(booking: b),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Text(
        'Silakan login untuk melihat riwayat',
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final f = _filters[index];
          final selected = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f, style: GoogleFonts.poppins(fontSize: 12)),
              selected: selected,
              onSelected: (_) => setState(() => _filter = f),
              selectedColor: const Color(0xFF2D5016),
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.grey[700],
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              checkmarkColor: Colors.white,
              backgroundColor: const Color(0xFFE8EDE3),
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }
}

class _BookingHistoryCard extends StatelessWidget {
  final String destName;
  final String statusLabel;
  final Color statusColor;
  final String dateRange;
  final String guestPrice;
  final VoidCallback onViewTicket;

  const _BookingHistoryCard({
    required this.destName,
    required this.statusLabel,
    required this.statusColor,
    required this.dateRange,
    required this.guestPrice,
    required this.onViewTicket,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onViewTicket,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    destName,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dateRange,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              guestPrice,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: onViewTicket,
                icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                label: Text(
                  'Lihat Tiket Booking',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D5016),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2D5016)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
