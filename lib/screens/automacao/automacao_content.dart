import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/botao_novo_corte.dart';
import 'modal_detalhes_corte.dart';
import '../corte/novo_corte_screen.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/estado_erro.dart';
import 'package:provider/provider.dart';
import '../../core/providers/fila_provider.dart';
import '../../core/utils/formatadores_data.dart';

// ============================================
// modelos de dados
// ============================================

// 5.00 vira "5" e 2.50 vira "2.5"
String _formatarMetros(double valor) =>
    valor.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

// ============================================
// tela de automação
// ============================================
class AutomacaoContent extends StatefulWidget {
  const AutomacaoContent({super.key});

  @override
  State<AutomacaoContent> createState() => _AutomacaoContentState();
}

class _AutomacaoContentState extends State<AutomacaoContent> {

  final Set<int> _abertas = {};
  Timer? _relogio;

  // estado vem do FilaProvider
  FilaProvider get _provider => context.read<FilaProvider>();
  List<ExecucaoCorte> get _fila => _provider.fila;
  List<EnvioHistorico> get _historico => _provider.historico;

  @override
  void initState() {
    super.initState();
    _provider.carregar();

    _relogio = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _fila.isNotEmpty) setState(() {});
    });
  }

  @override
  void dispose() {
    _relogio?.cancel();
    super.dispose();
  }
  
  Future<void> _abrirNovoCorte() async {
    final enviou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NovoCorteScreen()),
    );

    if (enviou == true && mounted) _provider.carregar();
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
    final provider = _provider;
    try {
      await ApiService.instance.post('/execucoes/${exec.id}/retentar');
      _mostrarAviso('Retentativa enviada para a máquina!');
      provider.carregar();
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
    @override
  Widget build(BuildContext context) {
    final provider = context.watch<FilaProvider>();

    if (provider.carregando) {
      return Center(child: CircularProgressIndicator(color: AppColors.green));
    }

    if (provider.erro != null) {
      return EstadoErro(
        mensagem: provider.erro!,
        aoTentarNovamente: () => provider.carregar(recomecar: true),
      );
    }

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: () => provider.carregar(),
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
            : Column(children: _buildItensHistorico()),
      ],
    );
  }

  // ============================================
  // container do histórico
  // ============================================
  List<Widget> _buildItensHistorico() {
    final itens = <Widget>[];
    DateTime? diaAtual;

    for (final envio in _historico) {
      final data = envio.dataCadastro;
      if (data != null) {
        final dia = DateTime(data.year, data.month, data.day);
        if (diaAtual != dia) {
          itens.add(Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSeparadorDia(dia),
          ));
          diaAtual = dia;
        }
      }
      itens.add(_buildCardHistorico(envio));
    }

    return itens;
  }

  Widget _buildSeparadorDia(DateTime dia) {
    return Opacity(
      opacity: 0.5,
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.green, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              formatarDia(dia),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppColors.green, thickness: 1)),
        ],
      ),
    );
  }

    // ============================================
  // collapse de um envio (peça + horário)
  // ============================================
  Widget _buildCardHistorico(EnvioHistorico envio) {
    final expandido = _abertas.contains(envio.id);
    final temErro =
        envio.execucoes.any((e) => e.fios.any((f) => f.status == 'E'));

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
            onTap: () => setState(() {
              if (expandido) {
                _abertas.remove(envio.id);
              } else {
                _abertas.add(envio.id);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.checkroom_outlined, size: 20, color: AppColors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          envio.nomePeca,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.green,
                          ),
                        ),
                        if (envio.dataCadastro != null)
                          Text(
                            formatarDiaHora(envio.dataCadastro!),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.green.withOpacity(0.6),
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (temErro)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.warning_amber_rounded, color: const Color.fromARGB(255, 117, 17, 2), size: 18),
                    ),

                  Icon(
                    expandido ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.green,
                  ),
                ],
              ),
            ),
          ),

          // cortes do envio dentro do collapse
          if (expandido)
            Column(
              children: envio.execucoes.map((exec) {
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