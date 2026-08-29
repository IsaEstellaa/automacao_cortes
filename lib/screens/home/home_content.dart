import 'package:flutter/material.dart';
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

  // mapeamento dos estados da maquina
  Map<String, dynamic> _infoStatus() {
    switch (_statusAtual) {
      case StatusMaquina.aguardando:
        return {
          'texto': 'A máquina está aguardando\num novo corte',
          'icone': Icons.settings_outlined,
          'corListras': AppColors.listrasFitaVerde,
          'corFundo': AppColors.fundoFitaVerde,
        };
      case StatusMaquina.trabalhando:
        return {
          'texto': 'A máquina está em processo\nde corte',
          'icone': Icons.precision_manufacturing_outlined,
          'corListras': AppColors.listrasFitaAmarelo,
          'corFundo': AppColors.fundoFitaAmarelo,
        };
      case StatusMaquina.naoEncontrada:
        return {
          'texto': 'A máquina não foi\nencontrada',
          'icone': Icons.highlight_off,
          'corListras': AppColors.listrasFitaVermelho,
          'corFundo': AppColors.fundoFitaVermelho,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // título com listras
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(60),
              topRight: Radius.circular(10),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 85,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // listras
                  CustomPaint(
                    painter: ListrasPainter(
                      cor: (info['corListras'] as Color).withOpacity(0.60),
                      espessura: 5,
                      espacamento: 35,
                    ),
                  ),

                  // fundo semi-transparente
                  Container(
                    color: (info['corFundo'] as Color).withOpacity(0.80),
                  ),

                  // texto por cima
                  Center(
                    child: Text(
                      info['texto'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textoPreto,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // sombra
          Container(
            height: 6,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 8,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Center(child: 
            Icon(
              info['icone'],
              size: 75,
              color: AppColors.textoPreto,
            ),
          ),
          const SizedBox(height: 16),
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