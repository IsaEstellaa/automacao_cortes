import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

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
          _buildItem(3, 'assets/icons/notificacao.svg'),
          _buildItem(4, 'assets/icons/configuracao.svg'),
        ],
      ),
    );
  }

  Widget _buildItem(int indice, String caminho, {bool isPng = false}) {
    final selecionado = indice == indiceSelecionado;
    final color = selecionado ? AppColors.greenSelected : AppColors.white;

    return GestureDetector(
      onTap: () => aoSelecionar(indice),
      child: isPng
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
            ),
    );
  }
}