/// Konfigurasi aplikasi — sesuaikan sesuai project Google Cloud / Firebase Anda.
class AppConfig {
  /// Folder Google Drive tempat admin mengunggah foto destinasi.
  static const String googleDriveFolderId = '19QjJ9MoUUbk4lpnQt5ay_5EMv8HgZ4dE';

  /// OAuth 2.0 Web Client ID (sama dengan meta tag di web/index.html).
  static const String webGoogleClientId =
      '866210125594-sbafjaiafirlc7bt98snnd78gcfrb2ni.apps.googleusercontent.com';

  // ─── Groq AI Configuration ──────────────────────────────────────────────

  /// Groq API Key — hanya dari compile-time define (env.json / CI).
  ///
  /// Jalankan dengan:
  /// `flutter run --dart-define-from-file=env.json`
  ///
  /// File [env.json] ada di .gitignore dan tidak pernah di-commit.
  static const String groqApiKey = String.fromEnvironment('GROQ_API_KEY');

  /// API key yang dibersihkan dari spasi, kutip dua, atau kutip satu akibat parsing terminal.
  static String get cleanGroqApiKey =>
      groqApiKey.trim().replaceAll('"', '').replaceAll("'", "");

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
