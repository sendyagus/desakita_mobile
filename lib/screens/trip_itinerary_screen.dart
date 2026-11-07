import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:desa_wisata/config/app_config.dart';
import 'package:desa_wisata/models/trip_plan.dart';
import 'package:desa_wisata/services/trip_plan_service.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';

/// Layar "Susunan Perjalanan": peta rute, ringkasan, dan linimasa kegiatan.
///
/// Isinya datang dari [TripPlan] — jadwal hasil KITA AI, jadwal otomatis dari
/// pemesanan tiket, atau contoh bawaan. [persistChanges] aktif hanya bila plan
/// berasal dari booking sungguhan, supaya Edit/Hapus ikut tersimpan.
class TripItineraryScreen extends StatefulWidget {
  final TripPlan plan;
  final bool persistChanges;

  const TripItineraryScreen({
    super.key,
    required this.plan,
    this.persistChanges = false,
  });

  @override
  State<TripItineraryScreen> createState() => _TripItineraryScreenState();
}

class _TripItineraryScreenState extends State<TripItineraryScreen> {
  late TripPlan _plan = widget.plan;
  final MapController _mapController = MapController();

  TripStats get _stats => TripPlanService.statsOf(_plan);

  List<LatLng> get _route {
    final points = _plan.stops
        .where((s) => s.hasPosition)
        .map((s) => LatLng(s.lat!, s.lng!))
        .toList();
    return points.length < 2 ? TripPlanService.fallbackRoute : points;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _apply(List<TripStop> stops) {
    setState(() {
      _plan = _plan.copyWith(stops: stops);
    });
    if (widget.persistChanges) TripPlanService.instance.save(_plan);
  }

  /// Ubah jam kegiatan memakai TimePicker 24 jam.
  Future<void> _editTime(TripStop stop) async {
    final parts = stop.normalizedTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 8,
      minute: int.tryParse(parts.last) ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Ubah jam ${stop.title}',
    );
    if (picked == null) return;
    final time =
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    final stops = _plan.stops.map((s) {
      return s == stop ? s.copyWith(time: time) : s;
    }).toList()..sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));
    _apply(stops);
    _toast('Jam ${stop.title} diubah ke $time');
  }

  Future<void> _deleteStop(TripStop stop) async {
    if (_plan.stops.length <= 1) {
      _toast('Minimal satu kegiatan harus tersisa dalam perjalanan.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus kegiatan?'),
        content: Text(
          '${stop.time} - ${stop.title} akan dikeluarkan dari '
          'susunan perjalanan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD53030),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _apply(_plan.stops.where((s) => s != stop).toList());
    _toast('Kegiatan dihapus dari susunan perjalanan.');
  }

  /// Buka detail kegiatan; bila titik punya koordinat, sediakan rutenya.
  void _viewStop(TripStop stop) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final position = stop.hasPosition
            ? LatLng(stop.lat!, stop.lng!)
            : _route.first;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${stop.time} - ${stop.title}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: DesaKitaColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stop.note,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  height: 1.5,
                  color: DesaKitaColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: DesaKitaColors.buttonGreen,
                  ),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _openRoute(position);
                  },
                  icon: const Icon(Icons.navigation_outlined),
                  label: const Text('Buka Rute di Google Maps'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openRoute(LatLng point) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination='
      '${point.latitude},${point.longitude}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _toast('Tidak bisa membuka Google Maps');
    }
  }

  /// Kembalikan kamera ke seluruh rute perjalanan.
  void _recenter() {
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: _route,
        padding: const EdgeInsets.all(24),
      ),
    );
  }

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
                      _RouteMap(
                        route: _route,
                        plan: _plan,
                        controller: _mapController,
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Row(
                          children: [
                            _MapCircleButton(
                              icon: Icons.navigation_outlined,
                              onTap: () => _openRoute(_route.last),
                            ),
                            const SizedBox(width: 8),
                            _MapCircleButton(
                              icon: Icons.my_location,
                              onTap: _recenter,
                            ),
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
                child: Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: 'Estimasi Perjalanan',
                        value: _stats.duration,
                      ),
                    ),
                    const _StatDivider(),
                    Expanded(
                      child: _Stat(
                        label: 'Jarak Total',
                        value: _stats.distanceKm.toStringAsFixed(1),
                        unit: 'KM',
                      ),
                    ),
                    const _StatDivider(),
                    Expanded(
                      child: _Stat(
                        label: '',
                        value: '${_stats.placeCount}',
                        unit: 'Tempat',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===== TIMELINE =====
            Expanded(
              child: _plan.stops.isEmpty
                  ? _emptyTimeline()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      itemCount: _plan.stops.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final stop = _plan.stops[index];
                        return _TimelineRow(
                          stop: stop,
                          isLast: index == _plan.stops.length - 1,
                          onEdit: () => _editTime(stop),
                          onDelete: () => _deleteStop(stop),
                          onView: () => _viewStop(stop),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyTimeline() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 34,
              color: DesaKitaColors.primary,
            ),
            const SizedBox(height: 10),
            Text(
              'Belum ada kegiatan tersisa',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: DesaKitaColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Minta KITA AI membuatkan jadwal baru, lalu tambahkan lewat '
              'halaman Trip.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                height: 1.5,
                color: DesaKitaColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PETA & WIDGET PENDUKUNG
// ---------------------------------------------------------------------------

class _RouteMap extends StatelessWidget {
  final List<LatLng> route;
  final TripPlan plan;
  final MapController controller;

  const _RouteMap({
    required this.route,
    required this.plan,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final tileUrl = AppConfig.isMapboxConfigured
        ? 'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12'
              '/tiles/256/{z}/{x}/{y}?access_token='
              '${AppConfig.mapboxAccessToken}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    final labeled = plan.stops
        .where((s) => s.kind == TripStopKind.destination && s.hasPosition)
        .toList();

    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCameraFit: CameraFit.coordinates(
          coordinates: route,
          padding: const EdgeInsets.all(24),
          maxZoom: 15,
        ),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: tileUrl,
          userAgentPackageName: 'com.desakita.desa_wisata',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: route,
              strokeWidth: 4,
              color: const Color(0xFF4F3DF0),
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: route.first,
              width: 28,
              height: 28,
              child: const Icon(Icons.circle, size: 14, color: Colors.white),
            ),
            for (final stop in labeled)
              Marker(
                point: LatLng(stop.lat!, stop.lng!),
                width: 130,
                height: 56,
                child: _MapLabel(
                  label: stop.title.replaceFirst('Sampai ke ', ''),
                  icon: Icons.landscape_outlined,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MapLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MapLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18),
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
  final VoidCallback onTap;

  const _MapCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (label.isNotEmpty)
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: DesaKitaColors.textSecondary,
            ),
          ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            text: value,
            children: unit.isEmpty
                ? null
                : [
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: DesaKitaColors.text,
          ),
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

/// Satu baris linimasa: jam, kartu kegiatan, dan aksi Edit/Hapus/Lihat.
class _TimelineRow extends StatelessWidget {
  final TripStop stop;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _TimelineRow({
    required this.stop,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kolom jam + garis penghubung.
          SizedBox(
            width: 46,
            child: Column(
              children: [
                Text(
                  stop.time,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: DesaKitaColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Container(width: 2, color: DesaKitaColors.divider),
                ),
                if (isLast) const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _card(context)),
        ],
      ),
    );
  }

  Widget _card(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesaKitaColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stop.time} - ${stop.title}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: DesaKitaColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stop.note,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: DesaKitaColors.textSecondary,
                      ),
                    ),
                    if ((stop.rating ?? 0) > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: DesaKitaColors.amber,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            stop.rating!.toStringAsFixed(1),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: DesaKitaColors.text,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (stop.imageUrl != null && stop.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 4),
                  child: _Thumbnail(path: stop.imageUrl!),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (stop.isEditable) ...[
                _ActionChip(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  background: const Color(0xFFE3F0E1),
                  foreground: DesaKitaColors.darkGreen,
                  onTap: onEdit,
                ),
                _ActionChip(
                  label: 'Hapus',
                  icon: Icons.delete_outline,
                  background: const Color(0xFFFDE8E7),
                  foreground: const Color(0xFFD53030),
                  onTap: onDelete,
                ),
              ] else
                _ActionChip(
                  label: 'Lihat',
                  icon: Icons.visibility_outlined,
                  background: const Color(0xFFE3F0E1),
                  foreground: DesaKitaColors.darkGreen,
                  onTap: onView,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Thumbnail baris jadwal; menerima aset lokal maupun URL jaringan.
class _Thumbnail extends StatelessWidget {
  final String path;

  const _Thumbnail({required this.path});

  @override
  Widget build(BuildContext context) {
    final isNetwork = path.startsWith('http');
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 44,
        height: 44,
        child: isNetwork
            ? Image.network(
                path,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _assetFallback(),
              )
            : Image.asset(
                path,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _assetFallback(),
              ),
      ),
    );
  }

  Widget _assetFallback() {
    return Image.asset('assets/img/desakita.jpg', fit: BoxFit.cover);
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: foreground),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
