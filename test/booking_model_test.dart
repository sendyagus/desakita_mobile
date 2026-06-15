import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desa_wisata/models/booking_model.dart';

void main() {
  final now = DateTime(2025, 6, 15, 10, 0);
  final checkIn = DateTime(2025, 7, 1);
  final checkOut = DateTime(2025, 7, 3);

  final sampleData = <String, dynamic>{
    'userId': 'user_123',
    'destinationId': 'dest_456',
    'checkIn': Timestamp.fromDate(checkIn),
    'checkOut': Timestamp.fromDate(checkOut),
    'guestCount': 2,
    'totalPrice': 'Rp 900.000',
    'status': 'pending',
    'notes': 'Minta extra bed',
    'createdAt': Timestamp.fromDate(now),
    'updatedAt': Timestamp.fromDate(now),
    'destinationName': 'Villa Hijau',
    'destinationCategory': 'Penginapan',
    'destinationLocation': 'Kemiling',
    'destinationRating': 4.5,
    'destinationPrice': 'Rp 450.000',
    'destinationImageUrl': 'https://example.com/img.jpg',
    'userFullName': 'Budi Santoso',
    'userEmail': 'budi@example.com',
    'userPhone': '08123456789',
  };

  group('BookingModel.fromFirestore', () {
    test('parses all fields correctly', () {
      final booking = BookingModel.fromFirestore('booking_1', sampleData);

      expect(booking.id, 'booking_1');
      expect(booking.userId, 'user_123');
      expect(booking.destinationId, 'dest_456');
      expect(booking.checkIn, checkIn);
      expect(booking.checkOut, checkOut);
      expect(booking.guestCount, 2);
      expect(booking.totalPrice, 'Rp 900.000');
      expect(booking.status, 'pending');
      expect(booking.notes, 'Minta extra bed');
      expect(booking.destinationName, 'Villa Hijau');
      expect(booking.destinationCategory, 'Penginapan');
      expect(booking.destinationLocation, 'Kemiling');
      expect(booking.destinationRating, 4.5);
      expect(booking.destinationPrice, 'Rp 450.000');
      expect(booking.userFullName, 'Budi Santoso');
      expect(booking.userEmail, 'budi@example.com');
      expect(booking.userPhone, '08123456789');
    });

    test('handles missing optional fields gracefully', () {
      final minimalData = <String, dynamic>{
        'checkIn': Timestamp.fromDate(checkIn),
        'checkOut': Timestamp.fromDate(checkOut),
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final booking = BookingModel.fromFirestore('booking_2', minimalData);

      expect(booking.userId, '');
      expect(booking.destinationId, '');
      expect(booking.guestCount, 1); // default
      expect(booking.totalPrice, ''); // default
      expect(booking.status, 'pending'); // default
      expect(booking.notes, isNull);
      expect(booking.destinationCategory, isNull);
      expect(booking.destinationRating, isNull);
    });
  });

  group('BookingModel.statusLabel', () {
    test('returns correct Indonesian label for each status', () {
      BookingModel makeBooking(String status) =>
          BookingModel.fromFirestore('x', {...sampleData, 'status': status});

      expect(makeBooking('pending').statusLabel, 'Menunggu Konfirmasi');
      expect(makeBooking('confirmed').statusLabel, 'Dikonfirmasi');
      expect(makeBooking('cancelled').statusLabel, 'Dibatalkan');
      expect(makeBooking('completed').statusLabel, 'Selesai');
      expect(makeBooking('unknown').statusLabel, 'Unknown');
    });
  });

  group('BookingModel.nightCount', () {
    test('calculates nights correctly', () {
      final booking = BookingModel.fromFirestore('x', sampleData);
      // July 1 to July 3 = 2 nights
      expect(booking.nightCount, 2);
    });

    test('returns 1 when same day', () {
      final sameDay = <String, dynamic>{
        ...sampleData,
        'checkIn': Timestamp.fromDate(DateTime(2025, 7, 1)),
        'checkOut': Timestamp.fromDate(DateTime(2025, 7, 1)),
      };
      final booking = BookingModel.fromFirestore('x', sameDay);
      expect(booking.nightCount, 1); // minimum 1
    });
  });

  group('BookingModel.formattedCheckIn', () {
    test('formats in Indonesian locale', () {
      final booking = BookingModel.fromFirestore('x', sampleData);
      expect(booking.formattedCheckIn, '1 Juli 2025');
    });
  });

  group('BookingModel.formattedCheckOut', () {
    test('formats in Indonesian locale', () {
      final booking = BookingModel.fromFirestore('x', sampleData);
      expect(booking.formattedCheckOut, '3 Juli 2025');
    });
  });

  group('BookingModel.toFirestore', () {
    test('produces valid Firestore map', () {
      final booking = BookingModel.fromFirestore('x', sampleData);
      final map = booking.toFirestore();

      expect(map['userId'], 'user_123');
      expect(map['destinationId'], 'dest_456');
      expect(map['checkIn'], isA<Timestamp>());
      expect(map['checkOut'], isA<Timestamp>());
      expect(map['guestCount'], 2);
      expect(map['totalPrice'], 'Rp 900.000');
      expect(map['status'], 'pending');
      expect(map['destinationName'], 'Villa Hijau');
      expect(map['userFullName'], 'Budi Santoso');
    });
  });
}
