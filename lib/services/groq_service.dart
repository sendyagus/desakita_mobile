import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:desa_wisata/config/app_config.dart';

/// Hasil pemanggilan Groq — memisahkan respons sukses dari error API.
class GroqResult {
  final bool success;
  final String text;
  final String? errorDetail;
  final int? httpStatus;
  final bool retryable;

  const GroqResult({
    required this.success,
    required this.text,
    this.errorDetail,
    this.httpStatus,
    this.retryable = false,
  });

  factory GroqResult.ok(String text) =>
      GroqResult(success: true, text: text);

  factory GroqResult.fail({
    required String text,
    String? errorDetail,
    int? httpStatus,
    bool retryable = false,
  }) =>
      GroqResult(
        success: false,
        text: text,
        errorDetail: errorDetail,
        httpStatus: httpStatus,
        retryable: retryable,
      );
}

/// Service untuk memanggil Groq AI via REST API (OpenAI-compatible).
///
/// Optimasi token:
/// - Hanya kirim maksimal 5 percakapan terakhir (10 messages).
/// - max_tokens dibatasi 300.
/// - temperature rendah (0.3) untuk respons fokus & singkat.
/// - System prompt menginstruksikan jawaban ringkas.
class GroqService {
  static String _getSystemPrompt(String? contextData) {
    final contextHeader = (contextData == null || contextData.isEmpty)
        ? ''
        : '\n\nDATA APLIKASI YANG RELEVAN UNTUK PERTANYAAN USER:\n'
          '=================================================\n'
          '$contextData\n'
          '=================================================\n';

    return 'Kamu adalah Kita, asisten virtual resmi aplikasi DesaKita.\n\n'
        'Aturan Wajib (PENTING):\n'
        '- HANYA rekomendasikan tempat wisata, penginapan, event, atau fasilitas yang terdaftar dalam DATA APLIKASI YANG RELEVAN di atas.\n'
        '- Jika ada tempat/kegiatan yang ditanyakan pengguna tidak ada di data di atas, jawab dengan sopan bahwa "Informasi tersebut belum tersedia di aplikasi DesaKita."\n'
        '- JANGAN mengarang informasi atau merekomendasikan tempat di luar data yang diberikan.\n'
        '- Jawab dalam bahasa Indonesia yang ramah, sopan, dan santun.\n'
        '- Maksimal 2 hingga 3 kalimat per respons untuk menghemat token.\n'
        '- Langsung ke inti jawaban tanpa basa-basi yang berlebihan.\n'
        '- Jangan mengulang pertanyaan pengguna.\n'
        '- Jangan memberikan salam pembuka/penutup yang berulang di setiap respons.\n'
        '- Jangan memberikan disclaimer atau penjelasan panjang lebar kecuali diminta secara khusus.\n'
        '- Gunakan poin-poin singkat jika diperlukan untuk keterbacaan.\n'
        '- Fokus hanya pada wisata, kuliner, penginapan, transportasi, acara budaya, dan layanan desa wisata di Kecamatan Kemiling, Bandar Lampung.\n'
        '- Jika informasi benar-benar tidak diketahui atau tidak ada di data, katakan tidak tahu atau belum tersedia secara singkat.\n'
        '$contextHeader';
  }

  /// Maksimal jumlah percakapan (pair user+assistant) yang dikirim.
  static const int _maxConversationPairs = 5;

  /// Batas token respons.
  static const int _maxTokens = 300;

  /// Temperature rendah → respons fokus, deterministik.
  static const double _temperature = 0.3;

  final String _modelName;
  final String _fallbackModelName;

  GroqService()
      : _modelName = AppConfig.groqModel.trim(),
        _fallbackModelName = AppConfig.groqFallbackModel.trim() {
    _logStartupConfig();
  }

  String get modelName => _modelName;

  void _logStartupConfig() {
    final key = AppConfig.cleanGroqApiKey;
    final keyStatus = AppConfig.isGroqConfigured
        ? 'OK (${_maskSecret(key)})'
        : 'TIDAK TERKONFIGURASI';

    debugPrint('🤖 [GroqService] Endpoint: ${AppConfig.groqEndpoint}');
    debugPrint('🤖 [GroqService] Model: $_modelName');
    debugPrint('🤖 [GroqService] Fallback: $_fallbackModelName');
    debugPrint('🤖 [GroqService] API Key: $keyStatus');
    debugPrint('🤖 [GroqService] Max pairs: $_maxConversationPairs');
    debugPrint('🤖 [GroqService] Max tokens: $_maxTokens');
  }

