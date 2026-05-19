import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'image_url_helper.dart';

/// Utility untuk memperbaiki URL gambar lama di Firestore
/// yang menggunakan format `uc?export=view` menjadi format thumbnail
class FixOldImageUrls {
  static Future<void> fixAllDestinations() async {
    try {
      debugPrint('🔧 Memulai perbaikan URL gambar lama...');
      
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('destinations').get();
      
      int fixed = 0;
      int skipped = 0;
      int errors = 0;
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final oldUrl = data['imageUrl'] as String?;
          
          if (oldUrl == null || oldUrl.isEmpty) {
            skipped++;
            continue;
          }
          
          // Cek apakah sudah menggunakan format thumbnail
          if (oldUrl.contains('/thumbnail?id=')) {
            debugPrint('✓ ${doc.id}: Sudah menggunakan format baru');
            skipped++;
            continue;
          }
          
          // Extract file ID
          final fileId = ImageUrlHelper.extractGoogleDriveFileId(oldUrl);
          if (fileId == null) {
            debugPrint('⚠️ ${doc.id}: Bukan URL Google Drive, skip');
            skipped++;
            continue;
          }
          
          // Generate URL baru dengan format thumbnail
          final newUrl = 'https://drive.google.com/thumbnail?id=$fileId&sz=w2000';
          
          // Update Firestore
          await doc.reference.update({
            'imageUrl': newUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          debugPrint('✅ ${doc.id}: $oldUrl → $newUrl');
          fixed++;
          
        } catch (e) {
          debugPrint('❌ Error fixing ${doc.id}: $e');
          errors++;
        }
      }
      
      debugPrint('');
      debugPrint('📊 Hasil perbaikan:');
      debugPrint('   ✅ Diperbaiki: $fixed');
      debugPrint('   ⏭️ Dilewati: $skipped');
      debugPrint('   ❌ Error: $errors');
      debugPrint('   📝 Total: ${snapshot.docs.length}');
      
    } catch (e) {
      debugPrint('❌ Error saat memperbaiki URL: $e');
      rethrow;
    }
  }
  
  /// Fix single destination by ID
  static Future<void> fixDestination(String destinationId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('destinations').doc(destinationId).get();
      
      if (!doc.exists) {
        debugPrint('❌ Destinasi tidak ditemukan: $destinationId');
        return;
      }
      
      final data = doc.data()!;
      final oldUrl = data['imageUrl'] as String?;
      
      if (oldUrl == null || oldUrl.isEmpty) {
        debugPrint('⚠️ Tidak ada imageUrl untuk diperbaiki');
        return;
      }
      
      if (oldUrl.contains('/thumbnail?id=')) {
        debugPrint('✓ Sudah menggunakan format baru');
        return;
      }
      
      final fileId = ImageUrlHelper.extractGoogleDriveFileId(oldUrl);
      if (fileId == null) {
        debugPrint('⚠️ Bukan URL Google Drive');
        return;
      }
      
      final newUrl = 'https://drive.google.com/thumbnail?id=$fileId&sz=w2000';
      
      await doc.reference.update({
        'imageUrl': newUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ URL diperbaiki: $oldUrl → $newUrl');
      
    } catch (e) {
      debugPrint('❌ Error: $e');
      rethrow;
    }
  }
  
  /// Verify all image URLs are accessible
  static Future<void> verifyAllUrls() async {
    try {
      debugPrint('🔍 Memverifikasi semua URL gambar...');
      
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('destinations').get();
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final url = data['imageUrl'] as String?;
        final name = data['name'] as String? ?? 'Unknown';
        
        if (url == null || url.isEmpty) {
          debugPrint('⚠️ $name: Tidak ada URL');
          continue;
        }
        
        final fileId = ImageUrlHelper.extractGoogleDriveFileId(url);
        if (fileId != null) {
          debugPrint('✓ $name: File ID = $fileId');
          debugPrint('  URL: $url');
        } else {
          debugPrint('⚠️ $name: Bukan Google Drive URL');
          debugPrint('  URL: $url');
        }
      }
      
    } catch (e) {
      debugPrint('❌ Error: $e');
      rethrow;
    }
  }
}
