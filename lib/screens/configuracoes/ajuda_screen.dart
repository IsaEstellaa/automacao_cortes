import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/painters.dart';
import '../../core/widgets/titulo_banner.dart';
import '../cadastro/boas_vindas_screen.dart';

const _emailContato = 'bellahestela@gmail.com';
const _versaoApp = '1.0.0';

class _ItemAjuda {
  final String pergunta;
  final String resposta;
  const _ItemAjuda(this.pergunta, this.resposta);
}

const _perguntasFrequentes = [
  _ItemAjuda(
    'Como cadastro uma peça?',
    'Na aba "Suas peças", toque no botão de nova peça. Informe o nome, uma descrição '
        '(opcional) e adicione os cortes: a quantidade de fios e a metragem de cada um '
        '(por exemplo, 10 fios de 5 metros).',
  ),
  _ItemAjuda(
    'Como envio cortes para a máquina?',
    'Na aba "Automação", toque em "Novo corte", escolha o material e os cortes da peça '
        'e confirme. Os cortes entram na fila e a máquina os executa na ordem em que '
        'foram enviados.',
  ),
  _ItemAjuda(
    'Por que não consigo enviar um novo corte?',
    'A máquina trabalha com um lote por vez. Enquanto houver cortes na fila (ou uma '
        'retentativa em andamento), novos envios ficam bloqueados. Espere terminar e envie '
        'de novo. Além disso, todos os cortes de um mesmo envio precisam ser da mesma peça.',
  ),
  _ItemAjuda(
    'O que significa um fio com erro?',
    'Quando a máquina não consegue cortar um fio, ele fica marcado com erro, e a peça '
        'aparece com um ícone de alerta no histórico. Toque no alerta para ver o que '
        'aconteceu com cada fio.',
  ),
  _ItemAjuda(
    'Como funciona a retentativa?',
    'No alerta do histórico, toque em "Retentar fios com erro". Só os fios com erro são '
        'cortados de novo, e a retentativa aparece na fila até terminar. Ela só pode ser '
        'feita com a máquina livre.',
  ),
  _ItemAjuda(
    'O que aparece no histórico?',
    'Os cortes já finalizados, agrupados por peça. Toque no nome da peça para ver '
        'cada corte feito.',
  ),
  _ItemAjuda(
    'Posso editar um corte ou um material?',
    'Pode. Ao editar um corte, o app guarda a versão antiga: o que já foi cortado '
        'continua aparecendo no histórico com os valores da época.',
  ),
  _ItemAjuda(
    'Como altero meu nome ou minha descrição?',
    'Em "Configurações", toque no lápis do seu perfil.',
  ),
];

const _problemas = [
  _ItemAjuda(
    'Sem conexão com o servidor',
    'Verifique a sua internet. Se estiver tudo certo, o servidor pode estar fora do ar: '
        'tente de novo em alguns minutos.',
  ),
  _ItemAjuda(
    'A fila não anda',
    'Confira se a máquina está ligada, com fio carregado e conectada à internet. Depois, '
        'puxe a tela da Automação para baixo para atualizar.',
  ),
  _ItemAjuda(
    'Um fio travou ou deu erro',
    'Veja o motivo no alerta do histórico, resolva na máquina (por exemplo, fio '
        'emaranhado ou acabando) e use "Retentar fios com erro".',
  ),
  _ItemAjuda(
    'O app pediu para eu entrar de novo',
    'Por segurança, depois de alguns dias a sessão expira. É só entrar novamente com o '
        'seu e-mail e a sua senha.',
  ),
];

class AjudaScreen extends StatefulWidget {
  const AjudaScreen({super.key});

  @override
  State<AjudaScreen> createState() => _AjudaScreenState();
}

class _AjudaScreenState extends State<AjudaScreen> {
  final Set<String> _abertos = {};

