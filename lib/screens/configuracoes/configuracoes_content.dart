import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/painters.dart';

class ConfiguracoesContent extends StatelessWidget {
  const ConfiguracoesContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          _buildCardPerfil(context),
          const SizedBox(height: 15),
          _buildItemMenu(
            context,
            icone: Icons.help_rounded,
            titulo: 'Ajuda',
            aoTocar: () {
              // TODO: navegar para tela de ajuda
            },
          ),
          const SizedBox(height: 15),
          _buildItemMenu(
            context,
            icone: Icons.notifications,
            titulo: 'Notificações',
            aoTocar: () {
              // TODO: navegar para tela de notificações
            },
          ),
          const SizedBox(height: 15),
          _buildItemMenu(
            context,
            icone: Icons.logout,
            titulo: 'Sair',
            aoTocar: () {
              // TODO: lógica de logout
            },
          ),
        ],
      ),
    );
  }

  // ============================================
  // cardzinho do perfil
  // ============================================
  Widget _buildCardPerfil(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(60),
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(60),
        ),
        border: Border.all(color: AppColors.bordaMarrom, width: 1),
        boxShadow: AppColors.sombra,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // foto de perfil
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(40),
            ),
            child: Container(
              width: 100,
              height: 100,
              color: AppColors.background,
              child: Icon(
                Icons.person_outline,
                size: 48,
                color: AppColors.green.withOpacity(0.4),
              ),
              // TODO: Fazerr a parte da foto
            ),
          ),
          const SizedBox(width: 12),

          // nome e descrição
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => AppColors.gradienteTitulo.createShader(bounds),
                  child: Text(
                    'Isabella Estella', // TODO: passar nome real do usuário
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lorem ipsum dolor sit its panamet, consectetur adipiscing elit. Mauris pellentesque. Suspendisse id cursus massa, blandit consectetur una.', // TODO: bio real
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textoPreto,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // ícone de editar
          GestureDetector(
            onTap: () {
              // TODO: navegar para tela de editar perfil
            },
            child: Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.green.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // itens das configurações
  // ============================================
  Widget _buildItemMenu(
    BuildContext context, {
    required IconData icone,
    required String titulo,
    required VoidCallback aoTocar,
  }) {
    return GestureDetector(
      onTap: aoTocar,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: AppColors.bordaMarrom, width: 1),
          boxShadow: AppColors.sombra,
        ),
        child: Row(
          children: [
          // título com listras
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 43,
                height: 43,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: AppColors.fundoFitaRosa.withOpacity(0.20),
                    ),

                    CustomPaint(
                      painter: ListrasPainter(
                        cor: AppColors.listrasFitaRosa.withOpacity(0.15),
                        espessura: 5,
                        espacamento: 18,
                      ),
                    ),

                    Center(
                      child: Icon(icone, color: AppColors.textoPreto, size: 22),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            Text(
              titulo,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textoPreto,
              ),
            ),

            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: AppColors.green.withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}