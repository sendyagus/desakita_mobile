import 'package:intl/intl.dart';

enum AnalyticsPeriod { week, month, threeMonths }

class BookingAnalyticsHelper {
  static DateTime rangeStart(AnalyticsPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case AnalyticsPeriod.week:
        return today.subtract(const Duration(days: 6));
      case AnalyticsPeriod.month:
        return DateTime(now.year, now.month, 1);
      case AnalyticsPeriod.threeMonths:
        return today.subtract(const Duration(days: 89));
    }
  }

  static DateTime rangeEnd() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  static String periodLabel(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.week:
        return 'Minggu Ini';
      case AnalyticsPeriod.month:
        return 'Bulan Ini';
      case AnalyticsPeriod.threeMonths:
        return '3 Bulan Terakhir';
    }
  }

  static String periodRangeText(AnalyticsPeriod period) {
    final start = rangeStart(period);
    final end = rangeEnd();
    final fmt = DateFormat('dd MMM yyyy', 'id_ID');
    return '${fmt.format(start)} — ${fmt.format(end)}';
  }

  static DateTime? parseCreatedAt(Map<String, dynamic> booking) {
    return DateTime.tryParse(booking['created_at'] as String? ?? '');
  }

  static List<Map<String, dynamic>> filterByPeriod(
    List<Map<String, dynamic>> bookings,
    AnalyticsPeriod period,
  ) {
    final start = rangeStart(period);
    final end = rangeEnd();
    return bookings.where((b) {
      final created = parseCreatedAt(b);
      if (created == null) return false;
      return !created.isBefore(start) && !created.isAfter(end);
    }).toList();
  }

  static Map<String, int> countByStatus(List<Map<String, dynamic>> list) {
    return {
      'pending': list.where((b) => b['status'] == 'pending').length,
      'confirmed': list.where((b) => b['status'] == 'confirmed').length,
      'cancelled': list.where((b) => b['status'] == 'cancelled').length,
      'completed': list.where((b) => b['status'] == 'completed').length,
    };
  }

  static int parseRevenueAmount(List<Map<String, dynamic>> list) {
    int total = 0;
    for (final b in list) {
      if (b['status'] != 'confirmed' && b['status'] != 'completed') continue;
      final price =
          (b['total_price'] as String? ?? '').replaceAll(RegExp(r'[^0-9]'), '');
      total += int.tryParse(price) ?? 0;
    }
    return total;
  }

  static String formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  static String statusLabel(String s) {
    switch (s) {
      case 'pending':
        return 'Menunggu';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'cancelled':
        return 'Dibatalkan';
      case 'completed':
        return 'Selesai';
      default:
        return s;
    }
  }

  /// Data batang: jumlah booking per bucket waktu.
  static List<BarBucket> barBuckets(
    List<Map<String, dynamic>> bookings,
    AnalyticsPeriod period,
  ) {
    final start = rangeStart(period);
    final end = rangeEnd();
    final buckets = <BarBucket>[];

    if (period == AnalyticsPeriod.week) {
      for (var i = 0; i < 7; i++) {
        final day = start.add(Duration(days: i));
        if (day.isAfter(end)) break;
        final label = DateFormat('E', 'id_ID').format(day);
        final count = bookings.where((b) {
          final c = parseCreatedAt(b);
          if (c == null) return false;
          return c.year == day.year &&
              c.month == day.month &&
              c.day == day.day;
        }).length;
        buckets.add(BarBucket(label: label, count: count));
      }
    } else if (period == AnalyticsPeriod.month) {
      final daysInMonth = DateTime(end.year, end.month + 1, 0).day;
      final step = daysInMonth > 20 ? 5 : 1;
      for (var d = 1; d <= daysInMonth; d += step) {
        final day = DateTime(end.year, end.month, d);
        if (day.isBefore(start)) continue;
        final endDay = (d + step - 1).clamp(1, daysInMonth);
        final count = bookings.where((b) {
          final c = parseCreatedAt(b);
          if (c == null) return false;
          return c.year == day.year &&
              c.month == day.month &&
              c.day >= d &&
              c.day <= endDay;
        }).length;
        buckets.add(BarBucket(label: '$d', count: count));
      }
    } else {
      for (var m = 0; m < 3; m++) {
        final monthDate = DateTime(start.year, start.month + m, 1);
        final label = DateFormat('MMM', 'id_ID').format(monthDate);
        final count = bookings.where((b) {
          final c = parseCreatedAt(b);
          if (c == null) return false;
          return c.year == monthDate.year && c.month == monthDate.month;
        }).length;
        buckets.add(BarBucket(label: label, count: count));
      }
    }

    return buckets;
  }
}

class BarBucket {
  final String label;
  final int count;

  BarBucket({required this.label, required this.count});
}
