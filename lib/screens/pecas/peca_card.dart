import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/painters.dart';
import 'pecas_content.dart';

class PecaCard extends StatelessWidget {
  final Peca peca;
  final VoidCallback aoTocar;
  final VoidCallback aoFavoritar;

  const PecaCard({
    super.key,
    required this.peca,
    required this.aoTocar,
    required this.aoFavoritar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: aoTocar,
      child: Container(
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
                    CustomPaint(
                      painter: ListrasPainter(
                        cor: AppColors.listrasFitaRosa.withOpacity(0.15),
                        espessura: 6,
                        espacamento: 20,
                      ),
                    ),
                    Container(color: AppColors.fundoFitaRosa.withOpacity(0.20)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              peca.nome,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textoPreto,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // estrela de favorito
                          GestureDetector(
                            onTap: aoFavoritar,
                            child: Icon(
                              peca.favorito ? Icons.star : Icons.star_border,
                              color: peca.favorito ? const Color.fromARGB(255, 148, 112, 6) : AppColors.green.withOpacity(0.5),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Container(
              height: 6,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 5,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
            ),

            // ícone da peça
            Expanded(
              child: Center(
                child: Icon(
                  Icons.checkroom_outlined, // TODO: substituir pelo SVG da peça
                  size: 64,
                  color: AppColors.green,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}