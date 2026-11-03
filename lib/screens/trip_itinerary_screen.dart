import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:desa_wisata/config/app_config.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';

/// Layar demo "Susunan Perjalanan" (itinerary) — murni tampilan,
/// tanpa fungsi Edit/Hapus/Lihat yang sebenarnya.
class TripItineraryScreen extends StatelessWidget {
  const TripItineraryScreen({super.key});

  // Titik rute demo: Rumah -> Bukit Sakura -> Puncak Mas (Kemiling).
  static const _route = <LatLng>[
    LatLng(-5.4290, 105.2530),
    LatLng(-5.4210, 105.2430),
    LatLng(-5.4150, 105.2330),
    LatLng(-5.4100, 105.2260),
    LatLng(-5.4043, 105.2202),
    LatLng(-5.4120, 105.2190),
    LatLng(-5.4206, 105.2225),
  ];

  static const _bukitSakura = LatLng(-5.4043, 105.2202);
  static const _puncakMas = LatLng(-5.4206, 105.2225);

  static const _items = <_ItineraryItem>[
    _ItineraryItem(
      time: '08:00',
      title: '08:00 - Berangkat dari Rumah',
      subtitle: 'Factual location',
      actions: [_ItemAction.edit, _ItemAction.hapus],
    ),
    _ItineraryItem(
      time: '08:20',
      title: '08:20 - Terdapat Umkm di Sekitar sini',
      subtitle: 'Factual location',
      actions: [_ItemAction.lihat],
    ),
    _ItineraryItem(
      time: '09:00',
      title: '09:00 - Sampai ke Bukit Sakura',
      subtitle: 'Factual location',
      rating: 4.8,
      thumbnail: 'assets/img/desakita.jpg',
      actions: [_ItemAction.edit, _ItemAction.hapus],
    ),
    _ItineraryItem(
      time: '12:00',
      title: '12:00 - Makan Siang',
      subtitle: 'Factual location',
      actions: [_ItemAction.edit, _ItemAction.hapus],
    ),
    _ItineraryItem(
      time: '14:00',
      title: '14:00 - Sore di Puncak Mas',
      subtitle: 'Factual location',
      rating: 4.9,
      thumbnail: 'assets/img/banner1.png',
      actions: [_ItemAction.edit, _ItemAction.hapus],
    ),
    _ItineraryItem(
      time: '17:00',
      title: '17:00 - Kembali ke Rumah',
      subtitle: 'Factual location',
      actions: [_ItemAction.lihat],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER =====
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Susunan Perjalanan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: DesaKitaColors.text,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ===== PETA RUTE =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 210,
                  child: Stack(
                    children: [
                      _RouteMap(),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Row(
                          children: [
                            _MapCircleButton(icon: Icons.navigation_outlined),
                            const SizedBox(width: 8),
                            _MapCircleButton(icon: Icons.my_location),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ===== STATISTIK PERJALANAN =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFBF8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: DesaKitaColors.divider),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: const Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: 'Estimasi Perjalanan',
                        value: '9 Jam',
                      ),
                    ),
                    _StatDivider(),
                    Expanded(child: _Stat(label: 'Jarak Total', value: '8.6')),
                    _StatDivider(),
                    Expanded(child: _Stat(label: '', value: '3', unit: 'Tempat')),
                  ],
                ),
              ),
            ),

            // ===== TIMELINE =====
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) => _TimelineRow(
                  item: _items[index],
                  isLast: index == _items.length - 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DATA & WIDGET DEMO
// ---------------------------------------------------------------------------

enum _ItemAction { edit, hapus, lihat }

class _ItineraryItem {
  final String time;
  final String title;
  final String subtitle;
  final double? rating;
  final String? thumbnail;
  final List<_ItemAction> actions;

  const _ItineraryItem({
    required this.time,
    required this.title,
    required this.subtitle,
    this.rating,
    this.thumbnail,
    required this.actions,
  });
}

class _RouteMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tileUrl = AppConfig.isMapboxConfigured
        ? 'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12'
              '/tiles/256/{z}/{x}/{y}?access_token='
              '${AppConfig.mapboxAccessToken}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    return IgnorePointer(
      child: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(-5.4140, 105.2330),
          initialZoom: 11.6,
        ),
        children: [
          TileLayer(urlTemplate: tileUrl, userAgentPackageName: 'com.desakita.desa_wisata'),
          PolylineLayer(
            polylines: [
              Polyline(
                points: TripItineraryScreen._route,
                strokeWidth: 4,
                color: const Color(0xFF4F3DF0),
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: TripItineraryScreen._route.first,
                width: 28,
                height: 28,
                child: const Icon(
                  Icons.circle,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              Marker(
                point: TripItineraryScreen._bukitSakura,
                width: 130,
                height: 56,
                child: const _MapLabel(
                  label: 'Bukit Sakura',
                  icon: Icons.landscape_outlined,
                ),
              ),
              Marker(
                point: TripItineraryScreen._puncakMas,
                width: 130,
                height: 56,
                child: const _MapLabel(
                  label: 'Puncak Mas',
                  icon: Icons.place,
                  iconColor: Color(0xFFD53030),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;

  const _MapLabel({
    required this.label,
    required this.icon,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: DesaKitaColors.text,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapCircleButton extends StatelessWidget {
  final IconData icon;
  const _MapCircleButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {},
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 17, color: DesaKitaColors.text),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _Stat({required this.label, required this.value, this.unit = ''});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (label.isNotEmpty)
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: DesaKitaColors.textSecondary,
            ),
          )
        else
          const SizedBox(height: 11),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            text: value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: DesaKitaColors.text,
            ),
            children: [
              if (unit.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: DesaKitaColors.textSecondary,
                  ),
                ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: DesaKitaColors.divider);
  }
}

class _TimelineRow extends StatelessWidget {
  final _ItineraryItem item;
  final bool isLast;

  const _TimelineRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Jam + garis vertikal
        SizedBox(
          width: 46,
          child: Column(
            children: [
              Text(
                item.time,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: DesaKitaColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 2,
                height: isLast ? 24 : 84,
                color: const Color(0xFF9DBFA6),
              ),
            ],
          ),
        ),
        // Kartu kegiatan
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DesaKitaColors.divider),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: DesaKitaColors.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: DesaKitaColors.textSecondary,
                        ),
                      ),
                      if (item.thumbnail != null || item.rating != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (item.thumbnail != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  item.thumbnail!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 40,
                                    height: 40,
                                    color: DesaKitaColors.mutedGreen,
                                    child: const Icon(
                                      Icons.image_outlined,
                                      size: 18,
                                      color: DesaKitaColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 10),
                            if (item.rating != null)
                              Row(
                                children: [
                                  ...List.generate(
                                    5,
                                    (i) => Icon(
                                      Icons.star,
                                      size: 12,
                                      color: i < item.rating!.round()
                                          ? const Color(0xFFF2B01E)
                                          : const Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.rating!.toStringAsFixed(1),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: DesaKitaColors.text,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final action in item.actions)
                            _ActionChip(action: action),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: DesaKitaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final _ItemAction action;
  const _ActionChip({required this.action});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (action) {
      _ItemAction.edit => (
        'Edit',
        const Color(0xFFE3F0E1),
        DesaKitaColors.darkGreen,
      ),
      _ItemAction.hapus => (
        'Hapus',
        const Color(0xFFFDE8E7),
        const Color(0xFFD53030),
      ),
      _ItemAction.lihat => (
        'Lihat',
        const Color(0xFFE3F0E1),
        DesaKitaColors.darkGreen,
      ),
    };
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
