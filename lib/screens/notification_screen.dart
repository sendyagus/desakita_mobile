import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum NotificationType { update, promo, booking, system }

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime date;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.date,
    this.isRead = false,
  });
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Simulasi data notifikasi, termasuk update aplikasi
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'Pembaruan Aplikasi v1.2.0 Tersedia! 🚀',
      body:
          'Kami telah merilis versi terbaru! Update kali ini menghadirkan asisten AI yang lebih pintar, perbaikan bug di halaman Booking, serta peningkatan kecepatan aplikasi hingga 40%. Yuk update sekarang!',
      type: NotificationType.update,
      date: DateTime.now().subtract(const Duration(minutes: 30)),
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      title: 'Diskon Spesial 25% Tiket Wisata Alam! 🍃',
      body:
          'Dapatkan potongan harga khusus untuk pemesanan tiket wisata alam di desa terpilih sepanjang minggu ini. Masukkan kode promo: ALAMINDONESIA saat checkout.',
      type: NotificationType.promo,
      date: DateTime.now().subtract(const Duration(hours: 4)),
      isRead: false,
    ),
    NotificationItem(
      id: '3',
      title: 'Booking Berhasil Dikonfirmasi! ✅',
      body:
          'Selamat! Pemesanan tiket Anda untuk paket "Eksplorasi Desa Pelangi" pada tanggal 25 Mei 2026 telah disetujui oleh admin. Silakan cek detail e-ticket di halaman Booking.',
      type: NotificationType.booking,
      date: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    NotificationItem(
      id: '4',
      title: 'Fitur Baru: DesaKita AI Agent 🤖',
      body:
          'Kini Anda bisa berkonsultasi langsung mengenai rekomendasi wisata, kuliner terbaik, serta rute perjalanan terdekat melalui AI Agent interaktif baru di tab tengah.',
      type: NotificationType.update,
      date: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
    NotificationItem(
      id: '5',
      title: 'Pemberitahuan Sistem ⚙️',
      body:
          'Akan dilakukan pemeliharaan server berkala pada hari Minggu pukul 01:00 - 03:00 WIB. Aplikasi mungkin tidak dapat diakses untuk sementara waktu selama proses ini.',
      type: NotificationType.system,
      date: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (var item in _notifications) {
        item.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Semua notifikasi ditandai sebagai dibaca',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2D5016),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _toggleReadStatus(int index) {
    setState(() {
      _notifications[index].isRead = !_notifications[index].isRead;
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((item) => item.id == id);
    });
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.update:
        return const Color(0xFF0F75EC); // Biru untuk update
      case NotificationType.promo:
        return const Color(0xFFE8A020); // Amber untuk promo
      case NotificationType.booking:
        return const Color(0xFF2D5016); // Hijau untuk booking
      case NotificationType.system:
        return const Color(0xFFD32F2F); // Merah untuk system
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.update:
        return Icons.system_update_alt_rounded;
      case NotificationType.promo:
        return Icons.local_offer_outlined;
      case NotificationType.booking:
        return Icons.confirmation_number_outlined;
      case NotificationType.system:
        return Icons.error_outline_rounded;
    }
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.update:
        return 'Update Aplikasi';
      case NotificationType.promo:
        return 'Promo & Penawaran';
      case NotificationType.booking:
        return 'Booking & Aktivitas';
      case NotificationType.system:
        return 'Sistem';
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF2D5016),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifikasi',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Baca Semua',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2D5016),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D5016).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$unreadCount Belum Dibaca',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF2D5016),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Geser kartu untuk menghapus',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          final title = item.title;
                          _deleteNotification(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Notifikasi dihapus',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                              action: SnackBarAction(
                                label: 'Urungkan',
                                textColor: Colors.white,
                                onPressed: () {
                                  setState(() {
                                    _notifications.insert(index, item);
                                  });
                                },
                              ),
                              backgroundColor: Colors.grey[800],
                              duration: const Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          margin: const EdgeInsets.only(bottom: 12.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.delete_sweep_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () => _toggleReadStatus(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 12.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: item.isRead
                                  ? Colors.white
                                  : const Color(0xFFF1F6EC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: item.isRead
                                    ? Colors.grey.withOpacity(0.08)
                                    : const Color(0xFF2D5016).withOpacity(0.12),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: item.isRead
                                      ? Colors.black.withOpacity(0.02)
                                      : const Color(
                                          0xFF2D5016,
                                        ).withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon Type Badge
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(
                                      item.type,
                                    ).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getTypeIcon(item.type),
                                    color: _getTypeColor(item.type),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Text Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getTypeColor(
                                                item.type,
                                              ).withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _getTypeLabel(item.type),
                                              style: GoogleFonts.poppins(
                                                color: _getTypeColor(item.type),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 9,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _formatTime(item.date),
                                            style: GoogleFonts.poppins(
                                              color: Colors.grey[500],
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.title,
                                        style: GoogleFonts.poppins(
                                          fontWeight: item.isRead
                                              ? FontWeight.w600
                                              : FontWeight.w700,
                                          fontSize: 13.5,
                                          color: const Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.body,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          color: Colors.grey[700],
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!item.isRead) ...[
                                  const SizedBox(width: 8),
                                  // Unread green dot
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(top: 24),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2D5016),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EDE3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 60,
                color: Color(0xFF2D5016),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum ada notifikasi',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: const Color(0xFF2D5016),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Semua update aplikasi, info penawaran wisata, dan status pesanan Anda akan muncul di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
