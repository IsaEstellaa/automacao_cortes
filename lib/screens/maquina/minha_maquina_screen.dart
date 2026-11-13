import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/modal_confirmacao.dart';
import '../../core/widgets/painters.dart';
import '../../core/widgets/titulo_banner.dart';

class MinhaMaquinaScreen extends StatefulWidget {
  const MinhaMaquinaScreen({super.key});

  @override
  State<MinhaMaquinaScreen> createState() => _MinhaMaquinaScreenState();
}

class _MinhaMaquinaScreenState extends State<MinhaMaquinaScreen> {
  bool _carregando = true;
  bool _ocupado = false;
  String? _erro;
  Map<String, dynamic>? _maquina;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _carregar();
    // TODO: retirar a atualizacao a cada 10s
    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _carregar(silencioso: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ============================================
  // dados
  // ============================================
  Future<void> _carregar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {
      final dados = await ApiService.instance.get('/maquinas/status');
      final lista = dados as List;
      if (!mounted) return;
      setState(() {
        _maquina = lista.isEmpty
            ? null
            : Map<String, dynamic>.from(lista.first as Map);
        _carregando = false;
        _erro = null;
      });
    } on ApiException catch (e) {
      if (!mounted || silencioso) return;
      setState(() {
        _erro = e.mensagem;
        _carregando = false;
      });
    }
  }

