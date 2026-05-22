/// Kategori destinasi yang dipakai di Home, Explore, dan Admin.
class AppCategories {
  static const List<String> all = [
    'Alam',
    'Penginapan',
    'Kuliner',
    'Edukasi',
  ];

  static const List<String> exploreFilters = [
    'Semua',
    ...all,
  ];

  /// Kategori yang bisa dibooking (Penginapan + wisata/Alam).
  static const List<String> bookableCategories = [
    'Penginapan',
    'Alam',
  ];

  static String normalize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final lower = raw.trim().toLowerCase();
    for (final c in all) {
      if (c.toLowerCase() == lower) return c;
    }
    return raw.trim();
  }

  static bool matchesFilter(String destinationCategory, String filter) {
    if (filter == 'Semua') return true;
    return normalize(destinationCategory) == filter;
  }

  static bool isBookableCategory(String category) {
    return bookableCategories.contains(normalize(category));
  }
}
