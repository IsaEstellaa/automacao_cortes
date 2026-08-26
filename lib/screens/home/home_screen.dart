import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/titulo_banner.dart';
import 'home_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceSelecionado = 2;

  // TODO: substituir por telas reais depois
  Widget _buildTela() {
    switch (_indiceSelecionado) {
      case 0:
        return _buildPaginaComTitulo('Automação', _placeholder('Automação'));
      case 1:
        return _buildPaginaComTitulo('Suas peças', _placeholder('Suas peças'));
      case 2:
        return const HomeContent();
      case 3:
        return _buildPaginaComTitulo('Notificações', _placeholder('Notificações'));
      case 4:
        return _buildPaginaComTitulo('Configurações', _placeholder('Configurações'));
      default:
        return _placeholder('Home');
    }
  }

  Widget _buildPaginaComTitulo(String titulo, Widget conteudo) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: TituloBanner(titulo: titulo),
        ),
        Expanded(child: conteudo),
      ],
    );
  }

  // tela temporária enquanto as outras não estão prontas - remover depois
  Widget _placeholder(String nome) {
    return Center(
      child: Text(
        nome,
        style: TextStyle(
          fontSize: 24,
          color: AppColors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(nomeUsuario: 'Isabella'), // TODO: passar nome real do usuário
          Expanded(
            child: _buildTela(),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        indiceSelecionado: _indiceSelecionado,
        aoSelecionar: (indice) {
          setState(() => _indiceSelecionado = indice);
        },
      ),
    );
  }
}