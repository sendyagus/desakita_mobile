import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk merepresentasikan review destinasi
class Review {
  final String id;
  final String destinationId;
  final String userId;
  final String userName;
  final String? userProfilePic;
  final int rating; // 1-5
  final String? title;
  final String comment;
  final List<String> photos; // Max 5 photos
  final int helpfulCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEdited;
  final String status; // 'pending', 'approved', 'rejected'
  final int reportedCount;
  final double? aiScore; // AI quality score (0-100)

  const Review({
    required this.id,
    required this.destinationId,
    required this.userId,
    required this.userName,
    this.userProfilePic,
    required this.rating,
    this.title,
    required this.comment,
    this.photos = const [],
    this.helpfulCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isEdited = false,
    this.status = 'approved',
    this.reportedCount = 0,
    this.aiScore,
  });

  /// Create from Firestore document
  factory Review.fromFirestore(DocumentSnapshot doc, {String? id}) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: id ?? doc.id,
      destinationId: data['destinationId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userProfilePic: data['userProfilePic'],
      rating: data['rating'] ?? 0,
      title: data['title'],
      comment: data['comment'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      helpfulCount: data['helpfulCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isEdited: data['isEdited'] ?? false,
      status: data['status'] ?? 'approved',
      reportedCount: data['reportedCount'] ?? 0,
      aiScore: data['aiScore'],
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'destinationId': destinationId,
      'userId': userId,
      'userName': userName,
      'userProfilePic': userProfilePic,
      'rating': rating,
      'title': title,
      'comment': comment,
      'photos': photos.isNotEmpty ? photos : FieldValue.delete(),
      'helpfulCount': helpfulCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isEdited': isEdited,
      'status': status,
      'reportedCount': reportedCount,
      if (aiScore != null) 'aiScore': aiScore,
    };
  }

  /// Clone review with updated fields
  Review copyWith({
    String? id,
    String? destinationId,
    String? userId,
    String? userName,
    String? userProfilePic,
    int? rating,
    String? title,
    String? comment,
    List<String>? photos,
    int? helpfulCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    String? status,
    int? reportedCount,
    double? aiScore,
  }) {
    return Review(
      id: id ?? this.id,
      destinationId: destinationId ?? this.destinationId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePic: userProfilePic ?? this.userProfilePic,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      photos: photos ?? this.photos,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      status: status ?? this.status,
      reportedCount: reportedCount ?? this.reportedCount,
      aiScore: aiScore ?? this.aiScore,
    );
  }

  /// Validate review data
  ValidationResult validate() {
    if (rating < 1 || rating > 5) {
      return ValidationResult(valid: false, error: 'Rating harus antara 1-5');
    }

    if (comment.trim().isEmpty) {
      return ValidationResult(
        valid: false,
        error: 'Comment tidak boleh kosong',
      );
    }

    if (comment.length < 20) {
      return ValidationResult(
        valid: false,
        error: 'Comment minimal 20 karakter',
      );
    }

    if (comment.length > 1000) {
      return ValidationResult(
        valid: false,
        error: 'Comment maksimal 1000 karakter',
      );
    }

    if (photos.isNotEmpty && photos.length > 5) {
      return ValidationResult(
        valid: false,
        error: 'Maksimal 5 foto per review',
      );
    }

    if (title != null && title!.length > 100) {
      return ValidationResult(
        valid: false,
        error: 'Judul maksimal 100 karakter',
      );
    }

    return ValidationResult(valid: true);
  }

  @override
  String toString() {
    return 'Review(id: $id, destinationId: $destinationId, rating: $rating, '
        'userId: $userId, comment: ${comment.length} chars, photos: ${photos.length})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Review && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Result dari validasi review
class ValidationResult {
  final bool valid;
  final String? error;

  const ValidationResult({required this.valid, this.error});
}
