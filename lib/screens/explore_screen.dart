import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart' hide Position;
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import 'package:desa_wisata/config/app_config.dart';
import 'package:desa_wisata/screens/destination_detail_screen.dart';
import 'package:desa_wisata/screens/umkm_detail_screen.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';

/// Halaman eksplorasi berbasis peta penuh (flutter_map) dengan marker
/// destinasi/UMKM dari Firestore, pencarian teks + suara, dan tombol rute.
class ExploreScreen extends StatefulWidget {
  /// 0 = Wisata (destinasi), 1 = UMKM.
  final int initialType;

  const ExploreScreen({super.key, this.initialType = 0});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

/// Satu titik di peta eksplorasi (dari Firestore atau fallback demo).
class _ExplorePlace {
  final String id;
  final String name;
  final String category;
  final String location;
  final String description;
  final LatLng? position;
  final bool isUmkm;
  final Map<String, dynamic> data;

  const _ExplorePlace({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.description,
    required this.position,
    required this.isUmkm,
    required this.data,
  });

  bool get isKuliner => category.toLowerCase().contains('kuliner');
}

class _ExploreScreenState extends State<ExploreScreen> {
  MapboxMap? _map;
  bool _styleReady = false;
  bool _is3D = true;
  String _baseStyle = MapboxStyles.OUTDOORS;

  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  int _selectedTypeIndex = 0; // 0 = wisata, 1 = UMKM
  int _selectedCategoryIndex = 0;

  /// `true` = tampilkan katalog kartu (wisata/UMKM), `false` = tampilkan peta.
  /// Halaman selalu dibuka pada peta; katalog hanya lewat tombol kanan atas.
  bool _catalogView = false;

  String _query = '';
  bool _listening = false;
  _ExplorePlace? _selected;

  /// Lokasi yang sedang ditampilkan pada popup info di peta.
  _ExplorePlace? _popupPlace;

  /// Id lokasi yang di-bookmark dari popup (state lokal, seperti di Beranda).
  final Set<String> _bookmarkedIds = {};