  Future<void> _executar(Future<void> Function() acao) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      await acao();
    } on ApiException catch (e) {
      _aviso(e.mensagem);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  // ============================================
  // ações
  // ============================================
  Future<void> _cadastrar() async {
    final nome = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogNome(
        titulo: 'Cadastrar máquina',
        inicial: 'Minha máquina',
        textoBotao: 'Cadastrar',
      ),
    );
    if (nome == null) return;

    await _executar(() async {
      final r = await ApiService.instance.post('/maquinas', {'nome': nome});
      await _carregar(silencioso: true);
      await _mostrarChave((r as Map)['chave'] as String);
    });
  }

  Future<void> _renomear() async {
    final atual = _maquina!;
    final nome = await showDialog<String>(
      context: context,
      builder: (_) => _DialogNome(
        titulo: 'Renomear máquina',
        inicial: (atual['nome'] ?? '').toString(),
        textoBotao: 'Salvar',
      ),
    );
    if (nome == null) return;

    await _executar(() async {
      await ApiService.instance.put(
        '/maquinas/${atual['id_maquina']}',
        {'nome': nome},
      );
      await _carregar(silencioso: true);
    });
  }

  void _novaChave() {
    final id = _maquina!['id_maquina'];
    ModalConfirmacao.mostrar(
      context,
      titulo: 'Gerar nova chave?',
      mensagem:
          'A chave atual deixará de funcionar. Você precisará colocar a nova chave na máquina.',
      textoBotaoConfirmar: 'Gerar',
      corBotao: AppColors.buttonRed,
      aoConfirmar: () => _executar(() async {
        final r = await ApiService.instance.post('/maquinas/$id/chave');
        await _carregar(silencioso: true);
        await _mostrarChave((r as Map)['chave'] as String);
      }),
    );
  }

  void _remover() {
    final id = _maquina!['id_maquina'];
    ModalConfirmacao.mostrar(
      context,
      titulo: 'Remover máquina?',
      mensagem:
          'Ela deixará de receber cortes. Você poderá cadastrar outra depois.',
      textoBotaoConfirmar: 'Remover',
      corBotao: AppColors.buttonRed,
      aoConfirmar: () => _executar(() async {
        await ApiService.instance.delete('/maquinas/$id');
        await _carregar(silencioso: true);
      }),
    );
  }

  Future<void> _mostrarChave(String chave) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.card,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚠️ Chave da máquina',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Guarde esta chave agora: ela não será mostrada de novo. É ela que a máquina usa para se conectar.',
                style: TextStyle(fontSize: 14, color: AppColors.textoPreto),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.bordaMarrom, width: 1),
                ),
                child: SelectableText(
                  chave,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                    color: AppColors.textoPreto,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // Expanded(
                  //   child: OutlinedButton.icon(
                  //     onPressed: () async {
                  //       await Clipboard.setData(ClipboardData(text: chave));
                  //       if (ctx.mounted) {
                  //         ScaffoldMessenger.of(ctx).showSnackBar(
                  //           const SnackBar(content: Text('Chave copiada')),
                  //         );
                  //       }
                  //     },
                  //     icon: Icon(Icons.copy, size: 18, color: AppColors.green),
                  //     label: Text(
                  //       'Copiar',
                  //       style: TextStyle(color: AppColors.green),
                  //     ),
                  //     style: OutlinedButton.styleFrom(
                  //       side: BorderSide(color: AppColors.green),
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          side: BorderSide(color: AppColors.bordaMarrom),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(30),
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                        ),
                        child: Text(
                          'Pronto',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // tela
  // ============================================
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
      body: RefreshIndicator(
        color: AppColors.green,
        onRefresh: () => _carregar(silencioso: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              TituloBanner(titulo: 'Minha máquina'),
              const SizedBox(height: 20),
              _buildConteudo(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConteudo() {
    if (_carregando) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }
    if (_erro != null) {return _buildErro();}
    if (_maquina == null) return _buildSemMaquina();
    return _buildMaquina();
  }

  Widget _buildErro() {
    return _card(
      Column(
        children: [
          Icon(Icons.cloud_off_outlined, size: 56, color: AppColors.textoPreto),
          const SizedBox(height: 12),
          Text(
            _erro!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.textoPreto),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _carregar(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(10),
                  ),
                ),
              ),
              child: Text(
                'Tentar de novo',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemMaquina() {
    return _card(
      Column(
        children: [
          Icon(
            Icons.precision_manufacturing_outlined,
            size: 64,
            color: AppColors.textoPreto,
          ),
          const SizedBox(height: 16),
          Text(
            'Você ainda não tem uma máquina cadastrada',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textoPreto,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cadastre a sua máquina para enviar os cortes. Você receberá uma chave para colocar nela.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textoPreto),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _ocupado ? null : _cadastrar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(10),
                  ),
                ),
              ),
              child: Text(
                'Cadastrar máquina',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaquina() {
    final m = _maquina!;
    final online = m['online'] == true;
    final trabalhando = online && m['trabalhando'] == true;
    final segundos = m['segundos_desde_contato'];

    final String textoStatus = !online
        ? 'Offline'
        : (trabalhando ? 'Trabalhando agora' : 'Online, aguardando um corte');
    final String detalhe = online
        ? 'Conectada agora'
        : (segundos is int
            ? 'Visto pela última vez ${_tempoDesde(segundos)}'
            : 'Ainda não se conectou');

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (m['nome'] ?? '').toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.green,
                  ),
                ),
              ),
              IconButton(
                onPressed: _ocupado ? null : _renomear,
                icon: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: AppColors.green.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: online ? AppColors.green : AppColors.buttonRed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  textoStatus,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textoPreto,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              detalhe,
              style: TextStyle(fontSize: 14, color: AppColors.textoMarrom),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _ocupado ? null : _novaChave,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.green),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Gerar nova chave',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.green,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _ocupado ? null : _remover,
              child: Text(
                'Remover máquina',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.buttonRed,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Para cadastrar outra máquina, remova esta.',
            style: TextStyle(fontSize: 12, color: AppColors.textoMarrom),
          ),
        ],
      ),
    );
  }

  String _tempoDesde(int s) {
    if (s < 60) return 'há $s s';
    if (s < 3600) return 'há ${s ~/ 60} min';
    if (s < 86400) return 'há ${s ~/ 3600} h';
    return 'há ${s ~/ 86400} dias';
  }

  Widget _card(Widget filho) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(40),
        ),
        border: Border.all(color: AppColors.bordaMarrom, width: 1),
        boxShadow: AppColors.sombra,
      ),
      child: filho,
    );
  }
}

class _DialogNome extends StatefulWidget {
  final String titulo;
  final String inicial;
  final String textoBotao;

  const _DialogNome({
    required this.titulo,
    required this.inicial,
    required this.textoBotao,
  });

  @override
  State<_DialogNome> createState() => _DialogNomeState();
}

class _DialogNomeState extends State<_DialogNome> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.inicial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    final nome = _controller.text.trim();
    if (nome.isEmpty) return;
    Navigator.pop(context, nome);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.titulo,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: 20),
            CustomPaint(
              painter: BordaTracejadaPainter(sombras: AppColors.sombra),
              child: TextField(
                controller: _controller,
                autofocus: true,
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                style: TextStyle(fontSize: 14, color: AppColors.green),
                decoration: InputDecoration(
                  hintText: 'Nome da máquina',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: AppColors.green.withOpacity(0.4),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _confirmar(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: AppColors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(30),
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                      ),
                      child: Text(
                        widget.textoBotao,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}