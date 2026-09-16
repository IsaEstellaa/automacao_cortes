import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/botao_novo_corte.dart';
import 'peca_card.dart';
import 'peca_detalhes_screen.dart';

// ============================================
// modelo de peça (vai vir do backend)
// ============================================
class Peca {
  final int id;
  final String nome;
  final String descricao;
  final List<String> fotos; // URLs das fotos
  bool favorito;

  Peca({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.fotos,
    this.favorito = false,
  });
}

// ============================================
// tela de peças
// ============================================
class PecasContent extends StatefulWidget {
  const PecasContent({super.key});

  @override
  State<PecasContent> createState() => _PecasContentState();
}

class _PecasContentState extends State<PecasContent> {
  final _buscaController = TextEditingController();
  bool _mostrarFavoritos = false;
  String _termoBusca = '';

  // dados mockados
  final List<Peca> _pecas = [
    Peca(id: 1, nome: 'Bolsa', descricao: 'Bolsa de macramê com alças longas.', fotos: [], favorito: true),
    Peca(id: 2, nome: 'Painel', descricao: 'Painel decorativo para sala.', fotos: []),
    Peca(id: 3, nome: 'Suporte', descricao: 'Suporte para vasos.', fotos: []),
  ];

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  // filtra as peças conforme busca e favoritos
  List<Peca> get _pecasFiltradas {
    return _pecas.where((p) {
      final buscaOk = p.nome.toLowerCase().contains(_termoBusca.toLowerCase());
      final favoritoOk = !_mostrarFavoritos || p.favorito;
      return buscaOk && favoritoOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: [

              BotaoNovoCorte(
                texto: 'Nova peça',
                aoTocar: () {
                  // TODO: navegar para tela de nova peça
                },
              ),
              const SizedBox(height: 16),

              // barra de busca + botãozinho de favoritos
              Row(
                children: [
                  Expanded(child: _buildBarraBusca()),
                  const SizedBox(width: 10),
                  _buildBotaoFavoritos(),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // grid das peças
        Expanded(
          child: _pecasFiltradas.isEmpty
              ? _buildVazio()
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,  // altura dos cards
                  ),
                  itemCount: _pecasFiltradas.length,
                  itemBuilder: (_, index) {
                    final peca = _pecasFiltradas[index];
                    return PecaCard(
                      peca: peca,
                      aoTocar: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PecaDetalhesScreen(peca: peca),
                        ),
                      ),
                      aoFavoritar: () => setState(() => peca.favorito = !peca.favorito),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ============================================
  // barra de busca
  // ============================================
  Widget _buildBarraBusca() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.bordaMarrom, width: 1),
        boxShadow: AppColors.sombra,
      ),
      child: TextField(
        controller: _buscaController,
        onChanged: (v) => setState(() => _termoBusca = v),
        style: TextStyle(fontSize: 14, color: AppColors.green),
        decoration: InputDecoration(
          hintText: 'Buscar peça...',
          hintStyle: TextStyle(color: AppColors.green.withOpacity(0.5), fontSize: 14),
          prefixIcon: Icon(Icons.search, color: AppColors.green.withOpacity(0.8), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ============================================
  // botão de filtro favoritos
  // ============================================
  Widget _buildBotaoFavoritos() {
    return GestureDetector(
      onTap: () => setState(() => _mostrarFavoritos = !_mostrarFavoritos),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: _mostrarFavoritos ? AppColors.green : AppColors.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.bordaMarrom, width: 1),
          boxShadow: AppColors.sombra,
        ),
        child: Icon(
          _mostrarFavoritos ? Icons.star : Icons.star_border,
          color: _mostrarFavoritos ? Colors.white : AppColors.green,
          size: 22,
        ),
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
          Icon(Icons.checkroom_outlined, size: 64, color: AppColors.green.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            _mostrarFavoritos ? 'Nenhuma peça favoritada' : 'Nenhuma peça encontrada',
            style: TextStyle(fontSize: 15, color: AppColors.green.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}