  /// Mengirim daftar riwayat chat ke Groq dengan retry & fallback model.
  ///
  /// [history] berupa list of maps: `{'role': 'user'|'assistant', 'content': '...'}`
  Future<GroqResult> generateResponse(
    List<Map<String, String>> history,
  ) async {
    return generateResponseWithContext(history, null);
  }

  /// Mengirim daftar riwayat chat dengan data konteks ke Groq.
  Future<GroqResult> generateResponseWithContext(
    List<Map<String, String>> history,
    String? contextData,
  ) async {
    if (!AppConfig.isGroqConfigured) {
      const msg =
          '⚠️ API Key Groq belum dikonfigurasi.\n\n'
          '1. Salin env.example.json → env.json\n'
          '2. Isi GROQ_API_KEY (dari https://console.groq.com/keys)\n'
          '3. Jalankan:\n'
          '   flutter run --dart-define-from-file=env.json';
      debugPrint('❌ [GroqService] $msg');
      return GroqResult.fail(text: msg, errorDetail: 'API key missing');
    }

    // Trim history ke maksimal _maxConversationPairs * 2 messages terakhir.
    final trimmedHistory = _trimHistory(history);

    debugPrint(
      '📤 [GroqService] Request → model=$_modelName, '
      'messages=${trimmedHistory.length + 1} (incl. system)',
    );

    // Coba model utama, lalu fallback.
    final modelsToTry = <String>{
      _modelName,
      if (_fallbackModelName.isNotEmpty && _fallbackModelName != _modelName)
        _fallbackModelName,
    };

    GroqResult? lastResult;

    for (final modelName in modelsToTry) {
      for (var attempt = 1; attempt <= AppConfig.groqMaxRetries; attempt++) {
        debugPrint(
          '🔄 [GroqService] Attempt $attempt/${AppConfig.groqMaxRetries} '
          'model=$modelName',
        );

        lastResult = await _callModel(modelName, trimmedHistory, contextData);

        if (lastResult.success) {
          if (modelName != _modelName) {
            debugPrint(
              '✅ [GroqService] Fallback model "$modelName" berhasil',
            );
          }
          return lastResult;
        }

        final shouldRetry =
            lastResult.retryable && attempt < AppConfig.groqMaxRetries;
        if (shouldRetry) {
          final delaySec = attempt;
          debugPrint(
            '⏳ [GroqService] Server sibuk, retry dalam ${delaySec}s...',
          );
          await Future.delayed(Duration(seconds: delaySec));
          continue;
        }

        break; // Gagal dan tidak retryable, coba model berikutnya.
      }
    }

    return lastResult ??
        GroqResult.fail(
          text: 'Terjadi kesalahan tidak terduga saat menghubungi AI.',
          errorDetail: 'No result',
        );
  }

  /// Trim history: hanya kirim N percakapan terakhir untuk hemat token.
  List<Map<String, String>> _trimHistory(List<Map<String, String>> history) {
    final maxMessages = _maxConversationPairs * 2;
    if (history.length <= maxMessages) return history;

    debugPrint(
      '✂️ [GroqService] Trimming history: ${history.length} → $maxMessages messages',
    );
    return history.sublist(history.length - maxMessages);
  }

