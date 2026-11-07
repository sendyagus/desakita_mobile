import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desa_wisata/models/ai_chat_models.dart';

/// Balasan KITA AI: teks untuk bubble chat + lampiran opsional
/// (kartu destinasi, chip budget, atau itinerary).
class AiBotReply {
  final String text;
  final AiChatAttachment? attachment;

  const AiBotReply(this.text, [this.attachment]);
}

/// Otak percakapan KITA AI.
///
/// Bukan model generatif: jawaban disusun dari data katalog Firestore
/// (destinasi & UMKM) dengan pencocokan kata kunci, sehingga rekomendasi
/// tempat dan susunan kegiatan tetap konsisten dan bisa dipakai offline.
class AiAgentService {
  AiAgentService._();

  static final AiAgentService instance = AiAgentService._();

  /// Rentang budget yang ditawarkan sebagai chip.
  static const budgetOptions = [
    '< 300 Rb',
    '300 Rb - 700 Rb',
    '700 Rb - 1,5 Jt',
    '> 1,5 Jt',
  ];

  static const _routeWords = [
    'rute',
    'peta',
    'navigasi',
    'arah',
    'lokasi saya',
  ];
  static const _ticketWords = ['tiket', 'booking', 'reservasi', 'pesan'];
  static const _eventWords = ['acara', 'event', 'festival'];
  static const _budgetWords = [
    'budget',
    'biaya',
    'anggaran',
    'ongkos',
    'murah',
    'mahal',
  ];
  static const _itineraryWords = [
    'itinerary',
    'jadwal',
    'kegiatan',
    'rencana',
    'susun',
    'plan',
    'jam',
  ];
  static const _umkmWords = [
    'umkm',
    'kuliner',
    'makan',
    'oleh-oleh',
    'oleh oleh',
    'kerajinan',
  ];
  static const _stayWords = ['penginapan', 'hotel', 'villa', 'homestay'];

  /// Kata yang diabaikan saat mencari kecocokan teks destinasi.
  static const _stopWords = {
    'untuk',
    'saya',
    'yang',
    'dari',
    'dengan',
    'rekomendasikan',
    'tempat',
    'wisata',
    'tolong',
    'bantu',
    'cari',
    'buat',
    'buatkan',
    'liburan',
    'hari',
    'ini',
    'ke',
  };

  Future<AiBotReply> respond(String rawInput) async {
    final input = rawInput.toLowerCase();

    if (_containsAny(input, _itineraryWords)) {
      return _itineraryReply(input);
    }
    if (_containsAny(input, _budgetWords)) {
      final choice = _budgetChoice(input);
      if (choice != null) return _itineraryReply(input, choice: choice);
      return AiBotReply(
        'Untuk memperkirakan biaya liburan, pilih salah satu rentang budget di bawah. '
        'Saya akan susunkan itinerary yang sesuai dengan angka tersebut.',
        AiChatAttachment.budget(budgetOptions),
      );
    }
    if (_containsAny(input, _routeWords)) {
      return const AiBotReply(
        'Informasi lokasi berupa teks tersedia pada detail destinasi. Petunjuk rute dan navigasi langsung belum terhubung karena integrasi peta belum dipasang.',
      );
    }
    if (_containsAny(input, _ticketWords)) {
      return const AiBotReply(
        'Untuk memesan tiket, buka tab **Explorasi**, pilih destinasi, buka **Lihat detail**, lalu tekan **Pesan Tiket**. Kamu juga bisa langsung menekan tombol **Pesan Tiket** pada kartu rekomendasi di obrolan ini.',
      );
    }
    if (_containsAny(input, _eventWords)) {
      return AiBotReply(await _upcomingEvents());
    }
    if (_containsAny(input, _umkmWords)) {
      return AiBotReply(
        await _catalogText(
          collectionName: 'umkm',
          input: input,
          label: 'UMKM lokal',
        ),
      );
    }
    if (_containsAny(input, _stayWords)) {
      return AiBotReply(
        await _catalogText(
          collectionName: 'destinations',
          input: 'penginapan $input',
          label: 'akomodasi yang terdaftar',
        ),
      );
    }
    return _recommendationReply(input);
  }

  // ---------------- rekomendasi ----------------

  Future<AiBotReply> _recommendationReply(String input) async {
    final items = await _fetchCatalog('destinations');
    if (items == null) {
      return const AiBotReply(
        'Saya belum dapat membaca data katalog sekarang. Periksa koneksi internet dan izin baca Firestore, lalu coba kembali.',
      );
    }
    if (items.isEmpty) {
      return const AiBotReply(
        'Belum ada destinasi wisata aktif pada katalog Firestore. Silakan coba lagi setelah pengelola menambahkan data.',
      );
    }
    final top = _ranked(items, input).take(3).toList();
    return AiBotReply(
      'baik, berikut tempat wisata yang saya rekomendasikan dari katalog DesaKita. '
      'Silakan tambahkan ke rencana atau langsung pesan tiket.',
      AiChatAttachment.destinations(top),
    );
  }

