import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/modal_confirmacao.dart';
import 'novo_material_screen.dart';

// ============================================
// modelo de material (virá do backend)
// ============================================
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

  // materiais mockados — substituir pelo backend --> NAO ESQUECER
  final List<MaterialFio> _materiais = [
    MaterialFio(id: 1, nome: 'Nylon 0.5mm', espessura: 0.5, gramatura: 120, observacao: 'Material resistente para peças maiores.', situacao: 'A'),
    MaterialFio(id: 2, nome: 'Algodão', gramatura: 80, observacao: null, situacao: 'A'),
    MaterialFio(id: 3, nome: 'Poliéster 1mm', espessura: 1.0, gramatura: 150, observacao: 'Boa tensão para cortes longos.', situacao: 'A'),
  ];

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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NovoMaterialScreen()),
            ),
          ),
        ],
      ),
      body: _materiais.isEmpty
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NovoMaterialScreen(materialParaEditar: material),
                  ),
                ),
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
                  aoConfirmar: () {
                    setState(() => _materiais.removeAt(index));
                  },
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NovoMaterialScreen()),
            ),
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