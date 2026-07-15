import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/review_model.dart';
import '../widgets/app_network_image.dart';

/// Widget untuk menampilkan card review individu
class ReviewCard extends StatefulWidget {
  final Review review;
  final bool isOwner; // Apakah ini review milik user saat ini
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onHelpful;
  final VoidCallback? onReport;
  final VoidCallback? onViewPhotos;

  const ReviewCard({
    super.key,
    required this.review,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
    this.onHelpful,
    this.onReport,
    this.onViewPhotos,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  late int _helpfulCount;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _helpfulCount = widget.review.helpfulCount;
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} tahun lalu';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} bulan lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Profile & Rating
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFEEF2E8),
                  backgroundImage: widget.review.userProfilePic != null
                      ? NetworkImage(widget.review.userProfilePic!)
                      : null,
                  child: widget.review.userProfilePic == null
                      ? Icon(
                          Icons.person_outline,
                          size: 20,
                          color: Colors.grey[600],
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.review.userName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          if (widget.review.isEdited) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Diedit',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          RatingStarDisplay(
                            rating: widget.review.rating.toDouble(),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getRelativeTime(widget.review.createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Menu (if owner)
                if (widget.isOwner)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    onSelected: (value) {
                      if (value == 'edit') {
                        widget.onEdit?.call();
                      } else if (value == 'delete') {
                        widget.onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const Divider(height: 24),

            // Title
            if (widget.review.title != null &&
                widget.review.title!.isNotEmpty) ...[
              Text(
                widget.review.title!,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Comment
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: _isExpanded
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      widget.review.comment,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                      maxLines: _isExpanded ? null : 3,
                      overflow: _isExpanded ? null : TextOverflow.ellipsis,
                    ),
                  ),
                  if (!_isExpanded && widget.review.comment.length > 200) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = true;
                        });
                      },
                      child: Text(
                        '... baca selengkapnya',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF2D5016),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Photos Preview
            if (widget.review.photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: widget.review.photos.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: widget.onViewPhotos,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AppNetworkImage(
                        imageUrl: widget.review.photos[index],
                        fit: BoxFit.cover,
                        placeholderLabel: 'Foto ${index + 1}',
                      ),
                    ),
                  );
                },
              ),
              if (widget.review.photos.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TextButton(
                    onPressed: widget.onViewPhotos,
                    child: Text(
                      'Lihat semua ${widget.review.photos.length} foto',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF2D5016),
                      ),
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 16),

            // Actions: Helpful & Report
            Row(
              children: [
                GestureDetector(
                  onTap: widget.onHelpful,
                  child: Row(
                    children: [
                      Icon(
                        Icons.thumb_up_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Membantu ($_helpfulCount)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onReport,
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Laporkan',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Simple helper for rating display in card
class RatingStarDisplay extends StatelessWidget {
  final double rating;

  const RatingStarDisplay({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    final filledStars = rating.floor();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isFilled = starValue <= filledStars;

        return Icon(
          Icons.star_rounded,
          color: isFilled ? const Color(0xFFFFC107) : Colors.grey[300],
          size: 16,
        );
      }),
    );
  }
}
