import 'package:flutter/foundation.dart';
import 'package:desa_wisata/services/destination_service.dart';
import 'package:desa_wisata/services/event_service.dart';

class DestinationContextService {
  final DestinationService _destinationService = DestinationService();
  final EventService _eventService = EventService();

  List<Map<String, dynamic>> _cachedDestinations = [];
  List<Map<String, dynamic>> _cachedEvents = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Inisialisasi service dengan memuat data dari Firebase ke cache lokal
  Future<void> initialize() async {
    try {
      debugPrint('🔍 [DestinationContextService] Memuat data dari Firebase...');
      _cachedDestinations = await _destinationService.getAllDestinations();
      _cachedEvents = await _eventService.getAllEvents();
      _isInitialized = true;
      debugPrint(
        '🔍 [DestinationContextService] Berhasil memuat '
        '${_cachedDestinations.length} destinasi & ${_cachedEvents.length} event.',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [DestinationContextService] Gagal menginisialisasi: $e\n$stackTrace');
    }
  }

  /// Memaksa refresh cache dengan mengambil data terbaru dari Firebase
  Future<void> refresh() async {
    _isInitialized = false;
    await initialize();
  }

  /// Mencari konteks wisata dan event yang relevan berdasarkan query pengguna
  String searchRelevantContext(String userQuery) {
    if (!_isInitialized) {
      debugPrint('⚠️ [DestinationContextService] Belum diinisialisasi. Menjalankan pencarian tanpa cache.');
      return '';
    }

    final query = userQuery.trim().toLowerCase();
    if (query.isEmpty) return '';

    // Pecah query menjadi kata-kata kunci
    final words = query.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
    if (words.isEmpty) {
      words.add(query);
    }

    // 1. Cari & skor destinasi
    final scoredDestinations = <_ScoredItem>[];
    for (final dest in _cachedDestinations) {
      double score = 0;
      final name = (dest['name'] as String? ?? '').toLowerCase();
      final category = (dest['category'] as String? ?? '').toLowerCase();
      final location = (dest['location'] as String? ?? '').toLowerCase();
      final description = (dest['description'] as String? ?? '').toLowerCase();
      final facilities = (dest['facilities'] as String? ?? '').toLowerCase();

      // Skor exact match utuh
      if (name.contains(query)) score += 15;
      if (category.contains(query)) score += 8;

      // Skor per kata kunci
      for (final word in words) {
        if (name.contains(word)) score += 10;
        if (category.contains(word)) score += 5;
        if (location.contains(word)) score += 4;
        if (description.contains(word)) score += 2;
        if (facilities.contains(word)) score += 2;
      }

      if (score > 0) {
        scoredDestinations.add(_ScoredItem(item: dest, score: score));
      }
    }

    // Sort destinasi berdasarkan skor tertinggi
    scoredDestinations.sort((a, b) => b.score.compareTo(a.score));

    // 2. Cari & skor event
    final scoredEvents = <_ScoredItem>[];
    for (final event in _cachedEvents) {
      double score = 0;
      final name = (event['name'] as String? ?? '').toLowerCase();
      final category = (event['category'] as String? ?? '').toLowerCase();
      final location = (event['location'] as String? ?? '').toLowerCase();
      final description = (event['description'] as String? ?? '').toLowerCase();

      // Skor exact match utuh
      if (name.contains(query)) score += 15;
      if (category.contains(query)) score += 8;

      // Skor per kata kunci
      for (final word in words) {
        if (name.contains(word)) score += 10;
        if (category.contains(word)) score += 5;
        if (location.contains(word)) score += 4;
        if (description.contains(word)) score += 2;
      }

      if (score > 0) {
        scoredEvents.add(_ScoredItem(item: event, score: score));
      }
    }

    // Sort event berdasarkan skor tertinggi
    scoredEvents.sort((a, b) => b.score.compareTo(a.score));

    // Ambil top hasil
    final topDestinations = scoredDestinations.take(5).map((e) => e.item).toList();
    final topEvents = scoredEvents.take(3).map((e) => e.item).toList();

    if (topDestinations.isEmpty && topEvents.isEmpty) {
      return 'TIDAK ADA DATA YANG RELEVAN DI DATABASE APLIKASI.';
    }

    // Build format teks konteks
    final sb = StringBuffer();
    
    if (topDestinations.isNotEmpty) {
      sb.writeln('DATA WISATA/DESTINASI RELEVAN:');
      for (var i = 0; i < topDestinations.length; i++) {
        final d = topDestinations[i];
        sb.writeln('${i + 1}. Nama: ${d['name']}');
        sb.writeln('   Kategori: ${d['category']}');
        sb.writeln('   Lokasi: ${d['location']}');
        if (d['price'] != null && d['price'].toString().isNotEmpty) {
          sb.writeln('   Harga: ${d['price']}');
        }
        if (d['rating'] != null) {
          sb.writeln('   Rating: ${d['rating']}');
        }
        if (d['facilities'] != null && d['facilities'].toString().isNotEmpty) {
          sb.writeln('   Fasilitas: ${d['facilities']}');
        }
        if (d['openingHours'] != null && d['openingHours'].toString().isNotEmpty) {
          sb.writeln('   Jam Buka: ${d['openingHours']}');
        }
        if (d['description'] != null && d['description'].toString().isNotEmpty) {
          sb.writeln('   Deskripsi: ${d['description']}');
        }
        sb.writeln();
      }
    }

    if (topEvents.isNotEmpty) {
      sb.writeln('DATA EVENT RELEVAN:');
      for (var i = 0; i < topEvents.length; i++) {
        final e = topEvents[i];
        sb.writeln('${i + 1}. Nama Event: ${e['name']}');
        sb.writeln('   Kategori: ${e['category']}');
        sb.writeln('   Lokasi: ${e['location']}');
        if (e['price'] != null && e['price'].toString().isNotEmpty) {
          sb.writeln('   Harga/Tiket: ${e['price']}');
        }
        if (e['start_date'] != null) {
          sb.writeln('   Tanggal: ${e['start_date']} s/d ${e['end_date']}');
        }
        if (e['organizer'] != null && e['organizer'].toString().isNotEmpty) {
          sb.writeln('   Penyelenggara: ${e['organizer']}');
        }
        if (e['description'] != null && e['description'].toString().isNotEmpty) {
          sb.writeln('   Deskripsi: ${e['description']}');
        }
        sb.writeln();
      }
    }

    return sb.toString().trim();
  }
}

class _ScoredItem {
  final Map<String, dynamic> item;
  final double score;

  _ScoredItem({required this.item, required this.score});
}
