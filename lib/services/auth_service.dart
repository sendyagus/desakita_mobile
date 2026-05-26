import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:desa_wisata/firebase_options.dart';
import 'package:desa_wisata/models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  static AuthService get instance => _instance;

  final fa.FirebaseAuth _auth = fa.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _users = 'users';

  fa.User? get currentAuthUser => _auth.currentUser;
  bool get isLoggedIn => currentAuthUser != null;
  Stream<fa.User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      debugPrint('📝 Starting registration for: $email');
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid == null) {
        throw fa.FirebaseAuthException(
          code: 'null-user',
          message: 'Registrasi gagal, user null',
        );
      }

      if (name.isNotEmpty) {
        await cred.user?.updateDisplayName(name);
      }

      final now = FieldValue.serverTimestamp();
      await _db.collection(_users).doc(uid).set({
        'fullName': name,
        'email': email,
        'phone': phone,
        'avatarUrl': null,
        'role': 'user',
        'isActive': true,
        'createdAt': now,
        'updatedAt': now,
      });

      final snap = await _db.collection(_users).doc(uid).get();
      final data = snap.data();
      if (data == null) {
        return _buildTempUser(uid, name, email, phone);
      }
      debugPrint('✅ Registration complete');
      return UserModel.fromFirestore(uid, data);
    } on fa.FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      throw fa.FirebaseAuthException(
        code: 'unknown',
        message: 'Registrasi gagal: $e',
      );
    }
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Starting login for: $email');
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw fa.FirebaseAuthException(
          code: 'null-user',
          message: 'Login gagal, user null',
        );
      }

      UserModel? profile = await _fetchUserProfile(uid);
      if (profile == null) {
        debugPrint('⚠️  Profile not found in Firestore, creating...');
        await _ensureUserDocFromAuth(uid);
        profile = await _fetchUserProfile(uid);
      }

      if (profile == null) {
        final u = _auth.currentUser!;
        debugPrint('⚠️  Using auth fallback profile');
        return _buildTempUser(
          uid,
          u.displayName ?? '',
          u.email ?? email,
          '',
        );
      }

      debugPrint('✅ Login complete - Role: ${profile.role}');
      return profile;
    } on fa.FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('❌ Login error: $e');
      throw fa.FirebaseAuthException(
        code: 'unknown',
        message: 'Login gagal: $e',
      );
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Buat akun baru tanpa mengganti sesi admin yang sedang login.
  Future<UserModel> createUserAsAdmin({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String role = 'user',
  }) async {
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'AdminUserCreator_${DateTime.now().millisecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final secondaryAuth = fa.FirebaseAuth.instanceFor(app: secondaryApp);

      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid == null) {
        throw fa.FirebaseAuthException(
          code: 'null-user',
          message: 'Gagal membuat user',
        );
      }

      if (fullName.isNotEmpty) {
        await cred.user?.updateDisplayName(fullName);
      }

      final now = FieldValue.serverTimestamp();
      await _db.collection(_users).doc(uid).set({
        'fullName': fullName,
        'email': email.trim(),
        'phone': phone,
        'avatarUrl': null,
        'role': role,
        'isActive': true,
        'createdAt': now,
        'updatedAt': now,
      });

      await secondaryAuth.signOut();

      final snap = await _db.collection(_users).doc(uid).get();
      final data = snap.data();
      if (data == null) {
        return _buildTempUser(uid, fullName, email.trim(), phone);
      }
      return UserModel.fromFirestore(uid, data);
    } on fa.FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('❌ createUserAsAdmin error: $e');
      throw fa.FirebaseAuthException(
        code: 'unknown',
        message: 'Gagal menambah user: $e',
      );
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final uid = currentAuthUser?.uid;
    if (uid == null) return null;
    return _fetchUserProfile(uid);
  }

  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (fullName != null) updates['fullName'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;

    await _db.collection(_users).doc(userId).update(updates);

    if (fullName != null && _auth.currentUser?.uid == userId) {
      await _auth.currentUser?.updateDisplayName(fullName);
    }

    final updated = await _fetchUserProfile(userId);
    if (updated == null) {
      throw fa.FirebaseAuthException(
        code: 'profile-missing',
        message: 'Gagal memperbarui profil.',
      );
    }
    return updated;
  }

  Future<List<UserModel>> getAllUsers() async {
    final snap = await _db
        .collection(_users)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => UserModel.fromFirestore(d.id, d.data()))
        .toList();
  }

  Future<void> toggleUserStatus(String userId, bool isActive) async {
    await _db.collection(_users).doc(userId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _db.collection(_users).doc(userId).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Hanya menghapus dokumen profil di Firestore. Akun Firebase Auth tetap ada
  /// kecuali dihapus lewat Admin SDK / Console.
  Future<void> deleteUser(String userId) async {
    await _db.collection(_users).doc(userId).delete();
  }

  Future<UserModel?> _fetchUserProfile(String userId) async {
    try {
      final snap = await _db.collection(_users).doc(userId).get();
      if (!snap.exists || snap.data() == null) return null;
      return UserModel.fromFirestore(userId, snap.data()!);
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureUserDocFromAuth(String uid) async {
    final u = _auth.currentUser;
    if (u == null) return;
    final now = FieldValue.serverTimestamp();
    await _db.collection(_users).doc(uid).set({
      'fullName': u.displayName ?? '',
      'email': u.email ?? '',
      'phone': '',
      'avatarUrl': u.photoURL,
      'role': 'user',
      'isActive': true,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  UserModel _buildTempUser(
    String id,
    String name,
    String email,
    String phone,
  ) {
    final now = DateTime.now();
    return UserModel(
      id: id,
      fullName: name,
      email: email,
      phone: phone,
      role: 'user',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }
}
