import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/botao_novo_corte.dart';
import 'peca_card.dart';
import 'peca_detalhes_screen.dart';
import 'nova_peca_screen.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/estado_erro.dart';

// ============================================
// modelo de peça
// ============================================

num _paraNumero(dynamic valor) {
  final n = num.tryParse(valor.toString()) ?? 0;
  return n == n.truncate() ? n.truncate() : n;
}

class Peca {
  final int id;
  final String nome;
  final String descricao;
  final List<String> fotos; // URLs das fotos
  bool favorito;
  final List<Map<String, dynamic>> cortes;

  Peca({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.fotos,
    this.favorito = false,
    this.cortes = const [],
  });

  factory Peca.fromJson(Map<String, dynamic> json) {
    final cortes = ((json['cortes'] as List?) ?? [])
      .map<Map<String, dynamic>>((c) => {
            'id_corte': c['id_corte'],
            'quantidade': _paraNumero(c['quantidade']),
            'metragem': _paraNumero(c['metragem']),
            'situacao': 'A',
          })
      .toList();

    return Peca(
      id: json['id_peca'] as int,
      nome: json['nome'] as String,
      descricao: (json['descricao'] as String?) ?? '',
      fotos: <String>[], // TODO: upload de fotos ainda não existe
      cortes: cortes,
    );
  }
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

  List<Peca> _pecas = [];
  bool _carregando = true;
  String? _erro;

  //TODO: favoritos ainda não são salvos no backend: ficam guardados só enquanto o app está aberto
  final Set<int> _favoritosIds = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // ============================================
  // busca as peças na API
  // ============================================
  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resposta = await ApiService.instance.get('/pecas') as List;
      final lista = resposta.map((j) {
        final peca = Peca.fromJson(j as Map<String, dynamic>);
        peca.favorito = _favoritosIds.contains(peca.id);
        return peca;
      }).toList();

      if (!mounted) return;
      setState(() => _pecas = lista);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrirNovaPeca() async {
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NovaPecaScreen()),
    );

    if (salvou == true) _carregar();
  }

  Future<void> _abrirDetalhes(Peca peca) async {
    final mudou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PecaDetalhesScreen(peca: peca)),
    );

    if (mudou == true) _carregar();
  }

  void _alternarFavorito(Peca peca) {
    setState(() {
      peca.favorito = !peca.favorito;
      if (peca.favorito) {
        _favoritosIds.add(peca.id);
      } else {
        _favoritosIds.remove(peca.id);
      }
    });
  }

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
                aoTocar: _abrirNovaPeca,
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
          child: _carregando
              ? Center(child: CircularProgressIndicator(color: AppColors.green))
              : _erro != null
                  ? EstadoErro(mensagem: _erro!, aoTentarNovamente: _carregar)
                  : _pecasFiltradas.isEmpty
                      ? _buildVazio()
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85, // altura dos cards
                          ),
                          itemCount: _pecasFiltradas.length,
                          itemBuilder: (_, index) {
                            final peca = _pecasFiltradas[index];
                            return PecaCard(
                              peca: peca,
                              aoTocar: () => _abrirDetalhes(peca),
                              aoFavoritar: () => _alternarFavorito(peca),
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