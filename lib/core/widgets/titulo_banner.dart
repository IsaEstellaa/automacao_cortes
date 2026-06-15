import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import './painters.dart';

class TituloBanner extends StatelessWidget {
  final String titulo;

  const TituloBanner({
    super.key,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: AppColors.fundoFitaRosa.withOpacity(0.20),
            ),

            CustomPaint(
              painter: ListrasPainter(
                cor: AppColors.listrasFitaRosa.withOpacity(0.15),
                espessura: 10,
                espacamento: 35,
              ),
            ),

            Center(
              child: ShaderMask(
                shaderCallback: (bounds) => AppColors.gradienteTitulo.createShader(bounds),
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}