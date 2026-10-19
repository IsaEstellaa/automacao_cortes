import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/botao_novo_corte.dart';
import 'modal_detalhes_corte.dart';
import '../corte/novo_corte_screen.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/estado_erro.dart';

// ============================================
// modelos de dados
// ============================================

DateTime? _paraData(dynamic valor) =>
    valor == null ? null : DateTime.tryParse(valor.toString());

// 5.00 vira "5" e 2.50 vira "2.5"
String _formatarMetros(double valor) =>
    valor.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

class FioExecucao {
  final int id;
  final String status; // P=pendente, C=concluído, E=erro

  FioExecucao({required this.id, required this.status});

  factory FioExecucao.fromJson(Map<String, dynamic> json) {
    return FioExecucao(
      id: json['id_fio'] as int,
      status: json['status'] as String,
    );
  }
}

class ExecucaoCorte {
  final int id;
  final String nomePeca;
  final int quantidade;
  final double metragem;
  final List<FioExecucao> fios;
  final String situacao; // A=aguardando, P=processando, C=concluído, E=com erro
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final bool retentativa; // true = fios sendo refeitos (não um corte novo)

  ExecucaoCorte({
    required this.id,
    required this.nomePeca,
    required this.quantidade,
    required this.metragem,
    required this.fios,
    required this.situacao,
    this.dataInicio,
    this.dataFim,
    this.retentativa = false,
  });

  factory ExecucaoCorte.fromJson(Map<String, dynamic> json) {
    return ExecucaoCorte(
      id: json['id_execucao'] as int,
      nomePeca: json['nome_peca'] as String,
      quantidade: (json['quantidade'] as num).toInt(),
      metragem: double.tryParse(json['metragem'].toString()) ?? 0,
      situacao: json['situacao'] as String,
      dataInicio: _paraData(json['data_inicio']),
      dataFim: _paraData(json['data_fim']),
      fios: (json['fios'] as List)
          .map((f) => FioExecucao.fromJson(f as Map<String, dynamic>))
          .toList(),
      retentativa: json['retentativa'] == true,
    );
  }

  // cálculos baseados nos fios
  int get fiosConcluidos => fios.where((f) => f.status == 'C').length;
  int get fiosPendentes => fios.where((f) => f.status == 'P').length;
  double get metragemCortada => fiosConcluidos * metragem;
  double get metragemRestante => fiosPendentes * metragem;
  double get progresso => quantidade > 0 ? fiosConcluidos / quantidade : 0;
}

class HistoricoPeca {
  final int idPeca;
  final String nomePeca;
  final List<ExecucaoCorte> execucoes;
  bool expandido;

  HistoricoPeca({
    required this.idPeca,
    required this.nomePeca,
    required this.execucoes,
    this.expandido = false,
  });

