import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient hijau (pengganti gambar)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('../assets/img/desakita.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Overlay pattern untuk efek sawah/alam
          CustomPaint(
            painter: _NaturePainter(),
          ),

          // Overlay gelap di bagian bawah untuk transisi
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x662D5016),
                  ],
                ),
              ),
            ),
          ),

          // Judul DesaKita
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Desa',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                          shadows: [
                            const Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 8,
                              color: Color(0x88000000),
                            ),
                          ],
                        ),
                      ),
                      TextSpan(
                        text: 'Kita',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                          shadows: [
                            const Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 8,
                              color: Color(0x88000000),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Ikon daun kecil
                const Icon(
                  Icons.eco,
                  color: Color(0xFFB8E06A),
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter untuk membuat efek garis-garis sawah/alam
class _NaturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Garis-garis melengkung seperti kontur sawah
    for (int i = 0; i < 8; i++) {
      final path = Path();
      final yBase = size.height * 0.3 + (i * size.height * 0.1);
      path.moveTo(0, yBase);
      path.cubicTo(
        size.width * 0.25,
        yBase - 20 + (i * 5),
        size.width * 0.75,
        yBase + 20 - (i * 3),
        size.width,
        yBase - 10 + (i * 4),
      );
      canvas.drawPath(path, paint);
    }

    // Titik-titik kecil seperti tanaman
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    for (int row = 0; row < 6; row++) {
      for (int col = 0; col < 10; col++) {
        canvas.drawCircle(
          Offset(
            col * (size.width / 9) + (row.isOdd ? 20 : 0),
            size.height * 0.2 + row * 35,
          ),
          3,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