  List<_ExplorePlace> _places = const [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  static const _destinationCategories = [
    'Semua',
    'Alam',
    'Budaya',
    'Kuliner',
    'Penginapan',
  ];
  static const _umkmCategories = [
    'Semua',
    'Kuliner',
    'Kerajinan',
    'Oleh-oleh',
    'Budaya',
  ];

  /// Koordinat fallback untuk data demo (dipakai bila dokumen Firestore
  /// belum punya field latitude/longitude).
  static const _demoCoordinates = <String, LatLng>{
    'puncak mas': LatLng(-5.4205801, 105.2224986),
    'bukit sakura': LatLng(-5.404013, 105.222813),
    'saung agrowisata': LatLng(-5.4018431, 105.2052365),
    'lembah durian': LatLng(-5.419488, 105.197188),
    'kampoeng vietnam': LatLng(-5.410988, 105.192813),
    'farm day': LatLng(-5.407458, 105.1937542),
    'lengkung langit': LatLng(-5.4178442, 105.1815289),
  };

  /// Batas wilayah Kecamatan Kemiling (garis merah putus-putus),
  /// dimuat dari `assets/geo/kemiling_boundary.json` (GeoJSON).
  List<LatLng> _boundary = const [];

  /// Kamera sudah pernah diposisikan menyesuaikan wilayah Kemiling.
  /// 0 = belum, 1 = fit dengan batas saja (marker belum tiba), 2 = fit final.
  int _fitStage = 0;

  /// Zona geser peta: bounding box Kecamatan Kemiling + toleransi kecil,
  /// dihitung dari [_boundary] (fallback: nilai statis kecamatan).
  static const double _boundaryTolerance = 0.012; // ~1,3 km
  static const double _minZoomKemiling = 12.5;
  double _minLat = -5.4375;
  double _maxLat = -5.3574;
  double _minLng = 105.1664;
  double _maxLng = 105.2366;
  bool _clampingCamera = false;

  /// Data demo (sesuai desain) yang dipakai bila koleksi Firestore kosong,
  /// sehingga peta Explorasi selalu menampilkan marker lokasi.
  /// Posisi diambil dari [_demoCoordinates] agar satu sumber data.
  static final _demoPlaces = <_ExplorePlace>[
    _ExplorePlace(
      id: 'demo-1',
      name: 'Puncak Mas',
      category: 'Wisata',
      location: 'Kemiling, Bandar Lampung',
      description: 'Wisata puncak dengan pemandangan kota.',
      position: _demoCoordinates['puncak mas'],
      isUmkm: false,
      data: const {'rating': 4.5, 'imageUrl': 'assets/img/banner1.png'},
    ),
    _ExplorePlace(
      id: 'demo-2',
      name: 'Bukit Sakura',
      category: 'Wisata',
      location: 'Kemiling, Bandar Lampung',
      description: 'Taman bunga di atas bukit.',
      position: _demoCoordinates['bukit sakura'],
      isUmkm: false,
      data: const {'rating': 4.3, 'imageUrl': 'assets/img/banner2.png'},
    ),
    _ExplorePlace(
      id: 'demo-3',
      name: 'Saung Agrowisata',
      category: 'Kuliner',
      location: 'Kemiling, Bandar Lampung',
      description: 'Makan di saung dengan suasana kebun.',
      position: _demoCoordinates['saung agrowisata'],
      isUmkm: false,
      data: const {'rating': 4.2, 'imageUrl': 'assets/img/banner3.png'},
    ),
    _ExplorePlace(
      id: 'demo-4',
      name: 'Lembah Durian',
      category: 'Wisata',
      location: 'Kemiling, Bandar Lampung',
      description: 'Wisata kebun durian.',
      position: _demoCoordinates['lembah durian'],
      isUmkm: false,
      data: const {'rating': 4.1, 'imageUrl': 'assets/img/desakita.jpg'},
    ),
    _ExplorePlace(
      id: 'demo-5',
      name: 'Kampoeng Vietnam',
      category: 'Wisata',
      location: 'Kemiling, Bandar Lampung',
      description: 'Kampung bertema Vietnam.',
      position: _demoCoordinates['kampoeng vietnam'],
      isUmkm: false,
      data: const {'rating': 4.4, 'imageUrl': 'assets/img/desakita.jpg'},
    ),
    _ExplorePlace(
      id: 'demo-6',
      name: 'Farm Day',
      category: 'Wisata',
      location: 'Kemiling, Bandar Lampung',
      description: 'Wisata edukasi pertanian.',
      position: _demoCoordinates['farm day'],
      isUmkm: false,
      data: const {'rating': 4.3, 'imageUrl': 'assets/img/banner1.png'},
    ),
    _ExplorePlace(
      id: 'demo-7',
      name: 'Lengkung Langit',
      category: 'Wisata',
      location: 'Kemiling, Bandar Lampung',
      description: 'Spot foto lengkung di tengah alam.',
      position: _demoCoordinates['lengkung langit'],
      isUmkm: false,
      data: const {'rating': 4.6, 'imageUrl': 'assets/img/banner2.png'},
    ),
  ];

  /// Contoh UMKM untuk katalog bila koleksi `umkm` belum bisa dibaca
  /// (kosong atau ditolak aturan Firestore), agar tampilan tetap utuh.
  static const _demoUmkm = <_ExplorePlace>[
    _ExplorePlace(
      id: 'demo-umkm-1',
      name: 'ALYN Tapis',
      category: 'Kerajinan',
      location: 'Sumber Agung, Kemiling, Bandar Lampung',
      description: 'Pengrajin kain tapis khas Lampung.',
      position: null,
      isUmkm: true,
      data: {
        'name': 'ALYN Tapis',
        'category': 'Kerajinan',
        'location': 'Sumber Agung, Kemiling, Bandar Lampung',
        'description': 'Pengrajin kain tapis khas Lampung.',
        'rating': 4.8,
        'reviewCount': 24,
        'imageUrl': 'assets/img/desakita.jpg',
      },
    ),
    _ExplorePlace(
      id: 'demo-umkm-2',
      name: 'Saung Agrowisata',
      category: 'Kuliner',
      location: 'Beringin Raya, Kemiling, Bandar Lampung',
      description: 'Kuliner saung dengan suasana kebun.',
      position: null,
      isUmkm: true,
      data: {
        'name': 'Saung Agrowisata',
        'category': 'Kuliner',
        'location': 'Beringin Raya, Kemiling, Bandar Lampung',
        'description': 'Kuliner saung dengan suasana kebun.',
        'rating': 4.4,
        'reviewCount': 18,
        'imageUrl': 'assets/img/banner3.png',
      },
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedTypeIndex = widget.initialType.clamp(0, 1).toInt();
    _listenPlaces();
    _loadBoundary();
  }

  /// Muat poligon batas Kecamatan Kemiling dari asset GeoJSON.
  Future<void> _loadBoundary() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/geo/kemiling_boundary.json',
      );
      final geo = jsonDecode(raw) as Map<String, dynamic>;
      final feature = (geo['features'] as List).first as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List;
      // Ring luar poligon: daftar [lng, lat].
      final ring = coordinates.first as List;
      final points = ring
          .map(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          )
          .toList();
      if (!mounted) return;
      setState(() => _boundary = points);
      _updateDragZone();
      if (_styleReady) {
        _renderBoundary();
        _fitCameraToArea();
      }
    } catch (e) {
      debugPrint('Gagal memuat batas kecamatan: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------- data ----------------

  void _listenPlaces() {
    _sub?.cancel();
    final isUmkm = _selectedTypeIndex == 1;
    _sub = FirebaseFirestore.instance
        .collection(isUmkm ? 'umkm' : 'destinations')
        .where('status', isEqualTo: true)
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;
            setState(() {
              _places = snap.docs.map((d) => _toPlace(d, isUmkm)).toList();
              _popupPlace = null;
              // Koleksi kosong → tampilkan data demo agar peta/katalog tetap
              // seperti desain.
              if (_places.isEmpty) {
                _places = isUmkm ? _demoUmkm : _demoPlaces;
              }
              // Tab Wisata → pastikan SEMUA titik destinasi yang telah
              // ditentukan (demo coordinates) ikut tampil di peta, meskipun
              // namanya belum ada / tidak cocok dengan dokumen Firestore.
              if (!isUmkm && _places != _demoPlaces) {
                final nama = _places
                    .map((p) => p.name.trim().toLowerCase())
                    .toSet();
                _places = [
                  ..._places,
                  ..._demoPlaces.where(
                    (p) => !nama.contains(p.name.trim().toLowerCase()),
                  ),
                ];
              }
            });
            _renderMarkers();
            _fitCameraToArea();
          },
          onError: (e) {
            debugPrint('Explore stream error: $e');
            _useDemoPlaces(isUmkm: isUmkm);
          },
        );
  }

