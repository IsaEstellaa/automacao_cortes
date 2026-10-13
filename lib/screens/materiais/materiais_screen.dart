import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/modal_confirmacao.dart';
import 'novo_material_screen.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/estado_erro.dart';

// ============================================
// modelo de material (virá do backend)
// ============================================

double? _paraDouble(dynamic valor) =>
    valor == null ? null : double.tryParse(valor.toString());

class MaterialFio {
  final int id;
  final String nome;
  final double? espessura;
  final double gramatura;
  final String? observacao;
  final String? situacao;

  MaterialFio({
    required this.id,
    required this.nome,
    this.espessura,
    required this.gramatura,
    this.observacao,
    this.situacao,
  });

  factory MaterialFio.fromJson(Map<String, dynamic> json) {
    return MaterialFio(
      id: json['id_material'] as int,
      nome: json['nome'] as String,
      gramatura: _paraDouble(json['gramatura']) ?? 0,
      espessura: _paraDouble(json['espessura']),
      observacao: json['observacao'] as String?,
      situacao: json['status'] as String?,
    );
  }
}

// ============================================
// tela de materiais
// ============================================
class MateriaisScreen extends StatefulWidget {
  const MateriaisScreen({super.key});

  @override
  State<MateriaisScreen> createState() => _MateriaisScreenState();
}

class _MateriaisScreenState extends State<MateriaisScreen> {

  List<MaterialFio> _materiais = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // ============================================
  // busca os materiais na API
  // ============================================
  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resposta = await ApiService.instance.get('/materiais') as List;
      final lista = resposta
          .map((j) => MaterialFio.fromJson(j as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() => _materiais = lista);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrirFormulario([MaterialFio? material]) async {
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NovoMaterialScreen(materialParaEditar: material),
      ),
    );

    if (salvou == true) _carregar();
  }

  Future<void> _excluir(MaterialFio material) async {
    try {
      await ApiService.instance.delete('/materiais/${material.id}');

      if (!mounted) return;
      setState(() => _materiais.removeWhere((m) => m.id == material.id));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensagem)),
      );
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
        title: const Text(
          'Materiais',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          // botão de adicionar material no topo
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 24),
            onPressed: () => _abrirFormulario(),
          ),
        ],
      ),
      body: _carregando
        ? Center(child: CircularProgressIndicator(color: AppColors.green))
        : _erro != null
            ? EstadoErro(mensagem: _erro!, aoTentarNovamente: _carregar)
            : _materiais.isEmpty
                ? _buildVazio()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    itemCount: _materiais.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) => _buildCardMaterial(_materiais[index], index),
                  ),
    );
  }

  // ============================================
  // card de material
  // ============================================
  Widget _buildCardMaterial(MaterialFio material, int index) {
    return Container(
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
          Row(
            children: [
              // nome do material
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) => AppColors.gradienteTitulo.createShader(bounds),
                  child: Text(
                    material.nome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // botão editar
              GestureDetector(
                onTap: () => _abrirFormulario(material),
                child: Icon(Icons.edit_outlined, size: 18, color: AppColors.green.withOpacity(0.6)),
              ),
              const SizedBox(width: 12),

              // botão excluir
              GestureDetector(
                onTap: () => ModalConfirmacao.mostrar(
                  context,
                  titulo: 'Excluir material',
                  mensagem: 'Deseja excluir "${material.nome}"?',
                  textoBotaoConfirmar: 'Excluir',
                  aoConfirmar: () => _excluir(material),
                  corBotao: AppColors.buttonRed,
                ),
                child: Icon(Icons.delete_outline, size: 18, color: AppColors.buttonRed.withOpacity(0.7)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // informações do material
          _buildInfo('Gramatura', '${material.gramatura}g'),
          if (material.espessura != null)
            _buildInfo('Espessura', '${material.espessura}mm'),
          if (material.observacao != null && material.observacao!.isNotEmpty)
            _buildInfo('Observação', material.observacao!),
        ],
      ),
    );
  }

  Widget _buildInfo(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green),
          ),
          Text(
            valor,
            style: TextStyle(fontSize: 13, color: AppColors.textoPreto),
          ),
        ],
      ),
    );
  }

  // ============================================
  // estado vazio
  // ============================================
  Widget _buildVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 64, color: AppColors.green.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            'Nenhum material cadastrado',
            style: TextStyle(fontSize: 15, color: AppColors.green.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _abrirFormulario(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar material'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
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
        ],
      ),
    );
  }
}