import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/titulo_banner.dart';
import '../../core/widgets/painters.dart';
import '../../core/widgets/modal_confirmacao.dart';
import 'materiais_screen.dart';
import '../../core/services/api_service.dart';

class NovoMaterialScreen extends StatefulWidget {
  final MaterialFio? materialParaEditar;

  const NovoMaterialScreen({
    super.key,
    this.materialParaEditar,
  });

  @override
  State<NovoMaterialScreen> createState() => _NovoMaterialScreenState();
}

class _NovoMaterialScreenState extends State<NovoMaterialScreen> {
  final _nomeController = TextEditingController();
  final _espessuraController = TextEditingController();
  final _gramaturaController = TextEditingController();
  final _observacaoController = TextEditingController();
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    if (widget.materialParaEditar != null) {
      _nomeController.text = widget.materialParaEditar!.nome;
      _espessuraController.text = widget.materialParaEditar!.espessura?.toString() ?? '';
      _gramaturaController.text = widget.materialParaEditar!.gramatura.toString();
      _observacaoController.text = widget.materialParaEditar!.observacao ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _espessuraController.dispose();
    _gramaturaController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  // ============================================
  // validação e envio para a API
  // ============================================
  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();
    final espessuraTexto = _espessuraController.text.trim();
    final observacao = _observacaoController.text.trim();

    final gramatura = double.tryParse(
      _gramaturaController.text.trim().replaceAll(',', '.'),
    );
    final espessura = espessuraTexto.isEmpty
        ? null
        : double.tryParse(espessuraTexto.replaceAll(',', '.'));

    if (nome.isEmpty) {
      _mostrarErro('Informe o nome do material.');
      return;
    }

    if (gramatura == null || gramatura <= 0) {
      _mostrarErro('Informe a gramatura (maior que zero).');
      return;
    }

    if (espessuraTexto.isNotEmpty && (espessura == null || espessura <= 0)) {
      _mostrarErro('A espessura deve ser um número maior que zero.');
      return;
    }

    final corpo = <String, dynamic>{
      'nome': nome,
      'gramatura': gramatura,
      'espessura': espessura,
      'observacao': observacao.isEmpty ? null : observacao,
    };

    setState(() => _salvando = true);

    try {
      final material = widget.materialParaEditar;

      if (material == null) {
        await ApiService.instance.post('/materiais', corpo);
      } else {
        await ApiService.instance.put('/materiais/${material.id}', corpo);
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _mostrarErro(e.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.materialParaEditar != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => ModalConfirmacao.mostrar(
            context,
            titulo: editando ? 'Descartar alterações?' : 'Descartar material?',
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
            TituloBanner(titulo: editando ? 'Editar material' : 'Novo material'),
            const SizedBox(height: 20),
            _buildFormulario(),
            const SizedBox(height: 24),
            _buildBotaoSalvar(editando),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ============================================
  // formulário
  // ============================================
  Widget _buildFormulario() {
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
          _buildLabel('Nome'),
          const SizedBox(height: 8),
          _buildCampo(
            controller: _nomeController,
            hint: 'Ex: Nylon 0.5mm',
          ),
          const SizedBox(height: 16),

          _buildLabel('Gramatura (g)'),
          const SizedBox(height: 8),
          _buildCampo(
            controller: _gramaturaController,
            hint: 'Ex: 120',
            teclado: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),

          _buildLabel('Espessura em mm (opcional)'),
          const SizedBox(height: 8),
          _buildCampo(
            controller: _espessuraController,
            hint: 'Ex: 0.5',
            teclado: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),

          _buildLabel('Observação (opcional)'),
          const SizedBox(height: 8),
          _buildCampo(
            controller: _observacaoController,
            hint: 'Ex: Material resistente para peças maiores...',
            maxLinhas: 3,
          ),
        ],
      ),
    );
  }

  // ============================================
  // botão salvar
  // ============================================
  Widget _buildBotaoSalvar(bool editando) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _salvando ? null : _salvar,
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
        child: _salvando
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              editando ? 'Salvar alterações' : 'Salvar material',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    TextInputType teclado = TextInputType.text,
  }) {
    return CustomPaint(
      painter: BordaTracejadaPainter(sombras: AppColors.sombra),
      child: TextField(
        controller: controller,
        maxLines: maxLinhas,
        keyboardType: teclado,
        style: TextStyle(fontSize: 14, color: AppColors.green),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: AppColors.green.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}