  /// Pakai data demo bila Firestore kosong / tidak bisa diakses.
  void _useDemoPlaces({bool isUmkm = false}) {
    if (!mounted) return;
    setState(() => _places = isUmkm ? _demoUmkm : _demoPlaces);
    _renderMarkers();
  }

  /// Konversi nilai koordinat apa pun (num atau string "-5,42")
  /// menjadi double. Mengembalikan null bila tidak bisa dibaca.
  double? _parseCoord(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) {
      final s = v.trim().replaceAll(',', '.');
      return double.tryParse(s.replaceAll(RegExp(r'[^0-9.\-+]'), ''));
    }
    return null;
  }

  /// Ambil titik dari kolom koordinat dokumen Firestore. Mendukung field
  /// latitude/longitude, lat/lng (num ATAU string), field GeoPoint, dan
  /// pasangan "@lat,lng" di dalam mapsUrl.
  LatLng? _positionFromDoc(Map<String, dynamic> d) {
    final lat = _parseCoord(d['latitude'] ?? d['lat']);
    final lng = _parseCoord(d['longitude'] ?? d['lng']);
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    for (final key in const ['position', 'coordinates', 'locationPoint']) {
      final v = d[key];
      if (v is GeoPoint) return LatLng(v.latitude, v.longitude);
      if (v is List && v.length >= 2) {
        final a = _parseCoord(v[0]);
        final b = _parseCoord(v[1]);
        if (a != null && b != null) {
          // Dukung [lat, lng] maupun [lng, lat] (deteksi dari rentang).
          return (a.abs() <= 90) ? LatLng(a, b) : LatLng(b, a);
        }
      }
    }
    final url = (d['mapsUrl'] ?? d['mapUrl'] ?? '').toString();
    final m = RegExp(
      r'@(-?\d+(?:[.,]\d+)?),(-?\d+(?:[.,]\d+)?)',
    ).firstMatch(url);
    if (m != null) {
      final a = double.tryParse(m.group(1)!.replaceAll(',', '.'));
      final b = double.tryParse(m.group(2)!.replaceAll(',', '.'));
      if (a != null && b != null) return LatLng(a, b);
    }
    return null;
  }

  _ExplorePlace _toPlace(
    DocumentSnapshot<Map<String, dynamic>> doc,
    bool isUmkm,
  ) {
    final d = doc.data() ?? {};
    final name = (d['name'] ?? '').toString();
    // Prioritas: koordinat eksplisit pada dokumen → fallback demo by nama.
    final pos =
        _positionFromDoc(d) ?? _demoCoordinates[name.trim().toLowerCase()];
    return _ExplorePlace(
      id: doc.id,
      name: name.isEmpty ? (isUmkm ? 'UMKM' : 'Destinasi') : name,
      category: (d['category'] ?? (isUmkm ? 'UMKM' : 'Wisata')).toString(),
      location: (d['location'] ?? '').toString(),
      description: (d['description'] ?? '').toString(),
      position: pos,
      isUmkm: isUmkm,
      data: {...d, 'id': doc.id},
    );
  }

