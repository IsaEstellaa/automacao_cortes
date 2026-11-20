import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class NotificacoesProvider extends ChangeNotifier {
  int _naoVistas = 0;
  int get naoVistas => _naoVistas;

  Future<void> atualizar() async {
    try {
      final resposta = await ApiService.instance.get('/notificacoes/contagem')
          as Map<String, dynamic>;
      final total = resposta['nao_visualizadas'] as int;

      if (total != _naoVistas) {
        _naoVistas = total;
        notifyListeners();
      }
    } on ApiException {
      // sem conexão, mantem
    }
  }

  void diminuir() {
    if (_naoVistas > 0) {
      _naoVistas--;
      notifyListeners();
    }
  }

  void zerar() {
    if (_naoVistas != 0) {
      _naoVistas = 0;
      notifyListeners();
    }
  }
}