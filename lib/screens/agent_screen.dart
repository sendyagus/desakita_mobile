import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  final List<String> _suggestions = [
    '🏕️  Rekomendasikan tempat camping',
    '🍜  Kuliner khas desa terdekat',
    '🎭  Acara budaya bulan ini',
    '🏡  Penginapan murah di desa',
    '🗺️  Rute wisata alam terbaik',
  ];

  // Simulasi respons bot berdasarkan kata kunci
  final Map<String, String> _botResponses = {
    'camping': '''Berikut rekomendasi tempat camping terbaik di sekitar desa:\n\n🏕️ **Camp 91 Outbound** — Kemiling, 2.5 km\nFasilitas lengkap, cocok untuk keluarga.\n\n🌲 **Lembah Durian Farm** — Sukarame, 5 km\nGlamping di tengah kebun durian.\n\n⛺ **Bukit Hijau Camp** — Langkapura, 7 km\nPemandangan sunrise terbaik.\n\nMau info lebih lanjut tentang salah satunya?''',
    'kuliner': '''Kuliner khas desa yang wajib dicoba:\n\n🍜 **Mie Ayam Pak Slamet** — Buka 07.00–15.00\n📍 Jl. Desa Pujon, 1.2 km\n\n🍚 **Nasi Liwet Bu Darmi** — Buka 10.00–20.00\n📍 Pasar Desa Sade, 2.0 km\n\n🥘 **Soto Desa Mbah Karto** — Buka 06.00–12.00\n📍 Alun-alun Desa, 0.8 km\n\nSemua tempat sudah terverifikasi dan direkomendasikan warga lokal! 😊''',
    'acara': '''Acara budaya yang akan datang:\n\n🎭 **Festival Panen Raya**\n📅 24 Oktober 2025 | 08.00 – Selesai\n📍 Desa Pujon Kidul, Malang\n\n🎪 **Pasar Budaya Nusantara**\n📅 5 November 2025 | 09.00 – 17.00\n📍 Desa Sade, Lombok\n\n🎶 **Festival Kuliner Desa**\n📅 12 November 2025 | 10.00 – Selesai\n📍 Desa Penglipuran, Bali\n\nIngin saya bantu booking tiket?''',
    'penginapan': '''Penginapan terjangkau di desa:\n\n🏡 **Homestay Desa Pujon**\nMulai Rp 200.000/malam ⭐ 4.4\n\n🛖 **Jukung Villa Lampung**\nMulai Rp 450.000/malam ⭐ 4.8\n\n⛺ **Lembah Durian Farm Stable**\nMulai Rp 350.000/malam ⭐ 4.6\n\nSemua tersedia untuk booking langsung di tab Booking! 🎉''',
    'rute': '''Rute wisata alam terbaik:\n\n🗺️ **Rute Pagi (3–4 jam)**\nStart: Alun-alun Desa → Kebun Teh → Air Terjun Hijau → Bukit Panorama\n\n🌄 **Rute Seharian**\nStart: Desa Pujon → Danau Hijau → Hutan Pinus → Camp 91 → Sunset Point\n\n💡 Tips: Berangkat sebelum jam 07.00 untuk menghindari keramaian dan mendapat cahaya terbaik untuk foto!\n\nMau saya buatkan itinerary lengkap?''',
    'default': '''Halo! Saya **Kita**, asisten virtual DesaKita 🌿\n\nSaya bisa membantu kamu dengan:\n• Rekomendasi destinasi wisata desa\n• Info kuliner dan penginapan\n• Jadwal acara budaya\n• Rute perjalanan\n• Booking layanan\n\nCoba tanyakan sesuatu, atau pilih topik di bawah! 😊''',
  };

  @override
  void initState() {
    super.initState();
    // Pesan sambutan awal
    Future.delayed(const Duration(milliseconds: 400), () {
      _addBotMessage(
        'Halo! Saya **Kita**, asisten virtual DesaKita 🌿\n\nAda yang bisa saya bantu hari ini? Kamu bisa tanya soal destinasi wisata, kuliner, penginapan, atau acara budaya di desa!',
      );
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: false));
    });
    _scrollToBottom();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text.trim(), isUser: true));
      _isTyping = true;
      _showSuggestions = false;
    });
    _inputController.clear();
    _scrollToBottom();

    // Simulasi delay respons bot
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final response = _getBotResponse(text.toLowerCase());
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: response, isUser: false));
      });
      _scrollToBottom();
    });
  }

  String _getBotResponse(String input) {
    if (input.contains('camp') || input.contains('camping') ||
        input.contains('kemah')) {
      return _botResponses['camping']!;
    } else if (input.contains('kuliner') || input.contains('makan') ||
        input.contains('makanan') || input.contains('resto')) {
      return _botResponses['kuliner']!;
    } else if (input.contains('acara') || input.contains('event') ||
        input.contains('festival') || input.contains('budaya')) {
      return _botResponses['acara']!;
    } else if (input.contains('penginapan') || input.contains('hotel') ||
        input.contains('villa') || input.contains('homestay') ||
        input.contains('murah')) {
      return _botResponses['penginapan']!;
    } else if (input.contains('rute') || input.contains('jalan') ||
        input.contains('wisata') || input.contains('alam')) {
      return _botResponses['rute']!;
    } else {
      return 'Maaf, saya belum mengerti pertanyaan itu 😅\n\nCoba tanyakan tentang:\n• Tempat wisata & camping\n• Kuliner khas desa\n• Acara & festival budaya\n• Penginapan & homestay\n• Rute perjalanan';
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
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
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
          // Avatar bot
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2D5016), Color(0xFF6B9E45)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D5016).withOpacity(0.3),
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
                  'Kita — Asisten DesaKita',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
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
                      'Online • Siap membantu',
                      style: GoogleFonts.poppins(
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
                colors: [Color(0xFF2D5016), Color(0xFF6B9E45)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D5016).withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.eco_rounded,
                color: Colors.white, size: 38),
          ),
          const SizedBox(height: 16),
          Text(
            'Halo! Saya Kita 👋',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Asisten virtual DesaKita\nsiap membantu perjalananmu',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
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
      color: const Color(0xFFF5F5F0),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pertanyaan populer',
            style: GoogleFonts.poppins(
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
                  onTap: () => _sendMessage(_suggestions[index]
                      .replaceAll(RegExp(r'[^\w\s]'), '')
                      .trim()),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFDDE8D0), width: 1.2),
                    ),
                    child: Text(
                      _suggestions[index],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF2D5016),
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
                color: const Color(0xFFF5F5F0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _inputController,
                style: GoogleFonts.poppins(fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Tanyakan sesuatu...',
                  hintStyle: GoogleFonts.poppins(
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
                  colors: [Color(0xFF2D5016), Color(0xFF4A7C2F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D5016).withOpacity(0.35),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Percakapan',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        content: Text(
          'Semua riwayat chat akan dihapus. Lanjutkan?',
          style: GoogleFonts.poppins(
              fontSize: 13, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
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
              backgroundColor: const Color(0xFF2D5016),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Hapus',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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

  _ChatMessage({
    required this.text,
    required this.isUser,
  }) : time = DateTime.now();
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
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                  colors: [Color(0xFF2D5016), Color(0xFF6B9E45)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.eco_rounded,
                  color: Colors.white, size: 16),
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
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF2D5016)
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
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
                  style: GoogleFonts.poppins(
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
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          fontWeight: i.isOdd ? FontWeight.w700 : FontWeight.w400,
        ),
      ));
    }

    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
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
        CurvedAnimation(
          parent: _controllers[i],
          curve: Curves.easeInOut,
        ),
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
                colors: [Color(0xFF2D5016), Color(0xFF6B9E45)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.eco_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),

          // Bubble typing
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  color: Colors.black.withOpacity(0.06),
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
                          color: const Color(0xFF2D5016).withOpacity(0.6),
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
