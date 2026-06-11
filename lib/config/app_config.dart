/// Konfigurasi aplikasi — sesuaikan sesuai project Google Cloud / Firebase Anda.
class AppConfig {
  /// Folder Google Drive tempat admin mengunggah foto destinasi.
  static const String googleDriveFolderId = '19QjJ9MoUUbk4lpnQt5ay_5EMv8HgZ4dE';

  /// OAuth 2.0 Web Client ID (sama dengan meta tag di web/index.html).
  static const String webGoogleClientId =
      '866210125594-sbafjaiafirlc7bt98snnd78gcfrb2ni.apps.googleusercontent.com';

  /// Google Gemini API Key.
  /// Load from --dart-define=GEMINI_API_KEY=your_key or fallback.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyD9Dm7MJjAnIR46nYPDl4pKBAPlZSUAc0o',
  );

  /// Nama model Gemini (Generative Language API).
  ///
  /// Model lama seperti `gemini-1.5-flash` sudah di-shutdown dan mengembalikan 404.
  /// Override via `--dart-define=GEMINI_MODEL=gemini-2.5-flash`.
  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );

  /// Model cadangan jika model utama sibuk (503) atau overload.
  static const String geminiFallbackModel = String.fromEnvironment(
    'GEMINI_FALLBACK_MODEL',
    defaultValue: 'gemini-2.5-flash-lite',
  );

  /// Jumlah percobaan ulang saat server Gemini sibuk (503/429).
  static const int geminiMaxRetries = 3;

  /// Versi API yang dipakai package `google_generative_ai` (default: v1beta).
  static const String geminiApiVersion = 'v1beta';

  /// Endpoint base Generative Language API.
  static String geminiGenerateContentEndpoint(String model) =>
      'https://generativelanguage.googleapis.com/$geminiApiVersion/models/$model:generateContent';
}
