import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/titulo_banner.dart';
import 'pecas_content.dart';

class PecaDetalhesScreen extends StatefulWidget {
  final Peca peca;

  const PecaDetalhesScreen({super.key, required this.peca});

  @override
  State<PecaDetalhesScreen> createState() => _PecaDetalhesScreenState();
}

class _PecaDetalhesScreenState extends State<PecaDetalhesScreen> {
  int _fotoAtual = 0;

  // cortes mockados — substituir pelo backend
  final List<Map<String, dynamic>> _cortes = [
    {'quantidade': 10, 'metragem': 500, 'situacao': 'A'},
    {'quantidade': 5, 'metragem': 200, 'situacao': 'A'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // aind nao sei se vou usar o AppHeader aqui, mas vou deixar comentado por enquanto
          // AppHeader(nomeUsuario: 'Isabella'), // TODO: nome real
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
    // se não tiver fotos, mostra placeholder
    if (widget.peca.fotos.isEmpty) {
      return Container(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 48, color: AppColors.green.withOpacity(0.4)),
            const SizedBox(height: 8),
            Text(
              'Nenhuma foto adicionada',
              style: TextStyle(fontSize: 13, color: AppColors.green.withOpacity(0.4)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // fotos
        SizedBox(
          height: 200,
          child: PageView.builder(
            itemCount: widget.peca.fotos.length,
            onPageChanged: (i) => setState(() => _fotoAtual = i),
            itemBuilder: (_, index) => ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                widget.peca.fotos[index],
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // indicador de página
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.peca.fotos.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _fotoAtual ? 16 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == _fotoAtual ? AppColors.green : AppColors.green.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
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
              // botão editar
              GestureDetector(
                onTap: () {
                  // TODO: navegar para tela de edição
                },
                child: Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.green.withOpacity(0.6)),
              ),
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

          _cortes.isEmpty
              ? Text(
                  'Nenhum corte cadastrado',
                  style: TextStyle(fontSize: 13, color: AppColors.green.withOpacity(0.5)),
                )
              : Column(
                  children: _cortes.map((corte) {
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
}