  Future<void> _copiarEmail() async {
    await Clipboard.setData(const ClipboardData(text: _emailContato));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('E-mail copiado!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            const TituloBanner(titulo: 'Ajuda'),
            const SizedBox(height: 20),

            _buildAtalhoIntroducao(),
            const SizedBox(height: 24),

            _buildTituloSecao('Perguntas frequentes'),
            ..._perguntasFrequentes.map(_buildItemExpansivel),
            const SizedBox(height: 14),

            _buildTituloSecao('Entendendo os status'),
            _buildLegenda(),
            const SizedBox(height: 14),

            _buildTituloSecao('Solução de problemas'),
            ..._problemas.map(_buildItemExpansivel),
            const SizedBox(height: 14),

            _buildTituloSecao('Contato e sobre'),
            _buildContato(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ============================================
  // rever a introdução (reabre o modal de boas-vindas)
  // ============================================
  Widget _buildAtalhoIntroducao() {
    return GestureDetector(
      onTap: () => mostrarModalBoasVindas(
        context,
        podeFechar: true,
        textoBotao: 'Fechar',
        aoContinuar: () => Navigator.pop(context),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.bordaMarrom, width: 1),
          boxShadow: AppColors.sombra,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 50,
                height: 50,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: AppColors.fundoFitaRosa.withOpacity(0.20)),
                    CustomPaint(
                      painter: ListrasPainter(
                        cor: AppColors.listrasFitaRosa.withOpacity(0.15),
                        espessura: 5,
                        espacamento: 18,
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: AppColors.greenSelected,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Rever a introdução',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textoPreto,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.green.withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // título de cada seção
  // ============================================
  Widget _buildTituloSecao(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          titulo,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.green,
          ),
        ),
      ),
    );
  }

  // ============================================
  // pergunta que abre e fecha
  // ============================================
  Widget _buildItemExpansivel(_ItemAjuda item) {
    final aberto = _abertos.contains(item.pergunta);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.bordaMarrom, width: 1),
        boxShadow: AppColors.sombra,
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() {
              if (aberto) {
                _abertos.remove(item.pergunta);
              } else {
                _abertos.add(item.pergunta);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.pergunta,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                  Icon(
                    aberto ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.green,
                  ),
                ],
              ),
            ),
          ),
          if (aberto)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.resposta,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textoPreto,
                    height: 1.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================
  // legenda dos status da Automação
  // ============================================
  Widget _buildLegenda() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.bordaMarrom, width: 1),
        boxShadow: AppColors.sombra,
      ),
      child: Column(
        children: [
          _buildLinhaLegenda(
            Icons.content_cut_outlined,
            'Processando',
            'O corte em destaque na fila, com barra de progresso, metragem e tempo decorrido.',
          ),
          const SizedBox(height: 14),
          _buildLinhaLegenda(
            Icons.schedule,
            'Aguardando',
            'Cortes esperando a vez na fila. A máquina segue a ordem de envio.',
          ),
          const SizedBox(height: 14),
          _buildLinhaLegenda(
            Icons.check_circle_outline,
            'Concluído',
            'Todos os fios foram cortados. Fica no histórico, agrupado por peça.',
          ),
          const SizedBox(height: 14),
          _buildLinhaLegenda(
            Icons.warning_amber_rounded,
            'Com erro',
            'Algum fio não foi cortado. Toque no alerta do histórico para ver o motivo.',
            cor: const Color.fromARGB(255, 117, 17, 2),
          ),
          const SizedBox(height: 14),
          _buildLinhaLegenda(
            Icons.replay,
            'Retentativa',
            'Fios com erro sendo cortados de novo. Aparece na fila até terminar.',
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaLegenda(
    IconData icone,
    String titulo,
    String descricao, {
    Color? cor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 22, color: cor ?? AppColors.green),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textoPreto,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                descricao,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textoPreto,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================
  // contato e sobre o projeto
  // ============================================
  Widget _buildContato() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'Precisa de ajuda?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textoPreto,
              ),
            ),
          ),
          const SizedBox(height: 6),

          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _copiarEmail,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.mail_outline, size: 20, color: AppColors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _emailContato,
                      style: TextStyle(fontSize: 14, color: AppColors.green),
                    ),
                  ),
                  Icon(
                    Icons.copy_outlined,
                    size: 18,
                    color: AppColors.green.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'Toque para copiar o e-mail.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textoPreto.withOpacity(0.6),
              ),
            ),
          ),

          const SizedBox(height: 14),
          Divider(color: AppColors.bordaMarrom.withOpacity(0.5), height: 1),
          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Automação de Cortes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textoPreto,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aplicativo para automatizar o corte de fios de macramê, integrando o '
                  'app a uma máquina de corte.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textoPreto,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Projeto de TCC do curso de Ciência da Computação.',
                  style: TextStyle(fontSize: 13, color: AppColors.textoPreto, height: 1.4),
                ),
                Text(
                  'Desenvolvido por Isabella Estella de Oliveira.',
                  style: TextStyle(fontSize: 13, color: AppColors.textoPreto, height: 1.4, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Versão $_versaoApp',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textoPreto.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}