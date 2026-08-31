import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// icone da notificacao
enum TipoNotificacao {
  maquina,  // ícone de tesoura
  alerta,   // ícone de warning
  info,     // ícone de informação
}

class Notificacao {
  final String titulo;
  final String descricao;
  final TipoNotificacao tipo;
  bool visto;

  Notificacao({
    required this.titulo,
    required this.descricao,
    required this.tipo,
    this.visto = false,
  });
}

class NotificacoesContent extends StatefulWidget {
  const NotificacoesContent({super.key});

  @override
  State<NotificacoesContent> createState() => _NotificacoesContentState();
}

class _NotificacoesContentState extends State<NotificacoesContent> {
  // TODO: Fazer funcionar
  final List<Notificacao> _notificacoes = [
    Notificacao(
      titulo: 'Corte finalizado',
      descricao: 'Seu corte de 40 fios foi concluído!',
      tipo: TipoNotificacao.maquina,
    ),
    Notificacao(
      titulo: 'Corte não finalizado',
      descricao: 'Seu corte não foi finalizado!',
      tipo: TipoNotificacao.alerta,
    ),
    Notificacao(
      titulo: 'Atualização disponível',
      descricao: 'Uma nova versão do app está disponível.',
      tipo: TipoNotificacao.info,
    ),
  ];

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
    return _notificacoes.isEmpty
        ? _buildVazia()
        : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            itemCount: _notificacoes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) => _buildCard(_notificacoes[index]),
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
        padding: const EdgeInsets.all(12),
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
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(5),
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(7),
                ),
              ),
              child: Icon(
                _iconeDoTipo(notificacao.tipo),
                color: AppColors.green,
                size: 26,
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
                      fontSize: 13,
                      color: AppColors.textoPreto,
                    ),
                  ),
                ],
              ),
            ),

            // botão de marcar como visto
            IconButton(
              onPressed: () {
                setState(() => notificacao.visto = !notificacao.visto);
              },
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