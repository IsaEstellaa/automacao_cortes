import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/titulo_banner.dart';
import '../../core/widgets/modal_confirmacao.dart';
import 'nova_peca_screen.dart';
import 'pecas_content.dart';
import '../../core/services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class PecaDetalhesScreen extends StatefulWidget {
  final Peca peca;

  const PecaDetalhesScreen({super.key, required this.peca});

  @override
  State<PecaDetalhesScreen> createState() => _PecaDetalhesScreenState();
}

class _PecaDetalhesScreenState extends State<PecaDetalhesScreen> {
  int _fotoAtual = 0;
  final _pageController = PageController();
  final _picker = ImagePicker();
  bool _enviandoFoto = false;

  static const int _maxFotos = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _mostrarAviso(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  // ============================================
  // fotos: escolher origem, enviar e remover
  // ============================================
  Future<void> _escolherOrigemFoto() async {
    if (_enviandoFoto) return;

    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.card,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: AppColors.green),
              title: Text('Tirar foto', style: TextStyle(color: AppColors.textoPreto)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: AppColors.green),
              title: Text('Escolher da galeria', style: TextStyle(color: AppColors.textoPreto)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (origem != null) await _adicionarFoto(origem);
  }

  Future<void> _adicionarFoto(ImageSource origem) async {
    XFile? arquivo;

    try {
      // já reduz a imagem antes de enviar
      arquivo = await _picker.pickImage(
        source: origem,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (_) {
      _mostrarAviso('Não foi possível abrir a câmera ou a galeria.');
      return;
    }

    if (arquivo == null) return;

    setState(() => _enviandoFoto = true);

    try {
      final resposta = await ApiService.instance.enviarArquivo(
        '/pecas/${widget.peca.id}/fotos',
        'foto',
        arquivo.path,
        metodo: 'POST',
      ) as Map<String, dynamic>;

      if (!mounted) return;
      setState(() => widget.peca.fotos.add(FotoPeca.fromJson(resposta)));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            widget.peca.fotos.length - 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } on ApiException catch (e) {
      _mostrarAviso(e.mensagem);
    } finally {
      if (mounted) setState(() => _enviandoFoto = false);
    }
  }

  void _confirmarRemocaoFoto(FotoPeca foto) {
    ModalConfirmacao.mostrar(
      context,
      titulo: 'Remover foto',
      mensagem: 'Tem certeza que deseja remover esta foto?',
      textoBotaoConfirmar: 'Remover',
      aoConfirmar: () => _removerFoto(foto),
      corBotao: AppColors.buttonRed,
    );
  }

  Future<void> _removerFoto(FotoPeca foto) async {
    try {
      await ApiService.instance.delete('/pecas/${widget.peca.id}/fotos/${foto.id}');

      if (!mounted) return;
      setState(() {
        widget.peca.fotos.removeWhere((f) => f.id == foto.id);
        if (_fotoAtual >= widget.peca.fotos.length) {
          _fotoAtual = widget.peca.fotos.isEmpty ? 0 : widget.peca.fotos.length - 1;
        }
      });
    } on ApiException catch (e) {
      _mostrarAviso(e.mensagem);
    }
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  // banner título
                  TituloBanner(titulo: widget.peca.nome),
                  const SizedBox(height: 16),

                  // carrossel de fotos
                  _buildCarrossel(),
                  const SizedBox(height: 16),

                  // descrição
                  _buildDescricao(),
                  const SizedBox(height: 16),

                  // cortes da peça
                  _buildCortes(),
                  const SizedBox(height: 24),

                  _buildBotoes(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // carrossel de fotos
  // ============================================
  Widget _buildCarrossel() {
    final fotos = widget.peca.fotos;

    if (fotos.isEmpty) {
      return GestureDetector(
        onTap: _escolherOrigemFoto,
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(40),
            ),
            border: Border.all(color: AppColors.bordaMarrom, width: 1),
          ),
          child: _enviandoFoto
              ? Center(child: CircularProgressIndicator(color: AppColors.green))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 48, color: AppColors.green.withOpacity(0.4)),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhuma foto adicionada',
                      style: TextStyle(fontSize: 13, color: AppColors.green.withOpacity(0.4)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toque para adicionar',
                      style: TextStyle(fontSize: 12, color: AppColors.green.withOpacity(0.4)),
                    ),
                  ],
                ),
        ),
      );
    }

