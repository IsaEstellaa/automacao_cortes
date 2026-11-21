import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

// estados possíveis da máquina
enum StatusMaquina {
  verificando,
  semMaquina,
  aguardando,
  trabalhando,
  naoEncontrada,
}

class StatusMaquinaProvider extends ChangeNotifier {
  StatusMaquina _status = StatusMaquina.verificando;
  Map<String, dynamic>? _maquina;
  String? _erro;
  bool _carregando = true;
  int _busca = 0;

  StatusMaquina get status => _status;
  Map<String, dynamic>? get maquina => _maquina;
  String? get erro => _erro;
  bool get carregando => _carregando;

  // busca GET /maquinas/status e atualiza o estado
  Future<void> carregar({bool recomecar = false}) async {
    final minhaBusca = ++_busca;

    if (recomecar) {
      _carregando = true;
      _erro = null;
      notifyListeners();
    }

    try {
      final dados = await ApiService.instance.get('/maquinas/status');
      final lista = dados as List;
      if (minhaBusca != _busca) return;

      _maquina = lista.isEmpty
          ? null
          : Map<String, dynamic>.from(lista.first as Map);
      _status = _calcularStatus(_maquina);
      _erro = null;
      _carregando = false;
      notifyListeners();
    } on ApiException catch (e) {
      if (minhaBusca != _busca) return;

      // sem resposta: mantém o que já tinha.
      if (_carregando) {
        _erro = e.mensagem;
        _status = StatusMaquina.naoEncontrada;
        _carregando = false;
        notifyListeners();
      }
    }
  }

  // volta ao estado inicial
  void reiniciar() {
    _busca++;
    _status = StatusMaquina.verificando;
    _maquina = null;
    _erro = null;
    _carregando = true;
    notifyListeners();
  }

  StatusMaquina _calcularStatus(Map<String, dynamic>? m) {
    if (m == null) return StatusMaquina.semMaquina;
    if (m['online'] != true) return StatusMaquina.naoEncontrada;
    if (m['trabalhando'] == true) return StatusMaquina.trabalhando;
    return StatusMaquina.aguardando;
  }
}