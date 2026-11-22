import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

// ============================================
// modelos de dados
// ============================================

DateTime? _paraData(dynamic valor) =>
    valor == null ? null : DateTime.tryParse(valor.toString());

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
  final DateTime? dataCadastro;
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
    this.dataCadastro,
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
      dataCadastro: _paraData(json['data_cadastro'])?.toLocal(),
      fios: (json['fios'] as List)
          .map((f) => FioExecucao.fromJson(f as Map<String, dynamic>))
          .toList(),
      retentativa: json['retentativa'] == true,
    );
  }

  // cálculos baseados nos fios
  int get fiosConcluidos => fios.where((f) => f.status == 'C').length;
  int get fiosPendentes => fios.where((f) => f.status == 'P').length;
  int get fiosComErro => fios.where((f) => f.status == 'E').length;
  int get fiosProcessados => fiosConcluidos + fiosComErro;
  double get metragemCortada => fiosConcluidos * metragem;
  double get metragemRestante => fiosPendentes * metragem;
  double get progresso => quantidade > 0 ? fiosProcessados / quantidade : 0;
}

// cortes da mesma peça enviados juntos
class EnvioHistorico {
  final String nomePeca;
  final DateTime? dataCadastro;
  final List<ExecucaoCorte> execucoes = [];

  EnvioHistorico({required this.nomePeca, required this.dataCadastro});

  int get id => execucoes.first.id;
}

// ============================================
// provider da fila e do histórico
// ============================================
class FilaProvider extends ChangeNotifier {
  List<ExecucaoCorte> _fila = [];
  List<EnvioHistorico> _historico = [];
  String? _erro;
  bool _carregando = true;
  bool _buscando = false;
  bool _recarregar = false;
  int _geracao = 0;

  List<ExecucaoCorte> get fila => _fila;
  List<EnvioHistorico> get historico => _historico;
  String? get erro => _erro;
  bool get carregando => _carregando;

  Future<void> carregar({bool recomecar = false}) async {
    if (recomecar) {
      _carregando = true;
      _erro = null;
      notifyListeners();
    }

    if (_buscando) {
      _recarregar = true;
      return;
    }
    _buscando = true;
    final geracao = _geracao;

    try {
      final respostas = await Future.wait([
        ApiService.instance.get('/execucoes/fila'),
        ApiService.instance.get('/execucoes/historico'),
      ]);

      final fila = (respostas[0] as List)
          .map((j) => ExecucaoCorte.fromJson(j as Map<String, dynamic>))
          .toList();

      // envio = cortes da mesma peça cadastrados no mesmo instante
      final envios = <String, EnvioHistorico>{};
      for (final grupo in (respostas[1] as List)) {
        for (final j in (grupo['execucoes'] as List)) {
          final e = ExecucaoCorte.fromJson(j as Map<String, dynamic>);
          final chave =
              '${grupo['id_peca']}-${e.dataCadastro?.millisecondsSinceEpoch}';
          envios
              .putIfAbsent(
                chave,
                () => EnvioHistorico(
                  nomePeca: e.nomePeca,
                  dataCadastro: e.dataCadastro,
                ),
              )
              .execucoes
              .add(e);
        }
      }

      final historico = envios.values.toList();
      for (final envio in historico) {
        envio.execucoes.sort((a, b) => a.id.compareTo(b.id));
      }
      historico.sort((a, b) {
        final porData = (b.dataCadastro ?? DateTime(0))
            .compareTo(a.dataCadastro ?? DateTime(0));
        return porData != 0 ? porData : b.id.compareTo(a.id);
      });

      if (geracao != _geracao) return;

      _fila = fila;
      _historico = historico;
      _erro = null;
      _carregando = false;
      notifyListeners();
    } on ApiException catch (e) {
      if (geracao != _geracao) return;

      if (_carregando) {
        _erro = e.mensagem;
        _carregando = false;
        notifyListeners();
      }
    } finally {
      _buscando = false;
      if (_recarregar) {
        _recarregar = false;
        carregar();
      }
    }
  }

  void reiniciar() {
    _geracao++;
    _fila = [];
    _historico = [];
    _erro = null;
    _carregando = true;
    notifyListeners();
  }
}