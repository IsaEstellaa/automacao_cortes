import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/painters.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/estado_erro.dart';
import '../../core/services/notificacoes_contador.dart';

// icone da notificacao
enum TipoNotificacao {
  maquina,  // ícone de tesoura
  alerta,   // ícone de warning
  info,     // ícone de informação
}

String _tituloDoTipo(String tipo) {
  switch (tipo) {
    case 'S':
      return 'Sucesso';
    case 'E':
      return 'Erro';
    case 'A':
      return 'Alerta';
    case 'I':
      return 'Informação';
    default:
      return 'Notificação';
  }
}

TipoNotificacao _tipoDoCodigo(String tipo) {
  switch (tipo) {
    case 'S':
      return TipoNotificacao.maquina;
    case 'E':
    case 'A':
      return TipoNotificacao.alerta;
    default:
      return TipoNotificacao.info;
  }
}

class Notificacao {
  final int id;
  final String titulo;
  final String descricao;
  final TipoNotificacao tipo;
  bool visto;

  Notificacao({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.tipo,
    this.visto = false,
  });

  // monta a notificação a partir do JSON
    factory Notificacao.fromJson(Map<String, dynamic> json) {
    final tipo = json['tipo'] as String;
    final titulo = json['titulo'] as String?;

    return Notificacao(
      id: json['id_notificacao'] as int,
      titulo: (titulo == null || titulo.trim().isEmpty) ? _tituloDoTipo(tipo) : titulo,
      descricao: json['mensagem'] as String,
      tipo: _tipoDoCodigo(tipo),
      visto: json['visualizada'] == 'S',
    );
  }
}

class NotificacoesContent extends StatefulWidget {
  const NotificacoesContent({super.key});

  @override
  State<NotificacoesContent> createState() => _NotificacoesContentState();
}

class _NotificacoesContentState extends State<NotificacoesContent> {
    List<Notificacao> _notificacoes = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar({bool recarga = false}) async {
    if (!recarga) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {
      final resposta = await ApiService.instance.get('/notificacoes') as List;
      final lista = resposta
          .map((j) => Notificacao.fromJson(j as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _notificacoes = lista;
        _erro = null;
      });
      NotificacoesContador.instance.atualizar();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (recarga) {
        _mostrarAviso(e.mensagem);
      } else {
        setState(() => _erro = e.mensagem);
      }
    } finally {
      if (mounted && !recarga) setState(() => _carregando = false);
    }
  }

  Future<void> _marcarComoVisto(Notificacao notificacao) async {
    if (notificacao.visto) return;

    setState(() => notificacao.visto = true);
    NotificacoesContador.instance.diminuir();

    try {
      await ApiService.instance.patch(
        '/notificacoes/${notificacao.id}/visualizada',
        {},
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => notificacao.visto = false);
      NotificacoesContador.instance.atualizar();
      _mostrarAviso(e.mensagem);
    }
  }

  void _mostrarAviso(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  IconData _iconeDoTipo(TipoNotificacao tipo) {
    switch (tipo) {
      case TipoNotificacao.maquina:
        return Icons.content_cut_outlined;
      case TipoNotificacao.alerta:
        return Icons.warning_amber_outlined;
      case TipoNotificacao.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return Center(child: CircularProgressIndicator(color: AppColors.green));
    }

    if (_erro != null) {
      return EstadoErro(mensagem: _erro!, aoTentarNovamente: _carregar);
    }

    // recarrega quando puxa para baixo
    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: () => _carregar(recarga: true),
      child: _notificacoes.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _buildVazia(),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: _notificacoes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) => _buildCard(_notificacoes[index]),
            ),
    );
  }

  // ============================================
  // card de notificação
  // ============================================
  Widget _buildCard(Notificacao notificacao) {
    final visto = notificacao.visto;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: visto ? 0.45 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(15),
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
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(5),
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(7),
              ),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: AppColors.fundoFitaRosa.withOpacity(0.20),
                    ),

                    CustomPaint(
                      painter: ListrasPainter(
                        cor: AppColors.listrasFitaRosa.withOpacity(0.15),
                        espessura: 5,
                        espacamento: 18,
                      ),
                    ),

                    Center(
                      child: Icon(
                        _iconeDoTipo(notificacao.tipo),
                        color: AppColors.greenSelected,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // título e descrição
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notificacao.titulo,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notificacao.descricao,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textoPreto,
                    ),
                  ),
                ],
              ),
            ),

            // botão de marcar como visto
            IconButton(
              onPressed: notificacao.visto ? null : () => _marcarComoVisto(notificacao),
              icon: Icon(
                visto ? Icons.check_circle : Icons.check_circle_outline,
                color: AppColors.green,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // estado vazio — quando não há notificações
  // ============================================
  Widget _buildVazia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.green.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            'Nenhuma notificação',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.green.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}