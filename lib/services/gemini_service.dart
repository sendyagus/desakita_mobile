import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:desa_wisata/config/app_config.dart';

/// Hasil pemanggilan Gemini — memisahkan respons sukses dari error API.
class GeminiGenerateResult {
  final bool success;
  final String text;
  final String? errorDetail;
  final int? httpStatus;
  final bool retryable;

  const GeminiGenerateResult({
    required this.success,
    required this.text,
    this.errorDetail,
    this.httpStatus,
    this.retryable = false,
  });

  factory GeminiGenerateResult.ok(String text) =>
      GeminiGenerateResult(success: true, text: text);

  factory GeminiGenerateResult.fail({
    required String text,
    String? errorDetail,
    int? httpStatus,
    bool retryable = false,
  }) => GeminiGenerateResult(
    success: false,
    text: text,
    errorDetail: errorDetail,
    httpStatus: httpStatus,
    retryable: retryable,
  );
}

/// Service untuk memanggil Google Gemini via package `google_generative_ai`.
class GeminiService {
  static const _deprecatedModels = {
    'gemini-1.5-flash',
    'gemini-1.5-flash-latest',
    'gemini-1.5-pro',
    'gemini-1.5-pro-latest',
    'gemini-pro',
    'gemini-1.0-pro',
  };

  static const _systemInstruction =
      'Kamu adalah "Kita", asisten virtual pintar dan ramah dari aplikasi DesaKita 🌿. '
      'Tugasmu adalah membantu pengguna dengan informasi destinasi wisata desa, kuliner lokal, '
      'penginapan/homestay, acara/festival budaya, rute perjalanan, dan booking layanan di desa wisata Indonesia. '
      'Berikan jawaban yang ramah, informatif, dan ringkas dalam bahasa Indonesia. '
      'Gunakan emoji yang sesuai untuk membuat percakapan lebih menarik dan interaktif.';

  final String _modelName;
  final String _fallbackModelName;

  GeminiService()
    : _modelName = AppConfig.geminiModel.trim(),
      _fallbackModelName = AppConfig.geminiFallbackModel.trim() {
    _logStartupConfig();
  }

  String get modelName => _modelName;

  String get apiEndpoint => AppConfig.geminiGenerateContentEndpoint(_modelName);

  GenerativeModel _createModel(String modelName) => GenerativeModel(
    model: modelName,
    apiKey: AppConfig.geminiApiKey,
    systemInstruction: Content.system(_systemInstruction),
  );

  void _logStartupConfig() {
    final key = AppConfig.geminiApiKey;
    final keyStatus = key.isEmpty || key == 'YOUR_API_KEY'
        ? 'TIDAK TERKONFIGURASI'
        : 'OK (${_maskSecret(key)})';

    debugPrint('🤖 [GeminiService] Package: google_generative_ai 0.4.7');
    debugPrint('🤖 [GeminiService] API version: ${AppConfig.geminiApiVersion}');
    debugPrint('🤖 [GeminiService] Model: $_modelName');
    debugPrint('🤖 [GeminiService] Fallback: $_fallbackModelName');
    debugPrint('🤖 [GeminiService] Endpoint: $apiEndpoint');
    debugPrint('🤖 [GeminiService] API Key: $keyStatus');
  }

  /// Mengirim daftar riwayat chat ke Gemini dengan retry & fallback model.
  Future<GeminiGenerateResult> generateResponse(List<Content> history) async {
    if (AppConfig.geminiApiKey.isEmpty ||
        AppConfig.geminiApiKey == 'YOUR_API_KEY') {
      const msg =
          '⚠️ Kunci API Gemini belum dikonfigurasi.\n\n'
          'Atur GEMINI_API_KEY melalui:\n'
          '`flutter run --dart-define=GEMINI_API_KEY=your_key`';
      debugPrint('❌ [GeminiService] $msg');
      return GeminiGenerateResult.fail(
        text: msg,
        errorDetail: 'API key missing',
      );
    }

    if (_deprecatedModels.contains(_modelName)) {
      final msg =
          '⚠️ Model Gemini "$_modelName" sudah tidak tersedia (shutdown).\n\n'
          'Gunakan model terbaru, misalnya `gemini-2.5-flash`.';
      debugPrint('❌ [GeminiService] $msg');
      return GeminiGenerateResult.fail(
        text: msg,
        errorDetail: 'Deprecated model: $_modelName',
        httpStatus: 404,
      );
    }

    debugPrint(
      '📤 [GeminiService] generateContent → model=$_modelName, '
      'historyLength=${history.length}',
    );

    final modelsToTry = <String>{
      _modelName,
      if (_fallbackModelName.isNotEmpty && _fallbackModelName != _modelName)
        _fallbackModelName,
    };

    GeminiGenerateResult? lastResult;

    for (final modelName in modelsToTry) {
      for (var attempt = 1; attempt <= AppConfig.geminiMaxRetries; attempt++) {
        debugPrint(
          '🔄 [GeminiService] Attempt $attempt/${AppConfig.geminiMaxRetries} '
          'model=$modelName',
        );

        lastResult = await _callModel(
          _createModel(modelName),
          history,
          modelName,
        );

        if (lastResult.success) {
          if (modelName != _modelName) {
            debugPrint(
              '✅ [GeminiService] Fallback model "$modelName" berhasil',
            );
          }
          return lastResult;
        }

        final shouldRetry =
            lastResult.retryable && attempt < AppConfig.geminiMaxRetries;
        if (shouldRetry) {
          final delaySec = attempt;
          debugPrint(
            '⏳ [GeminiService] Server sibuk, retry dalam ${delaySec}s...',
          );
          await Future.delayed(Duration(seconds: delaySec));
          continue;
        }

        break;
      }
    }

    return lastResult ??
        GeminiGenerateResult.fail(
          text: 'Terjadi kesalahan tidak terduga saat menghubungi Gemini.',
          errorDetail: 'No result',
        );
  }

