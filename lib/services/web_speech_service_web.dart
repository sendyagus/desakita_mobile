import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Service native untuk Web Speech API Recognition di Flutter Web.
///
/// Menggunakan `dart:js_interop` + `package:web` (modern Dart 3.x interop),
/// bukan `dart:js` yang sudah deprecated.
///
/// Mendukung:
/// - Bahasa Indonesia (`id-ID`)
/// - Continuous listening
/// - Interim results (partial transcription)
/// - Error handling & permission handling
/// - Chrome, Edge, Brave, Safari
class WebSpeechService {
  web.SpeechRecognition? _recognition;
  bool _isListening = false;

  final Function(String text, bool isFinal) onResult;
  final Function(String error) onError;
  final Function(bool isListening) onStatusChange;

  WebSpeechService({
    required this.onResult,
    required this.onError,
    required this.onStatusChange,
  }) {
    if (kIsWeb) {
      _initRecognition();
    }
  }

  void _initRecognition() {
    try {
      // Coba buat SpeechRecognition (Chrome / Edge / Brave / Safari)
      _recognition = _createSpeechRecognition();

      if (_recognition == null) {
        debugPrint(
          '⚠️ [WebSpeechService] Browser tidak mendukung SpeechRecognition.',
        );
        return;
      }

      _recognition!.continuous = true;
      _recognition!.interimResults = true;
      _recognition!.lang = 'id-ID';

      // onstart
      _recognition!.onstart = (web.Event event) {
        _isListening = true;
        onStatusChange(true);
        debugPrint('🎤 [WebSpeechService] Started listening');
      }.toJS;

      // onend
      _recognition!.onend = (web.Event event) {
        _isListening = false;
        onStatusChange(false);
        debugPrint('🎤 [WebSpeechService] Stopped listening');
      }.toJS;

      // onerror
      _recognition!.onerror = (web.SpeechRecognitionErrorEvent event) {
        final errorCode = event.error;
        debugPrint('🌐 [WebSpeechService] Error: $errorCode');
        onError(errorCode);
      }.toJS;

      // onresult
      _recognition!.onresult = (web.SpeechRecognitionEvent event) {
        _handleResult(event);
      }.toJS;
    } catch (e) {
      debugPrint('❌ [WebSpeechService] Gagal inisialisasi: $e');
    }
  }

  /// Membuat instance SpeechRecognition dengan fallback ke webkitSpeechRecognition.
  web.SpeechRecognition? _createSpeechRecognition() {
    try {
      return web.SpeechRecognition();
    } catch (_) {
      // Beberapa browser (Brave, older Chrome) mungkin perlu webkitSpeechRecognition
      try {
        if (globalContext.hasProperty('webkitSpeechRecognition'.toJS).toDart) {
          final ctor = globalContext.getProperty(
            'webkitSpeechRecognition'.toJS,
          );
          if (ctor != null && ctor.isA<JSFunction>()) {
            final instance = (ctor as JSFunction).callAsConstructor<JSObject>();
            return instance as web.SpeechRecognition;
          }
        }
      } catch (_) {}
      return null;
    }
  }

  /// Handle SpeechRecognitionEvent results.
  void _handleResult(web.SpeechRecognitionEvent event) {
    final results = event.results;
    String finalTranscript = '';
    String interimTranscript = '';
    bool isFinalResult = false;

    for (var i = 0; i < results.length; i++) {
      final result = results.item(i);
      final alternative = result.item(0);
      final transcript = alternative.transcript;
      final isResultFinal = result.isFinal;

      if (isResultFinal) {
        finalTranscript += transcript;
        isFinalResult = true;
      } else {
        interimTranscript += transcript;
      }
    }

    final combined = finalTranscript.isNotEmpty
        ? finalTranscript
        : interimTranscript;

    onResult(combined, isFinalResult);
  }

  /// Apakah browser saat ini mendukung Web Speech API.
  bool get isSupported {
    if (!kIsWeb) return false;
    return _recognition != null;
  }

  /// Apakah sedang mendengarkan.
  bool get isListening => _isListening;

  /// Mulai merekam / mendengarkan suara.
  void start() {
    if (!isSupported) {
      onError('unsupported_browser');
      return;
    }
    try {
      _recognition!.start();
    } catch (e) {
      debugPrint('❌ [WebSpeechService] Gagal memulai: $e');
      onError(e.toString());
    }
  }

  /// Hentikan perekaman dan proses hasil akhir.
  void stop() {
    try {
      _recognition?.stop();
    } catch (e) {
      debugPrint('❌ [WebSpeechService] Gagal menghentikan: $e');
    }
  }

  /// Membatalkan perekaman saat ini secara langsung.
  void cancel() {
    try {
      _recognition?.abort();
    } catch (e) {
      debugPrint('❌ [WebSpeechService] Gagal membatalkan: $e');
    }
  }
}
