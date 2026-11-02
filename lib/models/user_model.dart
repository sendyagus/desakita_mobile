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
  final bool preferencesCompleted;
  final Map<String, dynamic> travelPreferences;

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
    this.preferencesCompleted = false,
    this.travelPreferences = const {},
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
      preferencesCompleted: data['preferencesCompleted'] as bool? ?? false,
      travelPreferences: data['travelPreferences'] is Map
          ? Map<String, dynamic>.from(data['travelPreferences'] as Map)
          : const {},
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
      preferencesCompleted: map['preferences_completed'] as bool? ?? false,
      travelPreferences: map['travel_preferences'] is Map
          ? Map<String, dynamic>.from(map['travel_preferences'] as Map)
          : const {},
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
      'preferencesCompleted': preferencesCompleted,
      'travelPreferences': travelPreferences,
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
      'preferences_completed': preferencesCompleted,
      'travel_preferences': travelPreferences,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? role,
    bool? isActive,
    bool? preferencesCompleted,
    Map<String, dynamic>? travelPreferences,
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
      preferencesCompleted: preferencesCompleted ?? this.preferencesCompleted,
      travelPreferences: travelPreferences ?? this.travelPreferences,
    );
  }
}
