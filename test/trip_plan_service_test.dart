import 'package:flutter_test/flutter_test.dart';

import 'package:desa_wisata/models/ai_chat_models.dart';
import 'package:desa_wisata/models/trip_plan.dart';
import 'package:desa_wisata/services/trip_plan_service.dart';

void main() {
  final destination = <String, dynamic>{
    'id': 'd1',
    'name': 'Bukit Sakura',
    'location': 'Kemiling, Bandar Lampung',
    'rating': 4.8,
    'image_url': 'https://example.com/bukit.jpg',
    'latitude': -5.404013,
    'longitude': 105.222813,
  };

  AiItinerary sampleItinerary() => AiItinerary(
    title: 'Trip Heading: Hemat Bukit Sakura',
    destinationName: 'Bukit Sakura',
    imageUrl: 'https://example.com/bukit.jpg',
    destination: destination,
    stops: const [
      AiItineraryStop('06.00', 'Berangkat dari rumah menuju Bukit Sakura'),
      AiItineraryStop('07.00', 'Tiba, beli tiket masuk, keliling area'),
      AiItineraryStop('08.30', 'Eksplor spot foto dan area kebun'),
      AiItineraryStop('10.30', 'Istirahat, jajan makanan lokal'),
      AiItineraryStop('12.00', 'Foto terakhir dan pulang'),
    ],
    costPerPerson: 75000,
  );

  group('planFromItinerary', () {
    test('normalizes dotted AI times and classifies every row', () {
      final plan = TripPlanService.instance.planFromItinerary(
        sampleItinerary(),
        visitDate: DateTime(2026, 11, 7),
      );

      expect(plan.title, 'Hemat Bukit Sakura');
      expect(plan.id, 'ai-d1-20261107');
      expect(plan.stops.first.time, '06:00');
      expect(plan.stops.first.kind, TripStopKind.departure);
      expect(plan.stops[1].kind, TripStopKind.destination);
      expect(plan.stops[1].title, 'Sampai ke Bukit Sakura');
      expect(plan.stops[2].kind, TripStopKind.spot);
      expect(plan.stops[3].kind, TripStopKind.meal);
      expect(plan.stops.last.kind, TripStopKind.returnHome);
      expect(plan.destinationId, 'd1');
      expect(plan.costPerPerson, 75000);
    });

    test('shifts the whole schedule to the booked session start hour', () {
      final plan = TripPlanService.instance.planFromItinerary(
        sampleItinerary(),
        visitDate: DateTime(2026, 11, 8),
        startHour: 9,
      );

      expect(plan.stops.first.time, '09:00');
      expect(plan.stops[1].time, '10:00');
      expect(plan.stops[2].time, '11:30');
      expect(plan.stops.last.time, '15:00');
    });

    test('destination row carries coordinates, photo and rating', () {
      final plan = TripPlanService.instance.planFromItinerary(
        sampleItinerary(),
        visitDate: DateTime(2026, 11, 7),
      );
      final stop = plan.stops[1];

      expect(stop.hasPosition, isTrue);
      expect(stop.lat, closeTo(-5.404013, 0.000001));
      expect(stop.imageUrl, 'https://example.com/bukit.jpg');
      expect(stop.rating, 4.8);
      expect(stop.isEditable, isTrue);
      expect(plan.stops.last.isEditable, isFalse);
    });
  });

  group('planForBooking', () {
    final booking = <String, dynamic>{
      'id': 'b1',
      'check_in': DateTime(2026, 11, 8, 8).toIso8601String(),
      'guest_count': 2,
      'total_price': 'Rp 150.000',
      'destinations': <String, dynamic>{
        'id': 'd2',
        'name': 'Puncak Mas',
        'location': 'Kemiling',
        'image_url': 'https://example.com/puncak.jpg',
      },
    };

    test('builds a schedule around the session check-in hour', () {
      final plan = TripPlanService.instance.planForBooking(booking, const []);

      expect(plan.bookingId, 'b1');
      expect(plan.id, 'booking-b1');
      expect(plan.visitDate, DateTime(2026, 11, 8));
      expect(plan.stops.first.time, '07:00');
      expect(plan.stops.first.kind, TripStopKind.departure);
      expect(plan.stops[1].title, 'Sampai ke Puncak Mas');
      expect(plan.stops[1].kind, TripStopKind.destination);
      expect(plan.costPerPerson, 75000);
    });

    test('reuses the stored KITA AI plan for the same booking', () {
      final aiPlan = TripPlanService.instance.planFromItinerary(
        sampleItinerary(),
        visitDate: DateTime(2026, 11, 8),
        bookingId: 'b1',
      );

      final resolved = TripPlanService.instance.planForBooking(booking, [
        aiPlan,
      ]);

      expect(resolved.id, aiPlan.id);
      expect(resolved.stops.length, aiPlan.stops.length);
    });
  });

  group('statsOf', () {
    test('derives duration, distance and place count from the stops', () {
      final stats = TripPlanService.statsOf(TripPlanService.demoPlans().first);

      expect(stats.duration, '9 Jam');
      expect(stats.placeCount, 2);
      expect(stats.distanceKm, greaterThan(0));
      expect(stats.distanceLabel, contains('KM'));
    });

    test('empty schedule reports zeroed statistics', () {
      final empty = TripPlan(
        id: 'x',
        title: 'Kosong',
        visitDate: DateTime(2026, 11, 7),
        stops: const [],
      );
      final stats = TripPlanService.statsOf(empty);

      expect(stats.duration, '0 Jam');
      expect(stats.placeCount, 0);
      expect(stats.distanceKm, 0);
    });
  });

  group('routeOf', () {
    test('falls back to the demo route when positions are missing', () {
      final plan = TripPlan(
        id: 'x',
        title: 'Tanpa koordinat',
        visitDate: DateTime(2026, 11, 7),
        stops: const [TripStop(time: '08:00', title: 'Hanya satu kegiatan')],
      );

      expect(TripPlanService.routeOf(plan), TripPlanService.fallbackRoute);
    });

    test('closes the loop back to the starting point', () {
      final plan = TripPlanService.demoPlans().first;
      final route = TripPlanService.routeOf(plan);

      expect(route.length, greaterThan(2));
      expect(route.first.latitude, closeTo(route.last.latitude, 0.000001));
    });
  });

  group('serialization', () {
    test('keeps stops, kinds and dates intact', () {
      final plan = TripPlanService.instance.planFromItinerary(
        sampleItinerary(),
        visitDate: DateTime(2026, 11, 7),
      );
      final decoded = TripPlan.decodeList(TripPlan.encodeList([plan])).single;

      expect(decoded.id, plan.id);
      expect(decoded.visitDate, plan.visitDate);
      expect(decoded.stops.length, plan.stops.length);
      expect(decoded.stops[1].kind, TripStopKind.destination);
      expect(decoded.stops[1].lat, plan.stops[1].lat);
      expect(decoded.destination['name'], 'Bukit Sakura');
    });

    test('ignores corrupted payloads', () {
      expect(TripPlan.decodeList('bukan json'), isEmpty);
      expect(TripPlan.decodeList(null), isEmpty);
    });
  });

  group('suggestedVisitDate', () {
    test('lands on a Saturday', () {
      expect(
        TripPlanService.suggestedVisitDate(DateTime(2026, 11, 4)).weekday,
        DateTime.saturday,
      );
      expect(
        TripPlanService.suggestedVisitDate(DateTime(2026, 11, 6)).weekday,
        DateTime.saturday,
      );
    });
  });

  group('demoPlans', () {
    test('reproduces the designed Bukit Sakura & Puncak Mas timeline', () {
      final plans = TripPlanService.demoPlans();
      final times = plans.expand((p) => p.stops).map((s) => s.time).toList()
        ..sort();

      expect(plans.map((p) => p.destinationName), [
        'Bukit Sakura',
        'Puncak Mas',
      ]);
      expect(times, ['08:00', '08:20', '09:00', '12:00', '14:00', '17:00']);
    });
  });
}