  // ---------------- itinerary ----------------

  Future<AiBotReply> _itineraryReply(
    String input, {
    ({int maxTicket, String style})? choice,
  }) async {
    final items = await _fetchCatalog('destinations');
    if (items == null || items.isEmpty) {
      return const AiBotReply(
        'Belum ada destinasi aktif yang bisa saya jadikan dasar itinerary. Tambahkan data katalog terlebih dahulu.',
      );
    }

    // Destinasi yang disebut namanya menang; kalau tidak ada, pakai
    // hasil terfilter budget dengan rating tertinggi.
    final named = _matchByName(items, input);
    final pool = choice == null
        ? _ranked(items, input)
        : _ranked(
            items,
            input,
          ).where((item) => _priceOf(item) <= choice.maxTicket).toList();
    final target = named ?? (pool.isNotEmpty ? pool.first : items.first);
    final style =
        choice?.style ?? (input.contains('hemat') ? 'Hemat' : 'Santai');
    final itinerary = _buildItinerary(target, style);

    return AiBotReply(
      'baik, berikut itinerary ${style.toLowerCase()} untuk ${itinerary.destinationName}. '
      'Estimasi biaya sudah termasuk tiket masuk, transportasi, dan makan.',
      AiChatAttachment.trip(itinerary),
    );
  }

  AiItinerary _buildItinerary(Map<String, dynamic> place, String style) {
    final name = place['name'].toString();
    final ticket = _priceOf(place);
    final hemat = style == 'Hemat';
    final transport = hemat ? 15000 : 25000;
    final food = hemat ? 25000 : 45000;
    final extra = hemat ? 10000 : 30000;
    final stops = hemat
        ? const [
            AiItineraryStop('06.00', 'Berangkat dari rumah'),
            AiItineraryStop('07.00', 'Tiba, beli tiket masuk, keliling area'),
            AiItineraryStop('08.30', 'Eksplor spot foto dan area kebun'),
            AiItineraryStop('10.30', 'Istirahat, jajan makanan lokal'),
            AiItineraryStop('12.00', 'Foto terakhir dan pulang'),
          ]
        : const [
            AiItineraryStop('09.00', 'Berangkat dari rumah'),
            AiItineraryStop(
              '09.30',
              'Tiba, beli tiket, keliling dan lihat suasana',
            ),
            AiItineraryStop(
              '10.30',
              'Eksplor spot foto: lampion, bunga, dan area video',
            ),
            AiItineraryStop('12.00', 'Istirahat, beli minuman/makanan'),
            AiItineraryStop('15.00', 'Foto terakhir dan pulang'),
          ];

    return AiItinerary(
      title: 'Trip Heading: $style $name',
      destinationName: name,
      imageUrl: _imageUrlOf(place),
      destination: place,
      // Baris keberangkatan selalu menyebut nama destinasi tujuan.
      stops: [
        AiItineraryStop(
          stops.first.time,
          '${stops.first.activity} menuju $name',
        ),
        ...stops.skip(1),
      ],
      costPerPerson: ticket + transport + food + extra,
    );
  }

  // ---------------- data & ranking ----------------

