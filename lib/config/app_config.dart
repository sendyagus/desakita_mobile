import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Konfigurasi aplikasi — sesuaikan sesuai project Google Cloud / Firebase Anda.
class AppConfig {
  /// Folder Google Drive tempat admin mengunggah foto destinasi.
  static const String googleDriveFolderId = '19QjJ9MoUUbk4lpnQt5ay_5EMv8HgZ4dE';

  /// OAuth 2.0 Web Client ID (sama dengan meta tag di web/index.html).
  static const String webGoogleClientId =
      '866210125594-sbafjaiafirlc7bt98snnd78gcfrb2ni.apps.googleusercontent.com';

  // ─── Groq AI Configuration ──────────────────────────────────────────────

  /// Groq API Key dari --dart-define (opsional, mis. untuk CI).
  ///
  /// Untuk pengembangan lokal cukup isi `env.json` (gitignored) — otomatis
  /// dimuat oleh [loadEnv] sehingga `flutter run -d chrome` tanpa flag.
  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  /// Key yang dimuat runtime dari asset `env.json` (tidak pernah di-commit).
  static String _runtimeGroqApiKey = '';

  /// Panggil sekali di `main()` sebelum `runApp`.
  static Future<void> loadEnv() async {
    try {
      final raw = await rootBundle.loadString('env.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _runtimeGroqApiKey = (data['GROQ_API_KEY'] ?? '').toString();
    } catch (_) {
      // env.json tidak ada / tidak valid — fallback ke --dart-define.
      _runtimeGroqApiKey = '';
    }
  }

  /// API key yang dibersihkan dari spasi, kutip dua, atau kutip satu akibat parsing terminal.
  static String get cleanGroqApiKey {
    final source =
        groqApiKey.trim().isNotEmpty ? groqApiKey : _runtimeGroqApiKey;
    return source.trim().replaceAll('"', '').replaceAll("'", '');
  }

  /// Apakah API key Groq sudah dikonfigurasi.
  static bool get isGroqConfigured {
    final cleanKey = cleanGroqApiKey;
    return cleanKey.isNotEmpty && cleanKey != 'YOUR_GROQ_API_KEY_HERE';
  }

  /// Nama model Groq utama.
  static const String groqModel = String.fromEnvironment(
    'GROQ_MODEL',
    defaultValue: 'llama-3.3-70b-versatile',
  );

  /// Model cadangan jika model utama sibuk (429) atau overload.
  static const String groqFallbackModel = String.fromEnvironment(
    'GROQ_FALLBACK_MODEL',
    defaultValue: 'deepseek-r1-distill-llama-70b',
  );

  /// Jumlah percobaan ulang saat server Groq sibuk (429/503).
  static const int groqMaxRetries = 3;

  /// Endpoint Groq Chat Completions (OpenAI-compatible).
  static const String groqEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';
}
