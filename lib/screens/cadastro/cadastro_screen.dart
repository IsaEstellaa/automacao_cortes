import 'package:flutter/material.dart';
import '../../core/widgets/painters.dart';
import '../../core/constants/app_colors.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => CadastronScreenState();
}

class CadastronScreenState extends State<CadastroScreen> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  // controla se a senha está visível ou não
  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // Card principal - cadastro
  // ============================================

  Widget _buildCard() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.bordaMarrom,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildTitulo(),
              const SizedBox(height: 50),
              _buildCampoNome(),
              const SizedBox(height: 40),
              _buildCampoEmail(),
              const SizedBox(height: 40),
              _buildCampoSenha(),
              const SizedBox(height: 40),
              _buildCampoConfirmarSenha(),
              const SizedBox(height: 50),
              _buildBotaoCadastrar(),
            ],
          ),
        ),

        Positioned(
          top: -27,
          child: _buildDetalheRosa(),
        ),
      ],
    );
  }

  // ============================================
  // fitinha rosa
  // ============================================
  Widget _buildDetalheRosa() {
    return Opacity(
      opacity: 0.70,
      child: Container(
        width: 105,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.fundoFitaRosa,
        ),
        child: ClipRRect(
          child: CustomPaint(
            painter: ListrasPainter(),
          ),
        ),
      ),
    );
  }

  // ============================================
  // titulo
  // ============================================
  Widget _buildTitulo() {
    return ShaderMask(
      shaderCallback: (bounds) => AppColors.gradienteTitulo.createShader(bounds),
      child: Text(
        'Crie sua conta',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.3,
        ),
      ),
    );
  }

  // ============================================
  // campo de nome
  // ============================================
  Widget _buildCampoNome() {
    return _campoBordaTracejada(
      controller: _nomeController,
      hint: 'Nome',
      teclado: TextInputType.text,
    );
  }

  // ============================================
  // campo de e-mail
  // ============================================
  Widget _buildCampoEmail() {
    return _campoBordaTracejada(
      controller: _emailController,
      hint: 'E-mail',
      teclado: TextInputType.emailAddress,
    );
  }

  // ============================================
  // campo de senha
  // ============================================
  Widget _buildCampoSenha() {
    return _campoBordaTracejada(
      controller: _senhaController,
      hint: 'Senha',
      obscure: !_senhaVisivel,
      sufixo: IconButton(
        icon: Icon(
          _senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.green.withOpacity(0.6),
          size: 20,
        ),
        onPressed: () {
          setState(() => _senhaVisivel = !_senhaVisivel);
        },
      ),
    );
  }

  // ============================================
  // campo de confirmar senha
  // ============================================
  Widget _buildCampoConfirmarSenha() {
    return _campoBordaTracejada(
      controller: _confirmarSenhaController,
      hint: 'Confirmar Senha',
      obscure: !_confirmarSenhaVisivel,
      sufixo: IconButton(
        icon: Icon(
          _confirmarSenhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.green.withOpacity(0.6),
          size: 20,
        ),
        onPressed: () {
          setState(() => _confirmarSenhaVisivel = !_confirmarSenhaVisivel);
        },
      ),
    );
  }

  // ============================================
  // campo input com borda tracejada
  // ============================================
  Widget _campoBordaTracejada({
    required TextEditingController controller,
    required String hint,
    TextInputType teclado = TextInputType.text,
    bool obscure = false,
    Widget? sufixo,
  }) {
    return CustomPaint(
      painter: BordaTracejadaPainter(sombras: AppColors.sombra),
      child: TextField(
        controller: controller,
        keyboardType: teclado,
        obscureText: obscure,
        style: TextStyle(color: AppColors.green, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Color.fromARGB(255, 180, 149, 121).withOpacity(0.7),
            fontSize: 14,
          ),
          suffixIcon: sufixo,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        ),
      ),
    );
  }

  // ============================================
  // botão entrar
  // ============================================
  Widget _buildBotaoCadastrar() {
    return ElevatedButton(
        onPressed: () {
          // TODO: chamar lógica de criação de conta
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonBrown,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(6),
            ),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Finalizar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
  }
}