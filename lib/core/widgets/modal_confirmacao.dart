import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import './fita_decorativa.dart';

class ModalConfirmacao {
  static void mostrar(
    BuildContext context, {
    required String titulo,
    required String mensagem,
    required String textoBotaoConfirmar,
    required VoidCallback aoConfirmar,
    Color corBotao = Colors.red,
  }) {
    showDialog(
      context: context,
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
              padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    mensagem,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: AppColors.textoPreto, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // cancelar
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.card,
                            foregroundColor: AppColors.green,
                            elevation: 0,
                            side: BorderSide(color: AppColors.bordaMarrom),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(30),
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // confirmar
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            aoConfirmar();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corBotao,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(30),
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                          ),
                          child: Text(textoBotaoConfirmar),
                        ),
                      ),
                    ],
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
}