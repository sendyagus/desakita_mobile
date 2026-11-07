import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';

/// Satu item notifikasi (data demo lokal; belum terhubung ke backend).
class _NotificationItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String time;
  final bool unread;

  const _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
    this.unread = false,
  });
}

/// Layar Notifikasi — dikelompokkan per "Hari Ini" dan "Minggu Ini".
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late List<_NotificationItem> _today = const [
    _NotificationItem(
      icon: Icons.local_activity_outlined,
      iconColor: DesaKitaColors.primary,
      title: 'Trip terbaru',
      body:
          'Perbarui itinerary baru anda cek sekarang untuk memulai perjalanan yang menyenangkan',
      time: '1 menit yang lalu',
      unread: true,
    ),
    _NotificationItem(
      icon: Icons.verified_outlined,
      iconColor: DesaKitaColors.primary,
      title: 'Pesanan Tiket Dikonfirmasi',
      body:
          'Pesanan Tiket Anda untuk \'Bukit sakura dan puncak mas\' pada 10 July telah...',
      time: '1 menit yang lalu',
      unread: true,
    ),
  ];

  late List<_NotificationItem> _thisWeek = const [
    _NotificationItem(
      icon: Icons.redeem_outlined,
      iconColor: Color(0xFF8A5B00),
      title: 'Promo Spesial Liburan!',
      body:
          'Dapatkan diskon 20% untuk semua paket wisata alam khusus minggu ini...',
      time: '1 hari yang lalu',
      unread: true,
    ),
    _NotificationItem(
      icon: Icons.star_border_rounded,
      iconColor: Color(0xFF6B7280),
      title: 'Beri Nilai Perjalanan Anda',
      body: 'Bagaimana pengalaman Anda berkunjung di lembah bikp? Bagikan...',
      time: '2 hari yang lalu',
    ),
  ];

  int get _newCount =>
      _today.where((n) => n.unread).length +
      _thisWeek.where((n) => n.unread).length;

  void _markAllRead() {
    setState(() {
      _today = _today.map((n) => _copy(n, unread: false)).toList();
      _thisWeek = _thisWeek.map((n) => _copy(n, unread: false)).toList();
    });
  }

  _NotificationItem _copy(_NotificationItem n, {required bool unread}) {
    return _NotificationItem(
      icon: n.icon,
      iconColor: n.iconColor,
      title: n.title,
      body: n.body,
      time: n.time,
      unread: unread,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesaKitaColors.background,
      appBar: AppBar(
        backgroundColor: DesaKitaColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: DesaKitaColors.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifikasi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: DesaKitaColors.text,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _newCount == 0
                      ? 'Tidak ada notifikasi baru'
                      : 'Anda memiliki $_newCount notifikasi baru',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              TextButton(
                onPressed: _newCount == 0 ? null : _markAllRead,
                style: TextButton.styleFrom(
                  backgroundColor: DesaKitaColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Tandai semua',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionLabel(label: 'Hari Ini'),
          ..._today.map((n) => _NotificationCard(item: n)),
          const SizedBox(height: 8),
          _SectionLabel(label: 'Minggu Ini'),
          ..._thisWeek.map((n) => _NotificationCard(item: n)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 10),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: DesaKitaColors.text,
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _NotificationItem item;
  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesaKitaColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DesaKitaColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.time,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (item.unread)
            Container(
              margin: const EdgeInsets.only(top: 4, left: 6),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: DesaKitaColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}
