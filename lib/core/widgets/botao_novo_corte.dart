import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import './painters.dart';

class BotaoNovoCorte extends StatelessWidget {
  final VoidCallback aoTocar;

  const BotaoNovoCorte({
    super.key,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: aoTocar,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(40),
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(10),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 102,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ícones aleatórios
              CustomPaint(
                painter: IconesFundoPainter(
                  icones: [
                    Icons.tips_and_updates,
                    Icons.content_cut,
                    Icons.auto_awesome,
                    Icons.straighten,
                    Icons.color_lens,
                    Icons.precision_manufacturing,
                  ],
                  cor: AppColors.green.withOpacity(0.50),
                ),
              ),

              // fundo semi-transparente
              Container(
                color: AppColors.buttonBrown.withOpacity(0.75),
              ),

              // texto
              ShaderMask(
                shaderCallback: (bounds) => AppColors.gradienteTitulo.createShader(bounds),
                child: Center(
                  child: Text(
                    'Novo corte',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}