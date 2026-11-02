import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';
import 'package:desa_wisata/widgets/kita_ai_mascot.dart';

/// GIF animasi maskot KITA AI (lanskap lengkap: langit, bukit, robot).
const String _kMascotGif = 'assets/img/kita_ai_mascot.gif';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _showSuggestions = true;

  // Dashboard KITA AI (desain Figma) tampil lebih dulu; chat adalah mode kedua.
  bool _showDashboard = true;
  final List<_ChatSession> _sessions = [];

  static const List<String> _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  static const List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  String _formatIndonesianDate(DateTime date) =>
      '${_dayNames[date.weekday - 1]}, '
      '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

  final List<String> _suggestions = [
    'Rekomendasikan wisata alam',
    'Kuliner dan UMKM lokal',
    'Budget liburan < 300 ribu',
    'Buat itinerary singkat',
    'Cara pesan tiket wisata',
  ];

  void _enterChat({String? presetPrompt}) {
    setState(() {
      _showDashboard = false;
      if (_messages.isEmpty) {
        _messages.add(
          _ChatMessage(
            text:
                'Halo! Saya **Kita AI**, pendamping perjalanan DesaKita.\n\nSaya dapat membantu mencari destinasi, melihat profil UMKM, dan memberi panduan pemesanan berdasarkan data yang tersedia di aplikasi. Saat ini saya masih dalam **mode demo** dan belum terhubung ke model AI generatif.',
            isUser: false,
          ),
        );
      }
    });
    if (presetPrompt != null) _sendMessage(presetPrompt);
  }

  void _backToDashboard() {
    final firstUserMessage = _messages
        .where((m) => m.isUser)
        .map((m) => m.text)
        .firstOrNull;
    if (firstUserMessage != null) {
      // Arsipkan percakapan ke riwayat (in-memory, belum terhubung database).
      _sessions.insert(
        0,
        _ChatSession(
          title: firstUserMessage,
          time: DateTime.now(),
          messages: List.of(_messages),
        ),
      );
    }
    setState(() {
      _messages.clear();
      _showSuggestions = true;
      _showDashboard = true;
    });
  }

  void _openSession(_ChatSession session) {
    setState(() {
      _messages
        ..clear()
        ..addAll(session.messages);
      _showSuggestions = false;
      _showDashboard = false;
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final message = text.trim();
    if (message.isEmpty || _isTyping) return;

    setState(() {
      _messages.add(_ChatMessage(text: message, isUser: true));
      _isTyping = true;
      _showSuggestions = false;
    });
    _inputController.clear();
    _scrollToBottom();

    await Future<void>.delayed(const Duration(milliseconds: 350));
    final response = await _getBotResponse(message.toLowerCase());
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage(text: response, isUser: false));
    });
    _scrollToBottom();
  }

  Future<String> _getBotResponse(String input) async {
    if (input.contains('rute') ||
        input.contains('jalan') ||
        input.contains('peta') ||
        input.contains('navigasi')) {
      return 'Informasi lokasi berupa teks tersedia pada detail destinasi. Petunjuk rute dan navigasi langsung belum terhubung karena integrasi peta belum dipasang.';
    }

    if (input.contains('tiket') ||
        input.contains('pesan') ||
        input.contains('booking') ||
        input.contains('reservasi')) {
      return 'Untuk memesan tiket, buka tab **Explorasi**, pilih destinasi, buka **Lihat detail**, lalu tekan **Pesan Tiket**. Versi saat ini hanya menyimpan pesanan dengan status menunggu pembayaran; pembayaran dan QR tiket aktif belum terintegrasi.';
    }

    if (input.contains('budget') ||
        input.contains('anggaran') ||
        input.contains('itinerary') ||
        input.contains('rencana perjalanan') ||
        input.contains('healing') ||
        input.contains('pasangan')) {
      return 'Saya dapat membantu menyusun gambaran awal, tetapi belum memakai AI generatif untuk menghitung rekomendasi secara otomatis. Preferensi anggaran, gaya liburan, dan teman perjalanan bisa diisi lewat onboarding. Untuk sekarang, saya bisa menampilkan data destinasi yang tersedia di katalog.';
    }

    if (input.contains('acara') ||
        input.contains('event') ||
        input.contains('festival')) {
      return _getUpcomingEvents();
    }

    if (input.contains('umkm') ||
        input.contains('kuliner') ||
        input.contains('makan') ||
        input.contains('oleh-oleh') ||
        input.contains('oleh oleh') ||
        input.contains('kerajinan')) {
      return _getCatalogRecommendations(
        collectionName: 'umkm',
        input: input,
        label: 'UMKM lokal',
      );
    }

    if (input.contains('penginapan') ||
        input.contains('hotel') ||
        input.contains('villa') ||
        input.contains('homestay')) {
      return _getCatalogRecommendations(
        collectionName: 'destinations',
        input: 'penginapan $input',
        label: 'akomodasi yang terdaftar',
      );
    }

    return _getCatalogRecommendations(
      collectionName: 'destinations',
      input: input,
      label: 'destinasi wisata',
    );
  }

  Future<String> _getCatalogRecommendations({
    required String collectionName,
    required String input,
    required String label,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .where('status', isEqualTo: true)
          .get();
      if (snapshot.docs.isEmpty) {
        if (collectionName == 'umkm') {
          return "Belum ada profil UMKM aktif pada koleksi **umkm** di Firestore. Setelah data usaha dimasukkan, daftar rekomendasinya akan muncul di sini dan pada halaman Explorasi > UMKM.";
        }
        return 'Belum ada $label aktif pada katalog Firestore. Silakan coba lagi setelah pengelola menambahkan data.';
      }

      final words = input
          .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
          .split(RegExp(r'\s+'))
          .where(
            (word) =>
                word.length > 3 &&
                !const {
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
                }.contains(word),
          )
          .toSet();
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        return <String, dynamic>{
          'name': (data['name'] ?? 'Tanpa nama').toString(),
          'location': (data['location'] ?? 'Lokasi belum tersedia').toString(),
          'category': (data['category'] ?? '').toString(),
          'description': (data['description'] ?? '').toString(),
          'price': (data['price'] ?? '').toString(),
          'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
        };
      }).toList();

      var filtered = items.where((item) {
        if (words.isEmpty) return true;
        final searchable =
            '${item['name']} ${item['location']} ${item['category']} ${item['description']}'
                .toString()
                .toLowerCase();
        return words.any(searchable.contains);
      }).toList();
      if (filtered.isEmpty) filtered = items;
      filtered.sort(
        (a, b) => (b['rating'] as double).compareTo(a['rating'] as double),
      );
      final top = filtered.take(3).toList();
      final lines = <String>[];
      for (var i = 0; i < top.length; i++) {
        final item = top[i];
        final price = (item['price'] as String).trim();
        final rating = item['rating'] as double;
        lines.add(
          '${i + 1}. **${item['name']}**\n   ${item['location']}\n   ${item['category'].toString().isEmpty ? label : item['category']}${rating > 0 ? ' • Rating ${rating.toStringAsFixed(1)}' : ''}${price.isNotEmpty ? ' • $price' : ''}',
        );
      }
      return 'Berikut $label yang tercatat pada katalog DesaKita. Daftar ini disusun dari data Firestore dan rating yang tersedia, bukan hasil model AI generatif:\n\n${lines.join('\n\n')}\n\nBuka halaman Explorasi untuk melihat detail datanya.';
    } catch (_) {
      return 'Saya belum dapat membaca data katalog sekarang. Periksa koneksi internet dan izin baca Firestore, lalu coba kembali.';
    }
  }

  Future<String> _getUpcomingEvents() async {
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

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesaKitaColors.background,
      body: _showDashboard
          ? _buildDashboard()
          : SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

                  // Area chat
                  Expanded(
                    child: _messages.isEmpty
                        ? _buildEmptyState()
                        : _buildChatArea(),
                  ),

                  // Suggestions (hanya tampil di awal)
                  if (_showSuggestions && _messages.isNotEmpty)
                    _buildSuggestions(),

                  // Input bar
                  _buildInputBar(),
                ],
              ),
            ),
    );
  }

  // ─── Dashboard KITA AI (desain Figma) ──────────────────────────────────────

  Widget _buildDashboard() {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      children: [
        _buildAiHero(),
        const SizedBox(height: 34),
        _buildQuickActionPanel(),
        const SizedBox(height: 20),
        _buildHistorySection(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAiHero() {
    final topPadding = MediaQuery.of(context).padding.top;
    final heroHeight = 400.0 + topPadding;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: heroHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // GIF lanskap maskot sebagai background hero full ke atas (tanpa celah putih).
              Image.asset(
                _kMascotGif,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) => Stack(
                  fit: StackFit.expand,
                  children: [
                    // Fallback vektor bila aset GIF tidak ikut ter-bundle.
                    CustomPaint(painter: _AiScenePainter()),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 44,
                      child: Center(
                        child: KitaAiMascot(
                          size: 168,
                          color: const Color(0xFF0E7A45),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Top vignette halus agar notch dan status bar menyatu natural tanpa garis patahan
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 90,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x35000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
              // Scrim: bagian atas transparan penuh (agar warna langit GIF alami dan full),
              // dan fading lembut ke latar belakang halaman di bagian bawah.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        DesaKitaColors.background,
                        DesaKitaColors.background.withValues(alpha: 0.85),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.15, 0.45],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                top: (topPadding > 0 ? topPadding : 24) + 40,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mau liburan kemana\nhari ini?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: DesaKitaColors.text,
                        shadows: const [
                          Shadow(
                            color: Color(0x33000000),
                            blurRadius: 8,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ceritakan keinginanmu, biar aku bantu wujudkan!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: DesaKitaColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        shadows: const [
                          Shadow(
                            color: Color(0x24000000),
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Pill input menggantung di batas bawah hero
        Positioned(
          left: 16,
          right: 16,
          bottom: -26,
          child: _buildDashboardInputPill(),
        ),
      ],
    );
  }

  Widget _buildDashboardInputPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Mulai Obrolan Sekarang..',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.grey[400],
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (value) {
                _inputController.text = value;
                _enterChat(presetPrompt: value);
              },
            ),
          ),
          const SizedBox(width: 8),
          _CircleMiniButton(
            icon: Icons.graphic_eq_rounded,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Pencarian suara belum tersedia pada versi demo ini.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _CircleMiniButton(
            icon: Icons.send_rounded,
            onTap: () => _enterChat(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionPanel() {
    final actions = <_AiQuickAction>[
      _AiQuickAction(
        label: 'Pemandu\nWisata',
        icon: Icons.hiking_rounded,
        prompt: 'Rekomendasikan tempat wisata populer',
      ),
      _AiQuickAction(
        label: 'Rencana\nRute',
        icon: Icons.route_rounded,
        prompt: 'Bantu buat rencana rute perjalanan',
      ),
      _AiQuickAction(
        label: 'Radar\nUMKM',
        icon: Icons.radar_rounded,
        prompt: 'Tunjukkan UMKM lokal terbaik',
      ),
      _AiQuickAction(
        label: 'Pusat\nBantuan',
        icon: Icons.support_agent_rounded,
        prompt: 'Bagaimana cara memesan tiket?',
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4EC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: actions.map((action) {
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _enterChat(presetPrompt: action.prompt),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            DesaKitaColors.primary,
                            DesaKitaColors.darkGreen,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: DesaKitaColors.primary.withValues(
                              alpha: 0.28,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(action.icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: DesaKitaColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Riwayat',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: DesaKitaColors.text,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _sessions.isEmpty
                          ? 'Belum ada riwayat obrolan.'
                          : 'Semua riwayat (${_sessions.length} obrolan) sudah tampil di halaman ini.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: DesaKitaColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_sessions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DesaKitaColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: DesaKitaColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Belum ada riwayat obrolan. Mulai bertanya dan percakapanmu akan tersimpan di sini.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: DesaKitaColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._sessions.map(
              (session) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openSession(session),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: DesaKitaColors.divider),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: DesaKitaColors.text,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatIndonesianDate(session.time),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: DesaKitaColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: DesaKitaColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Kembali ke dashboard KITA AI
          IconButton(
            tooltip: 'Kembali',
            onPressed: _backToDashboard,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: DesaKitaColors.text,
              size: 22,
            ),
          ),
          const SizedBox(width: 2),

          // Avatar bot
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [DesaKitaColors.primary, DesaKitaColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: DesaKitaColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
          ),

          const SizedBox(width: 12),

          // Nama & status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kita AI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DesaKitaColors.text,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Mode demo • Data aplikasi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tombol hapus riwayat
          IconButton(
            onPressed: _messages.isEmpty ? null : _confirmClearChat,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: _messages.isEmpty ? Colors.grey[300] : Colors.grey[500],
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty State ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [DesaKitaColors.primary, DesaKitaColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: DesaKitaColors.primary.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 16),
          Text(
            'Halo! Saya Kita 👋',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DesaKitaColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Asisten perjalanan DesaKita\nberbasis data katalog saat ini',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Chat Area ─────────────────────────────────────────────────────────────

  Widget _buildChatArea() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isTyping && index == _messages.length) {
          return _TypingIndicator();
        }
        return _MessageBubble(message: _messages[index]);
      },
    );
  }

  // ─── Suggestions ───────────────────────────────────────────────────────────

  Widget _buildSuggestions() {
    return Container(
      color: const Color(0xFFF9FAF7),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mulai dari sini',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _sendMessage(
                    _suggestions[index]
                        .replaceAll(RegExp(r'[^\w\s]'), '')
                        .trim(),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFDDE8D0),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      _suggestions[index],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: DesaKitaColors.primary,
                        fontWeight: FontWeight.w500,
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

  // ─── Input Bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAF7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _inputController,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Tanyakan sesuatu...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Tombol kirim
          GestureDetector(
            onTap: () => _sendMessage(_inputController.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [DesaKitaColors.primary, DesaKitaColors.darkGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: DesaKitaColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Confirm Clear ─────────────────────────────────────────────────────────

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Percakapan',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: DesaKitaColors.text,
          ),
        ),
        content: Text(
          'Semua riwayat chat akan dihapus. Lanjutkan?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
                _showSuggestions = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesaKitaColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chat Message Model ───────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  _ChatMessage({required this.text, required this.isUser})
    : time = DateTime.now();
}

// ─── Dashboard Models & Widgets ───────────────────────────────────────────────

/// Arsip percakapan pada dashboard KITA AI (in-memory).
class _ChatSession {
  final String title;
  final DateTime time;
  final List<_ChatMessage> messages;

  const _ChatSession({
    required this.title,
    required this.time,
    required this.messages,
  });
}

class _AiQuickAction {
  final String label;
  final IconData icon;
  final String prompt;

  const _AiQuickAction({
    required this.label,
    required this.icon,
    required this.prompt,
  });
}

class _CircleMiniButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleMiniButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [DesaKitaColors.primary, DesaKitaColors.darkGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: DesaKitaColors.primary.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

/// Lanskap ilustratif hero dashboard: langit krem, awan, bukit, pinus, padang.
class _AiScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Langit
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF7EBD8), Color(0xFFF3F1E0), Color(0xFFE7F1DA)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    // Awan
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.85);
    void drawCloud(double cx, double cy, double s) {
      canvas.drawCircle(Offset(cx * w, cy * h), 14 * s, cloud);
      canvas.drawCircle(Offset(cx * w + 16 * s, cy * h + 4 * s), 10 * s, cloud);
      canvas.drawCircle(Offset(cx * w - 16 * s, cy * h + 5 * s), 9 * s, cloud);
    }

    drawCloud(0.16, 0.10, 1.0);
    drawCloud(0.82, 0.07, 0.8);
    drawCloud(0.62, 0.16, 0.55);

    // Bukit belakang
    final farHill = Paint()..color = const Color(0xFFA9C48C);
    final farPath = Path()
      ..moveTo(0, h * 0.52)
      ..quadraticBezierTo(w * 0.22, h * 0.34, w * 0.48, h * 0.50)
      ..quadraticBezierTo(w * 0.72, h * 0.36, w, h * 0.48)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(farPath, farHill);

    // Bukit depan
    final nearHill = Paint()..color = const Color(0xFF8FB877);
    final nearPath = Path()
      ..moveTo(0, h * 0.62)
      ..quadraticBezierTo(w * 0.30, h * 0.48, w * 0.62, h * 0.62)
      ..quadraticBezierTo(w * 0.84, h * 0.52, w, h * 0.60)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(nearPath, nearHill);

    // Deretan pinus kecil di punggung bukit
    final pine = Paint()..color = const Color(0xFF5E8C53);
    void drawPine(double cx, double cy, double s) {
      final base = Path()
        ..moveTo(cx * w, cy * h - 18 * s)
        ..lineTo(cx * w - 7 * s, cy * h)
        ..lineTo(cx * w + 7 * s, cy * h)
        ..close();
      canvas.drawPath(base, pine);
    }

    drawPine(0.08, 0.66, 1.1);
    drawPine(0.16, 0.70, 0.8);
    drawPine(0.26, 0.68, 1.0);
    drawPine(0.74, 0.68, 1.0);
    drawPine(0.84, 0.71, 0.8);
    drawPine(0.93, 0.66, 1.1);

    // Padang rumput depan
    final grass = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFBEE09A), Color(0xFFA9D483)],
      ).createShader(Rect.fromLTWH(0, h * 0.72, w, h * 0.28));
    final grassPath = Path()
      ..moveTo(0, h * 0.78)
      ..quadraticBezierTo(w * 0.5, h * 0.70, w, h * 0.78)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(grassPath, grass);
  }

  @override
  bool shouldRepaint(covariant _AiScenePainter oldDelegate) => false;
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar bot
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [DesaKitaColors.primary, DesaKitaColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? DesaKitaColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildMessageText(message.text, isUser),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.time),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),

          // Spacer untuk user
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageText(String text, bool isUser) {
    // Parse **bold** sederhana
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontWeight: i.isOdd ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: isUser ? Colors.white : const Color(0xFF1A1A1A),
          height: 1.5,
        ),
        children: spans,
      ),
    );
  }
}

// ─── Typing Indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      )..repeat(reverse: true),
    );

    _animations = List.generate(
      3,
      (i) => Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.easeInOut),
      ),
    );

    // Delay antar titik
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar bot
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [DesaKitaColors.primary, DesaKitaColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),

          // Bubble typing
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _animations[i],
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _animations[i].value),
                      child: Container(
                        width: 7,
                        height: 7,
                        margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: DesaKitaColors.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
