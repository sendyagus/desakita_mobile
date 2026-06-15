import 'dart:async';

import 'package:flutter/material.dart';
import 'package:desa_wisata/app/app_assets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:desa_wisata/services/groq_service.dart';
import 'package:desa_wisata/services/web_speech_service.dart';
import 'package:desa_wisata/services/destination_context_service.dart';
import 'package:desa_wisata/features/agent/models/chat_message.dart';
import 'package:desa_wisata/features/agent/widgets/typing_indicator.dart';
import 'package:desa_wisata/widgets/agent_chat_header.dart';
import 'package:desa_wisata/widgets/agent_empty_state.dart';
import 'package:desa_wisata/widgets/agent_suggestions.dart';
import 'package:desa_wisata/widgets/agent_input_bar.dart';

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
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _showSuggestions = true;
  String? _speechLocaleId;
  List<String> _availableSpeechLocales = [];
  double _soundLevel = 0;
  String? _speechHint;
  Timer? _speechAutoSubmitTimer;
  String _lastAutoSubmitCandidate = '';

  static const Duration _speechAutoSubmitDelay = Duration(milliseconds: 1500);

  // Services
  final GroqService _groqService = GroqService();
  final DestinationContextService _contextService = DestinationContextService();
  final List<Map<String, String>> _chatHistory = [];

  // Speech to Text
  final stt.SpeechToText _speech = stt.SpeechToText();
  WebSpeechService? _webSpeech;
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isWebSpeechSupported = false;

  // Text to Speech
  final FlutterTts _flutterTts = FlutterTts();
  bool _isTtsActive = true; // Global auto-read toggle
  bool _isSpeaking = false;
  String? _currentlySpeakingText;

  // TTS dibuat sedikit lebih cepat dari default sebelumnya (0.45)
  // agar respons agent terasa natural dan tidak membuat pengguna menunggu lama.
  static const String _ttsLanguage = 'id-ID';
  static const double _ttsSpeechRate = 0.58;
  static const double _ttsPitch = 1.03;
  static const double _ttsVolume = 1.0;

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
    _contextService.initialize();

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
    _speechAutoSubmitTimer?.cancel();
    _flutterTts.stop();
    if (kIsWeb) {
      _webSpeech?.cancel();
    } else {
      _speech.stop();
    }
    super.dispose();
  }

  // ─── Speech to Text Initialization ─────────────────────────────────────────

  Future<void> _initSpeech() async {
    if (kIsWeb) {
      _initWebSpeech();
      return;
    }
    try {
      _speechEnabled = await _speech.initialize(
        debugLogging: kDebugMode,
        onStatus: (status) {
          debugPrint('🎤 STT status: $status');
          if (status == stt.SpeechToText.listeningStatus) {
            if (mounted) {
              setState(() {
                _speechHint = 'Mendengarkan… silakan bicara';
              });
            }
          }
          if (status == stt.SpeechToText.notListeningStatus ||
              status == stt.SpeechToText.doneStatus) {
            if (mounted) {
              setState(() {
                _isListening = false;
                _soundLevel = 0;
                _speechHint = null;
              });
            }
            _pulseController.stop();
          }
        },
        onError: (errorNotification) {
          debugPrint(
            '🎤 STT error: ${errorNotification.errorMsg} '
            '(${errorNotification.permanent})',
          );
          if (mounted) {
            setState(() {
              _isListening = false;
              _soundLevel = 0;
              _speechHint = null;
            });
            _showSpeechSnackBar(
              _mapSpeechError(errorNotification.errorMsg),
              action: errorNotification.errorMsg == 'error_permission'
                  ? SnackBarAction(
                      label: 'Pengaturan',
                      textColor: Colors.white,
                      onPressed: openAppSettings,
                    )
                  : null,
            );
          }
          _pulseController.stop();
        },
      );

      if (_speechEnabled) {
        final locales = await _speech.locales();
        _availableSpeechLocales = locales.map((l) => l.localeId).toList();
        _speechLocaleId = _pickSpeechLocale(_availableSpeechLocales);
        debugPrint('🎤 [AgentScreen] STT locales: $_availableSpeechLocales');
        debugPrint('🎤 [AgentScreen] STT locale picked: $_speechLocaleId');
      } else {
        debugPrint('⚠️ [AgentScreen] STT initialize returned false');
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error STT initialization: $e');
    }
  }

  void _initWebSpeech() {
    _webSpeech = WebSpeechService(
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() {
          _inputController.text = text;
          _inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: _inputController.text.length),
          );
          if (text.isNotEmpty) {
            _speechHint = 'Mendengar: "$text"';
          }
        });
        _scheduleSpeechAutoSubmit(text, submitImmediately: isFinal);
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _soundLevel = 0;
          _speechHint = null;
        });
        _pulseController.stop();
        _showSpeechSnackBar(_mapWebSpeechError(error));
      },
      onStatusChange: (isListening) {
        if (!mounted) return;
        setState(() {
          _isListening = isListening;
          if (!isListening) {
            _soundLevel = 0;
            _speechHint = null;
            _pulseController.stop();
          }
        });
      },
    );
    _isWebSpeechSupported = _webSpeech!.isSupported;
    _speechEnabled = _isWebSpeechSupported;
  }

  String _mapWebSpeechError(String code) {
    switch (code) {
      case 'not-allowed':
      case 'permission-denied':
        return 'Izin mikrofon ditolak browser. Harap ijinkan mic di alamat bar browser Anda.';
      case 'no-speech':
        return 'Suara tidak terdeteksi. Coba bicara lebih dekat ke mikrofon.';
      case 'audio-capture':
        return 'Gagal mengakses mikrofon browser Anda.';
      case 'network':
        return 'Pengenalan suara gagal karena koneksi internet lambat / putus.';
      case 'service-not-allowed':
        return 'Fitur Web Speech diblokir browser. Di Brave/Edge, pastikan pengaturan Web Speech API aktif.';
      case 'unsupported_browser':
        return 'Browser Anda tidak mendukung Speech Recognition. Gunakan Chrome, Edge, atau Safari.';
      default:
        return 'Gagal mendeteksi suara ($code).';
    }
  }

  String _pickSpeechLocale(List<String> localeIds) {
    const preferred = ['id-ID', 'id_ID', 'in-ID', 'in_ID', 'id-IN'];
    for (final pref in preferred) {
      if (localeIds.contains(pref)) return pref;
    }
    for (final id in localeIds) {
      if (id.toLowerCase().startsWith('id')) return id;
    }
    return localeIds.isNotEmpty ? localeIds.first : 'id-ID';
  }

  String _mapSpeechError(String? code) {
    switch (code) {
      case 'error_no_match':
        return 'Suara tidak terdeteksi. Coba bicara lebih dekat ke mikrofon.';
      case 'error_speech_timeout':
        return 'Waktu bicara habis. Tap mic dan coba lagi.';
      case 'error_permission':
        return 'Izin mikrofon/pengenalan suara ditolak. Aktifkan di Pengaturan.';
      case 'error_network':
      case 'error_network_timeout':
        return 'Pengenalan suara membutuhkan koneksi internet.';
      case 'error_language_not_supported':
      case 'error_language_unavailable':
        return 'Bahasa Indonesia belum tersedia. Install Google app & voice data.';
      case 'error_busy':
        return 'Pengenal suara sedang sibuk. Tunggu sebentar lalu coba lagi.';
      case 'error_audio_error':
        return 'Gagal mengakses mikrofon. Tutup app lain yang memakai mic.';
      default:
        return 'Gagal mendeteksi suara${code != null ? ' ($code)' : ''}.';
    }
  }

  void _showSpeechSnackBar(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 12)),
        backgroundColor: Colors.orange[800],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: action,
      ),
    );
  }

  Future<bool> _ensureSpeechPermissions() async {
    if (kIsWeb) {
      // Di web, izin mic ditangani browser secara native saat start() dipanggil.
      return true;
    }

    var micStatus = await Permission.microphone.status;
    if (micStatus.isDenied || micStatus.isLimited) {
      micStatus = await Permission.microphone.request();
    }
    if (micStatus.isPermanentlyDenied) {
      _showSpeechSnackBar(
        'Izin mikrofon diblokir permanen. Buka Pengaturan untuk mengaktifkan.',
        action: SnackBarAction(
          label: 'Pengaturan',
          textColor: Colors.white,
          onPressed: openAppSettings,
        ),
      );
      return false;
    }
    if (!micStatus.isGranted) {
      _showSpeechSnackBar('Izin mikrofon diperlukan untuk fitur suara.');
      return false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      var speechStatus = await Permission.speech.status;
      if (speechStatus.isDenied || speechStatus.isLimited) {
        speechStatus = await Permission.speech.request();
      }
      if (speechStatus.isPermanentlyDenied) {
        _showSpeechSnackBar(
          'Izin pengenalan suara diblokir. Aktifkan di Pengaturan iOS.',
          action: SnackBarAction(
            label: 'Pengaturan',
            textColor: Colors.white,
            onPressed: openAppSettings,
          ),
        );
        return false;
      }
      if (!speechStatus.isGranted) {
        _showSpeechSnackBar('Izin pengenalan suara diperlukan.');
        return false;
      }
    }

    if (!await _speech.hasPermission) {
      _speechEnabled = await _speech.initialize(
        debugLogging: kDebugMode,
        onStatus: (status) => debugPrint('🎤 STT status: $status'),
        onError: (e) => debugPrint('🎤 STT error: ${e.errorMsg}'),
      );
      if (!_speechEnabled) {
        _showSpeechSnackBar(
          'Pengenalan suara tidak tersedia. Aktifkan izin mic & speech.',
        );
        return false;
      }
    }

    return true;
  }

  void _scheduleSpeechAutoSubmit(
    String recognizedText, {
    bool submitImmediately = false,
  }) {
    final candidate = recognizedText.trim();
    _speechAutoSubmitTimer?.cancel();

    if (candidate.isEmpty || _isTyping) {
      _lastAutoSubmitCandidate = '';
      return;
    }

    _lastAutoSubmitCandidate = candidate;

    if (submitImmediately) {
      _submitSpeechInput(candidate);
      return;
    }

    _speechAutoSubmitTimer = Timer(_speechAutoSubmitDelay, () {
      _submitSpeechInput(_lastAutoSubmitCandidate);
    });
  }

  Future<void> _submitSpeechInput(String text) async {
    final message = text.trim();
    if (!mounted || message.isEmpty || _isTyping) return;

    _speechAutoSubmitTimer?.cancel();
    _lastAutoSubmitCandidate = '';

    if (kIsWeb) {
      _webSpeech?.stop();
    } else if (_speech.isListening) {
      await _speech.stop();
    }

    if (!mounted) return;
    setState(() {
      _isListening = false;
      _soundLevel = 0;
      _speechHint = null;
      _inputController.text = message;
      _inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: _inputController.text.length),
      );
    });
    _pulseController.stop();
    _sendMessage(message);
  }

  Future<bool> _beginListen({String? localeId}) async {
    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        onSoundLevelChange: (level) {
          if (!mounted) return;
          setState(() {
            _soundLevel = level;
          });
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          partialResults: true,
          cancelOnError: false,
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 5),
          localeId: localeId,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 400));
      final active = _speech.isListening;
      debugPrint(
        '🎤 [AgentScreen] listen started=$active locale=${localeId ?? 'system'}',
      );
      return active;
    } catch (e) {
      debugPrint('🎤 [AgentScreen] listen exception: $e');
      return false;
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      _inputController.text = result.recognizedWords;
      _inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: _inputController.text.length),
      );
      if (result.recognizedWords.isNotEmpty) {
        _speechHint = 'Mendengar: "${result.recognizedWords}"';
      }
    });

    _scheduleSpeechAutoSubmit(
      result.recognizedWords,
      submitImmediately: result.finalResult,
    );
  }

  void _startListening() async {
    if (_isTyping) return;

    if (_isSpeaking) {
      await _stopTts();
    }
    if (kIsWeb) {
      if (_webSpeech == null || !_webSpeech!.isSupported) {
        _showSpeechSnackBar(
          'Browser Anda tidak mendukung Speech Recognition atau fitur diblokir.',
        );
        return;
      }
      _inputController.clear();
      setState(() {
        _isListening = true;
        _speechHint = 'Mendengarkan… silakan bicara';
        _soundLevel = 0;
      });
      _pulseController.repeat(reverse: true);
      _webSpeech!.start();
      return;
    }

    // Android/iOS mobile logic
    if (!await _ensureSpeechPermissions()) return;

    if (!_speechEnabled) {
      await _initSpeech();
      if (!_speechEnabled) {
        _showSpeechSnackBar(
          'Pengenalan suara tidak tersedia di perangkat ini.',
        );
        return;
      }
    }

    _inputController.clear();
    _speechAutoSubmitTimer?.cancel();
    _lastAutoSubmitCandidate = '';

    setState(() {
      _isListening = true;
      _speechHint = 'Menyiapkan mikrofon…';
      _soundLevel = 0;
    });
    _pulseController.repeat(reverse: true);

    var started = await _beginListen(localeId: _speechLocaleId);

    if (!started && _speechLocaleId != null) {
      debugPrint('🎤 [AgentScreen] Retry listen with system locale');
      await _speech.cancel();
      started = await _beginListen(localeId: null);
    }

    if (!started) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _speechHint = null;
        });
      }
      _pulseController.stop();
      _showSpeechSnackBar(
        'Tidak bisa memulai mikrofon. Pastikan Google app terpasang '
        '(Android) dan voice data Bahasa Indonesia sudah diunduh.',
      );
    }
  }

  void _stopListening() async {
    _speechAutoSubmitTimer?.cancel();

    setState(() {
      _speechHint = 'Sedang memproses suara…';
    });

    if (kIsWeb) {
      _webSpeech?.stop();
    } else {
      await _speech.stop();
    }

    if (mounted) {
      setState(() {
        _isListening = false;
        _soundLevel = 0;
        // Beri jeda sedikit agar perubahan status terlihat, lalu hilangkan hint
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() {
              _speechHint = null;
            });
          }
        });
      });
    }
    _pulseController.stop();
  }

  // ─── Text to Speech Initialization ─────────────────────────────────────────

  void _initTts() async {
    await _flutterTts.stop();
    await _flutterTts.awaitSpeakCompletion(true);

    if (!kIsWeb) {
      await _flutterTts.setSharedInstance(true);
    }

    await _flutterTts.setLanguage(_ttsLanguage);
    await _flutterTts.setSpeechRate(_ttsSpeechRate);
    await _flutterTts.setPitch(_ttsPitch);
    await _flutterTts.setVolume(_ttsVolume);

    await _selectIndonesianSoftVoice();

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

  Future<void> _selectIndonesianSoftVoice() async {
    if (kIsWeb) return;

    try {
      final voicesDynamic = await _flutterTts.getVoices;
      if (voicesDynamic is! List) return;

      final voices = voicesDynamic.cast<dynamic>();
      final idVoices = voices
          .where((v) {
            if (v is! Map) return false;
            final locale = (v['locale'] ?? '').toString().toLowerCase();
            return locale.startsWith('id');
          })
          .cast<Map>()
          .toList();

      if (idVoices.isEmpty) {
        debugPrint(
          '🔊 [AgentScreen] Tidak ada voice id-ID, pakai default sistem',
        );
        return;
      }

      const softFemaleHints = [
        'female',
        'woman',
        'perempuan',
        'wanita',
        'soft',
        'natural',
        'wavenet',
        'neural',
        'siti',
        'nanda',
        'ara',
        'zira',
        'nova',
        'ida',
      ];

      Map<dynamic, dynamic>? selected;
      for (final hint in softFemaleHints) {
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
        '🔊 [AgentScreen] TTS voice: ${selected['name']} (${selected['locale']}) '
        'rate=$_ttsSpeechRate pitch=$_ttsPitch',
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

    await _flutterTts.setLanguage(_ttsLanguage);
    await _flutterTts.setSpeechRate(_ttsSpeechRate);
    await _flutterTts.setPitch(_ttsPitch);
    await _flutterTts.setVolume(_ttsVolume);
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

  void _addBotMessage(String text, {bool addToChatHistory = false}) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false));
    });
    if (addToChatHistory) {
      _chatHistory.add({'role': 'assistant', 'content': text});
    }
    _scrollToBottom();
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping) return;

    final userText = text.trim();

    setState(() {
      _messages.add(ChatMessage(text: userText, isUser: true));
      _isTyping = true;
      _showSuggestions = false;
    });
    _inputController.clear();
    _scrollToBottom();

    // Hentikan suara jika sedang memutar saat mengirim pesan baru
    if (_isSpeaking) {
      await _stopTts();
    }

    // Tambah ke riwayat chat
    _chatHistory.add({'role': 'user', 'content': userText});

    // Cari konteks destinasi/event yang relevan dari database aplikasi
    final contextData = _contextService.searchRelevantContext(userText);
    debugPrint('🔍 [AgentScreen] Context found:\n$contextData');

    final result = await _groqService.generateResponseWithContext(
      _chatHistory,
      contextData,
    );

    if (!mounted) return;

    if (result.success) {
      _chatHistory.add({'role': 'assistant', 'content': result.text});

      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(text: result.text, isUser: false));
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
        '❌ [AgentScreen] AI error: ${result.errorDetail ?? result.text}',
      );
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(text: result.text, isUser: false, isError: true),
        );
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
          AgentChatHeader(
            isTtsActive: _isTtsActive,
            messagesEmpty: _messages.isEmpty,
            onToggleTts: () {
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
                        ? 'Suara respons otomatis aktif \uD83D\uDD0A'
                        : 'Suara respons otomatis dinonaktifkan \uD83D\uDD07',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            onClearChat: _confirmClearChat,
          ),

          // Area chat
          Expanded(
            child: _messages.isEmpty
                ? const AgentEmptyState()
                : _buildChatArea(),
          ),

          // Suggestions (hanya tampil di awal)
          if (_showSuggestions && _messages.isNotEmpty)
            AgentSuggestions(
              suggestions: _suggestions,
              onSuggestionTap: _sendMessage,
            ),

          // Input bar
          SafeArea(
            top: false,
            child: AgentInputBar(
              textController: _inputController,
              focusNode: _inputFocusNode,
              isListening: _isListening,
              isTyping: _isTyping,
              speechEnabled: _speechEnabled,
              soundLevel: _soundLevel,
              speechHint: _speechHint,
              pulseAnimation: _pulseController,
              onStartListening: _startListening,
              onStopListening: _stopListening,
              onSendMessage: _sendMessage,
              onShowNoSpeechSupport: () => _showSpeechSnackBar(
                kIsWeb
                    ? 'Browser Anda tidak mendukung Speech Recognition atau fitur diblokir.'
                    : 'Fitur suara tidak tersedia di perangkat ini.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header, EmptyState, Suggestions, dan InputBar diekstrak ke widgets/


  // ─── Chat Area ─────────────────────────────────────────────────────────────

  Widget _buildChatArea() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isTyping && index == _messages.length) {
          return const TypingIndicator();
        }
        final message = _messages[index];
        final isSpeakingThis =
            _isSpeaking && _currentlySpeakingText == message.text;
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

  // ─── Confirm Clear ─────────────────────────────────────────────────────────

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Percakapan',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        content: Text(
          'Semua riwayat chat akan dihapus. Lanjutkan?',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
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
                _chatHistory.clear();
                _showSuggestions = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5016),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(AppAssets.kitaAiIcon, fit: BoxFit.cover),
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
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildMessageText(
                    message.text,
                    isUser,
                    isError: isError,
                  ),
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
    var formattedText = text
        .replaceAll('\n* ', '\n• ')
        .replaceAll('\n- ', '\n• ');
    if (formattedText.startsWith('* ')) {
      formattedText = '• ${formattedText.substring(2)}';
    } else if (formattedText.startsWith('- ')) {
      formattedText = '• ${formattedText.substring(2)}';
    }

    // Parse **bold** sederhana
    final spans = <TextSpan>[];
    final parts = formattedText.split('**');
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
