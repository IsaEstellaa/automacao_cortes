import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/titulo_banner.dart';
import '../../core/widgets/painters.dart';
import '../../core/widgets/modal_confirmacao.dart';
import '../pecas/pecas_content.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/estado_erro.dart';
import '../materiais/materiais_screen.dart';

class NovoCorteScreen extends StatefulWidget {
  const NovoCorteScreen({super.key});

  @override
  State<NovoCorteScreen> createState() => _NovoCorteScreenState();
}

class _NovoCorteScreenState extends State<NovoCorteScreen> {
  Peca? _pecaSelecionada;
  List<bool> _cortesSelecionados = [];
  MaterialFio? _materialSelecionado;

  List<Peca> _pecas = [];
  List<MaterialFio> _materiais = [];
  bool _carregando = true;
  bool _enviando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // ============================================
  // busca peças e materiais na API
  // ============================================
  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final respostas = await Future.wait([
        ApiService.instance.get('/pecas'),
        ApiService.instance.get('/materiais'),
      ]);

      final pecas = (respostas[0] as List)
          .map((j) => Peca.fromJson(j as Map<String, dynamic>))
          .toList();
      final materiais = (respostas[1] as List)
          .map((j) => MaterialFio.fromJson(j as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _pecas = pecas;
        _materiais = materiais;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // ============================================
  // envia os cortes marcados para a fila da máquina
  // ============================================
  Future<void> _enviar() async {
    final peca = _pecaSelecionada!;
    final material = _materialSelecionado!;

    final ids = <int>[
      for (var i = 0; i < peca.cortes.length; i++)
        if (_cortesSelecionados[i]) peca.cortes[i]['id_corte'] as int,
    ];

    final mensagens = ScaffoldMessenger.of(context);

    setState(() => _enviando = true);

    try {
      await ApiService.instance.post('/execucoes', {
        'id_material': material.id,
        'cortes': ids,
      });

      if (!mounted) return;

      Navigator.pop(context, true);
      mensagens.showSnackBar(
        const SnackBar(content: Text('Cortes enviados para a máquina!')),
      );
    } on ApiException catch (e) {
      _mostrarErro(e.mensagem);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

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
      body: _carregando
        ? Center(child: CircularProgressIndicator(color: AppColors.green))
        : _erro != null
            ? EstadoErro(mensagem: _erro!, aoTentarNovamente: _carregar)
            : SingleChildScrollView(
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
          if (_pecas.isEmpty)
            Text(
              'Nenhuma peça cadastrada. Cadastre uma peça primeiro.',
              style: TextStyle(fontSize: 13, color: AppColors.green.withOpacity(0.5)),
            )
          else
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

          if (_materiais.isEmpty)
            Text(
              'Nenhum material cadastrado. Cadastre um material primeiro.',
              style: TextStyle(fontSize: 13, color: AppColors.green.withOpacity(0.5)),
            )
          else
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
        onPressed: temSelecionados && _materialSelecionado != null && !_enviando
            ? () => ModalConfirmacao.mostrar(
                  context,
                  titulo: 'Enviar para máquina',
                  mensagem:
                      'Deseja enviar $_totalSelecionados corte${_totalSelecionados != 1 ? 's' : ''} de "${_pecaSelecionada!.nome}" para a máquina?',
                  textoBotaoConfirmar: 'Enviar',
                  aoConfirmar: () => _enviar(),
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
        child: _enviando
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              temSelecionados
                  ? 'Enviar $_totalSelecionados corte${_totalSelecionados != 1 ? 's' : ''} para máquina'
                  : 'Selecione ao menos um corte',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
      ),
    );
  }
}