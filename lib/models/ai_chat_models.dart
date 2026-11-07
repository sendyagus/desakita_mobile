/// Model lampiran "kaya" pada balasan KITA AI.
///
/// Balasan bot tidak lagi sekadar teks: bisa membawa kartu rekomendasi
/// destinasi, pilihan budget, atau itinerary yang dirender di bawah bubble.
enum AiAttachmentKind { destinations, budgetOptions, itinerary }

class AiChatAttachment {
  final AiAttachmentKind kind;

  /// Dipakai pada [AiAttachmentKind.destinations].
  final List<Map<String, dynamic>> places;

  /// Dipakai pada [AiAttachmentKind.budgetOptions].
  final List<String> options;

  /// Dipakai pada [AiAttachmentKind.itinerary].
  final AiItinerary? itinerary;

  const AiChatAttachment({
    required this.kind,
    this.places = const [],
    this.options = const [],
    this.itinerary,
  });

  factory AiChatAttachment.destinations(List<Map<String, dynamic>> places) =>
      AiChatAttachment(kind: AiAttachmentKind.destinations, places: places);

  factory AiChatAttachment.budget(List<String> options) =>
      AiChatAttachment(kind: AiAttachmentKind.budgetOptions, options: options);

  factory AiChatAttachment.trip(AiItinerary itinerary) =>
      AiChatAttachment(kind: AiAttachmentKind.itinerary, itinerary: itinerary);
}

/// Satu baris kegiatan pada itinerary (jam + aktivitas).
class AiItineraryStop {
  final String time;
  final String activity;

  const AiItineraryStop(this.time, this.activity);
}

/// Rencana kegiatan singkat untuk satu destinasi.
class AiItinerary {
  /// Judul kartu, mis. "Trip Heading: Hemat Bukit Sakura".
  final String title;
  final String destinationName;
  final String imageUrl;

  /// Data destinasi mentah, dipakai saat user menekan "Pesan Tiket".
  final Map<String, dynamic> destination;

  final List<AiItineraryStop> stops;

  /// Estimasi biaya per orang (rupiah, tanpa pemisah).
  final int costPerPerson;

  const AiItinerary({
    required this.title,
    required this.destinationName,
    required this.imageUrl,
    required this.destination,
    required this.stops,
    required this.costPerPerson,
  });
}