  Future<GeminiGenerateResult> _callModel(
    GenerativeModel model,
    List<Content> history,
    String modelName,
  ) async {
    try {
      final response = await model.generateContent(history);
      final text = response.text;

      if (text == null || text.trim().isEmpty) {
        const msg = 'Maaf, Gemini tidak mengembalikan teks respons.';
        debugPrint('⚠️ [GeminiService] Empty response from API');
        return GeminiGenerateResult.fail(
          text: msg,
          errorDetail: 'Empty candidates/text',
        );
      }

      debugPrint(
        '✅ [GeminiService] Response OK model=$modelName (${text.length} chars)',
      );
      return GeminiGenerateResult.ok(text);
    } on InvalidApiKey catch (e) {
      debugPrint('❌ [GeminiService] InvalidApiKey: $e');
      return GeminiGenerateResult.fail(
        text:
            '⚠️ API Key Gemini tidak valid.\n\n'
            'Periksa kunci di Google AI Studio dan pastikan Generative Language API aktif.',
        errorDetail: e.message,
        httpStatus: 403,
      );
    } on UnsupportedUserLocation catch (e) {
      debugPrint('❌ [GeminiService] UnsupportedUserLocation: $e');
      return GeminiGenerateResult.fail(
        text:
            '⚠️ Lokasi Anda tidak didukung untuk Gemini API.\n\n'
            'Coba VPN atau hubungi admin project Google Cloud.',
        errorDetail: e.message,
      );
    } on GenerativeAIException catch (e) {
      debugPrint('❌ [GeminiService] GenerativeAIException: $e');
      return _mapGenerativeError(e, modelName);
    } catch (e, st) {
      debugPrint('❌ [GeminiService] Unexpected error: $e\n$st');
      return GeminiGenerateResult.fail(
        text:
            'Terjadi kesalahan saat menghubungi Gemini API.\n\n'
            'Detail: $e',
        errorDetail: e.toString(),
      );
    }
  }

  GeminiGenerateResult _mapGenerativeError(
    GenerativeAIException e,
    String modelName,
  ) {
    final message = e.message;
    final lower = message.toLowerCase();
    final status = _extractHttpStatus(message);

    if (status == 503 ||
        status == 429 ||
        lower.contains('high demand') ||
        lower.contains('unavailable') ||
        lower.contains('resource exhausted')) {
      return GeminiGenerateResult.fail(
        text:
            '⚠️ Server Gemini sedang sibuk.\n\n'
            'Mohon tunggu sebentar, lalu coba kirim ulang pertanyaan Anda.',
        errorDetail: message,
        httpStatus: status ?? 503,
        retryable: true,
      );
    }

    if (lower.contains('not found') &&
        (lower.contains('gemini-1.5') || lower.contains('gemini-1.0'))) {
      return GeminiGenerateResult.fail(
        text:
            '⚠️ Model Gemini lama sudah tidak tersedia.\n\n'
            'Google telah mematikan model Gemini 1.x. '
            'Aplikasi sekarang memakai `gemini-2.5-flash`.',
        errorDetail: message,
        httpStatus: 404,
      );
    }

    if (lower.contains('not found') || lower.contains('404')) {
      return GeminiGenerateResult.fail(
        text:
            '⚠️ Model `$modelName` tidak ditemukan di API ${AppConfig.geminiApiVersion}.',
        errorDetail: message,
        httpStatus: 404,
      );
    }

    if (lower.contains('api_key_invalid') || lower.contains('api key')) {
      return GeminiGenerateResult.fail(
        text: '⚠️ API Key Gemini ditolak oleh server.',
        errorDetail: message,
        httpStatus: 403,
      );
    }

    return GeminiGenerateResult.fail(
      text:
          'Terjadi kesalahan saat menghubungi Gemini API.\n\n'
          'Pastikan koneksi internet stabil dan coba lagi.',
      errorDetail: message,
      httpStatus: status,
    );
  }

  static int? _extractHttpStatus(String message) {
    final match = RegExp(r'\[(\d{3})\]').firstMatch(message);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  static String _maskSecret(String value) {
    if (value.length <= 8) return '***';
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }
}
