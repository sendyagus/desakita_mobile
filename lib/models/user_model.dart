import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> favorites;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.favorites = const [],
  });

  bool get isAdmin => role == 'admin';

  /// Profil dari Firestore (`users/{id}`).
  factory UserModel.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime parseDt(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) {
        return DateTime.tryParse(v) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return UserModel(
      id: id,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      role: data['role'] as String? ?? 'user',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: parseDt(data['createdAt']),
      updatedAt: parseDt(data['updatedAt']),
      favorites: List<String>.from(data['favorites'] ?? []),
    );
  }

  /// Kompatibilitas map Postgres/Supabase (snake_case).
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? '',
      email: map['email'] as String,
      phone: map['phone'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      role: map['role'] as String? ?? 'user',
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      favorites: List<String>.from(map['favorites'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'role': role,
      'isActive': isActive,
      'favorites': favorites,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
      'is_active': isActive,
      'favorites': favorites,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? role,
    bool? isActive,
    List<String>? favorites,
  }) {
    return UserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      favorites: favorites ?? this.favorites,
    );
  }
}