  factory HistoricoPeca.fromJson(Map<String, dynamic> json) {
    return HistoricoPeca(
      idPeca: json['id_peca'] as int,
      nomePeca: json['nome_peca'] as String,
      execucoes: (json['execucoes'] as List)
          .map((e) => ExecucaoCorte.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ============================================
// tela de automação
// ============================================
class AutomacaoContent extends StatefulWidget {
  const AutomacaoContent({super.key});

  @override
  State<AutomacaoContent> createState() => _AutomacaoContentState();
}

class _AutomacaoContentState extends State<AutomacaoContent> {

  List<ExecucaoCorte> _fila = [];
  List<HistoricoPeca> _historico = [];
  bool _carregando = true;
  bool _buscando = false;
  String? _erro;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _carregar();

    _timer = Timer.periodic(
        const Duration(seconds: 5), (_) => _carregar(silencioso: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ============================================
  // busca fila e histórico na API
  // silencioso = atualização automática, se falhar, mantém
  // ============================================
  Future<void> _carregar({bool silencioso = false}) async {
    if (_buscando) return;
    _buscando = true;

    if (!silencioso) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {
      final respostas = await Future.wait([
        ApiService.instance.get('/execucoes/fila'),
        ApiService.instance.get('/execucoes/historico'),
      ]);

      final fila = (respostas[0] as List)
          .map((j) => ExecucaoCorte.fromJson(j as Map<String, dynamic>))
          .toList();

      final abertas = _historico.where((h) => h.expandido).map((h) => h.idPeca).toSet();

      final historico = (respostas[1] as List).map((j) {
        final item = HistoricoPeca.fromJson(j as Map<String, dynamic>);
        item.expandido = abertas.contains(item.idPeca);
        return item;
      }).toList();

      if (!mounted) return;
      setState(() {
        _fila = fila;
        _historico = historico;
        _erro = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (!silencioso) setState(() => _erro = e.mensagem);
    } finally {
      _buscando = false;
      if (mounted && !silencioso) setState(() => _carregando = false);
    }
  }
  
  Future<void> _abrirNovoCorte() async {
    final enviou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NovoCorteScreen()),
    );

    if (enviou == true) _carregar(silencioso: true);
  }

  Future<void> _abrirDetalhes(ExecucaoCorte exec) async {
    try {
      final resposta = await ApiService.instance
          .get('/execucoes/${exec.id}/detalhes') as Map<String, dynamic>;

      final logs = [
        for (final f in (resposta['fios'] as List))
          if (f['mensagem'] != null)
            LogFio(idFio: f['id_fio'] as int, mensagem: f['mensagem'] as String),
      ];

      if (!mounted) return;

      ModalDetalhesCorte.mostrar(
        context,
        execucao: exec,
        logs: logs,
        retentando: resposta['retentando'] == true,
        aoRetentar: () => _retentar(exec),
      );
    } on ApiException catch (e) {
      _mostrarAviso(e.mensagem);
    }
  }

  Future<void> _retentar(ExecucaoCorte exec) async {
    try {
      await ApiService.instance.post('/execucoes/${exec.id}/retentar');
      _mostrarAviso('Retentativa enviada para a máquina!');
      _carregar(silencioso: true);
    } on ApiException catch (e) {
      _mostrarAviso(e.mensagem);
    }
  }

  void _mostrarAviso(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  // formata o tempo decorrido
  String _tempoDecorrido(DateTime? inicio) {
    if (inicio == null) return '--';
    final diff = DateTime.now().difference(inicio);
    final min = diff.inMinutes;
    final seg = diff.inSeconds % 60;
    return '${min}m${seg}s';
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return Center(child: CircularProgressIndicator(color: AppColors.green));
    }

    if (_erro != null) {
      return EstadoErro(mensagem: _erro!, aoTentarNovamente: _carregar);
    }

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: () => _carregar(silencioso: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            BotaoNovoCorte(aoTocar: _abrirNovoCorte),
            const SizedBox(height: 16),
            _buildSecaoFila(),
            const SizedBox(height: 16),
            _buildSecaoHistorico(),
          ],
        ),
      ),
    );
  }

  // ============================================
  // container da fila de automação
  // ============================================
  Widget _buildSecaoFila() {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // título da seção
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Fila de automação',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.green,
              ),
            ),
          ),

          // lista ou vazio
          _fila.isEmpty
              ? _buildVazio('Nenhum corte está sendo\nprocessado no momento')
              : Column(
                  children: _fila.asMap().entries.map((entry) {
                    final index = entry.key;
                    final exec = entry.value;
                    return _buildCardFila(exec, index == 0);
                  }).toList(),
                ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ============================================
  // card da fila de automação
  // ============================================
  Widget _buildCardFila(ExecucaoCorte exec, bool ativo) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(6),
          bottomLeft: Radius.circular(6),
          bottomRight: Radius.circular(30),
        ),
        border: Border.all(
          color: ativo ? AppColors.green : AppColors.bordaMarrom,
          width: ativo ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                exec.retentativa ? Icons.replay : Icons.content_cut_outlined,
                size: 20,
                color: AppColors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exec.retentativa
                      ? 'Retentativa: ${exec.quantidade} ${exec.quantidade == 1 ? 'corte' : 'cortes'} de ${_formatarMetros(exec.metragem)} metros'
                      : '${exec.quantidade} cortes de ${_formatarMetros(exec.metragem)} metros',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textoPreto,
                  ),
                ),
              ),
            ],
          ),

          // para o card ativo no momento
          if (ativo) ...[
            const SizedBox(height: 8),

            // barrinha de progresso
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: exec.progresso,
                backgroundColor: AppColors.bordaMarrom.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              '(${exec.fiosConcluidos}/${exec.quantidade}) concluídos',
              style: TextStyle(fontSize: 11, color: AppColors.textoPreto),
            ),
            const SizedBox(height: 6),

            Text(
              'Metragem cortada: ${_formatarMetros(exec.metragemCortada)}m',
              style: TextStyle(fontSize: 12, color: AppColors.textoPreto),
            ),
            Text(
              'Metragem restante: ${_formatarMetros(exec.metragemRestante)}m',
              style: TextStyle(fontSize: 12, color: AppColors.textoPreto),
            ),
            Text(
              'Tempo decorrido: ${_tempoDecorrido(exec.dataInicio)}',
              style: TextStyle(fontSize: 12, color: AppColors.textoPreto),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              '(${exec.fiosConcluidos}/${exec.quantidade}) concluídos',
              style: TextStyle(fontSize: 11, color: AppColors.textoPreto),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================
  // histórico
  // ============================================
  Widget _buildSecaoHistorico() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(30),
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(10),
            ),
            boxShadow: AppColors.sombra,
          ),
          child: Center(
            child: Text(
              'Histórico',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // lista ou vazio
        _historico.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(40),
                  ),
                  border: Border.all(color: AppColors.bordaMarrom, width: 1),
                ),
                child: _buildVazio('Nenhum corte realizado até\no momento'),
              )
            : Column(
                children: _historico.map(_buildCardHistorico).toList(),
              ),
      ],
    );
  }

  // ============================================
  // container do histórico
  // ============================================
  Widget _buildCardHistorico(HistoricoPeca historico) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          // header clicável do collapse
          GestureDetector(
            onTap: () => setState(() => historico.expandido = !historico.expandido),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  Icon(Icons.checkroom_outlined, size: 20, color: AppColors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      historico.nomePeca,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green,
                      ),
                    ),
                  ),

                  if (historico.execucoes.any((e) => e.fios.any((f) => f.status == 'E')))
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.warning_amber_rounded, color: const Color.fromARGB(255, 117, 17, 2), size: 18),
                    ),

                  Icon(
                    historico.expandido ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.green,
                  ),
                ],
              ),
            ),
          ),

          // cortes dentro do collapse
          if (historico.expandido)
            Column(
              children: historico.execucoes.map((exec) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(6),
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(30),
                    ),
                    border: Border.all(color: AppColors.bordaMarrom, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.content_cut_outlined, size: 18, color: AppColors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${exec.quantidade} cortes de ${_formatarMetros(exec.metragem)} metros',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textoPreto),
                            ),
                            Text(
                              '(${exec.fiosConcluidos}/${exec.quantidade}) concluídos',
                              style: TextStyle(fontSize: 11, color: AppColors.textoPreto),
                            ),
                          ],
                        ),
                      ),

                      // ícone de alerta se tiver fio com erro
                      if (exec.fios.any((f) => f.status == 'E'))
                        GestureDetector(
                          onTap: () => _abrirDetalhes(exec),
                          child: Icon(Icons.warning_amber_rounded,
                            color: const Color.fromARGB(255, 117, 17, 2), size: 20),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ============================================
  // estado vazio
  // ============================================
  Widget _buildVazio(String texto) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textoMarrom,
          ),
        ),
      ),
    );
  }
}