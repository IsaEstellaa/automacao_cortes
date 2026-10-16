import 'package:flutter/foundation.dart';
import 'api_service.dart';

class NotificacoesContador {
  NotificacoesContador._();
  static final NotificacoesContador instance = NotificacoesContador._();

  final ValueNotifier<int> naoVistas = ValueNotifier<int>(0);

  Future<void> atualizar() async {
    try {
      final resposta = await ApiService.instance.get('/notificacoes/contagem')
          as Map<String, dynamic>;
      naoVistas.value = resposta['nao_visualizadas'] as int;
    } on ApiException {
      // sem conexão: mantém o número que já estava no badge
    }
  }

  void diminuir() {
    if (naoVistas.value > 0) naoVistas.value = naoVistas.value - 1;
  }

  void zerar() => naoVistas.value = 0;
}