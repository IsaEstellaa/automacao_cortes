import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// notificacoes com o app aberto
class NotificacaoLocal {
  NotificacaoLocal._();
  static final NotificacaoLocal instance = NotificacaoLocal._();

  static const _canalId = 'automacao_cortes';
  static const _canalNome = 'Avisos da máquina';

  final ValueNotifier<int> abrirNotificacoes = ValueNotifier<int>(0);

  final _plugin = FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _assinaturaMensagem;
  StreamSubscription<RemoteMessage>? _assinaturaToque;
  bool _pronto = false;

  Future<void> iniciar() async {
    if (_pronto) return;

    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (_) => abrirNotificacoes.value++,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _canalId,
              _canalNome,
              description: 'Cortes concluídos, falhas e estado da máquina',
              importance: Importance.high,
            ),
          );

      _assinaturaMensagem = FirebaseMessaging.onMessage.listen(_aoReceber);

      _assinaturaToque = FirebaseMessaging.onMessageOpenedApp
          .listen((_) => abrirNotificacoes.value++);

      final inicial = await FirebaseMessaging.instance.getInitialMessage();
      if (inicial != null) abrirNotificacoes.value++;

      _pronto = true;
    } catch (e) {
      debugPrint('Notificação local não iniciou: $e');
    }
  }

  Future<void> _aoReceber(RemoteMessage mensagem) async {
    final aviso = mensagem.notification;
    if (aviso == null) return;

    try {
      await _plugin.show(
        id: mensagem.hashCode,
        title: aviso.title,
        body: aviso.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _canalId,
            _canalNome,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: 'notificacoes',
      );
    } catch (e) {
      debugPrint('Não mostrou a notificação: $e');
    }
  }

  Future<void> parar() async {
    await _assinaturaMensagem?.cancel();
    await _assinaturaToque?.cancel();
    _assinaturaMensagem = null;
    _assinaturaToque = null;
    _pronto = false;
  }
}