    final atual = _fotoAtual >= fotos.length ? fotos.length - 1 : _fotoAtual;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: fotos.length,
                onPageChanged: (i) => setState(() => _fotoAtual = i),
                itemBuilder: (_, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: AppColors.card,
                    child: Image.network(
                      fotos[index].url,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.broken_image_outlined,
                            size: 40, color: AppColors.green.withOpacity(0.4)),
                      ),
                      loadingBuilder: (_, filho, progresso) => progresso == null
                          ? filho
                          : Center(
                              child: CircularProgressIndicator(
                                color: AppColors.green,
                                strokeWidth: 2,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              // remover a foto que está na tela
              Positioned(
                top: 8,
                right: 8,
                child: _botaoFlutuante(
                  Icons.delete_outline,
                  () => _confirmarRemocaoFoto(fotos[atual]),
                ),
              ),

              // adicionar outra
              if (fotos.length < _maxFotos)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _botaoFlutuante(Icons.add_a_photo_outlined, _escolherOrigemFoto),
                ),

              // carregando
              if (_enviandoFoto)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      color: Colors.black.withOpacity(0.35),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(fotos.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == atual ? 16 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == atual ? AppColors.green : AppColors.green.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _botaoFlutuante(IconData icone, VoidCallback aoTocar) {
    return GestureDetector(
      onTap: aoTocar,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icone, size: 18, color: Colors.white),
      ),
    );
  }

  // ============================================
  // descrição da peça
  // ============================================
  Widget _buildDescricao() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Text(
                'Descrição',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.green,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.peca.descricao,
            style: TextStyle(fontSize: 14, color: AppColors.textoPreto, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ============================================
  // cortes da peça
  // ============================================
  Widget _buildCortes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Text(
            'Cortes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 12),

          widget.peca.cortes.isEmpty
              ? Text(
                  'Nenhum corte cadastrado',
                  style: TextStyle(fontSize: 13, color: AppColors.green.withOpacity(0.5)),
                )
              : Column(
                  children: widget.peca.cortes.map((corte) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(6),
                          bottomLeft: Radius.circular(6),
                          bottomRight: Radius.circular(20),
                        ),
                        border: Border.all(color: AppColors.bordaMarrom, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.content_cut_outlined, size: 18, color: AppColors.green),
                          const SizedBox(width: 8),
                          Text(
                            '${corte['quantidade']} fios de ${corte['metragem']}m',
                            style: TextStyle(fontSize: 14, color: AppColors.textoPreto),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  // ============================================
  // botoes
  // ============================================
  Widget _buildBotoes() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final salvou = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => NovaPecaScreen(pecaParaEditar: widget.peca),
                ),
              );

              // peça editada: volta para a lista, que recarrega com os dados novos
              if (salvou == true && mounted) Navigator.pop(context, true);
            },
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Editar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonGreen,
              foregroundColor: Colors.white,
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
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _mostrarModalExclusao(),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Excluir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonRed,
              foregroundColor: Colors.white,
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
          ),
        ),
      ],
    );
  }

  void _mostrarModalExclusao() {
    ModalConfirmacao.mostrar(
      context,
      titulo: 'Excluir peça',
      mensagem: 'Tem certeza que deseja excluir "${widget.peca.nome}"? Essa ação não poderá ser desfeita.',
      textoBotaoConfirmar: 'Excluir',
      aoConfirmar: () => _excluir(),
      corBotao: AppColors.buttonRed,
    );
  }

  Future<void> _excluir() async {
    try {
      await ApiService.instance.delete('/pecas/${widget.peca.id}');

      if (!mounted) return;

      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensagem)),
      );
    }
  }
}