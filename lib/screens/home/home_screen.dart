import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import '../../core/providers/notificacoes_provider.dart';
import '../../core/providers/status_maquina_provider.dart';
import '../../core/providers/fila_provider.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/titulo_banner.dart';
import '../notificacoes/notificacoes_content.dart';
import '../configuracoes/configuracoes_content.dart';
import '../automacao/automacao_content.dart';
import '../pecas/pecas_content.dart';
import 'home_content.dart';
import '../../core/services/push_service.dart';
import '../../core/services/notificacao_local.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _indiceSelecionado = 2;
  final Map<String, int> _ultimaSeq = {};

  StreamSubscription<RemoteMessage>? _assinaturaPush;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final notificacoes = context.read<NotificacoesProvider>();
    notificacoes.zerar();
    notificacoes.atualizar();

    final statusMaquina = context.read<StatusMaquinaProvider>();
    statusMaquina.reiniciar();
    statusMaquina.carregar();

    final fila = context.read<FilaProvider>();
    fila.reiniciar();
    fila.carregar();

    _assinaturaPush = FirebaseMessaging.onMessage.listen(_aoReceberPush);

    NotificacaoLocal.instance.abrirNotificacoes.addListener(_abrirAbaNotificacoes);
    NotificacaoLocal.instance.iniciar();
    PushService.instance.iniciar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _assinaturaPush?.cancel();

    NotificacaoLocal.instance.abrirNotificacoes.removeListener(_abrirAbaNotificacoes);

    super.dispose();
  }

  void _aoAvisoNotificacoes() {
    if (!mounted) return;
    context.read<NotificacoesProvider>().atualizar();
  }

  void _aoAvisoStatus() {
    if (!mounted) return;
    context.read<StatusMaquinaProvider>().carregar();
  }

  void _aoAvisoFila() {
    if (!mounted) return;
    context.read<FilaProvider>().carregar();
  }

  void _aoReceberPush(RemoteMessage msg) {
    final evento = msg.data['aviso'];
    if (evento == null) {
      _atualizarTudo();
      return;
    }

    final seq = int.tryParse(msg.data['seq'] ?? '') ?? 0;
    // aviso atrasado
    if (seq < (_ultimaSeq[evento] ?? 0)) return;
    _ultimaSeq[evento] = seq;

    switch (evento) {
      case 'fila':
        _aoAvisoFila();
        break;
      case 'status':
        _aoAvisoStatus();
        break;
      case 'notificacoes':
        _aoAvisoNotificacoes();
        break;
    }
  }

  void _atualizarTudo() {
    _aoAvisoNotificacoes();
    _aoAvisoStatus();
    _aoAvisoFila();
  }

  void _abrirAbaNotificacoes() {
    if (!mounted) return;
    final rotaHome = ModalRoute.of(context);
    Navigator.of(context).popUntil((rota) => rota == rotaHome);
    setState(() => _indiceSelecionado = 3);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _atualizarTudo();
    }
  }

  Widget _buildTela() {
    switch (_indiceSelecionado) {
      case 0:
        return _buildPaginaComTitulo('Automação', const AutomacaoContent());
      case 1:
        return _buildPaginaComTitulo('Suas peças', const PecasContent());
      case 2:
        return HomeContent(
          aoIrParaAba: (indice) => setState(() => _indiceSelecionado = indice),
        );
      case 3:
        return _buildPaginaComTitulo('Notificações', const NotificacoesContent());
      case 4:
        return _buildPaginaComTitulo(
          'Configurações',
          ConfiguracoesContent(
            aoAtualizarPerfil: () => setState(() {}),
            aoAbrirNotificacoes: () => setState(() => _indiceSelecionado = 3),
          ),
        );
      default:
        return _placeholder('Home');
    }
  }

  Widget _buildPaginaComTitulo(String titulo, Widget conteudo) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: TituloBanner(titulo: titulo),
        ),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              conteudo,
              //sombra
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 10,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.10),
                          Colors.black.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // tela temporária enquanto as outras não estão prontas - remover depois
  Widget _placeholder(String nome) {
    return Center(
      child: Text(
        nome,
        style: TextStyle(
          fontSize: 24,
          color: AppColors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(nomeUsuario: ApiService.instance.usuario?['nome'] ?? ''),
          Expanded(
            child: _buildTela(),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        indiceSelecionado: _indiceSelecionado,
        aoSelecionar: (indice) {
          setState(() => _indiceSelecionado = indice);
        },
      ),
    );
  }
}