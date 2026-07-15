/// Normalisasi URL gambar (Google Drive, Firebase Storage, dll.) agar bisa ditampilkan di [Image.network].
class ImageUrlHelper {
  /// URL kandidat untuk file Google Drive publik (urutan: paling stabil di mobile).
  static List<String> googleDriveDisplayUrls(String fileId) {
    return [
      // lh3.googleusercontent — paling stabil untuk Flutter mobile (tidak kena CORS/redirect).
      'https://lh3.googleusercontent.com/d/$fileId=s2000',
      'https://lh3.googleusercontent.com/d/$fileId=s1000',
      'https://lh3.googleusercontent.com/d/$fileId',
      // Domain usercontent — download langsung, sering berhasil.
      'https://drive.usercontent.google.com/download?id=$fileId&export=view&authuser=0',
      'https://drive.usercontent.google.com/download?id=$fileId&export=view',
      // Thumbnail API — kadang diblokir di mobile karena CORS.
      'https://drive.google.com/thumbnail?id=$fileId&sz=w2000',
      'https://drive.google.com/thumbnail?id=$fileId&sz=w1000',
      // uc endpoint — klasik tapi sering kena CORS/redirect.
      'https://drive.google.com/uc?export=view&id=$fileId',
      'https://drive.google.com/uc?id=$fileId&export=download',
      // Fallback: proxy via drive.google.com/thumbnail ukuran kecil.
      'https://drive.google.com/thumbnail?id=$fileId&sz=w400',
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
