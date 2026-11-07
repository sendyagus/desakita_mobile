import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MyApp());

const kGreen = Color(0xFF0B3D2E);
const kButtonGreen = Color(0xFF006400);

// ---------------------------------------------------------------------------
// MODEL & DATA (ganti koordinat dengan koordinat asli dari Google Maps)
// ---------------------------------------------------------------------------
enum PlaceCategory { wisata, kuliner }

class Place {
  final String id, name, description;
  final PlaceCategory category;
  final LatLng position;

  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.position,
    this.description = '',
  });
}

const places = <Place>[
  Place(
    id: '1',
    name: 'Puncak Mas',
    category: PlaceCategory.wisata,
    position: LatLng(-5.3560, 105.3000),
    description: 'Wisata puncak dengan pemandangan kota.',
  ),
  Place(
    id: '2',
    name: 'Bukit Sakura',
    category: PlaceCategory.wisata,
    position: LatLng(-5.3700, 105.2850),
    description: 'Taman bunga di atas bukit.',
  ),
  Place(
    id: '3',
    name: 'Saung Agrowisata',
    category: PlaceCategory.kuliner,
    position: LatLng(-5.3740, 105.2720),
    description: 'Makan di saung dengan suasana kebun.',
  ),
  Place(
    id: '4',
    name: 'Lembah Durian',
    category: PlaceCategory.wisata,
    position: LatLng(-5.3920, 105.2900),
    description: 'Wisata kebun durian.',
  ),
  Place(
    id: '5',
    name: 'Kampoeng Vietnam',
    category: PlaceCategory.wisata,
    position: LatLng(-5.3960, 105.2740),
    description: 'Kampung bertema Vietnam.',
  ),
  Place(
    id: '6',
    name: 'Farm Day',
    category: PlaceCategory.wisata,
    position: LatLng(-5.3980, 105.2870),
    description: 'Wisata edukasi pertanian.',
  ),
  Place(
    id: '7',
    name: 'Lengkung Langit',
    category: PlaceCategory.wisata,
    position: LatLng(-5.4030, 105.2820),
    description: 'Spot foto lengkung di tengah alam.',
  ),
];

// Batas area wisata (garis merah putus-putus). Gambar di geojson.io lalu salin.
const boundary = <LatLng>[
  LatLng(-5.3650, 105.2700),
  LatLng(-5.3640, 105.2800),
  LatLng(-5.3580, 105.2980),
  LatLng(-5.3750, 105.3080),
  LatLng(-5.3900, 105.3050),
  LatLng(-5.4050, 105.2950),
  LatLng(-5.4120, 105.2750),
  LatLng(-5.4000, 105.2600),
  LatLng(-5.3800, 105.2620),
  LatLng(-5.3650, 105.2700),
];

