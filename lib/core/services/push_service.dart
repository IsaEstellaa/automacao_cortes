import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  StreamSubscription<String>? _assinaturaToken;
  String? _tokenAtual;

  Future<void> iniciar() async {
    try {
      final fcm = FirebaseMessaging.instance;

      final permissao = await fcm.requestPermission();
      if (permissao.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await fcm.getToken();
      if (token != null) {
        await _registrar(token);
      }

      _assinaturaToken ??= fcm.onTokenRefresh.listen(_registrar);
    } catch (e) {
      debugPrint('Push não iniciou: $e');
    }
  }

  Future<void> _registrar(String token) async {
    _tokenAtual = token;
    try {
      await ApiService.instance.post('/dispositivos', {'token': token});
    } catch (e) {
      debugPrint('Não registrou o dispositivo: $e');
    }
  }

  Future<void> removerToken() async {
    final token = _tokenAtual;

    await _assinaturaToken?.cancel();
    _assinaturaToken = null;
    _tokenAtual = null;

    if (token == null) return;

    try {
      await ApiService.instance.post('/dispositivos/remover', {'token': token});
    } catch (e) {
      debugPrint('Não removeu o dispositivo: $e');
    }
  }
}