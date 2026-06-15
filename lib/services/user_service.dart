import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service untuk mengelola users di Firestore
class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _col = 'users';

  Future<List<UserModel>> getAllUsers() async {
    final snap = await _db.collection(_col).get();
    final list = snap.docs
        .map((d) => UserModel.fromFirestore(d.id, d.data()))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<UserModel>> getUsersByRole(String role) async {
    final snap = await _db
        .collection(_col)
        .where('role', isEqualTo: role)
        .get();
    final list = snap.docs
        .map((d) => UserModel.fromFirestore(d.id, d.data()))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<UserModel>> getActiveUsers() async {
    final snap = await _db
        .collection(_col)
        .where('isActive', isEqualTo: true)
        .get();
    final list = snap.docs
        .map((d) => UserModel.fromFirestore(d.id, d.data()))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<UserModel?> getUserById(String id) async {
    final doc = await _db.collection(_col).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromFirestore(doc.id, doc.data()!);
  }

  Future<UserModel> updateUser({
    required String id,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? role,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (fullName != null) updates['fullName'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
    if (role != null) updates['role'] = role;
    if (isActive != null) updates['isActive'] = isActive;

    await _db.collection(_col).doc(id).update(updates);
    final doc = await _db.collection(_col).doc(id).get();
    return UserModel.fromFirestore(doc.id, doc.data()!);
  }

  Future<void> deleteUser(String id) async {
    await _db.collection(_col).doc(id).delete();
  }

  Future<void> toggleUserStatus(String id, bool newStatus) async {
    await _db.collection(_col).doc(id).update({
      'isActive': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int> getTotalUsersCount() async {
    final snap = await _db.collection(_col).count().get();
    return snap.count ?? 0;
  }

  Future<int> getNewUsersToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final snap = await _db
        .collection(_col)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<void> toggleFavorite(String userId, String destinationId) async {
    final docRef = _db.collection(_col).doc(userId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final List<dynamic> favorites = data['favorites'] ?? [];
    if (favorites.contains(destinationId)) {
      await docRef.update({
        'favorites': FieldValue.arrayRemove([destinationId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.update({
        'favorites': FieldValue.arrayUnion([destinationId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<List<String>> getFavorites(String userId) async {
    final doc = await _db.collection(_col).doc(userId).get();
    if (!doc.exists || doc.data() == null) return [];
    return List<String>.from(doc.data()!['favorites'] ?? []);
  }

  /// Stream favorit secara real-time. Pakai ini di screen agar tidak perlu
  /// subscribe manual ke Firestore collection('users').doc(uid).snapshots().
  Stream<List<String>> watchFavorites(String userId) {
    return _db
        .collection(_col)
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return <String>[];
          return List<String>.from(doc.data()!['favorites'] ?? []);
        });
  }

  /// Cek apakah satu destinasi ada di favorit user (real-time).
  Stream<bool> isFavorite(String userId, String destinationId) {
    return watchFavorites(userId).map((favs) => favs.contains(destinationId));
  }
}
