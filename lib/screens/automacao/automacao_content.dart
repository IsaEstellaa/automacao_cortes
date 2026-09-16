import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/painters.dart';
import '../../core/widgets/botao_novo_corte.dart';
import 'modal_detalhes_corte.dart';

// ============================================
// modelos de dados (virão do backend)
// ============================================

class FioExecucao {
  final int id;
  final String status; // P=pendente, C=concluído, E=erro

  FioExecucao({required this.id, required this.status});
}

class ExecucaoCorte {
  final int id;
  final String nomePeca;
  final int quantidade;
  final double metragem;
  final List<FioExecucao> fios;
  final String situacao; // A=aguardando, P=processando, C=concluído
  final DateTime? dataInicio;
  final DateTime? dataFim;

  ExecucaoCorte({
    required this.id,
    required this.nomePeca,
    required this.quantidade,
    required this.metragem,
    required this.fios,
    required this.situacao,
    this.dataInicio,
    this.dataFim,
  });

  // cálculos baseados nos fios
  int get fiosConcluidos => fios.where((f) => f.status == 'C').length;
  int get fiosPendentes => fios.where((f) => f.status == 'P').length;
  double get metragemCortada => fiosConcluidos * metragem;
  double get metragemRestante => fiosPendentes * metragem;
  double get progresso => quantidade > 0 ? fiosConcluidos / quantidade : 0;
}

class HistoricoPeca {
  final String nomePeca;
  final List<ExecucaoCorte> execucoes;
  bool expandido;

  HistoricoPeca({
    required this.nomePeca,
    required this.execucoes,
    this.expandido = false,
  });
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

  // dados mockados
  // TODO: substituir por dados reais!!!!!!!
  final List<ExecucaoCorte> _fila = [
    ExecucaoCorte(
      id: 1,
      nomePeca: 'Bolsa',
      quantidade: 30,
      metragem: 44,
      situacao: 'P',
      dataInicio: DateTime.now().subtract(const Duration(minutes: 6, seconds: 23)),
      fios: List.generate(30, (i) => FioExecucao(id: i, status: i < 28 ? 'C' : 'P')),
    ),
    ExecucaoCorte(
      id: 2,
      nomePeca: 'Bolsa',
      quantidade: 12,
      metragem: 2,
      situacao: 'A',
      fios: List.generate(12, (i) => FioExecucao(id: i, status: 'P')),
    ),
    ExecucaoCorte(
      id: 3,
      nomePeca: 'Bolsa',
      quantidade: 20,
      metragem: 20,
      situacao: 'A',
      fios: List.generate(20, (i) => FioExecucao(id: i, status: 'P')),
    ),
  ];

  final List<HistoricoPeca> _historico = [
    HistoricoPeca(
      nomePeca: 'Bolsa',
      execucoes: [
        ExecucaoCorte(
          id: 10,
          nomePeca: 'Bolsa',
          quantidade: 30,
          metragem: 44,
          situacao: 'C',
          dataInicio: DateTime.now().subtract(const Duration(hours: 2)),
          dataFim: DateTime.now().subtract(const Duration(hours: 1, minutes: 53)),
          fios: List.generate(30, (i) => FioExecucao(id: i, status: i < 28 ? 'C' : 'E')),
        ),
        ExecucaoCorte(
          id: 10,
          nomePeca: 'Bolsa',
          quantidade: 20,
          metragem: 190,
          situacao: 'C',
          dataInicio: DateTime.now().subtract(const Duration(hours: 2)),
          dataFim: DateTime.now().subtract(const Duration(hours: 1, minutes: 53)),
          fios: List.generate(20, (i) => FioExecucao(id: i, status: i < 20 ? 'C' : 'E')),
        ),
        ExecucaoCorte(
          id: 10,
          nomePeca: 'Bolsa',
          quantidade: 15,
          metragem: 102,
          situacao: 'C',
          dataInicio: DateTime.now().subtract(const Duration(hours: 2)),
          dataFim: DateTime.now().subtract(const Duration(hours: 1, minutes: 53)),
          fios: List.generate(15, (i) => FioExecucao(id: i, status: i < 14 ? 'C' : 'E')),
        ),
      ],
    ),
    HistoricoPeca(
      nomePeca: 'Bolsa',
      execucoes: [
        ExecucaoCorte(
          id: 10,
          nomePeca: 'Bolsa',
          quantidade: 30,
          metragem: 44,
          situacao: 'C',
          dataInicio: DateTime.now().subtract(const Duration(hours: 2)),
          dataFim: DateTime.now().subtract(const Duration(hours: 1, minutes: 53)),
          fios: List.generate(30, (i) => FioExecucao(id: i, status: i < 30 ? 'C' : 'E')),
        ),
      ],
    ),
    HistoricoPeca(
      nomePeca: 'Bolsa',
      execucoes: [
        ExecucaoCorte(
          id: 10,
          nomePeca: 'Bolsa',
          quantidade: 30,
          metragem: 44,
          situacao: 'C',
          dataInicio: DateTime.now().subtract(const Duration(hours: 2)),
          dataFim: DateTime.now().subtract(const Duration(hours: 1, minutes: 53)),
          fios: List.generate(30, (i) => FioExecucao(id: i, status: i < 10 ? 'C' : 'E')),
        ),
      ],
    ),
  ];

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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          BotaoNovoCorte(
            aoTocar: () {
              // TODO: navegar para tela de novo corte
            },
          ),
          const SizedBox(height: 16),
          _buildSecaoFila(),
          const SizedBox(height: 16),
          _buildSecaoHistorico(),
        ],
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
              Icon(Icons.content_cut_outlined, size: 20, color: AppColors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${exec.quantidade} cortes de ${exec.metragem.toStringAsFixed(0)} metros',
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
              'Metragem cortada: ${exec.metragemCortada.toStringAsFixed(0)}m',
              style: TextStyle(fontSize: 12, color: AppColors.textoPreto),
            ),
            Text(
              'Metragem restante: ${exec.metragemRestante.toStringAsFixed(0)}m',
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
                              '${exec.quantidade} cortes de ${exec.metragem.toStringAsFixed(0)} metros',
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
                          onTap: () => ModalDetalhesCorte.mostrar(
                            context,
                            execucao: exec,
                            logs: [], // TODO: passar logs reais
                            aoRetentar: () {
                              // TODO: criar RETENTATIVA + EXECUCAO_CORTE
                            },
                          ),
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