  List<String> get _categories =>
      _selectedTypeIndex == 1 ? _umkmCategories : _destinationCategories;

  List<_ExplorePlace> get _results => _query.trim().isEmpty
      ? const []
      : _places
            .where(
              (p) =>
                  p.name.toLowerCase().contains(_query.toLowerCase()) ||
                  p.location.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();

  List<_ExplorePlace> get _sheetPlaces {
    final selectedCategory =
        _categories[_selectedCategoryIndex.clamp(0, _categories.length - 1)];
    return _places.where((p) {
      final matchesCategory =
          selectedCategory == 'Semua' ||
          p.category.toLowerCase() == selectedCategory.toLowerCase();
      return matchesCategory;
    }).toList();
  }

  /// Daftar untuk katalog kartu: kategori terpilih + kata kunci pencarian.
  List<_ExplorePlace> get _catalogPlaces {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _sheetPlaces;
    return _sheetPlaces
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.location.toLowerCase().contains(q),
        )
        .toList();
  }

  /// Pindah antara tampilan peta dan katalog kartu.
  void _toggleView() {
    FocusScope.of(context).unfocus();
    setState(() => _catalogView = !_catalogView);
  }

  /// Ambil URL gambar dari dokumen (imageUrl / image_url / image).
  String _imageOf(_ExplorePlace p) {
    final raw = p.data['imageUrl'] ?? p.data['image_url'] ?? p.data['image'];
    final url = (raw ?? '').toString().trim();
    return url == 'null' ? '' : url;
  }

  double _ratingOf(_ExplorePlace p) {
    final r = p.data['rating'];
    if (r is num) return r.toDouble();
    return double.tryParse(r?.toString() ?? '') ?? 0;
  }

  // ---------------- actions ----------------

