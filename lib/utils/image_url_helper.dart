/// Normalisasi URL gambar (Google Drive, Firebase Storage, dll.) agar bisa ditampilkan di [Image.network].
class ImageUrlHelper {
  /// URL kandidat untuk file Google Drive publik (urutan: paling kompatibel dengan Flutter Web).
  static List<String> googleDriveDisplayUrls(String fileId) {
    return [
      // Thumbnail API - paling stabil untuk Flutter Web (tidak kena CORS)
      'https://drive.google.com/thumbnail?id=$fileId&sz=w2000',
      'https://drive.google.com/thumbnail?id=$fileId&sz=w1920',
      'https://drive.google.com/thumbnail?id=$fileId&sz=w1000',
      // Domain usercontent - alternatif yang bagus
      'https://drive.usercontent.google.com/download?id=$fileId&export=view&authuser=0',
      'https://drive.usercontent.google.com/download?id=$fileId&export=view',
      // uc endpoint - klasik tapi kadang kena CORS di web
      'https://drive.google.com/uc?export=view&id=$fileId',
      'https://drive.google.com/uc?id=$fileId&export=download',
      // lh3 googleusercontent - kadang work untuk file publik
      'https://lh3.googleusercontent.com/d/$fileId=w2000',
      'https://lh3.googleusercontent.com/d/$fileId',
      'https://lh3.googleusercontent.com/d/$fileId=s1000',
    ];
  }

  /// Satu URL utama (untuk kompatibilitas); prefer thumbnail untuk web.
  static String? resolveDisplayUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;

    final trimmed = url.trim();
    final fileId = extractGoogleDriveFileId(trimmed);
    if (fileId != null) {
      return googleDriveDisplayUrls(fileId).first;
    }
    return trimmed;
  }

  /// Semua URL kandidat untuk Drive (untuk fallback saat load gagal).
  static List<String>? googleDriveCandidatesFromUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final fileId = extractGoogleDriveFileId(url.trim());
    if (fileId == null) return null;
    return googleDriveDisplayUrls(fileId);
  }

  static String? extractGoogleDriveFileId(String url) {
    final patterns = [
      RegExp(r'[?&]id=([a-zA-Z0-9_-]+)'),
      RegExp(r'/file/d/([a-zA-Z0-9_-]+)'),
      RegExp(r'/d/([a-zA-Z0-9_-]+)'),
      RegExp(r'googleusercontent\.com/d/([a-zA-Z0-9_-]+)'),
      RegExp(r'/open\?[^#]*id=([a-zA-Z0-9_-]+)'),
      RegExp(r'/thumbnail\?id=([a-zA-Z0-9_-]+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) return match.group(1);
    }
    return null;
  }
}
