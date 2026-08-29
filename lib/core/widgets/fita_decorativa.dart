import 'package:flutter/material.dart';
import './painters.dart';

class FitaDecorativa extends StatelessWidget {
  final Color corFundo;
  final Color corListras;
  final double opacity;
  final double width;
  final double height;

  // ============================================
  // fitinha decorativa com listras :D
  // ============================================

  const FitaDecorativa({
    super.key,
    required this.corFundo,
    required this.corListras,
    this.opacity = 0.70,
    this.width = 105,
    this.height = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: corFundo),
        child: ClipRRect(
          child: CustomPaint(
            painter: ListrasPainter(cor: corListras),
          ),
        ),
      ),
    );
  }
}