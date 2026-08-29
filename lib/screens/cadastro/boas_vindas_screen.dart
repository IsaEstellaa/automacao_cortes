import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/fita_decorativa.dart';
import '../home/home_screen.dart';

class BoasVindasScreen extends StatefulWidget {
  const BoasVindasScreen({super.key});

  @override
  State<BoasVindasScreen> createState() => _BoasVindasScreenState();
}

class _BoasVindasScreenState extends State<BoasVindasScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mostrarBoasVindas();
    });
  }

  void _mostrarBoasVindas() {
    showDialog(
      context: context,
      barrierDismissible: false, // usuário não pode fechar clicando fora
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.card,
        clipBehavior: Clip.none,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 40, 30, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => AppColors.gradienteTitulo.createShader(bounds),
                      child: Center(
                        child: Text(
                          'Seja bem-vindo(a)',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Estamos felizes em ter você por aqui!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textoMarrom,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Este aplicativo foi pensado e criado para tornar o processo de corte mais simples, rápido e automatizado.',
                      style: TextStyle(fontSize: 15, color: AppColors.textoPreto),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Agora você já pode:',
                      style: TextStyle(fontSize: 15, color: AppColors.textoPreto),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Column(
                      children: [
                        _itensBoasVindas('configurar materiais'),
                        _itensBoasVindas('programar cortes'),
                        _itensBoasVindas('monitorar a máquina em tempo real'),
                        _itensBoasVindas('automatizar processos de corte'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Vamos começar?',
                      style: TextStyle(fontSize: 16, color: AppColors.textoMarrom),
                    ),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () {
                      // fecha o modal e vai para a home
                      // pushAndRemoveUntil limpa a pilha de navegação
                      // o usuário não consegue voltar pro cadastro apertando voltar
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
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
                      'Continuar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              top: -25,
              child: FitaDecorativa(
                corFundo: AppColors.fundoFitaRosa,
                corListras: AppColors.listrasFitaRosa,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
    );
  }
}

Widget _itensBoasVindas(String texto) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text('•  ', style: TextStyle(color: AppColors.textoPreto, fontSize: 15)),
        Text(texto, style: TextStyle(color: AppColors.textoPreto, fontSize: 15)),
      ],
    ),
  );
}