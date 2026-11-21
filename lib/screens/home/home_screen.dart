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
import '../../core/services/tempo_real.dart';
import '../../core/services/push_service.dart';
import '../../core/services/notificacao_local.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _indiceSelecionado = 2;

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
    TempoReal.instance.status.addListener(_aoAvisoStatus);

    final fila = context.read<FilaProvider>();
    fila.reiniciar();
    fila.carregar();
    TempoReal.instance.fila.addListener(_aoAvisoFila);

    TempoReal.instance.notificacoes.addListener(_aoAvisoNotificacoes);
    TempoReal.instance.conectar();

    _assinaturaPush =
        FirebaseMessaging.onMessage.listen((_) => _atualizarTudo());

    NotificacaoLocal.instance.abrirNotificacoes.addListener(_abrirAbaNotificacoes);
    NotificacaoLocal.instance.iniciar();
    PushService.instance.iniciar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _assinaturaPush?.cancel();

    TempoReal.instance.notificacoes.removeListener(_aoAvisoNotificacoes);
    TempoReal.instance.status.removeListener(_aoAvisoStatus);
    TempoReal.instance.fila.removeListener(_aoAvisoFila);
    NotificacaoLocal.instance.abrirNotificacoes.removeListener(_abrirAbaNotificacoes);
    TempoReal.instance.desconectar();

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
        return const HomeContent();
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
        Expanded(child: conteudo),
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