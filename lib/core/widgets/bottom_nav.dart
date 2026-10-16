import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/notificacoes_contador.dart';

class AppBottomNav extends StatelessWidget {
  final int indiceSelecionado;

  final ValueChanged<int> aoSelecionar;

  const AppBottomNav({
    super.key,
    required this.indiceSelecionado,
    required this.aoSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.green,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // TODO: adicionar os icones corretos
          _buildItem(0, 'assets/icons/tesoura.svg'),
          _buildItem(1, 'assets/icons/macrame.png', isPng: true),
          _buildItem(2, 'assets/icons/home.svg'),
          _buildItem(3, 'assets/icons/notificacao.svg', comBadge: true),
          _buildItem(4, 'assets/icons/configuracao.svg'),
        ],
      ),
    );
  }

  Widget _buildItem(
    int indice,
    String caminho, {
    bool isPng = false,
    bool comBadge = false,
  }) {
    final selecionado = indice == indiceSelecionado;
    final color = selecionado ? AppColors.greenSelected : AppColors.white;

    final icone = isPng
        ? Image.asset(
            caminho,
            width: 30,
            height: 30,
            color: color,
            colorBlendMode: BlendMode.srcIn,
          )
        : SvgPicture.asset(
            caminho,
            width: 30,
            height: 30,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          );

    return GestureDetector(
      onTap: () => aoSelecionar(indice),
      child: comBadge
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                icone,
                Positioned(top: -6, right: -8, child: _buildBadge()),
              ],
            )
          : icone,
    );
  }

  // bolinha com o número de notificações não vistas
  // some sozinha quando não há nenhuma
  Widget _buildBadge() {
    return ValueListenableBuilder<int>(
      valueListenable: NotificacoesContador.instance.naoVistas,
      builder: (_, total, __) {
        if (total <= 0) return const SizedBox.shrink();

        return Container(
          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
          padding: const EdgeInsets.symmetric(horizontal: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.buttonRed,
            borderRadius: BorderRadius.circular(9),
            // borda da cor do menu, para a bolinha se destacar do ícone
            border: Border.all(color: AppColors.green, width: 1.5),
          ),
          child: Text(
            total > 9 ? '9+' : '$total',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        );
      },
    );
  }
}