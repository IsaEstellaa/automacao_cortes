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
                height: 56,
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
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Center(
                        child: Text(
                          peca.nome,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textoPreto,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // capa da peça: a primeira foto
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  peca.fotos.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Center(
                            child: Icon(
                              Icons.checkroom_outlined, // TODO: substituir pelo SVG da peça
                              size: 64,
                              color: AppColors.green,
                            ),
                          ),
                        )
                      : SizedBox.expand(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(9),
                              bottomRight: Radius.circular(39),
                            ),
                            child: Image.network(
                              peca.fotos.first.url,
                              fit: BoxFit.cover,
                              cacheWidth: 500,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(
                                  Icons.checkroom_outlined,
                                  size: 64,
                                  color: AppColors.green,
                                ),
                              ),
                              loadingBuilder: (_, filho, progresso) => progresso == null
                                  ? filho
                                  : Center(
                                      child: Icon(
                                        Icons.checkroom_outlined,
                                        size: 64,
                                        color: AppColors.green.withOpacity(0.3),
                                      ),
                                    ),
                            ),
                          ),
                        ),

                  // sombrinha suave embaixo do nome
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 8,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.12),
                              Colors.black.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // estrela de favorito sobre a foto
                  Positioned(
                    bottom: 5,
                    left: 5,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: aoFavoritar,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.80),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          peca.favorito ? Icons.star : Icons.star_border,
                          size: 20,
                          color: peca.favorito
                              ? const Color.fromARGB(255, 148, 112, 6)
                              : AppColors.green.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}