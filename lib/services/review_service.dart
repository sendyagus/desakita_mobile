import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/review_model.dart';

/// Service untuk mengelola operations pada reviews
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _reviews = FirebaseFirestore.instance.collection(
    'reviews',
  );

  /// Get reviews stream untuk satu destinasi
  Stream<List<Review>> getReviewsByDestination(
    String destinationId, {
    int limit = 20,
    String? lastDocumentId,
  }) {
    Query query = _reviews
        .where('destinationId', isEqualTo: destinationId)
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    // Pagination by document id is intentionally handled by callers that have
    // a DocumentSnapshot. Keeping this stream simple avoids passing a
    // DocumentReference to startAfterDocument, which requires a snapshot.
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Review.fromFirestore(doc, id: doc.id))
          .toList();
    });
  }

  /// Get semua reviews untuk user saat ini
  Stream<List<Review>> getUserReviews() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _reviews
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Review.fromFirestore(doc, id: doc.id))
              .toList();
        });
  }

  /// Get single review by ID
  Future<Review?> getReviewById(String reviewId) async {
    try {
      final doc = await _reviews.doc(reviewId).get();
      if (doc.exists) {
        return Review.fromFirestore(doc, id: doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting review: $e');
      return null;
    }
  }

  /// Create new review
  Future<ReviewResult> createReview({
    required String destinationId,
    required int rating,
    required String comment,
    String? title,
    List<String>? photos,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return ReviewResult.error('User tidak login');
    }

    // Validation
    final review = Review(
      id: '',
      destinationId: destinationId,
      userId: user.uid,
      userName: user.displayName ?? 'User',
      userProfilePic: user.photoURL,
      rating: rating,
      title: title,
      comment: comment,
      photos: photos ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final validation = review.validate();
    if (!validation.valid) {
      return ReviewResult.error(validation.error!);
    }

    // Check if already reviewed this destination
    final existingReview = await _checkExistingReview(user.uid, destinationId);

    if (existingReview != null) {
      return ReviewResult.error('Anda sudah mereview destinasi ini');
    }

    try {
      final docRef = await _reviews.add({
        ...review.toMap(),
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final createdReview = Review.fromFirestore(
        await docRef.get(),
        id: docRef.id,
      );

      // Update destination statistics
      await _updateDestinationStats(destinationId);

      return ReviewResult.success(createdReview);
    } catch (e) {
      debugPrint('Error creating review: $e');
      return ReviewResult.error('Gagal membuat review: $e');
    }
  }

  /// Update existing review
  Future<ReviewResult> updateReview(
    String reviewId, {
    int? rating,
    String? comment,
    String? title,
    List<String>? photos,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return ReviewResult.error('User tidak login');
    }

    try {
      final reviewDoc = await _reviews.doc(reviewId).get();
      if (!reviewDoc.exists) {
        return ReviewResult.error('Review tidak ditemukan');
      }

      final existingReview = Review.fromFirestore(reviewDoc);

      // Verify ownership
      if (existingReview.userId != user.uid) {
        return ReviewResult.error('Tidak dapat mengedit review orang lain');
      }

      // Prepare updates
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
        'isEdited': true,
      };

      if (rating != null) {
        updates['rating'] = rating;
      }

      if (comment != null) {
        updates['comment'] = comment;
      }

      if (title != null) {
        updates['title'] = title;
      }

      if (photos != null) {
        if (photos.isNotEmpty) {
          updates['photos'] = photos;
        } else {
          updates['photos'] = FieldValue.delete();
        }
      }

      // Validate before updating
      final updatedReview = existingReview.copyWith(
        rating: rating,
        comment: comment,
        title: title,
        photos: photos,
      );

      final validation = updatedReview.validate();
      if (!validation.valid) {
        return ReviewResult.error(validation.error!);
      }

      await _reviews.doc(reviewId).update(updates);

      // Re-fetch to get updated data
      final refreshed = Review.fromFirestore(
        await _reviews.doc(reviewId).get(),
        id: reviewId,
      );

      // Update destination stats since rating might have changed
      await _updateDestinationStats(existingReview.destinationId);

      return ReviewResult.success(refreshed);
    } catch (e) {
      debugPrint('Error updating review: $e');
      return ReviewResult.error('Gagal mengupdate review: $e');
    }
  }

  /// Delete review
  Future<ReviewResult> deleteReview(String reviewId) async {
    final user = _auth.currentUser;
    if (user == null) {
      return ReviewResult.error('User tidak login');
    }

    try {
      final reviewDoc = await _reviews.doc(reviewId).get();
      if (!reviewDoc.exists) {
        return ReviewResult.error('Review tidak ditemukan');
      }

      final existingReview = Review.fromFirestore(reviewDoc);

      // Verify ownership or admin role
      final isAdmin = await _checkAdminRole(user.uid);
      if (existingReview.userId != user.uid && !isAdmin) {
        return ReviewResult.error('Tidak dapat menghapus review ini');
      }

      // Soft delete by setting status to deleted
      await _reviews.doc(reviewId).update({
        'status': 'deleted',
        'updatedAt': Timestamp.now(),
      });

      // Update destination stats
      await _updateDestinationStats(existingReview.destinationId);

      return ReviewResult.success(existingReview);
    } catch (e) {
      debugPrint('Error deleting review: $e');
      return ReviewResult.error('Gagal menghapus review: $e');
    }
  }

  /// Mark review as helpful
  Future<ReviewResult> markHelpful(String reviewId) async {
    try {
      await _reviews.doc(reviewId).update({
        'helpfulCount': FieldValue.increment(1),
      });

      final updated = Review.fromFirestore(
        await _reviews.doc(reviewId).get(),
        id: reviewId,
      );

      return ReviewResult.success(updated);
    } catch (e) {
      debugPrint('Error marking helpful: $e');
      return ReviewResult.error('Gagal menandai review sebagai membantu');
    }
  }

  /// Report review
  Future<ReviewResult> reportReview(String reviewId, String reason) async {
    try {
      await _reviews.doc(reviewId).update({
        'reportedCount': FieldValue.increment(1),
      });

      return ReviewResult.success(null);
    } catch (e) {
      debugPrint('Error reporting review: $e');
      return ReviewResult.error('Gagal melaporkan review');
    }
  }

  /// Get destination review statistics
  Future<Map<String, dynamic>> getDestinationStats(String destinationId) async {
    try {
      final reviews = await _reviews
          .where('destinationId', isEqualTo: destinationId)
          .where('status', isEqualTo: 'approved')
          .get();

      final docs = reviews.docs;
      final count = docs.length;

      if (count == 0) {
        return {
          'avgRating': 0.0,
          'totalReviews': 0,
          'ratingDistribution': {'5': 0, '4': 0, '3': 0, '2': 0, '1': 0},
        };
      }

      final ratings = docs.map((d) => (d.data() as Map)['rating'] as int);
      final sum = ratings.fold<int>(0, (sum, r) => sum + r);
      final avg = sum / count;

      final distribution = {
        '5': ratings.where((r) => r == 5).length,
        '4': ratings.where((r) => r == 4).length,
        '3': ratings.where((r) => r == 3).length,
        '2': ratings.where((r) => r == 2).length,
        '1': ratings.where((r) => r == 1).length,
      };

      return {
        'avgRating': avg.roundToDouble(),
        'totalReviews': count,
        'ratingDistribution': distribution,
      };
    } catch (e) {
      debugPrint('Error getting destination stats: $e');
      return {
        'avgRating': 0.0,
        'totalReviews': 0,
        'ratingDistribution': {'5': 0, '4': 0, '3': 0, '2': 0, '1': 0},
      };
    }
  }

  /// Check if user already reviewed a destination
  Future<Review?> _checkExistingReview(
    String userId,
    String destinationId,
  ) async {
    final snapshot = await _reviews
        .where('userId', isEqualTo: userId)
        .where('destinationId', isEqualTo: destinationId)
        .where('status', whereNotIn: ['deleted'])
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return Review.fromFirestore(
        snapshot.docs.first,
        id: snapshot.docs.first.id,
      );
    }
    return null;
  }

  /// Update destination rating statistics
  Future<void> _updateDestinationStats(String destinationId) async {
    final stats = await getDestinationStats(destinationId);

    await _firestore.collection('destinations').doc(destinationId).update({
      'avgRating': stats['avgRating'],
      'totalReviews': stats['totalReviews'],
      'ratingDistribution': stats['ratingDistribution'],
    });
  }

  /// Check if user has admin role
  Future<bool> _checkAdminRole(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final role = userDoc.data()?['role'];
        return role == 'admin';
      }
    } catch (e) {
      debugPrint('Error checking admin role: $e');
    }
    return false;
  }
}

/// Result wrapper untuk review operations
class ReviewResult {
  final bool success;
  final Review? review;
  final String? error;

  const ReviewResult._({this.success = false, this.review, this.error});

  factory ReviewResult.success(Review? review) {
    return ReviewResult._(success: true, review: review);
  }

  factory ReviewResult.error(String message) {
    return ReviewResult._(success: false, error: message);
  }
}
