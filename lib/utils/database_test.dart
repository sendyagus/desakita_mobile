import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Uji koneksi Firebase (Auth + Firestore).
class DatabaseTest {
  static Future<Map<String, dynamic>> testConnection() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'details': <String, dynamic>{},
    };

    try {
      if (Firebase.apps.isEmpty) {
        result['message'] = 'Firebase belum di-initialize';
        return result;
      }

      await FirebaseFirestore.instance
          .collection('destinations')
          .limit(1)
          .get();

      result['success'] = true;
      result['message'] = 'Koneksi Firestore berhasil!';
      result['details'] = {
        'initialized': true,
        'can_query': true,
      };
    } on FirebaseException catch (e) {
      result['message'] = 'Firestore error: ${e.message}';
      result['details'] = {'code': e.code};
    } catch (e) {
      result['message'] = 'Error: $e';
    }

    return result;
  }

  static Future<Map<String, dynamic>> testUsersCollection() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
    };

    try {
      if (FirebaseAuth.instance.currentUser == null) {
        result['message'] = 'Belum login — skip cek koleksi users';
        result['success'] = true;
        return result;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      result['success'] = true;
      result['message'] = 'Dokumen users/{uid} dapat diakses';
    } on FirebaseException catch (e) {
      result['message'] = 'Users collection error: ${e.message}';
      result['code'] = e.code;
    } catch (e) {
      result['message'] = 'Error: $e';
    }

    return result;
  }

  static Future<void> runAllTests() async {
    // ignore: avoid_print
    print('═══════════════════════════════════════');
    // ignore: avoid_print
    print('TESTING FIREBASE');
    // ignore: avoid_print
    print('═══════════════════════════════════════');

    // ignore: avoid_print
    print('\n1 Testing Firestore...');
    final connTest = await testConnection();
    // ignore: avoid_print
    print('   ${connTest['success'] == true ? 'OK' : 'FAIL'} ${connTest['message']}');

    // ignore: avoid_print
    print('\n2 Testing users doc...');
    final usersTest = await testUsersCollection();
    // ignore: avoid_print
    print('   ${usersTest['success'] == true ? 'OK' : 'FAIL'} ${usersTest['message']}');

    // ignore: avoid_print
    print('\n═══════════════════════════════════════');
  }
}
