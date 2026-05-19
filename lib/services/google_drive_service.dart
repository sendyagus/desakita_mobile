import 'package:desa_wisata/config/app_config.dart';
import 'package:desa_wisata/utils/image_url_helper.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

/// Upload foto destinasi ke Google Drive (OAuth terpisah dari Firebase Auth).
class GoogleDriveService {
  GoogleDriveService._();
  static final GoogleDriveService instance = GoogleDriveService._();

  static const _driveScopes = [drive.DriveApi.driveFileScope];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _driveScopes,
    clientId: kIsWeb ? AppConfig.webGoogleClientId : null,
  );

  final ImagePicker _picker = ImagePicker();

  GoogleSignInAccount? _cachedAccount;

  String? get signedInEmail => _cachedAccount?.email;

  Future<bool> isSignedIn() async {
    if (_cachedAccount != null) return true;
    _cachedAccount = await _googleSignIn.signInSilently();
    return _cachedAccount != null;
  }

  /// Hubungkan Google Drive — panggil dari tombol (user gesture, wajib di web).
  Future<bool> connectGoogleAccount() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Login Google dibatalkan.');
      }

      final client = await _googleSignIn.authenticatedClient();
      if (client == null) {
        throw Exception(
          'Tidak mendapat token akses. Pastikan OAuth Client ID benar '
          'dan Google Drive API aktif.',
        );
      }

      _cachedAccount = account;
      debugPrint('✅ Google Drive terhubung: ${account.email}');
      return true;
    } catch (e) {
      debugPrint('❌ Gagal hubungkan Google Drive: $e');
      if (e.toString().contains('popup_closed')) {
        throw Exception(
          'Jendela login tertutup. Klik "Hubungkan Google Drive" lagi '
          'dan selesaikan login.',
        );
      }
      rethrow;
    }
  }

  Future<void> disconnectGoogleAccount() async {
    await _googleSignIn.signOut();
    _cachedAccount = null;
  }

  Future<http.Client> _authenticatedHttpClient() async {
    var client = await _googleSignIn.authenticatedClient();
    if (client != null) return client;

    if (kIsWeb) {
      throw Exception(
        'Belum terhubung ke Google Drive. Klik "Hubungkan Google Drive" terlebih dahulu.',
      );
    }

    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Login Google dibatalkan.');
    }
    _cachedAccount = account;

    client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw Exception('Gagal mendapatkan token akses Google Drive.');
    }
    return client;
  }

  Future<XFile?> pickImageFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      throw Exception('Gagal memilih gambar: $e');
    }
  }

  Future<String> uploadToGoogleDrive(XFile file) async {
    try {
      debugPrint('📤 Mulai upload ke Google Drive...');
      final httpClient = await _authenticatedHttpClient();
      final driveApi = drive.DriveApi(httpClient);

      final bytes = await file.readAsBytes();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.name)}';
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [AppConfig.googleDriveFolderId];

      final response = await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(Stream.value(bytes), bytes.length),
      );

      final fileId = response.id;
      if (fileId == null) {
        throw Exception('Upload gagal: tidak ada file ID dari Google Drive.');
      }

      await driveApi.permissions.create(
        drive.Permission()
          ..type = 'anyone'
          ..role = 'reader',
        fileId,
      );

      // Gunakan format thumbnail yang lebih stabil untuk ditampilkan
      debugPrint('✅ File ID: $fileId');
      final displayUrl = 'https://drive.google.com/thumbnail?id=$fileId&sz=w2000';
      debugPrint('🔗 Display URL: $displayUrl');
      return displayUrl;
    } catch (e, stackTrace) {
      debugPrint('❌ Error uploading to Google Drive: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      if (e is Exception) rethrow;
      throw Exception('Gagal upload ke Google Drive: $e');
    }
  }

  Future<void> deleteFromGoogleDrive(String imageUrl) async {
    final fileId = extractFileId(imageUrl);
    if (fileId == null) return;

    try {
      final httpClient = await _authenticatedHttpClient();
      final driveApi = drive.DriveApi(httpClient);
      await driveApi.files.delete(fileId);
    } catch (e) {
      throw Exception('Gagal menghapus dari Google Drive: $e');
    }
  }

  String? extractFileId(String url) =>
      ImageUrlHelper.extractGoogleDriveFileId(url);
}
