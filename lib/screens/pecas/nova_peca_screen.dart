import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/titulo_banner.dart';
import '../../core/widgets/modal_confirmacao.dart';
import '../../core/widgets/painters.dart';

// modelo de corte do formulário
class CorteFormulario {
  TextEditingController quantidade;
  TextEditingController metragem;

  CorteFormulario()
      : quantidade = TextEditingController(),
        metragem = TextEditingController();

  void dispose() {
    quantidade.dispose();
    metragem.dispose();
  }
}

class NovaPecaScreen extends StatefulWidget {
  const NovaPecaScreen({super.key});

  @override
  State<NovaPecaScreen> createState() => _NovaPecaScreenState();
}

class _NovaPecaScreenState extends State<NovaPecaScreen> {
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();

  // lista de fotos selecionadas (por enquanto só paths)
  final List<String> _fotos = [];

  // lista de cortes do formulário — começa com um vazio
  final List<CorteFormulario> _cortes = [CorteFormulario()];

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    for (final c in _cortes) c.dispose();
    super.dispose();
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
          onPressed: () => ModalConfirmacao.mostrar(
            context,
            titulo: 'Descartar peça?',
            mensagem: 'As informações preenchidas serão perdidas.',
            textoBotaoConfirmar: 'Descartar',
            aoConfirmar: () => Navigator.pop(context),
            corBotao: AppColors.buttonRed,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            TituloBanner(titulo: 'Nova peça'),
            const SizedBox(height: 20),
            _buildSecaoInfos(),
            const SizedBox(height: 16),
            _buildSecaoFotos(),
            const SizedBox(height: 16),
            _buildSecaoCortes(),
            const SizedBox(height: 24),
            _buildBotaoSalvar(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ============================================
  // seção de nome e descrição
  // ============================================
  Widget _buildSecaoInfos() {
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
          _buildLabel('Nome da peça'),
          const SizedBox(height: 8),
          _buildCampo(
            controller: _nomeController,
            hint: 'Ex: Bolsa de macramê',
          ),
          const SizedBox(height: 16),
          _buildLabel('Descrição'),
          const SizedBox(height: 8),
          _buildCampo(
            controller: _descricaoController,
            hint: 'Descreva a peça...',
            maxLinhas: 3,
          ),
        ],
      ),
    );
  }

  // ============================================
  // seção de fotos
  // ============================================
  Widget _buildSecaoFotos() {
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
          _buildLabel('Fotos'),
          const SizedBox(height: 12),

          // botões de galeria e câmera
          Row(
            children: [
              Expanded(
                child: _buildBotaoFoto(
                  icone: Icons.photo_library_outlined,
                  texto: 'Galeria',
                  aoTocar: () {
                    // TODO: abrir galeria com image_picker (nao faço idea de como fazer isso ainda)
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBotaoFoto(
                  icone: Icons.camera_alt_outlined,
                  texto: 'Câmera',
                  aoTocar: () {
                    // TODO: abrir câmera com image_picker (nao faço idea de como fazer isso ainda/2)
                  },
                ),
              ),
            ],
          ),

          // preview das fotos selecionadas --> vou testar depois
          if (_fotos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _fotos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        _fotos[index],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // botão de remover foto
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => setState(() => _fotos.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Nenhuma foto adicionada',
                style: TextStyle(fontSize: 13, color: AppColors.green.withOpacity(0.7)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBotaoFoto({
    required IconData icone,
    required String texto,
    required VoidCallback aoTocar,
  }) {
    return GestureDetector(
      onTap: aoTocar,
      child: CustomPaint(
        painter: BordaTracejadaPainter(sombras: AppColors.sombra),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, color: AppColors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                texto,
                style: TextStyle(fontSize: 14, color: AppColors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // seção de cortes
  // ============================================
  Widget _buildSecaoCortes() {
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
          _buildLabel('Cortes'),
          const SizedBox(height: 12),

          // campos de corte
          ...List.generate(_cortes.length, (index) {
            return _buildCampoCorte(index);
          }),

          // botão adicionar corte
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _cortes.add(CorteFormulario())),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.bordaMarrom,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: AppColors.green, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Adicionar corte',
                    style: TextStyle(fontSize: 14, color: AppColors.green),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoCorte(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10), // 👈 margin vira Padding externo
      child: CustomPaint(
        painter: BordaTracejadaPainter(sombras: AppColors.sombra),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.content_cut_outlined, size: 16, color: AppColors.green),
              const SizedBox(width: 8),

              SizedBox(
                width: 50,
                child: TextField(
                  controller: _cortes[index].quantidade,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.green),
                  decoration: InputDecoration(
                    hintText: 'Qtde',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.green.withOpacity(0.4)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),

              Text(' fios de ', style: TextStyle(fontSize: 13, color: AppColors.textoPreto)),

              SizedBox(
                width: 50,
                child: TextField(
                  controller: _cortes[index].metragem,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.green),
                  decoration: InputDecoration(
                    hintText: 'Metros',
                    hintStyle: TextStyle(fontSize: 12, color: AppColors.green.withOpacity(0.4)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),

              Text('m', style: TextStyle(fontSize: 13, color: AppColors.textoPreto)),

              Spacer(),

              // botão remover corte
              if (_cortes.length > 1) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() {
                    _cortes[index].dispose();
                    _cortes.removeAt(index);
                  }),
                  child: Icon(Icons.remove_circle_outline,
                      size: 18, color: AppColors.buttonRed.withOpacity(0.7)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // botão salvar
  // ============================================
  Widget _buildBotaoSalvar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // TODO: validar e salvar via API
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(6),
            ),
          ),
        ),
        child: const Text(
          'Salvar peça',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ============================================
  // widgets auxiliares
  // ============================================
  Widget _buildLabel(String texto) {
    return Text(
      texto,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.green,
      ),
    );
  }

  Widget _buildCampo({
    required TextEditingController controller,
    required String hint,
    int maxLinhas = 1,
  }) {
    return CustomPaint(
      painter: BordaTracejadaPainter(sombras: AppColors.sombra),
      child: TextField(
        controller: controller,
        maxLines: maxLinhas,
        style: TextStyle(fontSize: 14, color: AppColors.green),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: AppColors.green.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}