// ---------------------------------------------------------------------------
// APP
// ---------------------------------------------------------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: kGreen, useMaterial3: true),
      home: const MapPage(),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _speech = stt.SpeechToText();

  String _query = '';
  bool _listening = false;
  Place? _selected;
  LatLng? _userPosition;

  List<Place> get _results => _query.isEmpty
      ? []
      : places
            .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

  // ---------------- actions ----------------
  void _focusPlace(Place p) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selected = p;
      _query = '';
      _searchController.clear();
    });
    _mapController.move(p.position, 16);
    _showDetail(p);
  }

  Future<void> _goToMyLocation() async {
    var enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _toast('Aktifkan GPS terlebih dahulu');
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      _toast('Izin lokasi ditolak');
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    final ll = LatLng(pos.latitude, pos.longitude);
    setState(() => _userPosition = ll);
    _mapController.move(ll, 16);
  }

  Future<void> _openRoute(Place p) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${p.position.latitude},${p.position.longitude}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _toast('Tidak bisa membuka Google Maps');
    }
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final ok = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
    );
    if (!ok) {
      _toast('Pengenalan suara tidak tersedia');
      return;
    }
    setState(() => _listening = true);
    _speech.listen(
      localeId: 'id_ID',
      onResult: (r) {
        setState(() {
          _searchController.text = r.recognizedWords;
          _query = r.recognizedWords;
        });
      },
    );
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ---------------- bottom sheets ----------------
  void _showDetail(Place p) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PinIcon(category: p.category, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(p.description),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: kButtonGreen),
                onPressed: () => _openRoute(p),
                icon: const Icon(Icons.directions),
                label: const Text('Rute ke sini'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (ctx, scroll) => ListView.builder(
          controller: scroll,
          padding: const EdgeInsets.all(12),
          itemCount: places.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) {
              return const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Daftar Lokasi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              );
            }
            final p = places[i - 1];
            return ListTile(
              leading: _PinIcon(category: p.category, size: 18),
              title: Text(p.name),
              subtitle: Text(
                p.category == PlaceCategory.kuliner ? 'Kuliner' : 'Wisata',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                _focusPlace(p);
              },
            );
          },
        ),
      ),
    );
  }

  // ---------------- build ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ===== PETA =====
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-5.385, 105.285),
              initialZoom: 13.5,
              onTap: (_, __) => FocusScope.of(context).unfocus(),
            ),
            children: [
              TileLayer(
                // Ganti dengan tile MapTiler/Mapbox untuk gaya abu-abu + hijau
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.peta_wisata',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: boundary,
                    strokeWidth: 2.5,
                    color: Colors.redAccent,
                    pattern: StrokePattern.dotted(),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  for (final p in places)
                    Marker(
                      point: p.position,
                      width: 120,
                      height: 64,
                      child: GestureDetector(
                        onTap: () => _focusPlace(p),
                        child: _PlaceMarker(
                          place: p,
                          selected: _selected?.id == p.id,
                        ),
                      ),
                    ),
                  if (_userPosition != null)
                    Marker(
                      point: _userPosition!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(blurRadius: 6, color: Colors.black26),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ===== SEARCH BAR + TOMBOL =====
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildSearchBar()),
                      const SizedBox(width: 10),
                      _RoundButton(
                        color: kButtonGreen,
                        iconColor: Colors.white,
                        icon: Icons.format_list_bulleted,
                        size: 50,
                        onTap: _showList,
                      ),
                    ],
                  ),
                  if (_results.isNotEmpty) _buildSearchResults(),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      children: [
                        _RoundButton(
                          icon: Icons.my_location,
                          onTap: _goToMyLocation,
                        ),
                        const SizedBox(height: 12),
                        _RoundButton(
                          icon: Icons.directions,
                          onTap: () {
                            if (_selected != null) {
                              _openRoute(_selected!);
                            } else {
                              _toast('Pilih lokasi dulu untuk melihat rute');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(left: 16, right: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black26,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: kGreen),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Cari destinasi tujuan kamu..',
                hintStyle: TextStyle(fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: _toggleMic,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _listening ? Colors.red : kButtonGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _listening ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.only(top: 8, right: 60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
      ),
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [
          for (final p in _results)
            ListTile(
              dense: true,
              leading: _PinIcon(category: p.category, size: 14),
              title: Text(p.name),
              onTap: () => _focusPlace(p),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// WIDGET KECIL
// ---------------------------------------------------------------------------
class _PinIcon extends StatelessWidget {
  final PlaceCategory category;
  final double size;
  const _PinIcon({required this.category, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size,
      backgroundColor: kGreen,
      child: Icon(
        category == PlaceCategory.kuliner ? Icons.restaurant : Icons.terrain,
        color: Colors.white,
        size: size,
      ),
    );
  }
}

class _PlaceMarker extends StatelessWidget {
  final Place place;
  final bool selected;
  const _PlaceMarker({required this.place, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedScale(
          scale: selected ? 1.25 : 1,
          duration: const Duration(milliseconds: 200),
          child: _PinIcon(category: place.category, size: 14),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
          ),
          child: Text(
            place.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: kGreen,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color, iconColor;
  final double size;

  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
    this.iconColor = kGreen,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: iconColor),
        ),
      ),
    );
  }
}
