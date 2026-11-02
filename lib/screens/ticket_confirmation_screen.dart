import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';
import 'package:desa_wisata/widgets/destination_photo.dart';

class TicketConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> booking;
  final Map<String, dynamic> destination;

  const TicketConfirmationScreen({
    super.key,
    required this.booking,
    required this.destination,
  });

  String _value(dynamic value, {String fallback = '-'}) {
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    final displayDestination = <String, dynamic>{
      ...destination,
      'imageUrl': destination['imageUrl'] ?? destination['image_url'],
    };
    final destinationName = _value(destination['name']);
    final bookingId = _value(booking['id']);
    final shortenedCode = bookingId.length > 12
        ? bookingId.substring(0, 12).toUpperCase()
        : bookingId.toUpperCase();
    final total = _value(booking['total_price'] ?? booking['totalPrice']);
    final guestCount = _value(
      booking['guest_count'] ?? booking['guestCount'],
      fallback: '1',
    );
    final date = _date(booking['check_in'] ?? booking['checkIn']);
    final paymentStatus = _value(
      booking['payment_status'] ?? booking['paymentStatus'],
      fallback: 'awaiting_payment',
    );

    return Scaffold(
      backgroundColor: DesaKitaColors.background,
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x09000000),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: DesaKitaColors.mutedGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 34,
                    color: DesaKitaColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pesanan berhasil dibuat',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: DesaKitaColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pesanan tersimpan dan menunggu pembayaran. Tiket belum aktif.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    height: 1.5,
                    color: DesaKitaColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                DestinationPhoto(
                  imageUrl: displayDestination['imageUrl']?.toString(),
                  fallbackAsset: 'assets/img/cs1.jpg',
                  height: 150,
                  width: double.infinity,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    destinationName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: DesaKitaColors.text,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _value(destination['location']),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: DesaKitaColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'KODE REFERENSI PESANAN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w800,
                          color: DesaKitaColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 7),
                      SelectableText(
                        shortenedCode,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                          color: DesaKitaColors.darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _detailRow('Tanggal kunjungan', date),
                _detailRow('Jumlah pengunjung', '$guestCount orang'),
                _detailRow(
                  'Metode pembayaran',
                  _value(booking['payment_method'] ?? booking['paymentMethod']),
                ),
                _detailRow('Total pesanan', total, emphasized: true),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2CC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      paymentStatus == 'awaiting_payment'
                          ? 'Menunggu pembayaran'
                          : paymentStatus,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF8A5B00),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DesaKitaColors.divider),
            ),
            child: Text(
              'Kode ini adalah referensi pesanan, bukan QR tiket masuk. Integrasi gerbang pembayaran dan penerbitan QR perlu ditambahkan sebelum digunakan untuk kunjungan nyata.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                height: 1.55,
                color: DesaKitaColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Kembali ke aplikasi'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool emphasized = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: DesaKitaColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(
                fontSize: emphasized ? 13 : 11,
                fontWeight: FontWeight.w800,
                color: emphasized
                    ? DesaKitaColors.primary
                    : DesaKitaColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
