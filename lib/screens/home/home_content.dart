import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/painters.dart';
import '../../core/widgets/card_nav.dart';

// enum com os possíveis estados da máquina
// quando integrar com IoT, só muda o valor do _statusAtual
enum StatusMaquina {
  aguardando,
  trabalhando,
  naoEncontrada,
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // trocar aqui para simular os estados
  StatusMaquina _statusAtual = StatusMaquina.aguardando;

  // retorna as informações de cada estado
  Map<String, dynamic> _infoStatus() {
    switch (_statusAtual) {
      case StatusMaquina.aguardando:
        return {
          'texto': 'A máquina está aguardando\num novo corte',
          'icone': Icons.settings_outlined,
        };
      case StatusMaquina.trabalhando:
        return {
          'texto': 'A máquina está\ntrabalhando',
          'icone': Icons.precision_manufacturing_outlined,
        };
      case StatusMaquina.naoEncontrada:
        return {
          'texto': 'Máquina não\nencontrada',
          'icone': Icons.wifi_off_outlined,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          _buildCardStatus(),
          const SizedBox(height: 16),
          _buildBotaoNovoCorte(),
          const SizedBox(height: 16),
          _buildGrid(),
        ],
      ),
    );
  }

  // ============================================
  // card de status da máquina
  // ============================================
  Widget _buildCardStatus() {
    final info = _infoStatus();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bordaMarrom, width: 1),
      ),
      child: Column(
        children: [
          Text(
            info['texto'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.green,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Icon(
            info['icone'],
            size: 64,
            color: AppColors.green,
          ),
        ],
      ),
    );
  }

  // ============================================
  // botão "Novo corte" com listras
  // ============================================
  Widget _buildBotaoNovoCorte() {
    return GestureDetector(
      onTap: () {
        // TODO: navegar para tela de novo corte
      },
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
              // listras de fundo
              CustomPaint(
                painter: ListrasPainter(
                  cor: AppColors.buttonBrown.withOpacity(0.4),
                  espessura: 10,
                  espacamento: 22,
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

  // ============================================
  // cards de navegação
  // ============================================
  Widget _buildGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: 
            CardNav(
              titulo: 'Materiais',
              svgPath: 'assets/icons/materiais.png',
              isPng: true,
              aoTocar: () { /* navegar */ },
            )),
            const SizedBox(width: 16),
            Expanded(child:
            CardNav(
              titulo: 'Histórico',
              svgPath: 'assets/icons/historico.png',
              isPng: true,
              aoTocar: () { /* navegar */ },
            )),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(child: 
            CardNav(
              titulo: 'Nova peça',
              svgPath: 'assets/icons/peca.png',
              isPng: true,
              aoTocar: () { /* navegar */ },
            )),
            const SizedBox(width: 16),
            Expanded(child:
            CardNav(
              titulo: 'Materiais',
              svgPath: 'assets/icons/materiais.png',
              isPng: true,
              aoTocar: () { /* navegar */ },
            )),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}