import 'package:flutter/material.dart';
import '../../core/widgets/painters.dart';
import '../../core/constants/app_colors.dart';
import '../cadastro/cadastro_screen.dart';
import '../../core/widgets/fita_decorativa.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  // controla se a senha está visível ou não
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
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
  // Card principal - login
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
              const SizedBox(height: 52),
              _buildCampoEmail(),
              const SizedBox(height: 40),
              _buildCampoSenha(),
              const SizedBox(height: 8),
              _buildEsqueceuSenha(),
              const SizedBox(height: 26),
              _buildBotaoEntrar(),
              const SizedBox(height: 16),
              _buildLinkCadastro(),
            ],
          ),
        ),

        Positioned(
          top: -27,
          child: FitaDecorativa(
            corFundo: AppColors.fundoFitaVerde,
            corListras: AppColors.listrasFitaVerde,
          ),
        ),
      ],
    );
  }

  // ============================================
  // titulo
  // ============================================
  Widget _buildTitulo() {
    return ShaderMask(
      shaderCallback: (bounds) => AppColors.gradienteTitulo.createShader(bounds),
      child: Text(
        'Entre com sua conta',
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
  // "esqueceu sua senha?"
  // ============================================
  Widget _buildEsqueceuSenha() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // TODO: navegar para tela de recuperação de senha
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Esqueceu sua senha?',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textoSutil,
            fontWeight: FontWeight.w400,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }

  // ============================================
  // botão entrar
  // ============================================
  Widget _buildBotaoEntrar() {
    return ElevatedButton(
        onPressed: () {
          // TODO: chamar lógica de autenticação
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
          'Entrar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
  }

  // ============================================
  // link de cadastro
  // ============================================
  Widget _buildLinkCadastro() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CadastroScreen(),
          ),
        );
      },
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: AppColors.textoSutil),
          children: [
            const TextSpan(text: 'Não tem uma conta?\n'),
            TextSpan(
              text: 'Cadastre-se clicando aqui!',
              style: const TextStyle(
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}