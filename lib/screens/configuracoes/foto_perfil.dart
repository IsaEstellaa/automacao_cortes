import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';

class FotoPerfil extends StatefulWidget {
  final VoidCallback? aoAtualizar;

  const FotoPerfil({super.key, this.aoAtualizar});

  @override
  State<FotoPerfil> createState() => _FotoPerfilState();
}

class _FotoPerfilState extends State<FotoPerfil> {
  final _picker = ImagePicker();
  bool _enviando = false;

  String? get _urlFoto {
    final url = ApiService.instance.usuario?['url_foto'];
    return (url is String && url.isNotEmpty) ? url : null;
  }

  Future<void> _abrirOpcoes() async {
    if (_enviando) return;

    final escolha = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: AppColors.green),
              title: Text('Tirar foto', style: TextStyle(color: AppColors.textoPreto)),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: AppColors.green),
              title: Text('Escolher da galeria', style: TextStyle(color: AppColors.textoPreto)),
              onTap: () => Navigator.pop(context, 'galeria'),
            ),
            if (_urlFoto != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Color.fromARGB(255, 117, 17, 2)),
                title: Text('Remover foto', style: TextStyle(color: AppColors.textoPreto)),
                onTap: () => Navigator.pop(context, 'remover'),
              ),
          ],
        ),
      ),
    );

    if (escolha == 'camera') await _enviar(ImageSource.camera);
    if (escolha == 'galeria') await _enviar(ImageSource.gallery);
    if (escolha == 'remover') await _remover();
  }

  Future<void> _enviar(ImageSource origem) async {
    XFile? arquivo;

    try {
      // já reduz a imagem antes de enviar
      arquivo = await _picker.pickImage(
        source: origem,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (_) {
      _mostrarAviso('Não foi possível abrir a câmera ou a galeria.');
      return;
    }

    if (arquivo == null) return;

    setState(() => _enviando = true);

    try {
      final resposta = await ApiService.instance
          .enviarArquivo('/usuario/perfil/foto', 'foto', arquivo.path);

      ApiService.instance.atualizarUsuario(resposta as Map<String, dynamic>);
      widget.aoAtualizar?.call();
    } on ApiException catch (e) {
      _mostrarAviso(e.mensagem);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _remover() async {
    setState(() => _enviando = true);

    try {
      final resposta = await ApiService.instance.delete('/usuario/perfil/foto');

      ApiService.instance.atualizarUsuario(resposta as Map<String, dynamic>);
      widget.aoAtualizar?.call();
    } on ApiException catch (e) {
      _mostrarAviso(e.mensagem);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mostrarAviso(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Widget _placeholder() {
    return Icon(
      Icons.person_outline,
      size: 48,
      color: AppColors.green.withOpacity(0.4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = _urlFoto;

    return GestureDetector(
      onTap: _abrirOpcoes,
      child: SizedBox(
        width: 100,
        height: 100,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(10),
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(40),
              ),
              child: Container(
                width: 100,
                height: 100,
                color: AppColors.background,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (url == null)
                      Center(child: _placeholder())
                    else
                      Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(child: _placeholder()),
                        loadingBuilder: (_, filho, progresso) =>
                            progresso == null ? filho : Center(child: _placeholder()),
                      ),

                    // carregando
                    if (_enviando)
                      Container(
                        color: Colors.black.withOpacity(0.35),
                        child: const Center(
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.card, width: 2),
                ),
                child: const Icon(Icons.photo_camera, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}