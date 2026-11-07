import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:desa_wisata/models/ai_chat_models.dart';
import 'package:desa_wisata/screens/ticket_booking_screen.dart';
import 'package:desa_wisata/services/ai_agent_service.dart';
import 'package:desa_wisata/services/trip_plan_service.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';
import 'package:desa_wisata/widgets/ai_chat_cards.dart';

/// Latar penuh mode suara: GIF maskot dengan lanskap (langit, bukit, robot).
const String _kVoiceBackground = 'assets/img/kita_ai_mascot.gif';

/// Satu giliran percakapan pada mode suara.
class _VoiceTurn {
  final String text;
  final bool isUser;
  final AiChatAttachment? attachment;

  const _VoiceTurn({required this.text, required this.isUser, this.attachment});
}

/// Mode percakapan suara KITA AI.
///
/// Pengguna bicara, hasil pengenalan suara (id_ID) otomatis dikirim ke
/// [AiAgentService], lalu balasan teks + kartu rekomendasi tampil di layar.
/// Masih bisa diketik manual lewat kolom di bawah.
class KitaAiVoiceScreen extends StatefulWidget {
  const KitaAiVoiceScreen({super.key});

  @override
  State<KitaAiVoiceScreen> createState() => _KitaAiVoiceScreenState();
}

