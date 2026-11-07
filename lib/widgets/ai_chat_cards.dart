import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desa_wisata/models/ai_chat_models.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';
import 'package:desa_wisata/widgets/destination_photo.dart';

/// Widget kartu kaya yang menyertai balasan KITA AI di dalam chat:
/// rekomendasi destinasi, pilihan budget, dan itinerary.

/// Rupiah tanpa spasi, mis. 315000 -> "Rp315.000" (mengikuti desain).
String aiRupiahCompact(int value) {
  final digits = value.toString();
  final buffer = StringBuffer('Rp');
  for (var i = 0; i < digits.length; i++) {
    buffer.write(digits[i]);
    final remaining = digits.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
  }
  return buffer.toString();
}

/// Kartu rekomendasi destinasi, ditumpuk vertikal di bawah bubble bot.
class AiDestinationCards extends StatelessWidget {
  final List<Map<String, dynamic>> places;
  final ValueChanged<Map<String, dynamic>> onPlan;
  final ValueChanged<Map<String, dynamic>> onBook;

  const AiDestinationCards({
    super.key,
    required this.places,
    required this.onPlan,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final place in places)
          Padding(padding: const EdgeInsets.only(top: 10), child: _card(place)),
      ],
    );
  }

  Widget _card(Map<String, dynamic> place) {
    final rating = (place['rating'] as num?)?.toDouble() ?? 0;
    final location = (place['location'] ?? '').toString();
    final name = (place['name'] ?? 'Destinasi').toString();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesaKitaColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              DestinationPhoto(
                imageUrl: (place['imageUrl'] ?? place['image_url'] ?? '')
                    .toString(),
                width: double.infinity,
                height: 132,
                borderRadius: BorderRadius.zero,
              ),
              if (rating > 0)
                Positioned(top: 8, left: 8, child: _ratingBadge(rating)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: DesaKitaColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 13,
                      color: DesaKitaColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        location.isEmpty ? 'Lokasi belum tersedia' : location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: DesaKitaColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _pillButton(
                        label: 'Tambahkan ke Rencana',
                        background: DesaKitaColors.primary,
                        onTap: () => onPlan(place),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _pillButton(
                        label: 'Pesan Tiket',
                        background: DesaKitaColors.darkGreen,
                        onTap: () => onBook(place),
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

  Widget _ratingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 12, color: DesaKitaColors.amber),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: DesaKitaColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillButton({
    required String label,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip pilihan rentang budget.
class AiBudgetChips extends StatelessWidget {
  final List<String> options;
  final ValueChanged<String> onSelect;

  const AiBudgetChips({
    super.key,
    required this.options,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in options)
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelect(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DesaKitaColors.borderMuted),
                  ),
                  child: Text(
                    option,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: DesaKitaColors.text,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kartu itinerary: header foto + linimasa kegiatan + estimasi biaya.
class AiItineraryCard extends StatelessWidget {
  final AiItinerary itinerary;
  final VoidCallback onBook;
  final VoidCallback onLater;

  const AiItineraryCard({
    super.key,
    required this.itinerary,
    required this.onBook,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DesaKitaColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              DestinationPhoto(
                imageUrl: itinerary.imageUrl,
                width: double.infinity,
                height: 124,
                borderRadius: BorderRadius.zero,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black26,
                        Colors.black.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Text(
                  itinerary.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            child: Column(
              children: [
                for (final stop in itinerary.stops) _stopRow(stop),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DesaKitaColors.surfaceGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimasi Biaya Perjalanan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: DesaKitaColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${aiRupiahCompact(itinerary.costPerPerson)} /orang',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: DesaKitaColors.darkGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: onLater,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DesaKitaColors.darkGreen,
                          side: const BorderSide(color: DesaKitaColors.divider),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          minimumSize: const Size(0, 38),
                        ),
                        child: const Text(
                          'Nanti',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: onBook,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesaKitaColors.buttonGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          minimumSize: const Size(0, 38),
                        ),
                        child: const Text(
                          'Pesan Tiket',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stopRow(AiItineraryStop stop) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Text(
              stop.time,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: DesaKitaColors.darkGreen,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: VerticalDivider(
              width: 1,
              thickness: 1,
              color: DesaKitaColors.divider,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                stop.activity,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  height: 1.45,
                  color: DesaKitaColors.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
