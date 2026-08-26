import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';
import './painters.dart';

class CardNav extends StatelessWidget {
  final String titulo;
  final VoidCallback aoTocar;
  final IconData? icone;
  final String? svgPath;
  final bool isPng;

  const CardNav({
    super.key,
    required this.titulo,
    required this.aoTocar,
    this.icone,
    this.svgPath,
    this.isPng = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: aoTocar,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(40),
          ),
          border: Border.all(color: AppColors.bordaMarrom, width: 1),
          boxShadow: AppColors.sombra,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // título com listras
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(10),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // listras
                    CustomPaint(
                      painter: ListrasPainter(
                        cor: AppColors.listrasFitaRosa.withOpacity(0.15),
                        espessura: 6,
                        espacamento: 20,
                      ),
                    ),

                    // fundo semi-transparente
                    Container(
                      color: AppColors.fundoFitaRosa.withOpacity(0.20),
                    ),

                    // texto por cima
                    Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) => AppColors.gradienteTitulo.createShader(bounds),
                        child: Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textoPreto,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),
            Center(child: _buildIcone()),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildIcone() {
    if (svgPath != null && isPng) {
      return Image.asset(svgPath!, width: 80, height: 80,
          color: AppColors.green, colorBlendMode: BlendMode.srcIn);
    }
    if (svgPath != null) {
      return SvgPicture.asset(svgPath!, width: 80, height: 80,
          colorFilter: ColorFilter.mode(AppColors.green, BlendMode.srcIn));
    }
    return Icon(icone, size: 80, color: AppColors.green);
  }
}