  /// Build request body untuk Groq API.
  Map<String, dynamic> _buildRequestBody(
    String modelName,
    List<Map<String, String>> trimmedHistory,
    String? contextData,
  ) {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _getSystemPrompt(contextData)},
      ...trimmedHistory,
    ];

    // Jika ada contextData, tingkatkan max token agar respon tidak terpotong
    final maxTokens = (contextData != null && contextData.isNotEmpty) ? 500 : _maxTokens;

    return {
      'model': modelName,
      'messages': messages,
      'max_tokens': maxTokens,
      'temperature': _temperature,
    };
  }

  /// Melakukan HTTP POST ke Groq API.
  Future<GroqResult> _callModel(
    String modelName,
    List<Map<String, String>> trimmedHistory,
    String? contextData,
  ) async {
    try {
      final body = _buildRequestBody(modelName, trimmedHistory, contextData);

      final response = await http
          .post(
            Uri.parse(AppConfig.groqEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppConfig.cleanGroqApiKey}',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 [GroqService] HTTP ${response.statusCode} model=$modelName');

      if (response.statusCode == 200) {
        return _parseSuccessResponse(response.body, modelName);
      }

      return _mapHttpError(response.statusCode, response.body, modelName);
    } on http.ClientException catch (e) {
      debugPrint('❌ [GroqService] Network error: $e');
      return GroqResult.fail(
        text:
            'Gagal terhubung ke server AI.\n\n'
            'Pastikan koneksi internet stabil dan coba lagi.',
        errorDetail: e.toString(),
        retryable: true,
      );
    } catch (e, st) {
      debugPrint('❌ [GroqService] Unexpected error: $e\n$st');
      return GroqResult.fail(
        text:
            'Terjadi kesalahan saat menghubungi AI.\n\n'
            'Detail: $e',
        errorDetail: e.toString(),
      );
    }
  }

  /// Parse respons sukses (HTTP 200) dari Groq API.
  GroqResult _parseSuccessResponse(String responseBody, String modelName) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>?;

      if (choices == null || choices.isEmpty) {
        debugPrint('⚠️ [GroqService] Empty choices from API');
        return GroqResult.fail(
          text: 'Maaf, AI tidak mengembalikan respons.',
          errorDetail: 'Empty choices array',
        );
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      final text = (message?['content'] as String?)?.trim() ?? '';

      if (text.isEmpty) {
        debugPrint('⚠️ [GroqService] Empty content from API');
        return GroqResult.fail(
          text: 'Maaf, AI tidak mengembalikan teks respons.',
          errorDetail: 'Empty message content',
        );
      }

      // Log usage untuk monitoring konsumsi token.
      final usage = json['usage'] as Map<String, dynamic>?;
      if (usage != null) {
        debugPrint(
          '📊 [GroqService] Tokens — '
          'prompt: ${usage['prompt_tokens']}, '
          'completion: ${usage['completion_tokens']}, '
          'total: ${usage['total_tokens']}',
        );
      }

      debugPrint(
        '✅ [GroqService] Response OK model=$modelName (${text.length} chars)',
      );
      return GroqResult.ok(text);
    } catch (e) {
      debugPrint('❌ [GroqService] JSON parse error: $e');
      return GroqResult.fail(
        text: 'Gagal memproses respons dari AI.',
        errorDetail: 'JSON parse error: $e',
      );
    }
  }

  /// Map HTTP error codes ke pesan user-friendly.
  GroqResult _mapHttpError(int statusCode, String body, String modelName) {
    debugPrint('❌ [GroqService] HTTP $statusCode: $body');

    String? serverMessage;
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      serverMessage = error?['message'] as String?;
    } catch (_) {}

    switch (statusCode) {
      case 401:
        return GroqResult.fail(
          text:
              '⚠️ API Key Groq ditolak oleh server.\n\n'
              'Periksa GROQ_API_KEY di env.json dan pastikan key masih aktif.',
          errorDetail: serverMessage ?? 'Unauthorized',
          httpStatus: 401,
        );

      case 429:
        return GroqResult.fail(
          text:
              '⚠️ Server AI sedang sibuk (rate limit).\n\n'
              'Mohon tunggu sebentar, lalu coba kirim ulang.',
          errorDetail: serverMessage ?? 'Rate limited',
          httpStatus: 429,
          retryable: true,
        );

      case 404:
        return GroqResult.fail(
          text: '⚠️ Model `$modelName` tidak ditemukan di Groq API.',
          errorDetail: serverMessage ?? 'Model not found',
          httpStatus: 404,
        );

      case 503:
      case 502:
        return GroqResult.fail(
          text:
              '⚠️ Server AI sedang tidak tersedia.\n\n'
              'Mohon tunggu sebentar, lalu coba lagi.',
          errorDetail: serverMessage ?? 'Service unavailable',
          httpStatus: statusCode,
          retryable: true,
        );

      default:
        return GroqResult.fail(
          text:
              'Terjadi kesalahan dari server AI (HTTP $statusCode).\n\n'
              'Pastikan koneksi internet stabil dan coba lagi.',
          errorDetail: serverMessage ?? 'HTTP $statusCode',
          httpStatus: statusCode,
        );
    }
  }

  static String _maskSecret(String value) {
    if (value.length <= 8) return '***';
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }
}
