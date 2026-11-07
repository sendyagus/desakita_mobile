import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:desa_wisata/models/ai_chat_models.dart';
import 'package:desa_wisata/screens/kita_ai_voice_screen.dart';
import 'package:desa_wisata/screens/ticket_booking_screen.dart';
import 'package:desa_wisata/services/ai_agent_service.dart';
import 'package:desa_wisata/services/trip_plan_service.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';
import 'package:desa_wisata/widgets/ai_chat_cards.dart';
import 'package:desa_wisata/widgets/kita_ai_mascot.dart';

/// GIF animasi maskot KITA AI (lanskap lengkap: langit, bukit, robot).
const String _kMascotGif = 'assets/img/kita_ai_mascot.gif';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key, this.initialPrompt});

  /// Bila diisi (mis. dari "Aksi Cepat" di Beranda), langsung masuk mode chat
  /// dan mengirim prompt ini sebagai pesan pertama.
  final String? initialPrompt;

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _listening = false;
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

  /// Destinasi yang ditambahkan user lewat tombol "Tambahkan ke Rencana".
  final List<Map<String, dynamic>> _planned = [];

  @override
  void initState() {
    super.initState();
    final prompt = widget.initialPrompt;
    if (prompt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _enterChat(presetPrompt: prompt);
      });
    }
  }

  void _enterChat({String? presetPrompt}) {
    setState(() {
      _showDashboard = false;
      if (_messages.isEmpty) {
        _messages.add(
          _ChatMessage(
            text:
                'Halo! Saya **Kita AI**, pendamping perjalanan DesaKita.\n\n'
                'Saya bisa merekomendasikan tempat wisata dari katalog, '
                'menyusun jadwal kegiatan (itinerary) sesuai budget, dan '
                'membantu kamu memesan tiket destinasi.',
            isUser: false,
          ),
        );
      }
    });
    if (presetPrompt != null) _sendMessage(presetPrompt);
  }

  /// Buka layar percakapan suara KITA AI (layar penuh, mode demo • data aplikasi
  /// yang sama dengan chat teks).
  Future<void> _openVoiceMode() async {
    if (_listening) await _toggleMic(); // hentikan diktasi inline dulu
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KitaAiVoiceScreen()),
    );
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

    final reply = await AiAgentService.instance.respond(message);
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(
        _ChatMessage(
          text: reply.text,
          isUser: false,
          attachment: reply.attachment,
        ),
      );
    });
    _scrollToBottom();
  }

  // ---------------- aksi pada kartu rekomendasi & itinerary ----------------

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _addToPlan(Map<String, dynamic> place) {
    setState(() => _planned.add(place));
    _toast(
      'Ditambahkan ke rencana: ${place['name']} (${_planned.length} tujuan)',
    );
  }

  /// Buka alur pesan tiket untuk destinasi pada kartu/itinerary.
  /// Itinerary yang sedang tampil ikut diteruskan agar tersimpan sebagai
  /// "Susunan Perjalanan" setelah pemesanan berhasil.
  void _bookTicket(Map<String, dynamic> place, {AiItinerary? itinerary}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TicketBookingScreen(destination: place, itinerary: itinerary),
      ),
    );
  }

  /// Chip budget dipilih → diteruskan sebagai pertanyaan user.
  void _chooseBudget(String option) => _sendMessage('Budget $option');

  /// "Nanti" → jadwal disimpan lebih dulu dan siap tampil di halaman Trip.
  void _laterItinerary(AiItinerary itinerary) {
    final date = TripPlanService.suggestedVisitDate();
    final plan = TripPlanService.instance.planFromItinerary(
      itinerary,
      visitDate: date,
    );
    TripPlanService.instance.save(plan);
    _toast('Jadwal ${plan.destinationName} disimpan. Lihat di menu Trip.');
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
                filled: false,
                fillColor: Colors.transparent,
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
            onTap: _openVoiceMode,
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

          // Mode percakapan suara (layar penuh).
          IconButton(
            tooltip: 'Mode suara',
            onPressed: _openVoiceMode,
            icon: Icon(
              Icons.mic_rounded,
              color: DesaKitaColors.primary,
              size: 24,
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
        return _MessageBubble(
          message: _messages[index],
          onPlan: _addToPlan,
          onBook: (place) => _bookTicket(place),
          onBookItinerary: (trip) =>
              _bookTicket(trip.destination, itinerary: trip),
          onBudget: _chooseBudget,
          onLater: _laterItinerary,
        );
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Input field
            Expanded(
              child: TextField(
                controller: _inputController,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  fillColor: Colors.transparent,
                  hintText: 'Mulai Obrolan Sekarang..',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onSubmitted: (value) {
                  if (_listening) _toggleMic();
                  _sendMessage(value);
                },
              ),
            ),

            const SizedBox(width: 8),

            // Tombol input suara.
            _CircleMiniButton(
              icon: _listening ? Icons.stop_rounded : Icons.graphic_eq_rounded,
              solidColor: _listening ? Colors.red : null,
              onTap: _toggleMic,
            ),

            const SizedBox(width: 6),

            // Tombol kirim.
            _CircleMiniButton(
              icon: Icons.send_rounded,
              onTap: () {
                if (_listening) _toggleMic();
                _sendMessage(_inputController.text);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Dengarkan lalu isi kolom chat dengan hasil pengenalan suara (id_ID).
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengenalan suara tidak tersedia di perangkat ini'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _listening = true);
    _speech.listen(
      // ignore: deprecated_member_use
      localeId: 'id_ID',
      onResult: (r) {
        setState(() {
          _inputController.text = r.recognizedWords;
          _inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: _inputController.text.length),
          );
        });
      },
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

  /// Kartu rekomendasi/chip budget/itinerary di bawah bubble (khusus bot).
  final AiChatAttachment? attachment;

  _ChatMessage({required this.text, required this.isUser, this.attachment})
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
  final Color? solidColor;

  const _CircleMiniButton({
    required this.icon,
    required this.onTap,
    this.solidColor,
  });

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
            color: solidColor,
            gradient: solidColor != null
                ? null
                : const LinearGradient(
                    colors: [DesaKitaColors.primary, DesaKitaColors.darkGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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

  /// Aksi pada kartu rekomendasi & itinerary.
  final ValueChanged<Map<String, dynamic>> onPlan;
  final ValueChanged<Map<String, dynamic>> onBook;
  final ValueChanged<AiItinerary> onBookItinerary;
  final ValueChanged<String> onBudget;
  final ValueChanged<AiItinerary> onLater;

  const _MessageBubble({
    required this.message,
    required this.onPlan,
    required this.onBook,
    required this.onBookItinerary,
    required this.onBudget,
    required this.onLater,
  });

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    final bubble = Padding(
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

    final attachment = message.attachment;
    if (isUser || attachment == null) return bubble;

    // Balasan bot berkarta kaya: bubble teks lalu kartunya di bawahnya.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [bubble, _buildAttachment(attachment)],
    );
  }

  Widget _buildAttachment(AiChatAttachment attachment) {
    switch (attachment.kind) {
      case AiAttachmentKind.destinations:
        return AiDestinationCards(
          places: attachment.places,
          onPlan: onPlan,
          onBook: onBook,
        );
      case AiAttachmentKind.budgetOptions:
        return AiBudgetChips(options: attachment.options, onSelect: onBudget);
      case AiAttachmentKind.itinerary:
        final trip = attachment.itinerary!;
        return AiItineraryCard(
          itinerary: trip,
          onBook: () => onBookItinerary(trip),
          onLater: () => onLater(trip),
        );
    }
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
