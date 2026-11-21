import 'dart:async';
import '../maquina/minha_maquina_screen.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/painters.dart';
import '../../core/widgets/card_nav.dart';
import '../../core/widgets/fita_decorativa.dart';
import '../../core/widgets/botao_novo_corte.dart';
import '../corte/novo_corte_screen.dart';
import '../materiais/materiais_screen.dart';
import 'package:provider/provider.dart';
import '../../core/providers/status_maquina_provider.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // estado vem do StatusMaquinaProvider
  StatusMaquina get _statusAtual =>
      context.watch<StatusMaquinaProvider>().status;

  Future<void> _abrirMinhaMaquina() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MinhaMaquinaScreen()),
    );
    if (mounted) context.read<StatusMaquinaProvider>().carregar();
  }

  // mapeamento dos estados da maquina
  Map<String, dynamic> _infoStatus() {
    switch (_statusAtual) {
      case StatusMaquina.verificando:
        return {
          'texto': 'Verificando a máquina...',
          'icone': Icons.sync,
          'corListras': AppColors.listrasFitaRosa,
          'corFundo': AppColors.fundoFitaRosa,
        };
      case StatusMaquina.semMaquina:
        return {
          'texto': 'Você não possui uma\n máquina cadastrada',
          'icone': Icons.add_circle_outline,
          'corListras': AppColors.listrasFitaRosa,
          'corFundo': AppColors.fundoFitaRosa,
        };
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
          BotaoNovoCorte(
            aoTocar: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NovoCorteScreen()),
            ),
          ),
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

          if (_statusAtual != StatusMaquina.naoEncontrada)
            const SizedBox(height: 18),

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
          if (_statusAtual == StatusMaquina.semMaquina) ...[
            Center(
              child: ElevatedButton(
                onPressed: _abrirMinhaMaquina,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(30),
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                ),
                child: const Text(
                  'Cadastrar máquina',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
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
              aoTocar: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MateriaisScreen()),
              ),
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
              aoTocar: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MateriaisScreen()),
              ),
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
                    Text('⚠️', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 5),
                    ShaderMask(
                      shaderCallback: (bounds) => AppColors.gradienteTitulo.createShader(bounds),
                      child: Center(
                        child: Text(
                          'Máquina indisponível',
                          style: TextStyle(
                            fontSize: 22,
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