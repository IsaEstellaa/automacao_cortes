import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/painters.dart';
import '../../core/widgets/card_nav.dart';
import '../../core/widgets/fita_decorativa.dart';

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
  StatusMaquina _statusAtual = StatusMaquina.naoEncontrada;

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

          if (_statusAtual == StatusMaquina.naoEncontrada)
            Align(
              alignment: Alignment.bottomLeft,
              child: IconButton(
                onPressed: () => _mostrarModalAjuda(context),
                icon: Icon(
                  Icons.help_outline,
                  color: AppColors.green,
                  size: 28,
                ),
              ),
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

void _mostrarModalAjuda(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.card,
      clipBehavior: Clip.none, // 👈 permite a fita "vazar" pra fora
      child: Stack(
        clipBehavior: Clip.none, // 👈 aqui também
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('⚠️', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => AppColors.gradienteTitulo.createShader(bounds),
                      child: Center(
                        child: Text(
                          'Máquina indisponível',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Possíveis causas:',
                    style: TextStyle(fontSize: 15, color: AppColors.textoPreto),
                  ),
                ),
                const SizedBox(height: 8),
                _itemCausa('Máquina desligada'),
                _itemCausa('Sem conexão com a internet'),
                _itemCausa('Rede instável'),
                _itemCausa('Cabo desconectado'),
                const SizedBox(height: 12),

                Text(
                  'A conexão pode levar alguns segundos para ser restabelecida.',
                  style: TextStyle(fontSize: 15, color: AppColors.textoPreto),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(6),
                      ),
                    ),
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          Positioned(
            top: -25,
            child: FitaDecorativa(
              corFundo: AppColors.fundoFitaRosa,
              corListras: AppColors.listrasFitaRosa,
            ),
          ),
        ]
      )
    ),
  );
}

Widget _itemCausa(String texto) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text('•  ', style: TextStyle(color: AppColors.textoMarrom, fontSize: 15)),
        Text(texto, style: TextStyle(color: AppColors.textoMarrom, fontSize: 15)),
      ],
    ),
  );
}

// void _mostrarModalAjuda(BuildContext context) {
//   showModalBottomSheet(
//     context: context,
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//     ),
//     backgroundColor: AppColors.card,
//     builder: (_) => Padding(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         mainAxisSize: MainAxisSize.min, // ocupa só o necessário
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'O que pode ter acontecido?',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: AppColors.green,
//             ),
//           ),
//           const SizedBox(height: 16),
//           _itemModal(Icons.wifi_off_outlined, 'Verifique sua conexão com a internet'),
//           _itemModal(Icons.power_off_outlined, 'Verifique se a máquina está ligada'),
//           _itemModal(Icons.bluetooth_disabled_outlined, 'Verifique se o bluetooth está ativo'),
//           const SizedBox(height: 8),
//         ],
//       ),
//     ),
//   );
// }

// Widget _itemModal(IconData icone, String texto) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(vertical: 8),
//     child: Row(
//       children: [
//         Icon(icone, color: AppColors.green, size: 24),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Text(
//             texto,
//             style: TextStyle(fontSize: 15, color: AppColors.green),
//           ),
//         ),
//       ],
//     ),
//   );
// }