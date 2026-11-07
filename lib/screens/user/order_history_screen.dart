import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:desa_wisata/services/booking_service.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';
import 'package:desa_wisata/widgets/destination_photo.dart';
import 'booking_ticket_screen.dart';

/// Layar khusus riwayat pesanan user (menu "Riwayat Pesanan" di Profil).
///
/// Menampilkan daftar booking milik user yang sedang login beserta status,
/// tanggal kunjungan, dan total pembayaran. Tiap kartu punya tombol
/// "Lihat Tiket" yang membuka [BookingTicketScreen].
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final BookingService _bookingService = BookingService();

  /// 'Semua' menampilkan seluruh pesanan, 'Selesai' menampilkan pesanan yang
  /// sudah rampung (status completed) atau tanggal kunjungannya sudah lewat.
  String _segment = 'Semua';
  final List<String> _segments = const ['Semua', 'Selesai'];

  List<Map<String, dynamic>> _applySegment(List<Map<String, dynamic>> list) {
    if (_segment == 'Semua') return list;
    return list.where(_isFinished).toList();
  }

  bool _isFinished(Map<String, dynamic> booking) {
    final status = (booking['status'] ?? '').toString().toLowerCase();
    if (status == 'completed') return true;
    final visit = DateTime.tryParse((booking['check_in'] ?? '').toString());
    if (visit == null) return false;
    final today = DateTime.now();
    return DateTime(
      visit.year,
      visit.month,
      visit.day,
    ).isBefore(DateTime(today.year, today.month, today.day));
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFB5730A);
      case 'confirmed':
        return DesaKitaColors.primary;
      case 'completed':
        return const Color(0xFF2196F3);
      case 'cancelled':
        return const Color(0xFFB42318);
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    if (d == null) return '-';
    return DateFormat('d MMMM yyyy', 'id_ID').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: DesaKitaColors.background,
      appBar: AppBar(
        backgroundColor: DesaKitaColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: DesaKitaColors.text,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Riwayat Pesanan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: DesaKitaColors.text,
          ),
        ),
      ),
      body: userId == null
          ? const _NotLoggedInView()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                  child: _SegmentedToggle(
                    segments: _segments,
                    selected: _segment,
                    onChanged: (value) => setState(() => _segment = value),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _bookingService.getUserBookings(userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: DesaKitaColors.primary,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return _MessageView(
                          icon: Icons.wifi_tethering_error_rounded,
                          message: 'Gagal memuat riwayat pesanan',
                        );
                      }

                      final filtered = _applySegment(snapshot.data ?? const []);
                      if (filtered.isEmpty) {
                        return const _MessageView(
                          icon: Icons.receipt_long_outlined,
                          message: 'Belum ada pesanan',
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final booking = filtered[index];
                          return _OrderCard(
                            booking: booking,
                            statusLabel: _statusLabel(
                              (booking['status'] ?? 'pending').toString(),
                            ),
                            statusColor: _statusColor(
                              (booking['status'] ?? 'pending').toString(),
                            ),
                            dateLabel: _formatDate(
                              booking['check_in'] as String?,
                            ),
                            onViewTicket: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BookingTicketScreen(booking: booking),
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
}

/// Kontrol segmented dua opsi ala mockup (aktif = hijau solid).
class _SegmentedToggle extends StatelessWidget {
  final List<String> segments;
  final String selected;
  final ValueChanged<String> onChanged;

  const _SegmentedToggle({
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DesaKitaColors.warmSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: segments.map((segment) {
          final isActive = segment == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(segment),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? DesaKitaColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    segment,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : DesaKitaColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Satu kartu pesanan sesuai mockup: thumbnail, kategori, nama, tanggal,
/// chip status, total pembayaran, dan tombol "Lihat Tiket".
class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final String statusLabel;
  final Color statusColor;
  final String dateLabel;
  final VoidCallback onViewTicket;

  const _OrderCard({
    required this.booking,
    required this.statusLabel,
    required this.statusColor,
    required this.dateLabel,
    required this.onViewTicket,
  });

  @override
  Widget build(BuildContext context) {
    final dest = booking['destinations'] as Map<String, dynamic>? ?? {};
    final name = dest['name'] as String? ?? 'Destinasi';
    final category = dest['category'] as String? ?? 'Destinasi';
    final imageUrl = dest['image_url'] as String?;
    final total = booking['total_price'] as String? ?? 'Rp 0';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesaKitaColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DestinationPhoto(
                imageUrl: imageUrl,
                fallbackAsset: 'assets/img/cs1.jpg',
                width: 64,
                height: 64,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: DesaKitaColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            dateLabel,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Pembayaran',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      total,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: DesaKitaColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: onViewTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesaKitaColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Lihat Tiket',
                    style: GoogleFonts.plusJakartaSans(
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
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String message;

  const _MessageView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotLoggedInView extends StatelessWidget {
  const _NotLoggedInView();

  @override
  Widget build(BuildContext context) {
    return const _MessageView(
      icon: Icons.lock_outline,
      message: 'Silakan login untuk melihat riwayat pesanan',
    );
  }
}
