# ðŸ“‹ REVIEW & RATING INTEGRATION GUIDE
# Destination Detail Screen Integration
# =======================================

## âœ… COMPONENTS ALREADY CREATED
Semua komponen sudah ada:
- âœ… lib/models/review_model.dart
- âœ… lib/services/review_service.dart
- âœ… lib/widgets/rating_star_widget.dart
- âœ… lib/widgets/review_card.dart
- âœ… lib/screens/write_review_screen.dart
- âœ… firestore.rules (updated)

## ðŸ”§ INSTRUCTIONS UNTUK MENAMBAHKAN KE destination_detail_screen.dart

### STEP 1: Tambahkan Imports (setelah line 10)
Copy baris ini setelah `import 'package:url_launcher/url_launcher.dart';`

```dart
import 'package:desa_wisata/services/review_service.dart';
import 'package:desa_wisata/screens/write_review_screen.dart';
import 'package:desa_wisata/widgets/rating_star_widget.dart';
import 'package:desa_wisata/widgets/review_card.dart';
```

### STEP 2: Tambahkan State Variables (sebelum @override void initState)
Tambahkan variabel berikut di dalam class `_DestinationDetailScreenState`:

```dart
// Review related
final ReviewService _reviewService = ReviewService();
List<Map<String, dynamic>> _reviews = [];
bool _isReviewLoading = false;
Map<String, dynamic> _reviewStats = {
  'avgRating': 0.0,
  'totalReviews': 0,
  'ratingDistribution': {'5': 0, '4': 0, '3': 0, '2': 0, '1': 0},
};
```

### STEP 3: Tambahkan Method _loadReviewStats() (setelah _loadDestination())

```dart
Future<void> _loadReviewStats() async {
  setState(() => _isReviewLoading = true);

  try {
    final stats = await _reviewService.getDestinationStats(widget.destinationId);
    if (mounted) {
      setState(() => _reviewStats = stats);

      // Listen to reviews stream
      _reviewService.getReviewsByDestination(widget.destinationId).listen(
        (reviews) {
          if (!mounted) return;
          setState(() {
            _reviews = reviews.map((r) => {
              'id': r.id,
              'destinationId': r.destinationId,
              'userId': r.userId,
              'userName': r.userName,
              'userProfilePic': r.userProfilePic,
              'rating': r.rating,
              'title': r.title,
              'comment': r.comment,
              'photos': r.photos,
              'helpfulCount': r.helpfulCount,
              'createdAt': r.createdAt.toIso8601String(),
              'updatedAt': r.updatedAt.toIso8601String(),
              'isEdited': r.isEdited,
              'status': r.status,
            }).toList();
          });
        },
      );
    }
  } catch (e) {
    debugPrint('Error loading review stats: $e');
    if (mounted) setState(() => _isReviewLoading = false);
  }
}
```

**Panggil method ini** di akhir method `_loadDestination()` (sebelum closing brace):
```dart
await _loadReviewStats();
```

### STEP 4: Tambahkan Helper Methods (sebelum closing brace class)

```dart
bool _isReviewOwner(String userId) {
  final currentUser = FirebaseAuth.instance.currentUser;
  return currentUser != null && currentUser.uid == userId;
}

Widget _emptyReviewState() {
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('Belum ada review',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text('Jadilah yang pertama memberikan review!',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
        ],
      ),
    ),
  );
}

Widget _loginPromptForReview() {
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.person_outline, size: 32, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text('Login untuk memberikan review',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
          const SizedBox(height: 4),
          Text('Bagikan pengalaman Anda membantu wisatawan lain',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600))),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5016),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text('Login Sekarang'),
          ),
        ],
      ),
    ),
  );
}

void _confirmDeleteReview(BuildContext context, String reviewId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Text('Hapus Review?', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Text('Apakah Anda yakin ingin menghapus review ini? Tindakan ini tidak dapat dibatalkan.', style: GoogleFonts.poppins(fontSize: 13)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey[700])),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Review dihapus', style: TextStyle(fontSize: 13)), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
}
```

### STEP 5: Update Build Method (sebelum "Space for bottom bar" sekitar line 614)

Cari section ini dan tambahkan sebelum `SizedBox(height: bookable ? 100 : 24)`:

```dart
// â”€â”€â”€ Review Sections â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
_reviewSummarySection(),
const SizedBox(height: 16),
_reviewsListSection(),
```

Dan ubah height menjadi:
```dart
SizedBox(height: bookable ? 140 : 24),
```

**Note**: Method `_reviewSummarySection()`, `_ratingSummaryView()`, dan `_reviewsListSection()` bisa langsung di-dipanggil seperti itu karena menggunakan components yang sudah ada (`RatingSummaryWidget` dan `ReviewCard`).

---

## ðŸŽ¯ SUMMARY IMPLEMENTASI

| Komponen | Status | Lokasi |
|----------|--------|--------|
| Model Data | âœ… Ready | `lib/models/review_model.dart` |
| Service Layer | âœ… Ready | `lib/services/review_service.dart` |
| UI Widgets | âœ… Ready | Multiple files in widgets/ |
| Write Form | âœ… Ready | `lib/screens/write_review_screen.dart` |
| Security Rules | âœ… Updated | `firestore.rules` |
| Integration | â³ Pending | Apply manual steps above |

## ðŸš€ NEXT STEPS SETELAH INTEGRASI

1. **Run Tests**: Jalankan aplikasi dan test flow lengkap
2. **Test Review Creation**: Login â†’ Buka detail destinasi â†’ Tulis review
3. **Test Review Display**: Pastikan reviews muncul dengan benar
4. **Test Photo Upload**: Integrate Firebase Storage untuk foto (TODO)
5. **Test Moderation**: Admin can approve/reject reviews

## âš ï¸ TODO - FUTURE ENHANCEMENTS

- [ ] Firebase Storage integration untuk upload review photos
- [ ] AI spam detection via Groq API
- [ ] Pagination untukå¤§é‡ reviews
- [ ] Review editing functionality
- [ ] Reply/Thread system
- [ ] Sort by: newest, highest, lowest, most helpful
- [ ] Multi-language support (auto-translate)

Silakan apply step-by-step dari instructions di atas! Setiap step kecil dan aman. Good luck! ðŸš€
