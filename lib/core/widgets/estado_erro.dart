import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class EstadoErro extends StatelessWidget {
  final String mensagem;
  final VoidCallback aoTentarNovamente;

  const EstadoErro({
    super.key,
    required this.mensagem,
    required this.aoTentarNovamente,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 64, color: AppColors.green.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.green.withOpacity(0.6)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: aoTentarNovamente,
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
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}