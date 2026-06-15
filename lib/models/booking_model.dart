import 'package:cloud_firestore/cloud_firestore.dart';

/// Model booking yang selaras dengan skema Firestore di [BookingService].
///
/// Field check-in/check-out dan guestCount sesuai dengan data yang
/// disimpan oleh BookingService.createBooking().
class BookingModel {
  final String id;
  final String userId;
  final String destinationId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestCount;
  final String totalPrice;
  final String status; // pending, confirmed, cancelled, completed
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Snapshot destinasi (denormalized)
  final String destinationName;
  final String? destinationCategory;
  final String? destinationLocation;
  final double? destinationRating;
  final String? destinationPrice;
  final String? destinationImageUrl;

  // Snapshot user (denormalized)
  final String userFullName;
  final String userEmail;
  final String userPhone;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.destinationId,
    required this.checkIn,
    required this.checkOut,
    required this.guestCount,
    required this.totalPrice,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.destinationName,
    this.destinationCategory,
    this.destinationLocation,
    this.destinationRating,
    this.destinationPrice,
    this.destinationImageUrl,
    required this.userFullName,
    required this.userEmail,
    required this.userPhone,
  });

  factory BookingModel.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime parseDt(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return BookingModel(
      id: id,
      userId: data['userId'] ?? '',
      destinationId: data['destinationId'] ?? '',
      checkIn: parseDt(data['checkIn']),
      checkOut: parseDt(data['checkOut']),
      guestCount: (data['guestCount'] as num?)?.toInt() ?? 1,
      totalPrice: data['totalPrice'] ?? '',
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      createdAt: parseDt(data['createdAt']),
      updatedAt: parseDt(data['updatedAt']),
      destinationName: data['destinationName'] ?? '',
      destinationCategory: data['destinationCategory'],
      destinationLocation: data['destinationLocation'],
      destinationRating: (data['destinationRating'] as num?)?.toDouble(),
      destinationPrice: data['destinationPrice'],
      destinationImageUrl: data['destinationImageUrl'],
      userFullName: data['userFullName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userPhone: data['userPhone'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'destinationId': destinationId,
      'checkIn': Timestamp.fromDate(checkIn),
      'checkOut': Timestamp.fromDate(checkOut),
      'guestCount': guestCount,
      'totalPrice': totalPrice,
      'status': status,
      'notes': notes,
      'destinationName': destinationName,
      'destinationCategory': destinationCategory,
      'destinationLocation': destinationLocation,
      'destinationRating': destinationRating,
      'destinationPrice': destinationPrice,
      'destinationImageUrl': destinationImageUrl,
      'userFullName': userFullName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'cancelled':
        return 'Dibatalkan';
      case 'completed':
        return 'Selesai';
      default:
        return 'Unknown';
    }
  }

  String get formattedCheckIn {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${checkIn.day} ${months[checkIn.month - 1]} ${checkIn.year}';
  }

  String get formattedCheckOut {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${checkOut.day} ${months[checkOut.month - 1]} ${checkOut.year}';
  }

  /// Jumlah malam antara check-in dan check-out.
  int get nightCount {
    final diff = checkOut.difference(checkIn).inDays;
    return diff > 0 ? diff : 1;
  }
}