class _KitaAiVoiceScreenState extends State<KitaAiVoiceScreen>
    with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_VoiceTurn> _turns = [];

  bool _listening = false;
  bool _processing = false;
  String _heard = '';
  String? _error;

  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _wave.dispose();
    _textController.dispose();
    _scrollController.dispose();
    if (_speech.isListening) _speech.cancel();
    super.dispose();
  }

  // ─── Pengenalan suara ──────────────────────────────────────────────────────

  Future<void> _startListening() async {
    if (_listening) return;
    final ok = await _speech.initialize(onStatus: _onStatus, onError: _onError);
    if (!mounted) return;
    if (!ok) {
      setState(
        () => _error = 'Pengenalan suara tidak tersedia di perangkat ini',
      );
      return;
    }
    setState(() {
      _error = null;
      _heard = '';
      _listening = true;
    });
    await _speech.listen(
      onResult: _onResult,
      listenOptions: stt.SpeechListenOptions(
        localeId: 'id_ID',
        partialResults: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(milliseconds: 1500),
        cancelOnError: false,
      ),
    );
  }

  Future<void> _stopListening() async {
    if (!_listening) return;
    try {
      await _speech.stop();
    } catch (_) {
      // Penghentiannya tetap diperbarui lewat status 'notListening'.
    }
    if (!mounted) return;
    setState(() => _listening = false);
  }

  void _onStatus(String status) {
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      if (!_listening) return;
      setState(() => _listening = false);
      _submitTranscript();
    }
  }

  void _onError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() {
      _listening = false;
      _error = error.errorMsg.isEmpty
          ? 'Suara tidak terbaca, coba lagi'
          : 'Suara tidak terbaca: ${error.errorMsg}';
    });
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      _heard = result.recognizedWords;
      _textController.text = result.recognizedWords;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    });
    if (result.finalResult) _submitTranscript();
  }

  /// Kirim hasil bacaan suara bila ada; bila kosong cukup kembalikan ke idle.
  void _submitTranscript() {
    final text = _heard.trim();
    if (text.isEmpty) {
      setState(() => _listening = false);
      return;
    }
    _send(text);
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _processing) return;
    if (_listening) await _stopListening();

    setState(() {
      _processing = true;
      _heard = '';
      _error = null;
      _turns.add(_VoiceTurn(text: text, isUser: true));
      _textController.clear();
    });
    _scrollDown();

    final reply = await AiAgentService.instance.respond(text);
    if (!mounted) return;
    setState(() {
      _processing = false;
      _turns.add(
        _VoiceTurn(
          text: reply.text,
          isUser: false,
          attachment: reply.attachment,
        ),
      );
    });
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Aksi pada kartu balasan ───────────────────────────────────────────────

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _addToPlan(Map<String, dynamic> place) =>
      _toast('Ditambahkan ke rencana: ${place['name']}');

  void _bookTicket(Map<String, dynamic> place, {AiItinerary? itinerary}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TicketBookingScreen(destination: place, itinerary: itinerary),
      ),
    );
  }

  void _laterItinerary(AiItinerary itinerary) {
    final plan = TripPlanService.instance.planFromItinerary(
      itinerary,
      visitDate: TripPlanService.suggestedVisitDate(),
    );
    TripPlanService.instance.save(plan);
    _toast('Jadwal ${plan.destinationName} disimpan. Lihat di menu Trip.');
  }

  // ─── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesaKitaColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _kVoiceBackground,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFBFE3F7), DesaKitaColors.background],
                ),
              ),
            ),
          ),
          // Scrim halus agar teks tetap terbaca di atas gambar.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.30),
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.55),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildStatus(),
                Expanded(child: _buildTranscript()),
                _buildControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 4),
      child: Row(
        children: [
          _CircleGlassButton(
            icon: Icons.arrow_back_rounded,
            size: 38,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          ClipOval(
            child: Image.asset(
              _kVoiceBackground,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              alignment: const Alignment(0, 0.55),
              errorBuilder: (context, error, stackTrace) => Container(
                width: 36,
                height: 36,
                color: DesaKitaColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kita AI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: DesaKitaColors.text,
                  ),
                ),
                Text(
                  'Agent',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: DesaKitaColors.text,
            ),
            onSelected: (value) {
              if (value == 'clear') {
                setState(() {
                  _turns.clear();
                  _heard = '';
                  _error = null;
                });
              } else if (value == 'exit') {
                Navigator.pop(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Bersihkan sesi'),
              ),
              const PopupMenuItem(
                value: 'exit',
                child: Text('Kembali ke chat teks'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    final listening = _listening;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: Column(
        children: [
          Text(
            listening
                ? 'Mendengarkan...'
                : _processing
                ? 'KITA AI sedang menyusun jawaban...'
                : 'Ketuk tombol hijau lalu bicara',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: listening ? DesaKitaColors.primary : DesaKitaColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Apa yang bisa saya bantu hari ini?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: Colors.grey[600],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: const Color(0xFFB42318),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTranscript() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      children: [
        for (final turn in _turns) _buildTurn(turn),
        if (_processing) _buildTypingRow(),
      ],
    );
  }

  Widget _buildTurn(_VoiceTurn turn) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: turn.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: turn.isUser
                  ? DesaKitaColors.primary.withValues(alpha: 0.92)
                  : Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(turn.isUser ? 16 : 4),
                bottomRight: Radius.circular(turn.isUser ? 4 : 16),
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 8),
              ],
            ),
            child: Text(
              turn.text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.45,
                color: turn.isUser ? Colors.white : DesaKitaColors.text,
              ),
            ),
          ),
          if (turn.attachment != null && !turn.isUser) ...[
            const SizedBox(height: 8),
            _buildAttachment(turn.attachment!),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachment(AiChatAttachment attachment) {
    switch (attachment.kind) {
      case AiAttachmentKind.destinations:
        return AiDestinationCards(
          places: attachment.places,
          onPlan: _addToPlan,
          onBook: _bookTicket,
        );
      case AiAttachmentKind.budgetOptions:
        return AiBudgetChips(
          options: attachment.options,
          onSelect: (option) => _send('Budget $option'),
        );
      case AiAttachmentKind.itinerary:
        final itinerary = attachment.itinerary!;
        return AiItineraryCard(
          itinerary: itinerary,
          onBook: () =>
              _bookTicket(itinerary.destination, itinerary: itinerary),
          onLater: () => _laterItinerary(itinerary),
        );
    }
  }

  Widget _buildTypingRow() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: _PulseDot(delay: i * 160),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Column(
        children: [
          // Kolom teks: menampilkan transkrip langsung atau ketikan manual.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(color: Color(0x1A000000), blurRadius: 12),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      hintText: _listening && _heard.isEmpty
                          ? 'Bicara sekarang...'
                          : 'mulai obrolanmu dengan pemandu wisata ai',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: Colors.grey[400],
                      ),
                    ),
                    onSubmitted: (value) => _send(value),
                  ),
                ),
                _CircleGlassButton(
                  icon: _listening ? Icons.mic_off_rounded : Icons.mic_rounded,
                  size: 38,
                  color: _listening ? const Color(0xFFB42318) : null,
                  onTap: () =>
                      _listening ? _stopListening() : _startListening(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tombol utama: mulai dengar / kirim transkrip.
          GestureDetector(
            onTap: () => _listening ? _submitTranscript() : _startListening(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 66,
              height: 66,
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
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: _listening
                    ? _Waveform(controller: _wave, color: Colors.white)
                    : const Icon(
                        Icons.graphic_eq_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _listening ? 'Ketuk untuk kirim' : 'Ketuk untuk bicara',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lima batang equalizer yang berdenyut selama mode mendengarkan.
class _Waveform extends StatelessWidget {
  final AnimationController controller;
  final Color color;

  const _Waveform({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    const heights = <double>[10, 18, 26, 16, 12];
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(heights.length, (i) {
            final phase = (controller.value * 2 * math.pi) + i * 0.7;
            final t = (math.sin(phase).abs() + 1) / 2;
            return Container(
              width: 4,
              height: heights[i] * (0.45 + 0.55 * t),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

class _PulseDot extends StatefulWidget {
  final int delay;
  const _PulseDot({required this.delay});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _scale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: DesaKitaColors.primary.withValues(alpha: 0.75),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _CircleGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? color;

  const _CircleGlassButton({
    required this.icon,
    required this.onTap,
    this.size = 38,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: size * 0.5,
            color: color ?? DesaKitaColors.text,
          ),
        ),
      ),
    );
  }
}
