import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gemini;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:desa_wisata/services/gemini_service.dart';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _showSuggestions = true;
  bool _speechSendScheduled = false;
  String? _speechLocaleId;

  // Services
  final GeminiService _geminiService = GeminiService();
  final List<gemini.Content> _geminiHistory = [];

  // Speech to Text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  // Text to Speech
  final FlutterTts _flutterTts = FlutterTts();
  bool _isTtsActive = true; // Global auto-read toggle
  bool _isSpeaking = false;
  String? _currentlySpeakingText;

  // Animation
  late final AnimationController _pulseController;

  final List<String> _suggestions = [
    '🏕️  Rekomendasikan tempat camping',
    '🍜  Kuliner khas desa terdekat',
    '🎭  Acara budaya bulan ini',
    '🏡  Penginapan murah di desa',
    '🗺️  Rute wisata alam terbaik',
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

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
    _inputFocusNode.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  // ─── Speech to Text Initialization ─────────────────────────────────────────

  void _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          debugPrint('STT status: $status');
          if (status == 'notListening' || status == 'done') {
            if (mounted) {
              setState(() {
                _isListening = false;
              });
            }
            _pulseController.stop();
          }
        },
        onError: (errorNotification) {
          debugPrint('STT error: $errorNotification');
          if (mounted) {
            setState(() {
              _isListening = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Gagal mendeteksi suara. Pastikan izin mikrofon aktif.',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                backgroundColor: Colors.orange[800],
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          _pulseController.stop();
        },
      );

      if (_speechEnabled) {
        _speechLocaleId = await _resolveSpeechLocale();
        debugPrint('🎤 [AgentScreen] STT locale: $_speechLocaleId');
      } else {
        debugPrint('⚠️ [AgentScreen] STT tidak tersedia di perangkat ini');
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error STT initialization: $e');
    }
  }

  Future<String> _resolveSpeechLocale() async {
    final locales = await _speech.locales();
    const preferred = ['id-ID', 'id_ID', 'in-ID', 'in_ID', 'id-IN'];

    for (final pref in preferred) {
      if (locales.any((l) => l.localeId == pref)) return pref;
    }

    for (final locale in locales) {
      if (locale.localeId.toLowerCase().startsWith('id')) {
        return locale.localeId;
      }
    }

    return locales.isNotEmpty ? locales.first.localeId : 'id-ID';
  }

  void _startListening() async {
    if (_isTyping) return;

    if (!kIsWeb) {
      var micStatus = await Permission.microphone.status;
      if (micStatus.isDenied || micStatus.isLimited) {
        micStatus = await Permission.microphone.request();
      }
      if (!micStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Izin mikrofon diperlukan untuk fitur suara.',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final speechStatus = await Permission.speech.status;
        if (speechStatus.isDenied) {
          await Permission.speech.request();
        }
      }
    }

    if (!_speechEnabled) {
      final success = await _speech.initialize();
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pengenalan suara tidak tersedia di perangkat ini.',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      _speechEnabled = true;
      _speechLocaleId = await _resolveSpeechLocale();
    }

    _speechSendScheduled = false;
    _inputController.clear();

    setState(() {
      _isListening = true;
    });
    _pulseController.repeat(reverse: true);

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _inputController.text = result.recognizedWords;
          _inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: _inputController.text.length),
          );
        });

        if (result.finalResult) {
          final words = result.recognizedWords.trim();
          if (words.isNotEmpty && !_speechSendScheduled) {
            _speechSendScheduled = true;
            Future.delayed(const Duration(milliseconds: 400), () {
              if (!mounted || !_speechSendScheduled) return;
              _speechSendScheduled = false;
              _finishListeningAndSend(words);
            });
          }
        }
      },
      localeId: _speechLocaleId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
      cancelOnError: false,
      listenMode: stt.ListenMode.dictation,
    );
  }

  Future<void> _finishListeningAndSend(String text) async {
    await _speech.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
    _pulseController.stop();
    if (text.trim().isNotEmpty && !_isTyping) {
      _sendMessage(text.trim());
    }
  }

  void _stopListening() async {
    final text = _inputController.text.trim();
    _speechSendScheduled = false;
    await _speech.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
    _pulseController.stop();

    if (text.isNotEmpty && !_isTyping) {
      _sendMessage(text);
    }
  }

  // ─── Text to Speech Initialization ─────────────────────────────────────────

  void _initTts() async {
    await _flutterTts.stop();
    await _flutterTts.awaitSpeakCompletion(true);

    if (!kIsWeb) {
      await _flutterTts.setSharedInstance(true);
    }

    await _flutterTts.setLanguage('id-ID');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.08);
    await _flutterTts.setVolume(1.0);

    await _selectIndonesianFemaleVoice();

    _flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = true;
        });
      }
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _currentlySpeakingText = null;
        });
      }
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _currentlySpeakingText = null;
        });
      }
      debugPrint('TTS error: $msg');
    });
  }

  Future<void> _selectIndonesianFemaleVoice() async {
    if (kIsWeb) return;

    try {
      final voicesDynamic = await _flutterTts.getVoices;
      if (voicesDynamic is! List) return;

      final voices = voicesDynamic.cast<dynamic>();
      final idVoices = voices.where((v) {
        if (v is! Map) return false;
        final locale = (v['locale'] ?? '').toString().toLowerCase();
        return locale.startsWith('id');
      }).cast<Map>().toList();

      if (idVoices.isEmpty) {
        debugPrint('🔊 [AgentScreen] Tidak ada voice id-ID, pakai default sistem');
        return;
      }

      const femaleHints = [
        'female',
        'woman',
        'perempuan',
        'gadis',
        'siti',
        'ara',
        'zira',
        'nova',
        'ida',
        'nanda',
      ];

      Map<dynamic, dynamic>? selected;
      for (final hint in femaleHints) {
        for (final voice in idVoices) {
          final name = (voice['name'] ?? '').toString().toLowerCase();
          if (name.contains(hint)) {
            selected = voice;
            break;
          }
        }
        if (selected != null) break;
      }

      selected ??= idVoices.first;

      await _flutterTts.setVoice({
        'name': selected['name'],
        'locale': selected['locale'],
      });
      debugPrint(
        '🔊 [AgentScreen] TTS voice: ${selected['name']} (${selected['locale']})',
      );
    } catch (e) {
      debugPrint('🔊 [AgentScreen] Gagal memilih voice TTS: $e');
    }
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;

    final cleanText = text
        .replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true), '')
        .replaceAll('**', '')
        .replaceAll('###', '')
        .replaceAll('##', '')
        .replaceAll('#', '')
        .replaceAll('*', '')
        .replaceAll('•', '')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleanText.isEmpty) return;

    await _flutterTts.setLanguage('id-ID');
    await _flutterTts.speak(cleanText);
  }

  Future<void> _stopTts() async {
    await _flutterTts.stop();
    setState(() {
      _isSpeaking = false;
      _currentlySpeakingText = null;
    });
  }

  Future<void> _toggleSpeakMessage(String text) async {
    if (_isSpeaking && _currentlySpeakingText == text) {
      await _stopTts();
    } else {
      await _stopTts();
      setState(() {
        _currentlySpeakingText = text;
        _isSpeaking = true;
      });
      await _speak(text);
    }
  }

  // ─── Helper Message ────────────────────────────────────────────────────────

  void _addBotMessage(String text, {bool addToGeminiHistory = false}) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: false));
    });
    if (addToGeminiHistory) {
      _geminiHistory.add(gemini.Content.model([gemini.TextPart(text)]));
    }
    _scrollToBottom();
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping) return;

    final userText = text.trim();

    setState(() {
      _messages.add(_ChatMessage(text: userText, isUser: true));
      _isTyping = true;
      _showSuggestions = false;
    });
    _inputController.clear();
    _scrollToBottom();

    // Hentikan suara jika sedang memutar saat mengirim pesan baru
    if (_isSpeaking) {
      await _stopTts();
    }

    // Tambah ke riwayat Gemini
    _geminiHistory.add(gemini.Content.text(userText));

    final result = await _geminiService.generateResponse(_geminiHistory);

    if (!mounted) return;

    if (result.success) {
      _geminiHistory.add(gemini.Content.model([gemini.TextPart(result.text)]));

      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: result.text, isUser: false));
      });
      _scrollToBottom();

      if (_isTtsActive) {
        setState(() {
          _currentlySpeakingText = result.text;
        });
        await _speak(result.text);
      }
    } else {
      debugPrint(
        '❌ [AgentScreen] Gemini error: ${result.errorDetail ?? result.text}',
      );
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: result.text,
          isUser: false,
          isError: true,
        ));
      });
      _scrollToBottom();

      if (mounted && result.errorDetail != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorDetail!,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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
      body: Column(
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
          SafeArea(
            top: false,
            child: _buildInputBar(),
          ),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
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
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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

              // Tombol Toggle TTS (Auto-Read)
              IconButton(
                onPressed: () {
                  setState(() {
                    _isTtsActive = !_isTtsActive;
                  });
                  if (!_isTtsActive) {
                    _stopTts();
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isTtsActive
                            ? 'Suara respons otomatis aktif 🔊'
                            : 'Suara respons otomatis dinonaktifkan 🔇',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: Icon(
                  _isTtsActive ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: _isTtsActive ? const Color(0xFF2D5016) : Colors.grey[400],
                  size: 22,
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
        ),
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
        final message = _messages[index];
        final isSpeakingThis = _isSpeaking && _currentlySpeakingText == message.text;
        return _MessageBubble(
          message: message,
          isCurrentlySpeaking: isSpeakingThis,
          onSpeakPressed: message.isUser || message.isError
              ? null
              : () => _toggleSpeakMessage(message.text),
        );
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
                  onTap: () {
                    final cleanText = _suggestions[index]
                        .replaceAll(RegExp(r'[^\w\s]'), '')
                        .trim();
                    _sendMessage(cleanText);
                  },
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
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                if (event.logicalKey != LogicalKeyboardKey.enter) {
                  return KeyEventResult.ignored;
                }
                if (HardwareKeyboard.instance.isShiftPressed) {
                  return KeyEventResult.ignored;
                }
                final text = _inputController.text.trim();
                if (text.isNotEmpty && !_isTyping) {
                  _sendMessage(text);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F0),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _inputController,
                  focusNode: _inputFocusNode,
                  style: GoogleFonts.poppins(fontSize: 14),
                  maxLines: 1,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'Tanyakan sesuatu... (Enter = kirim)',
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
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _sendMessage(value);
                    }
                  },
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Tombol Mic / Audio dengan Efek Detak (Pulse Animation)
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final double scale = _isListening
                    ? 1.0 + (_pulseController.value * 0.12)
                    : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? Colors.red[600] : const Color(0xFFE8F0E3),
                      boxShadow: [
                        if (_isListening)
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 10 + (_pulseController.value * 6),
                            spreadRadius: 2 + (_pulseController.value * 2),
                          )
                        else
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening ? Colors.white : const Color(0xFF2D5016),
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 8),

          // Tombol kirim
          GestureDetector(
            onTap: _isTyping
                ? null
                : () => _sendMessage(_inputController.text),
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
              _stopTts();
              setState(() {
                _messages.clear();
                _geminiHistory.clear();
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
  final bool isError;
  final DateTime time;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  }) : time = DateTime.now();
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool isCurrentlySpeaking;
  final VoidCallback? onSpeakPressed;

  const _MessageBubble({
    required this.message,
    this.isCurrentlySpeaking = false,
    this.onSpeakPressed,
  });

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isError = message.isError;

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
                        : isError
                            ? const Color(0xFFFFEBEE)
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
                  child: _buildMessageText(message.text, isUser, isError: isError),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.time),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                    if (!isUser && onSpeakPressed != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onSpeakPressed,
                        child: Icon(
                          isCurrentlySpeaking
                              ? Icons.volume_up_rounded
                              : Icons.volume_mute_rounded,
                          size: 14,
                          color: isCurrentlySpeaking
                              ? const Color(0xFF2D5016)
                              : Colors.grey[400],
                        ),
                      ),
                    ],
                  ],
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

  Widget _buildMessageText(String text, bool isUser, {bool isError = false}) {
    // Ubah bullet list asteriks (*) ke bullet bulat (•) untuk tampilan rapi
    var formattedText = text.replaceAll('\n* ', '\n• ').replaceAll('\n- ', '\n• ');
    if (formattedText.startsWith('* ')) {
      formattedText = '• ${formattedText.substring(2)}';
    } else if (formattedText.startsWith('- ')) {
      formattedText = '• ${formattedText.substring(2)}';
    }

    // Parse **bold** sederhana
    final spans = <TextSpan>[];
    final parts = formattedText.split('**');
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
          color: isUser
              ? Colors.white
              : isError
                  ? const Color(0xFFC62828)
                  : const Color(0xFF1A1A1A),
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
