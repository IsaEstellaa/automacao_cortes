import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/titulo_banner.dart';
import '../../core/widgets/painters.dart';
import '../../core/widgets/modal_confirmacao.dart';

const _mascarasTelefone = ['(##) ####-####', '(##) #####-####'];
const _mascarasData = ['##/##/####'];

String _soDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

String _aplicarMascara(String digitos, List<String> mascaras) {
  final mascara = mascaras.firstWhere(
    (m) => '#'.allMatches(m).length >= digitos.length,
    orElse: () => mascaras.last,
  );

  final resultado = StringBuffer();
  var i = 0;

  for (final c in mascara.split('')) {
    if (i >= digitos.length) break;
    if (c == '#') {
      resultado.write(digitos[i]);
      i++;
    } else {
      resultado.write(c);
    }
  }

  return resultado.toString();
}

class _MascaraFormatter extends TextInputFormatter {
  final List<String> mascaras;
  const _MascaraFormatter(this.mascaras);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    final texto = _aplicarMascara(_soDigitos(novo.text), mascaras);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _dataController = TextEditingController();
  String? _sexo; // 'F', 'M', 'O' ou null (não informar)

  late final String _inicial;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();

    final usuario = ApiService.instance.usuario ?? {};

    _nomeController.text = (usuario['nome'] as String?) ?? '';
    _descricaoController.text = (usuario['descricao'] as String?) ?? '';

    final telefone = usuario['telefone'] as String?;
    if (telefone != null) {
      _telefoneController.text = _aplicarMascara(_soDigitos(telefone), _mascarasTelefone);
    }

    final nasc = usuario['data_nasc'] as String?;
    if (nasc != null && nasc.length >= 10) {
      _dataController.text =
          '${nasc.substring(8, 10)}/${nasc.substring(5, 7)}/${nasc.substring(0, 4)}';
    }

    _sexo = usuario['sexo'] as String?;
    _inicial = _fotografia();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _telefoneController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  String _fotografia() =>
      '${_nomeController.text}|${_descricaoController.text}|'
      '${_telefoneController.text}|${_dataController.text}|$_sexo';

  bool get _alterado => _fotografia() != _inicial;

  String? _dataParaIso(String texto) {
    if (texto.length != 10) return null;

    final dia = int.tryParse(texto.substring(0, 2));
    final mes = int.tryParse(texto.substring(3, 5));
    final ano = int.tryParse(texto.substring(6, 10));
    if (dia == null || mes == null || ano == null) return null;

    final data = DateTime(ano, mes, dia);
    final existe = data.year == ano && data.month == mes && data.day == dia;
    if (!existe || ano < 1900 || data.isAfter(DateTime.now())) return null;

    return '${ano.toString().padLeft(4, '0')}-'
        '${mes.toString().padLeft(2, '0')}-'
        '${dia.toString().padLeft(2, '0')}';
  }

  String? _validar() {
    if (_nomeController.text.trim().length < 2) {
      return 'Informe seu nome (mínimo de 2 letras).';
    }

    final telefone = _soDigitos(_telefoneController.text);
    if (telefone.isNotEmpty && telefone.length < 10) {
      return 'Telefone incompleto. Informe o DDD e o número.';
    }

    if (_dataController.text.isNotEmpty && _dataParaIso(_dataController.text) == null) {
      return 'Data de nascimento inválida.';
    }

    return null;
  }

  Future<void> _salvar() async {
    final erro = _validar();
    if (erro != null) {
      _mostrarAviso(erro);
      return;
    }

    setState(() => _salvando = true);

    try {
      final telefone = _soDigitos(_telefoneController.text);

      final resposta = await ApiService.instance.put('/usuario/perfil', {
        'nome': _nomeController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'telefone': telefone.isEmpty ? null : telefone,
        'data_nasc': _dataController.text.isEmpty ? null : _dataParaIso(_dataController.text),
        'sexo': _sexo,
      });

      ApiService.instance.atualizarUsuario(resposta as Map<String, dynamic>);

      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _mostrarAviso(e.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mostrarAviso(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
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
          onPressed: () {
            if (!_alterado) {
              Navigator.pop(context);
              return;
            }

            ModalConfirmacao.mostrar(
              context,
              titulo: 'Descartar alterações?',
              mensagem: 'As informações alteradas serão perdidas.',
              textoBotaoConfirmar: 'Descartar',
              aoConfirmar: () => Navigator.pop(context),
              corBotao: AppColors.buttonRed,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            const TituloBanner(titulo: 'Editar perfil'),
            const SizedBox(height: 20),
            _buildFormulario(),
            const SizedBox(height: 24),
            _buildBotaoSalvar(),
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
            hint: 'Seu nome',
            maxCaracteres: 100,
            capitalizacao: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          _buildLabel('Descrição (opcional)'),
          const SizedBox(height: 8),
          _buildCampo(
            controller: _descricaoController,
            hint: 'Conte um pouco sobre você...',
            maxLinhas: 4,
            maxCaracteres: 300,
            capitalizacao: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),

          _buildLabel('Telefone (opcional)'),
          const SizedBox(height: 8),
          _buildCampo(
            controller: _telefoneController,
            hint: '(11) 91234-5678',
            teclado: TextInputType.phone,
            formatadores: const [_MascaraFormatter(_mascarasTelefone)],
          ),
          const SizedBox(height: 16),

          _buildLabel('Data de nascimento (opcional)'),
          const SizedBox(height: 8),
          _buildCampo(
            controller: _dataController,
            hint: 'dd/mm/aaaa',
            teclado: TextInputType.number,
            formatadores: const [_MascaraFormatter(_mascarasData)],
          ),
          const SizedBox(height: 16),

          _buildLabel('Sexo (opcional)'),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildOpcaoSexo('F', 'Feminino'),
              const SizedBox(width: 8),
              _buildOpcaoSexo('M', 'Masculino'),
              const SizedBox(width: 8),
              _buildOpcaoSexo('O', 'Outro'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOpcaoSexo(String codigo, String texto) {
    final selecionado = _sexo == codigo;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sexo = selecionado ? null : codigo),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selecionado ? AppColors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.green.withOpacity(selecionado ? 1 : 0.4),
            ),
          ),
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selecionado ? Colors.white : AppColors.green,
            ),
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
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                'Salvar alterações',
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
    int? maxCaracteres,
    TextInputType teclado = TextInputType.text,
    TextCapitalization capitalizacao = TextCapitalization.none,
    List<TextInputFormatter> formatadores = const [],
  }) {
    return CustomPaint(
      painter: BordaTracejadaPainter(sombras: AppColors.sombra),
      child: TextField(
        controller: controller,
        maxLines: maxLinhas,
        maxLength: maxCaracteres,
        keyboardType: teclado,
        textCapitalization: capitalizacao,
        inputFormatters: formatadores,
        style: TextStyle(fontSize: 14, color: AppColors.green),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: AppColors.green.withOpacity(0.4)),
          border: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}