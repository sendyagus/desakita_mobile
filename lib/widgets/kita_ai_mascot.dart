import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:desa_wisata/theme/desakita_theme.dart';

/// Maskot "Kita AI" DesaKita: robot ramah berwarna hijau dengan daun di kepala.
/// Digambar dengan CustomPainter agar tajam di semua ukuran (tanpa aset bitmap).
class KitaAiMascot extends StatelessWidget {
  final double size;
  final Color? color;

  const KitaAiMascot({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MascotPainter(primary: color ?? DesaKitaColors.primary),
        willChange: false,
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final Color primary;

  const _MascotPainter({required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    final bodyPaint = Paint()..color = primary;
    final lightPaint = Paint()..color = const Color(0xFFE6F3E7);
    final whitePaint = Paint()..color = Colors.white;
    final darkPaint = Paint()..color = const Color(0xFF154212);
    final leafPaint = Paint()..color = const Color(0xFF10B981);

    // Antena
    final antenna = Paint()
      ..color = primary
      ..strokeWidth = 1.6 * s
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(12 * s, 4.2 * s), Offset(12 * s, 2.2 * s), antenna);
    canvas.drawCircle(Offset(12 * s, 2.0 * s), 1.25 * s, leafPaint);

    // Daun di kepala
    canvas.save();
    canvas.translate(15.4 * s, 6.6 * s);
    canvas.rotate(-math.pi / 5);
    final leafPath = Path()
      ..addOval(Rect.fromLTWH(0, -1.1 * s, 3.6 * s, 2.2 * s));
    canvas.drawPath(leafPath, leafPaint);
    canvas.restore();

    // Kepala/badan kapsul
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4.2 * s, 6.4 * s, 15.6 * s, 13.4 * s),
      Radius.circular(5.4 * s),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Wajah (panel terang)
    final faceRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(6.6 * s, 9.2 * s, 10.8 * s, 7.6 * s),
      Radius.circular(3.6 * s),
    );
    canvas.drawRRect(faceRect, lightPaint);

    // Mata
    canvas.drawCircle(Offset(10.0 * s, 12.8 * s), 1.35 * s, darkPaint);
    canvas.drawCircle(Offset(14.0 * s, 12.8 * s), 1.35 * s, darkPaint);
    canvas.drawCircle(Offset(10.45 * s, 12.35 * s), 0.45 * s, whitePaint);
    canvas.drawCircle(Offset(14.45 * s, 12.35 * s), 0.45 * s, whitePaint);

    // Senyum
    final smile = Paint()
      ..color = const Color(0xFF154212)
      ..strokeWidth = 1.1 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final smileRect = Rect.fromLTWH(10.4 * s, 13.6 * s, 3.2 * s, 2.2 * s);
    canvas.drawArc(smileRect, 0.15 * math.pi, 0.7 * math.pi, false, smile);

    // Pipi
    final cheek = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.55);
    canvas.drawCircle(Offset(8.0 * s, 14.6 * s), 0.8 * s, cheek);
    canvas.drawCircle(Offset(16.0 * s, 14.6 * s), 0.8 * s, cheek);

    // Kaki kecil
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(7.4 * s, 19.4 * s, 3.2 * s, 2.4 * s),
        Radius.circular(1.2 * s),
      ),
      bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(13.4 * s, 19.4 * s, 3.2 * s, 2.4 * s),
        Radius.circular(1.2 * s),
      ),
      bodyPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) =>
      oldDelegate.primary != primary;
}