  /// `null` bila pembacaan Firestore gagal, daftar kosong bila memang tidak
  /// ada data aktif.
  Future<List<Map<String, dynamic>>?> _fetchCatalog(String collection) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collection)
          .where('status', isEqualTo: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return <String, dynamic>{
          ...data,
          'id': doc.id,
          'name': (data['name'] ?? 'Tanpa nama').toString(),
          'location': (data['location'] ?? 'Lokasi belum tersedia').toString(),
          'category': (data['category'] ?? '').toString(),
          'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
        };
      }).toList();
    } catch (_) {
      return null;
    }
  }

  /// Urutkan berdasarkan kecocokan kata kunci lalu rating tertinggi.
  List<Map<String, dynamic>> _ranked(
    List<Map<String, dynamic>> items,
    String input,
  ) {
    final words = _keywords(input);
    final matched = items.where((item) {
      if (words.isEmpty) return true;
      final searchable =
          '${item['name']} ${item['location']} ${item['category']} ${item['description']}'
              .toString()
              .toLowerCase();
      return words.any(searchable.contains);
    }).toList();
    final pool = matched.isEmpty ? items : matched;
    pool.sort(
      (a, b) => (b['rating'] as double).compareTo(a['rating'] as double),
    );
    return pool;
  }

  /// Destinasi yang namanya disebut langsung pada kalimat user.
  Map<String, dynamic>? _matchByName(
    List<Map<String, dynamic>> items,
    String input,
  ) {
    for (final item in items) {
      final name = item['name'].toString().toLowerCase().trim();
      if (name.isEmpty || name == 'tanpa nama') continue;
      if (input.contains(name)) return item;
      // Cocokkan juga kata khas nama, mis. "sakura" pada "Bukit Sakura".
      final distinctive = name
          .split(RegExp(r'\s+'))
          .where((word) => word.length > 4 && !_stopWords.contains(word));
      if (distinctive.isNotEmpty && distinctive.any(input.contains)) {
        return item;
      }
    }
    return null;
  }

  Set<String> _keywords(String input) => input
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.length > 3 && !_stopWords.contains(word))
      .toSet();

  /// Rentang budget yang dipilih user lewat chip; null bila belum menyebut angka.
  static ({int maxTicket, String style})? _budgetChoice(String input) {
    if (input.contains('1,5') ||
        input.contains('1.5') ||
        input.contains('1500')) {
      return input.contains('>') || input.contains('di atas')
          ? (maxTicket: 99999999, style: 'Premium')
          : (maxTicket: 1500000, style: 'Nyaman');
    }
    if (input.contains('300 rb - 700') || input.contains('300-700')) {
      return (maxTicket: 700000, style: 'Santai');
    }
    if (input.contains('300')) return (maxTicket: 300000, style: 'Hemat');
    if (input.contains('700')) return (maxTicket: 700000, style: 'Santai');
    return null;
  }

  static bool _containsAny(String input, List<String> words) =>
      words.any(input.contains);

  static int _priceOf(Map<String, dynamic> item) {
    final raw = (item['price'] ?? '').toString().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    return int.tryParse(raw) ?? 0;
  }

  static String _imageUrlOf(Map<String, dynamic> item) {
    final raw = item['imageUrl'] ?? item['image_url'] ?? item['image'];
    return (raw ?? '').toString().trim();
  }

  // ---------------- balasan teks lama ----------------

  Future<String> _catalogText({
    required String collectionName,
    required String input,
    required String label,
  }) async {
    final items = await _fetchCatalog(collectionName);
    if (items == null) {
      return 'Saya belum dapat membaca data katalog sekarang. Periksa koneksi internet dan izin baca Firestore, lalu coba kembali.';
    }
    if (items.isEmpty) {
      if (collectionName == 'umkm') {
        return 'Belum ada profil UMKM aktif pada koleksi **umkm** di Firestore. Setelah data usaha dimasukkan, daftar rekomendasinya akan muncul di sini dan pada halaman Explorasi > UMKM.';
      }
      return 'Belum ada $label aktif pada katalog Firestore. Silakan coba lagi setelah pengelola menambahkan data.';
    }

    final top = _ranked(items, input).take(3).toList();
    final lines = <String>[];
    for (var i = 0; i < top.length; i++) {
      final item = top[i];
      final price = (item['price'] ?? '').toString().trim();
      final rating = item['rating'] as double;
      lines.add(
        '${i + 1}. **${item['name']}**\n   ${item['location']}\n   ${item['category'].toString().isEmpty ? label : item['category']}${rating > 0 ? ' • Rating ${rating.toStringAsFixed(1)}' : ''}${price.isNotEmpty ? ' • $price' : ''}',
      );
    }
    return 'Berikut $label yang tercatat pada katalog DesaKita. Daftar ini disusun dari data Firestore dan rating yang tersedia, bukan hasil model AI generatif:\n\n${lines.join('\n\n')}\n\nBuka halaman Explorasi untuk melihat detail datanya.';
  }

  Future<String> _upcomingEvents() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('status', isEqualTo: true)
          .get();
      final now = DateTime.now();
      final events =
          snapshot.docs
              .map((doc) {
                final data = doc.data();
                final rawDate = data['startDate'];
                final date = rawDate is Timestamp
                    ? rawDate.toDate()
                    : DateTime.tryParse(rawDate?.toString() ?? '');
                return <String, dynamic>{
                  'name': (data['name'] ?? 'Acara Desa').toString(),
                  'location': (data['location'] ?? 'Lokasi belum tersedia')
                      .toString(),
                  'startDate': date,
                  'price': (data['price'] ?? '').toString(),
                };
              })
              .where(
                (event) =>
                    event['startDate'] is DateTime &&
                    (event['startDate'] as DateTime).isAfter(now),
              )
              .toList()
            ..sort(
              (a, b) => (a['startDate'] as DateTime).compareTo(
                b['startDate'] as DateTime,
              ),
            );

      if (events.isEmpty) {
        return 'Belum ada acara mendatang yang tercatat pada katalog DesaKita. Informasi acara akan ditampilkan setelah pengelola menambah data ke halaman acara.';
      }
      final lines = events
          .take(3)
          .map((event) {
            final date = event['startDate'] as DateTime;
            final dateLabel =
                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
            final price = (event['price'] as String).trim();
            return '• **${event['name']}** — $dateLabel\n  ${event['location']}${price.isNotEmpty ? ' • $price' : ''}';
          })
          .join('\n\n');
      return 'Berikut acara mendatang yang tercatat di aplikasi:\n\n$lines';
    } catch (_) {
      return 'Saya belum dapat membaca data acara. Periksa koneksi dan izin baca Firestore, atau buka halaman acara jika tersedia.';
    }
  }
}
