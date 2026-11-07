import 'dart:convert';

/// Jenis baris kegiatan pada linimasa "Susunan Perjalanan".
///
/// Menentukan aksi yang tersedia (Edit/Hapus vs Lihat) dan bagaimana baris
/// tersebut diperhitungkan pada statistik (jumlah tempat, jarak rute).
enum TripStopKind { departure, destination, spot, meal, returnHome }

TripStopKind _kindFromString(String? value) {
  return TripStopKind.values.firstWhere(
    (k) => k.name == value,
    orElse: () => TripStopKind.spot,
  );
}

/// Jam tulisan KITA AI memakai pemisah titik ("09.00"), linimasa memakai
/// titik dua ("09:00") — keduanya diterima di sini.
List<String> _timeParts(String value) {
  return value.replaceAll('.', ':').split(':');
}

/// Satu baris jadwal: jam, judul kegiatan, dan titik koordinat bila ada.
class TripStop {
  /// Jam dalam format `HH:mm` agar bisa dipakai pada TimePicker.
  final String time;
  final String title;

  /// Keterangan pendek di bawah judul (lokasi/alamat).
  final String note;
  final TripStopKind kind;
  final double? lat;
  final double? lng;

  /// Thumbnail + rating hanya untuk baris destinasi.
  final String? imageUrl;
  final double? rating;

  const TripStop({
    required this.time,
    required this.title,
    this.note = 'Factual location',
    this.kind = TripStopKind.spot,
    this.lat,
    this.lng,
    this.imageUrl,
    this.rating,
  });

  /// Baris kegiatan tetap (UMKM sekitar, kepulangan) tidak bisa diubah.
  bool get isEditable =>
      kind == TripStopKind.departure ||
      kind == TripStopKind.destination ||
      kind == TripStopKind.meal;

  bool get hasPosition => lat != null && lng != null;

  /// Jam dalam menit sejak tengah hari, dipakai untuk menghitung durasi.
  int get minutesOfDay => hourOf(time) * 60 + minuteOf(time);

  /// Jam dalam format 24 jam (`HH:mm`), aman untuk TimePicker.
  String get normalizedTime =>
      '${hourOf(time).toString().padLeft(2, '0')}:'
      '${minuteOf(time).toString().padLeft(2, '0')}';

  /// Jam tulisan jadwal (mis. "09.00"/"09:00") sebagai angka 0-23.
  static int hourOf(String value) {
    final parts = _timeParts(value);
    return parts.isEmpty ? 0 : (int.tryParse(parts.first) ?? 0);
  }

  static int minuteOf(String value) {
    final parts = _timeParts(value);
    return parts.length < 2 ? 0 : (int.tryParse(parts[1]) ?? 0);
  }

  TripStop copyWith({String? time, String? title, String? note}) {
    return TripStop(
      time: time ?? this.time,
      title: title ?? this.title,
      note: note ?? this.note,
      kind: kind,
      lat: lat,
      lng: lng,
      imageUrl: imageUrl,
      rating: rating,
    );
  }

  Map<String, dynamic> toJson() => {
    'time': time,
    'title': title,
    'note': note,
    'kind': kind.name,
    'lat': lat,
    'lng': lng,
    'imageUrl': imageUrl,
    'rating': rating,
  };

  factory TripStop.fromJson(Map<String, dynamic> json) => TripStop(
    time: (json['time'] ?? '08:00').toString(),
    title: (json['title'] ?? 'Kegiatan').toString(),
    note: (json['note'] ?? 'Factual location').toString(),
    kind: _kindFromString(json['kind']?.toString()),
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
    imageUrl: json['imageUrl']?.toString(),
    rating: (json['rating'] as num?)?.toDouble(),
  );
}

/// Rencana perjalanan yang sudah dipesan/dibuat dan tampil di halaman Trip.
class TripPlan {
  /// Id stabil: id booking, atau `ai-<destinationId>-<tanggal>`.
  final String id;

  /// Judul singkat, mis. "Hemat Bukit Sakura".
  final String title;
  final String destinationId;
  final String destinationName;
  final String imageUrl;

  /// Snapshot destinasi untuk layar detail (nama, lokasi, harga, rating).
  final Map<String, dynamic> destination;
  final DateTime visitDate;

  /// Estimasi biaya per orang dalam rupiah.
  final int costPerPerson;

  /// Booking terkait, bila jadwal sudah benar-benar dipesan.
  final String? bookingId;
  final List<TripStop> stops;

  const TripPlan({
    required this.id,
    required this.title,
    required this.stops,
    this.destinationId = '',
    this.destinationName = '',
    this.imageUrl = '',
    this.destination = const {},
    required this.visitDate,
    this.costPerPerson = 0,
    this.bookingId,
  });

  int get stopCount => stops.length;

  TripPlan copyWith({List<TripStop>? stops, String? bookingId}) {
    return TripPlan(
      id: id,
      title: title,
      destinationId: destinationId,
      destinationName: destinationName,
      imageUrl: imageUrl,
      destination: destination,
      visitDate: visitDate,
      costPerPerson: costPerPerson,
      bookingId: bookingId ?? this.bookingId,
      stops: stops ?? this.stops,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'destinationId': destinationId,
    'destinationName': destinationName,
    'imageUrl': imageUrl,
    'destination': destination,
    'visitDate': visitDate.toIso8601String(),
    'costPerPerson': costPerPerson,
    'bookingId': bookingId,
    'stops': stops.map((s) => s.toJson()).toList(),
  };

  factory TripPlan.fromJson(Map<String, dynamic> json) {
    final rawStops = json['stops'];
    return TripPlan(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Perjalanan').toString(),
      destinationId: (json['destinationId'] ?? '').toString(),
      destinationName: (json['destinationName'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      destination: json['destination'] is Map
          ? Map<String, dynamic>.from(json['destination'] as Map)
          : const {},
      visitDate:
          DateTime.tryParse((json['visitDate'] ?? '').toString()) ??
          DateTime.now(),
      costPerPerson: (json['costPerPerson'] as num?)?.toInt() ?? 0,
      bookingId: json['bookingId']?.toString(),
      stops: rawStops is List
          ? rawStops
                .whereType<Map>()
                .map((s) => TripStop.fromJson(s.cast<String, dynamic>()))
                .toList()
          : const [],
    );
  }

  static String encodeList(List<TripPlan> plans) =>
      jsonEncode(plans.map((p) => p.toJson()).toList());

  static List<TripPlan> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => TripPlan.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
