import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget untuk menampilkan interactive star rating (1-5 stars)
class RatingStarWidget extends StatefulWidget {
  final double rating; // Current rating (0-5)
  final int maxStars; // Default: 5
  final Function(int)? onRatingChanged; // Callback saat rating berubah
  final bool readOnly; // Readonly mode (tampilan saja)
  final Color? activeColor; // Warna star aktif
  final Color? inactiveColor; // Warna star tidak aktif
  final double size; // Ukuran icon default: 24
  final EdgeInsetsGeometry? padding;

  const RatingStarWidget({
    super.key,
    required this.rating,
    this.maxStars = 5,
    this.onRatingChanged,
    this.readOnly = false,
    this.activeColor,
    this.inactiveColor,
    this.size = 24,
    this.padding,
  });

  @override
  State<RatingStarWidget> createState() => _RatingStarWidgetState();
}

class _RatingStarWidgetState extends State<RatingStarWidget> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  @override
  void didUpdateWidget(RatingStarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating) {
      setState(() {
        _currentRating = widget.rating;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxStars, (index) {
        final starValue = index + 1;
        final isFilled = starValue <= _currentRating.round();

        return GestureDetector(
          onTap: widget.readOnly
              ? null
              : () {
                  setState(() {
                    _currentRating = starValue.toDouble();
                  });
                  widget.onRatingChanged?.call(starValue);
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            margin: widget.padding ?? const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              Icons.star_rounded,
              color: isFilled
                  ? widget.activeColor ?? const Color(0xFFFFD54F)
                  : widget.inactiveColor ?? Colors.grey[300],
              size: widget.size,
            ),
          ),
        );
      }),
    );
  }
}

/// Widget untuk menampilkan static rating display (readonly)
class StaticRatingDisplay extends StatelessWidget {
  final double rating;
  final int maxStars;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const StaticRatingDisplay({
    super.key,
    required this.rating,
    this.maxStars = 5,
    this.size = 20,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final filledStars = rating.floor();
    final hasHalfStar = rating % 1 >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        final starValue = index + 1;
        Color color;

        if (starValue <= filledStars) {
          color = activeColor ?? const Color(0xFFFFC107);
        } else if (starValue == filledStars + 1 && hasHalfStar) {
          // Half star not implemented in simple version
          color = inactiveColor ?? Colors.grey[300]!;
        } else {
          color = inactiveColor ?? Colors.grey[300]!;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Icon(Icons.star_rounded, color: color, size: size),
        );
      }),
    );
  }
}

/// Widget untuk menampilkan summary rating dengan bar chart
class RatingSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> distribution; // {'5': count, '4': count, ...}
  final int totalReviews;
  final double averageRating;

  const RatingSummaryWidget({
    super.key,
    required this.distribution,
    required this.totalReviews,
    required this.averageRating,
  });

  @override
  Widget build(BuildContext context) {
    if (totalReviews == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Average rating large display
        Row(
          children: [
            Text(
              averageRating.toStringAsFixed(1),
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D5016),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StaticRatingDisplay(rating: averageRating, size: 24),
            ),
            const SizedBox(width: 8),
            Text(
              '($totalReviews reviews)',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Breakdown per bintang
        ...List.generate(5, (index) {
          final starCount = 5 - index;
          final count = distribution['$starCount'] ?? 0;
          final percentage = totalReviews > 0
              ? (count / totalReviews * 100)
              : 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  '$starCount ${starCount == 1 ? '★' : '★★★'}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFC107),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${percentage.toInt().round()}%',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '($count)',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
