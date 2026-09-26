import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/titulo_banner.dart';
import '../../core/widgets/painters.dart';
import '../../core/widgets/modal_confirmacao.dart';
import '../pecas/pecas_content.dart';

class NovoCorteScreen extends StatefulWidget {
  const NovoCorteScreen({super.key});

  @override
  State<NovoCorteScreen> createState() => _NovoCorteScreenState();
}

// modelo de material --> tirar depois pq vai vir do backend
class MaterialFio {
  final int id;
  final String nome;
  final double? espessura;
  final double gramatura;

  MaterialFio({
    required this.id,
    required this.nome,
    this.espessura,
    required this.gramatura,
  });
}

class _NovoCorteScreenState extends State<NovoCorteScreen> {
  Peca? _pecaSelecionada;
  List<bool> _cortesSelecionados = [];
  MaterialFio? _materialSelecionado;

  // peças mockadas (novamente) — substituir pelo backend
  // TODO: NAO ESQUECER DE SUBSTITUIR
  final List<Peca> _pecas = [
    Peca(
      id: 1,
      nome: 'Bolsa',
      descricao: 'Bolsa de macramê',
      fotos: [],
      cortes: [
        {'quantidade': 10, 'metragem': 500},
        {'quantidade': 5, 'metragem': 200},
        {'quantidade': 8, 'metragem': 300},
      ],
    ),
    Peca(
      id: 2,
      nome: 'Painel',
      descricao: 'Painel decorativo',
      fotos: [],
      cortes: [
        {'quantidade': 20, 'metragem': 100},
      ],
    ),
    Peca(
      id: 3,
      nome: 'Suporte',
      descricao: 'Suporte para vasos',
      fotos: [],
      cortes: [
        {'quantidade': 6, 'metragem': 150},
        {'quantidade': 4, 'metragem': 250},
      ],
    ),
  ];

  // tirar depois
  final List<MaterialFio> _materiais = [
    MaterialFio(id: 1, nome: 'Nylon 0.5mm', espessura: 0.5, gramatura: 120),
    MaterialFio(id: 2, nome: 'Algodão', gramatura: 80),
    MaterialFio(id: 3, nome: 'Poliéster 1mm', espessura: 1.0, gramatura: 150),
  ];

  // seleção dos cortes
  void _selecionarPeca(Peca peca) {
    setState(() {
      _pecaSelecionada = peca;
      _cortesSelecionados = List.filled(peca.cortes.length, true);
    });
  }

  bool get _todosSelecionados =>
      _cortesSelecionados.isNotEmpty && _cortesSelecionados.every((s) => s);

  void _toggleTodos() {
    setState(() {
      final novoValor = !_todosSelecionados;
      _cortesSelecionados = List.filled(_cortesSelecionados.length, novoValor);
    });
  }

  int get _totalSelecionados =>
      _cortesSelecionados.where((s) => s).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            TituloBanner(titulo: 'Novo corte'),
            const SizedBox(height: 20),
            _buildSecaoPecas(),
            if (_pecaSelecionada != null) ...[
              const SizedBox(height: 16),
              _buildSecaoMaterial(),
              const SizedBox(height: 16),
              _buildSecaoCortes(),
              const SizedBox(height: 24),
              _buildBotaoEnviar(),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================
  // seção de seleção de peça
  // ============================================
  Widget _buildSecaoPecas() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
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
          Text(
            'Selecione a peça',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 12),

          // lista de peças
          Column(
            children: _pecas.map((peca) {
              final selecionada = _pecaSelecionada?.id == peca.id;
              return GestureDetector(
                onTap: () => _selecionarPeca(peca),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: selecionada
                        ? AppColors.green.withOpacity(0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(6),
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: selecionada ? AppColors.green : AppColors.bordaMarrom,
                      width: selecionada ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.checkroom_outlined,
                        size: 20,
                        color: selecionada ? AppColors.green : AppColors.green.withOpacity(0.5),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          peca.nome,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: selecionada ? FontWeight.bold : FontWeight.normal,
                            color: AppColors.green,
                          ),
                        ),
                      ),
                      Text(
                        '${peca.cortes.length} corte${peca.cortes.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.green.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        selecionada ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: selecionada ? AppColors.green : AppColors.green.withOpacity(0.4),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================
  // seção de cortes da peça selecionada
  // ============================================
  Widget _buildSecaoCortes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
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
          // título + marcar/desmarcar todos
          Row(
            children: [
              Text(
                'Cortes de ${_pecaSelecionada!.nome}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.green,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _toggleTodos,
                child: Text(
                  _todosSelecionados ? 'Desmarcar todos' : 'Marcar todos',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.buttonBrown,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // lista de cortes com checkbox
          ...List.generate(_pecaSelecionada!.cortes.length, (index) {
            final corte = _pecaSelecionada!.cortes[index];
            final selecionado = _cortesSelecionados[index];

            return GestureDetector(
              onTap: () => setState(() => _cortesSelecionados[index] = !selecionado),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: selecionado
                      ? AppColors.green.withOpacity(0.08)
                      : AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: selecionado ? AppColors.green : AppColors.bordaMarrom,
                    width: selecionado ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.content_cut_outlined, size: 16, color: AppColors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${corte['quantidade']} fios de ${corte['metragem']}m',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textoPreto,
                          decoration: selecionado ? null : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                    Icon(
                      selecionado ? Icons.check_box : Icons.check_box_outline_blank,
                      color: selecionado ? AppColors.green : AppColors.green.withOpacity(0.4),
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============================================
  // seção de seleção de materiais
  // ============================================
  Widget _buildSecaoMaterial() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
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
          Text(
            'Selecione o material',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 12),

          Column(
            children: _materiais.map((material) {
              final selecionado = _materialSelecionado?.id == material.id;
              return GestureDetector(
                onTap: () => setState(() => _materialSelecionado = material),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: selecionado
                        ? AppColors.green.withOpacity(0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(6),
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: selecionado ? AppColors.green : AppColors.bordaMarrom,
                      width: selecionado ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.category_outlined, size: 18,
                          color: selecionado ? AppColors.green : AppColors.green.withOpacity(0.5)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              material.nome,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                                color: AppColors.green,
                              ),
                            ),
                            Text(
                              '${material.gramatura}g${material.espessura != null ? ' · ${material.espessura}mm' : ''}',
                              style: TextStyle(fontSize: 12, color: AppColors.textoPreto),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        selecionado ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: selecionado ? AppColors.green : AppColors.green.withOpacity(0.4),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================
  // botão enviar para máquina
  // ============================================
  Widget _buildBotaoEnviar() {
    final temSelecionados = _totalSelecionados > 0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: temSelecionados && _materialSelecionado != null
            ? () => ModalConfirmacao.mostrar(
                  context,
                  titulo: 'Enviar para máquina',
                  mensagem:
                      'Deseja enviar $_totalSelecionados corte${_totalSelecionados != 1 ? 's' : ''} de "${_pecaSelecionada!.nome}" para a máquina?',
                  textoBotaoConfirmar: 'Enviar',
                  aoConfirmar: () {
                    // TODO: criar EXECUCAO_CORTE e enviar para a fila
                    Navigator.pop(context);
                  },
                  corBotao: AppColors.green,
                )
            : null, // desabilita se não tiver nenhum selecionado
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.green.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(6),
            ),
          ),
        ),
        child: Text(
          temSelecionados
              ? 'Enviar $_totalSelecionados corte${_totalSelecionados != 1 ? 's' : ''} para máquina'
              : 'Selecione ao menos um corte',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}