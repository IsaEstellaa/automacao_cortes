import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/fita_decorativa.dart';
import 'automacao_content.dart';

// ============================================
// modelo de log de fio (virá do backend)
// ============================================
class LogFio {
  final int idFio;
  final String mensagem;
  final DateTime dataHora;

  LogFio({
    required this.idFio,
    required this.mensagem,
    required this.dataHora,
  });
}

// ============================================
// modal de detalhes do corte
// ============================================
class ModalDetalhesCorte {
  static void mostrar(
    BuildContext context, {
    required ExecucaoCorte execucao,
    required List<LogFio> logs,
    required VoidCallback aoRetentar,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => AppColors.gradienteTitulo.createShader(bounds),
                      child: Text(
                        'Notificações sobre o corte',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // lista de todos os fios
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 300,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: execucao.fios.length,
                      itemBuilder: (_, index) {
                        final fio = execucao.fios[index];
                        final tentativa = index + 1;

                        // busca o log desse fio
                        final log = logs.where((l) => l.idFio == fio.id).isNotEmpty
                            ? logs.firstWhere((l) => l.idFio == fio.id)
                            : null;

                        // mensagem baseada no status
                        final mensagem = fio.status == 'C'
                            ? 'Corte realizado com sucesso'
                            : fio.status == 'E'
                                ? (log?.mensagem ?? 'Erro no corte')
                                : 'Aguardando corte';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ícone do status
                              Icon(
                                fio.status == 'C'
                                    ? Icons.check_circle_outline
                                    : fio.status == 'E'
                                        ? Icons.error_outline
                                        : Icons.radio_button_unchecked,
                                size: 16,
                                color: fio.status == 'C'
                                    ? AppColors.green
                                    : fio.status == 'E'
                                        ? Color.fromARGB(255, 117, 17, 2).withOpacity(0.7)
                                        : AppColors.textoPreto.withOpacity(0.4),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(fontSize: 14, color: AppColors.textoPreto),
                                    children: [
                                      TextSpan(
                                        text: 'Tentativa de corte [$tentativa/${execucao.quantidade}]\n',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.green,
                                        ),
                                      ),
                                      TextSpan(text: '- $mensagem'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // botão retentar
                  // só aparece se tiver fio com erro!!
                  if (execucao.fios.any((f) => f.status == 'E'))
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          aoRetentar();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
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
                        child: const Text(
                          'Retentar fios com erro',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  // botão entendido
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonBrown,
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
                      child: const Text(
                        'Entendido',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              top: -25,
              child: FitaDecorativa(
                corFundo: AppColors.fundoFitaVerde,
                corListras: AppColors.listrasFitaVerde,
              ),
            ),
          ],
        ),
      ),
    );
  }
}