import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Script untuk membuat akun admin
/// Username: admin
/// Password: 12345678
class CreateAdmin {
  static Future<void> createAdminAccount() async {
    try {
      debugPrint('🔧 Membuat akun admin...');

      // Email untuk admin (karena Firebase Auth butuh email)
      const adminEmail = 'admin1@desakita.com';
      const adminPassword = '12345678';
      const adminName = 'Administrator';
      const adminPhone = '+6281234567890';

      // 1. Cek apakah admin sudah ada
      final existingUsers = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: adminEmail)
          .limit(1)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        debugPrint('⚠️  Admin sudah ada!');
        debugPrint('   Email: $adminEmail');
        debugPrint('   Password: $adminPassword');
        return;
      }

      // 2. Buat user di Firebase Authentication
      debugPrint('📝 Membuat user di Firebase Auth...');
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      final userId = userCredential.user?.uid;
      if (userId == null) {
        throw Exception('Failed to create user');
      }

      // 3. Update display name
      await userCredential.user?.updateDisplayName(adminName);

      // 4. Buat dokumen di Firestore
      debugPrint('📝 Membuat dokumen di Firestore...');
      final now = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fullName': adminName,
        'email': adminEmail,
        'phone': adminPhone,
        'avatarUrl': null,
        'role': 'admin', // PENTING: role admin
        'isActive': true,
        'createdAt': now,
        'updatedAt': now,
      });

      debugPrint('✅ Akun admin berhasil dibuat!');
      debugPrint('');
      debugPrint('═══════════════════════════════════════');
      debugPrint('   AKUN ADMIN BERHASIL DIBUAT');
      debugPrint('═══════════════════════════════════════');
      debugPrint('   Email    : $adminEmail');
      debugPrint('   Password : $adminPassword');
      debugPrint('   Role     : admin');
      debugPrint('═══════════════════════════════════════');
      debugPrint('');
      debugPrint('Silakan login dengan kredensial di atas.');
      debugPrint('');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        debugPrint('⚠️  Email admin sudah digunakan!');
        debugPrint('   Email: admin@desakita.com');
        debugPrint('   Password: 12345678');
      } else {
        debugPrint('❌ Error Firebase Auth: ${e.code} - ${e.message}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error membuat admin: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Alternatif: Buat admin dengan username custom
  /// Tapi tetap butuh email untuk Firebase Auth
  static Future<void> createAdminWithUsername({
    required String username,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    try {
      debugPrint('🔧 Membuat akun admin dengan username: $username');

      // Firebase Auth butuh email, jadi kita buat email dari username
      final adminEmail = '$username@desakita.com';
      final adminName = fullName ?? 'Admin $username';
      final adminPhone = phone ?? '+6281234567890';

      // 1. Cek apakah admin sudah ada
      final existingUsers = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: adminEmail)
          .limit(1)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        debugPrint('⚠️  Admin dengan username "$username" sudah ada!');
        debugPrint('   Email: $adminEmail');
        return;
      }

      // 2. Buat user di Firebase Authentication
      debugPrint('📝 Membuat user di Firebase Auth...');
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: adminEmail,
        password: password,
      );

      final userId = userCredential.user?.uid;
      if (userId == null) {
        throw Exception('Failed to create user');
      }

      debugPrint('✅ User created dengan UID: $userId');

      // 3. Update display name
      await userCredential.user?.updateDisplayName(adminName);
      debugPrint('✅ Display name updated');

      // Small delay to ensure Firebase state is updated
      await Future.delayed(const Duration(milliseconds: 500));

      // 4. Buat dokumen di Firestore
      debugPrint('📝 Membuat dokumen di Firestore...');
      final now = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fullName': adminName,
        'email': adminEmail,
        'phone': adminPhone,
        'avatarUrl': null,
        'role': 'admin', // PENTING: role admin
        'isActive': true,
        'createdAt': now,
        'updatedAt': now,
      });

      debugPrint('✅ Firestore document created');
      debugPrint('');
      debugPrint('═══════════════════════════════════════');
      debugPrint('   AKUN ADMIN BERHASIL DIBUAT');
      debugPrint('═══════════════════════════════════════');
      debugPrint('   Username : $username');
      debugPrint('   Email    : $adminEmail');
      debugPrint('   Password : $password');
      debugPrint('   Role     : admin');
      debugPrint('═══════════════════════════════════════');
      debugPrint('');
      debugPrint('Silakan login dengan email: $adminEmail');
      debugPrint('');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        debugPrint('⚠️  Username "$username" sudah digunakan!');
      } else {
        debugPrint('❌ Error Firebase Auth: ${e.code} - ${e.message}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error membuat admin: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
}
