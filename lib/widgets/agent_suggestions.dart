import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Baris chip saran pertanyaan populer di AgentScreen.
class AgentSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSuggestionTap;

  const AgentSuggestions({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F0),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pertanyaan populer',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    final cleanText = suggestions[index]
                        .replaceAll(RegExp(r'[^\w\s]'), '')
                        .trim();
                    onSuggestionTap(cleanText);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFDDE8D0),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      suggestions[index],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF2D5016),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