  void _focusPlace(_ExplorePlace p) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selected = p;
      _query = '';
      _searchController.clear();
    });
    if (p.position != null) {
      _flyTo(p.position!);
    }
    setState(() => _popupPlace = p);
  }

  Future<void> _goToMyLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
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
    try {
      final pos = await Geolocator.getCurrentPosition();
      final ll = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      _flyTo(ll, zoom: 16);
    } catch (_) {
      _toast('Gagal mengambil lokasi saat ini');
    }
  }

  Future<void> _openRoute(_ExplorePlace p) async {
    if (p.position == null) {
      _toast('Lokasi belum memiliki koordinat');
      return;
    }
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination='
      '${p.position!.latitude},${p.position!.longitude}',
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
      _toast('Pengenalan suara tidak tersedia di perangkat ini');
      return;
    }
    setState(() => _listening = true);
    _speech.listen(
      // ignore: deprecated_member_use
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

  void _openDetail(_ExplorePlace p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => p.isUmkm
            ? UmkmDetailScreen(umkm: p.data)
            : DestinationDetailScreen(destination: p.data),
      ),
    );
  }

  /// Hitung ulang zona geser (bbox boundary + toleransi) agar peta tetap
  /// berkisar di Kecamatan Kemiling.
  void _updateDragZone() {
    if (_boundary.isEmpty) return;
    var minLat = _boundary.first.latitude;
    var maxLat = minLat;
    var minLng = _boundary.first.longitude;
    var maxLng = minLng;
    for (final p in _boundary) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    setState(() {
      _minLat = minLat - _boundaryTolerance;
      _maxLat = maxLat + _boundaryTolerance;
      _minLng = minLng - _boundaryTolerance;
      _maxLng = maxLng + _boundaryTolerance;
    });
  }

  /// Jaga kamera tetap di dalam zona Kemiling: pull-back center yang keluar
  /// dan batasi zoom-out agar daerah lain tidak ikut terlihat.
  Future<void> _enforceKemilingBounds() async {
    final map = _map;
    if (map == null || !_styleReady || _clampingCamera) return;
    try {
      final cam = await map.getCameraState();
      final pos = cam.center.coordinates;
      final lat = pos.lat.toDouble();
      final lng = pos.lng.toDouble();
      final clampedLat = lat.clamp(_minLat, _maxLat);
      final clampedLng = lng.clamp(_minLng, _maxLng);
      final clampedZoom = cam.zoom.clamp(_minZoomKemiling, 20.0);
      final outside =
          (clampedLat - lat).abs() > 0.0005 ||
          (clampedLng - lng).abs() > 0.0005 ||
          (clampedZoom - cam.zoom).abs() > 0.05;
      if (!outside) return;
      _clampingCamera = true;
      await map.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(clampedLng.toDouble(), clampedLat.toDouble()),
          ),
          zoom: clampedZoom.toDouble(),
          bearing: cam.bearing,
          pitch: cam.pitch,
        ),
      );
    } catch (e) {
      debugPrint('Bounds clamp error: $e');
    } finally {
      _clampingCamera = false;
    }
  }

  // ---------------- mapbox map ----------------

  void _onMapCreated(MapboxMap map) {
    _map = map;
    // Tap pada marker/lokasi → tampilkan popup info.
    try {
      map.addInteraction(
        TapInteraction.onMap(_onMapTap),
        interactionID: 'explorePlaceTap',
      );
    } catch (e) {
      debugPrint('addInteraction error: $e');
    }
  }

  /// Cari marker terdekat (dalam radius piksel) dari titik yang di-tap,
  /// lalu buka popup info; tap di area kosong menutup popup.
  Future<void> _onMapTap(MapContentGestureContext ctx) async {
    final map = _map;
    if (map == null) return;
    final touch = ctx.touchPosition;
    _ExplorePlace? hit;
    var best = 48.0; // toleransi radius tap (px)
    try {
      for (final p in _places) {
        final pos = p.position;
        if (pos == null) continue;
        final px = await map.pixelForCoordinate(
          Point(coordinates: Position(pos.longitude, pos.latitude)),
        );
        final dx = (px.x - touch.x).abs();
        final dy = (px.y - touch.y).abs();
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < best) {
          best = dist;
          hit = p;
        }
      }
    } catch (e) {
      debugPrint('Tap query error: $e');
      return;
    }
    if (!mounted) return;
    setState(() {
      _popupPlace = hit;
      if (hit != null) _selected = hit;
    });
  }

  /// Dipanggil setiap style selesai dimuat (termasuk saat ganti style).
  Future<void> _onStyleLoaded(StyleLoadedEventData data) async {
    _styleReady = true;
    await _setupTerrain();
    await _renderBoundary();
    await _renderMarkers();
    await _fitCameraToArea();
  }

  /// Posisikan kamera agar seluruh wilayah yang telah ditentukan terlihat:
  /// bounding box gabungan batas Kecamatan Kemiling + marker lokasi.
  Future<void> _fitCameraToArea() async {
    final map = _map;
    if (map == null || !_styleReady) return;
    if (_fitStage == 2 || (_fitStage == 1 && _places.isEmpty)) return;
    final points = <LatLng>[
      ..._boundary,
      for (final p in _places)
        if (p.position != null) p.position!,
    ];
    if (points.isEmpty) return;
    _fitStage = _places.isEmpty ? 1 : 2;
    var minLat = points.first.latitude;
    var maxLat = minLat;
    var minLng = points.first.longitude;
    var maxLng = minLng;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    try {
      final camera = await map.cameraForCoordinateBounds(
        CoordinateBounds(
          southwest: Point(coordinates: Position(minLng, minLat)),
          northeast: Point(coordinates: Position(maxLng, maxLat)),
          infiniteBounds: false,
        ),
        MbxEdgeInsets(top: 150, left: 56, bottom: 90, right: 56),
        _is3D ? 20.0 : 0.0,
        _is3D ? 60.0 : 0.0,
        14.5,
        null,
      );
      await map.flyTo(camera, MapAnimationOptions(duration: 1200));
    } catch (e) {
      debugPrint('Camera fit error: $e');
      // Fallback: pusat Kecamatan Kemiling hasil kalkulasi boundary.
      await _flyTo(const LatLng(-5.3971, 105.2015), zoom: 13.5);
    }
  }

  /// Elevasi/terrain 3D. Aman bila tidak didukung (mis. di web).
  Future<void> _setupTerrain() async {
    final style = _map;
    if (style == null) return;
    try {
      await style.addSource(
        RasterDemSource(
          id: 'desakita-dem',
          url: 'mapbox://mapbox.mapbox-terrain-dem-v1',
          tileSize: 514,
          maxzoom: 14.0,
        ),
      );
      await style.setStyleTerrain(
        jsonEncode({'source': 'desakita-dem', 'exaggeration': 1.4}),
      );
    } catch (e) {
      debugPrint('Terrain error: $e');
    }
  }

  /// Gambar ulang batas Kecamatan Kemiling (garis merah putus-putus).
  Future<void> _renderBoundary() async {
    final style = _map;
    if (style == null || !_styleReady) return;
    if (await style.styleLayerExists('boundary-line')) {
      await style.removeStyleLayer('boundary-line');
    }
    if (await style.styleSourceExists('boundary-src')) {
      await style.removeStyleSource('boundary-src');
    }
    if (_boundary.isEmpty) return;
    try {
      final coords = <List<double>>[
        for (final p in _boundary) [p.longitude, p.latitude],
      ];
      coords.add(coords.first); // tutup ring
      final geojson = jsonEncode({
        'type': 'Feature',
        'geometry': {'type': 'LineString', 'coordinates': coords},
      });
      await style.addSource(GeoJsonSource(id: 'boundary-src', data: geojson));
      await style.addLayer(
        LineLayer(
          id: 'boundary-line',
          sourceId: 'boundary-src',
          lineColor: 0xFFE53935,
          lineWidth: 2.5,
          lineDasharray: const [2.0, 2.0],
        ),
      );
    } catch (e) {
      debugPrint('Boundary error: $e');
    }
  }

  /// Render marker lokasi (titik hijau + label nama) via CircleLayer +
  /// SymbolLayer, memakai satu GeoJsonSource. approach ini lintas platform
  /// (Android, iOS, dan web), berbeda dari annotation manager yang hanya
  /// tersedia di Android/iOS.
  Future<void> _renderMarkers() async {
    final style = _map;
    if (style == null || !_styleReady) return;
    for (final id in const ['places-label', 'places-circle']) {
      if (await style.styleLayerExists(id)) {
        await style.removeStyleLayer(id);
      }
    }
    if (await style.styleSourceExists('places-src')) {
      await style.removeStyleSource('places-src');
    }
    final features = _places
        .where((p) => p.position != null)
        .map(
          (p) => {
            'type': 'Feature',
            'properties': {'name': p.name},
            'geometry': {
              'type': 'Point',
              'coordinates': [p.position!.longitude, p.position!.latitude],
            },
          },
        )
        .toList();
    final geojson = jsonEncode({
      'type': 'FeatureCollection',
      'features': features,
    });
    try {
      await style.addSource(
        GeoJsonSource(id: 'places-src', data: geojson, dynamicData: true),
      );
      await style.addLayer(
        CircleLayer(
          id: 'places-circle',
          sourceId: 'places-src',
          circleRadius: 8,
          circleColor: 0xFF0B3D2E,
          circleStrokeColor: 0xFFFFFFFF,
          circleStrokeWidth: 3,
        ),
      );
      await style.addLayer(
        SymbolLayer(
          id: 'places-label',
          sourceId: 'places-src',
          textFieldExpression: const ['get', 'name'],
          textSize: 12,
          textColor: 0xFFFFFFFF,
          textHaloColor: 0xFF0B3D2E,
          textHaloWidth: 1.8,
          textAllowOverlap: true,
          textOffset: const [0.0, 1.5],
        ),
      );
    } catch (e) {
      debugPrint('Marker render error: $e');
    }
  }

  Future<void> _flyTo(LatLng ll, {double zoom = 15.5}) async {
    await _map?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(ll.longitude, ll.latitude)),
        zoom: zoom,
        pitch: _is3D ? 60.0 : 0.0,
        bearing: _is3D ? 20.0 : 0.0,
      ),
      MapAnimationOptions(duration: 1500),
    );
  }

  Future<void> _toggle3D() async {
    setState(() => _is3D = !_is3D);
    final map = _map;
    if (map == null) return;
    try {
      final cam = await map.getCameraState();
      await map.flyTo(
        CameraOptions(
          center: cam.center,
          zoom: cam.zoom,
          pitch: _is3D ? 60.0 : 0.0,
          bearing: _is3D ? 20.0 : 0.0,
        ),
        MapAnimationOptions(duration: 800),
      );
    } catch (e) {
      debugPrint('toggle3D error: $e');
    }
  }

  Future<void> _changeStyle(String uri) async {
    setState(() => _baseStyle = uri);
    _styleReady = false;
    await _map?.loadStyleURI(uri);
  }

  // ---------------- popup info lokasi ----------------

  /// Kartu info melayang (sesuai desain): thumbnail + badge rating, nama,
  /// deskripsi, chip kategori, bookmark, dan tautan "selengkapnya".
  Widget _buildInfoPopup(_ExplorePlace p) {
    final rating = (p.data['rating'] as num?)?.toDouble() ?? 4.3;
    final imageUrl = (p.data['imageUrl'] ?? p.data['image_url'] ?? '')
        .toString();
    final bookmarked = _bookmarkedIds.contains(p.id);
    final desc = p.description.trim().isNotEmpty ? p.description : p.location;
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail + badge rating.
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFFE3EDE2),
                  ),
                  child: _popupImage(imageUrl),
                ),
                Positioned(
                  top: 5,
                  left: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 12,
                          color: Color(0xFFF5A623),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: DesaKitaColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: DesaKitaColors.text,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: bookmarked ? 'Hapus bookmark' : 'Bookmark',
                          onPressed: () => setState(() {
                            if (bookmarked) {
                              _bookmarkedIds.remove(p.id);
                            } else {
                              _bookmarkedIds.add(p.id);
                            }
                          }),
                          icon: Icon(
                            bookmarked ? Icons.bookmark : Icons.bookmark_border,
                            color: DesaKitaColors.darkGreen,
                            size: 22,
                          ),
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(
                            minWidth: 34,
                            minHeight: 34,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    Text(
                      desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: DesaKitaColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F4EF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p.category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: DesaKitaColors.text,
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _openDetail(p),
                          child: Row(
                            children: [
                              Text(
                                'selengkapnya',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic,
                                  color: const Color(0xFF1A73E8),
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.arrow_forward,
                                size: 14,
                                color: Color(0xFF1A73E8),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gambar thumbnail popup: URL jaringan, asset lokal, atau placeholder.
  Widget _popupImage(String url) {
    Widget placeholder() => Container(
      color: const Color(0xFFD8E4D6),
      child: const Icon(
        Icons.terrain,
        color: DesaKitaColors.darkGreen,
        size: 28,
      ),
    );
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: 68,
        height: 68,
        errorBuilder: (_, _, _) => placeholder(),
      );
    }
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        width: 68,
        height: 68,
        errorBuilder: (_, _, _) => placeholder(),
      );
    }
    return placeholder();
  }

  /// Segmented control Wisata / UMKM (hanya dipakai pada halaman katalog).
  Widget _buildTypeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: DesaKitaColors.divider),
      ),
      child: Row(children: [_typeButton('Wisata', 0), _typeButton('UMKM', 1)]),
    );
  }

  Widget _typeButton(String label, int index) {
    final selected = _selectedTypeIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (selected) return;
          FocusScope.of(context).unfocus();
          setState(() {
            _selectedTypeIndex = index;
            _selectedCategoryIndex = 0;
          });
          _listenPlaces();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? DesaKitaColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : DesaKitaColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- katalog kartu ----------------

  /// Halaman katalog: search bar + segmented control + daftar kartu.
  Widget _buildCatalogBody() {
    final places = _catalogPlaces;
    return Column(
      children: [
        ColoredBox(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildSearchBar(onLight: true)),
                      const SizedBox(width: 10),
                      _buildViewButton(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildTypeSwitcher(),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: places.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _selectedTypeIndex == 1
                          ? 'Belum ada data UMKM di Firestore.'
                          : 'Belum ada destinasi aktif.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: DesaKitaColors.textSecondary,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                  itemCount: places.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => _catalogCard(places[i]),
                ),
        ),
      ],
    );
  }

  /// Kartu katalog: foto besar + badge rating, nama, lokasi, tombol detail.
  Widget _catalogCard(_ExplorePlace p) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DesaKitaColors.divider),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            color: Color(0x14000000),
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 190,
                width: double.infinity,
                child: _catalogImage(_imageOf(p)),
              ),
              Positioned(top: 10, left: 10, child: _ratingBadge(_ratingOf(p))),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: DesaKitaColors.text,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 15,
                      color: DesaKitaColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        p.location.isEmpty ? p.category : p.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: DesaKitaColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _detailButton(p),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailButton(_ExplorePlace p) {
    return Material(
      color: DesaKitaColors.buttonGreen,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openDetail(p),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            'Lihat detail',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// Badge rating melayang di sudut kiri atas foto.
  Widget _ratingBadge(double rating) {
    if (rating <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: DesaKitaColors.amber),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: DesaKitaColors.text,
            ),
          ),
        ],
      ),
    );
  }

  /// Foto kartu: URL jaringan, asset lokal, atau placeholder.
  Widget _catalogImage(String url) {
    Widget placeholder() => Container(
      color: DesaKitaColors.mutedGreen,
      child: const Center(
        child: Icon(
          Icons.storefront,
          size: 36,
          color: DesaKitaColors.darkGreen,
        ),
      ),
    );
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder(),
      );
    }
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder(),
      );
    }
    return placeholder();
  }

  // ---------------- build ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _catalogView ? Colors.white : Colors.transparent,
      body: _catalogView ? _buildCatalogBody() : _buildMapBody(),
    );
  }

  /// Tampilan peta penuh dengan search bar dan segmented control.
  Widget _buildMapBody() {
    return Stack(
      children: [
        // ===== PETA (SDK Mapbox) =====
        if (AppConfig.isMapboxConfigured)
          MapWidget(
            key: const ValueKey('exploreMapbox'),
            styleUri: _baseStyle,
            viewport: CameraViewportState(
              // Pusat Kecamatan Kemiling (dari kemiling_boundary.json).
              center: Point(coordinates: Position(105.2015, -5.3971)),
              zoom: 13.5,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
            onCameraChangeListener: (_) => _enforceKemilingBounds(),
          )
        else
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Token Mapbox belum dikonfigurasi.\n\n'
                'Isi MAPBOX_ACCESS_TOKEN di env.json lalu jalankan ulang.',
                textAlign: TextAlign.center,
              ),
            ),
          ),

        // ===== SEARCH BAR + TOMBOL KATALOG =====
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
                    _buildViewButton(),
                  ],
                ),
                if (_results.isNotEmpty) _buildSearchResults(),
              ],
            ),
          ),
        ),

        // ===== TOMBOL LOKASI & RUTE (kanan) =====
        SafeArea(
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, top: 74),
              child: Column(
                children: [
                  _RoundButton(icon: Icons.my_location, onTap: _goToMyLocation),
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
                  const SizedBox(height: 12),
                  _RoundButton(
                    icon: _is3D ? Icons.map_outlined : Icons.view_in_ar,
                    onTap: _toggle3D,
                  ),
                  const SizedBox(height: 12),
                  PopupMenuButton<String>(
                    tooltip: 'Ganti gaya peta',
                    onSelected: _changeStyle,
                    initialValue: _baseStyle,
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: MapboxStyles.OUTDOORS,
                        child: Text('Outdoor'),
                      ),
                      PopupMenuItem(
                        value: MapboxStyles.LIGHT,
                        child: Text('Standar'),
                      ),
                      PopupMenuItem(
                        value: MapboxStyles.SATELLITE_STREETS,
                        child: Text('Satelit'),
                      ),
                    ],
                    child: const _StyleButton(icon: Icons.layers),
                  ),
                ],
              ),
            ),
          ),
        ),
        // ===== POPUP INFO LOKASI (tap marker) =====
        // Align di LUAR Material: Align tidak menyerap tap di luar kartu,
        // sedangkan Material (full-size) akan memblokir seluruh peta.
        if (_popupPlace != null)
          Align(
            alignment: Alignment.bottomLeft,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: _buildInfoPopup(_popupPlace!),
              ),
            ),
          ),
      ],
    );
  }

  /// Kolom pencarian. [onLight] = `true` bila latar halaman sudah putih
  /// (katalog), sehingga cukup garis tipis tanpa bayangan.
  Widget _buildSearchBar({bool onLight = false}) {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(left: 16, right: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: onLight ? Border.all(color: DesaKitaColors.borderMuted) : null,
        boxShadow: onLight
            ? null
            : const [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black26,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: DesaKitaColors.darkGreen),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cari destinasi tujuan kamu..',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: DesaKitaColors.textSecondary,
                ),
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
                color: _listening ? Colors.red : DesaKitaColors.buttonGreen,
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

  /// Tombol hijau kanan atas: beralih antara katalog kartu dan peta.
  Widget _buildViewButton() {
    return Material(
      color: DesaKitaColors.buttonGreen,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _toggleView,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(
            _catalogView ? Icons.map_outlined : Icons.format_list_bulleted,
            color: Colors.white,
          ),
        ),
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
              leading: _PinIcon(category: p.category, isUmkm: p.isUmkm),
              title: Text(
                p.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => _focusPlace(p),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WIDGET KECIL
// ---------------------------------------------------------------------------

class _PinIcon extends StatelessWidget {
  final String category;
  final bool isUmkm;

  const _PinIcon({required this.category, this.isUmkm = false});

  bool get _isKuliner => isUmkm || category.toLowerCase().contains('kuliner');

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: DesaKitaColors.darkGreen,
      child: Icon(
        _isKuliner ? Icons.restaurant : Icons.terrain,
        color: Colors.white,
        size: 14,
      ),
    );
  }
}

/// Tombol bulat statis untuk membuka menu ganti gaya peta.
class _StyleButton extends StatelessWidget {
  final IconData icon;

  const _StyleButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, color: DesaKitaColors.darkGreen),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: DesaKitaColors.darkGreen),
        ),
      ),
    );
  }
}
