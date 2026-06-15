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
          _buildItem(0, Icons.content_cut_outlined),
          _buildItem(1, Icons.checkroom_outlined),
          _buildItem(2, Icons.home_rounded),
          _buildItem(3, Icons.notifications_outlined),
          _buildItem(4, Icons.settings_outlined),
        ],
      ),
    );
  }

  Widget _buildItem(int indice, IconData icone) {
    final selecionado = indice == indiceSelecionado;

    return GestureDetector(
      onTap: () => aoSelecionar(indice),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          icone,
          color: selecionado
              ? AppColors.greenSelected
              : AppColors.white,
          size: 35,
        ),
      ),
    );
  }
}