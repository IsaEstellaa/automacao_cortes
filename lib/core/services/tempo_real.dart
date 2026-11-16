import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_service.dart';

// conexão em tempo real com o back
class TempoReal with WidgetsBindingObserver {
  TempoReal._();
  static final TempoReal instance = TempoReal._();

  final ValueNotifier<int> fila = ValueNotifier<int>(0);
  final ValueNotifier<int> status = ValueNotifier<int>(0);
  final ValueNotifier<int> notificacoes = ValueNotifier<int>(0);

  io.Socket? _socket;
  bool _observando = false;

  bool get conectado => _socket?.connected ?? false;

  void conectar() {
    desconectar();

    final token = ApiService.instance.token;
    if (token == null) return;

    final socket = io.io(
      ApiService.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );

    socket.onConnect((_) {
      debugPrint('[tempo real] conectado');
      _atualizarTudo();
    });
    socket.onDisconnect(
      (motivo) => debugPrint('[tempo real] desconectado: $motivo'),
    );
    socket.onConnectError(
      (erro) => debugPrint('[tempo real] erro de conexão: $erro'),
    );

    socket.on('fila', (_) => fila.value++);
    socket.on('status', (_) => status.value++);
    socket.on('notificacoes', (_) => notificacoes.value++);

    _socket = socket;
    socket.connect();

    if (!_observando) {
      WidgetsBinding.instance.addObserver(this);
      _observando = true;
    }
  }

  void desconectar() {
    _socket?.dispose();
    _socket = null;
  }

  void _atualizarTudo() {
    fila.value++;
    status.value++;
    notificacoes.value++;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _socket != null) {
      if (!conectado) _socket!.connect();
      _atualizarTudo();
    }
  }
}