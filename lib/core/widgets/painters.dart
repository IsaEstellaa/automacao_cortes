import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

// ============================================
// desenho da borda tracejada
// ============================================
class BordaTracejadaPainter extends CustomPainter {
  final List<BoxShadow> sombras;

  BordaTracejadaPainter({this.sombras = const []});

  @override
  void paint(Canvas canvas, Size size) {

    final rect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(6),
      bottomLeft: const Radius.circular(6),
      bottomRight: const Radius.circular(20),
    );

    for (final sombra in sombras) {
      final paint = Paint()
        ..color = sombra.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sombra.blurRadius);
      canvas.drawRRect(rect.shift(sombra.offset), paint);
    }

    final background = Paint()
      ..color = Color.fromARGB(200, 224, 213, 200)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rect, background);

    final paint = Paint()
      ..color = AppColors.tracejado
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    _drawDashedRRect(canvas, rect, paint);
  }

  void _drawDashedRRect(Canvas canvas, RRect rrect, Paint paint) {
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    const dashLen = 8.0;
    const gapLen = 4.0;

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + dashLen).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        distance += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================
// desenha as listras
// ============================================
class ListrasPainter extends CustomPainter {
  final Color cor;
  final double espessura;
  final double espacamento;

  ListrasPainter({
    required this.cor,
    this.espessura = 4,
    this.espacamento = 13,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cor
      ..strokeWidth = espessura;

    for (double x = -size.height; x < size.width + size.height; x += espacamento) {
      canvas.drawLine(
        Offset(x, -2),
        Offset(x + size.height, size.height + 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}