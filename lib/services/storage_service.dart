import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

/// Service untuk upload dan manage files di Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Gagal memilih gambar: $e');
    }
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Gagal mengambil foto: $e');
    }
  }

  /// Upload image to Firebase Storage
  /// [folder] - folder path in storage (e.g., 'destinations', 'events', 'users')
  /// [file] - XFile from image picker
  /// Returns download URL
  Future<String> uploadImage({
    required String folder,
    required XFile file,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final ref = _storage.ref().child('$folder/$fileName');
      
      debugPrint('📤 Starting upload...');
      debugPrint('📁 Folder: $folder');
      debugPrint('📄 File name: $fileName');
      debugPrint('🌐 Platform: ${kIsWeb ? "Web" : "Mobile"}');
      
      UploadTask uploadTask;
      
      if (kIsWeb) {
        // For web, use bytes
        debugPrint('🔄 Reading file as bytes...');
        final bytes = await file.readAsBytes();
        debugPrint('✅ File read: ${bytes.length} bytes');
        
        debugPrint('🔄 Uploading to Firebase Storage...');
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        // For mobile, use file
        debugPrint('🔄 Uploading file...');
        uploadTask = ref.putFile(File(file.path));
      }
      
      final snapshot = await uploadTask.whenComplete(() {});
      debugPrint('✅ Upload complete!');
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('🔗 Download URL: $downloadUrl');
      
      return downloadUrl;
    } catch (e, stackTrace) {
      debugPrint('❌ Upload error: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      throw Exception('Gagal upload gambar: $e');
    }
  }

  /// Upload image from file path
  Future<String> uploadImageFromPath({
    required String folder,
    required String filePath,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(filePath)}';
      final ref = _storage.ref().child('$folder/$fileName');
      
      final uploadTask = ref.putFile(File(filePath));
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Gagal upload gambar: $e');
    }
  }

  /// Delete image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Gagal menghapus gambar: $e');
    }
  }

  /// Get download URL from storage path
  Future<String> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Gagal mendapatkan URL: $e');
    }
  }

  /// Show image picker dialog (gallery or camera)
  Future<XFile?> showImageSourceDialog() async {
    // This will be called from UI with showDialog
    // For now, default to gallery
    return await pickImageFromGallery();
  }
}
