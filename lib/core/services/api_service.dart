import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String mensagem;
  final int? statusCode;

  ApiException(this.mensagem, [this.statusCode]);

  @override
  String toString() => mensagem;
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String baseUrl = 'http://10.0.2.2:3000';
  static const Duration _timeout = Duration(seconds: 20);

  static const _storage = FlutterSecureStorage();
  static const _chaveToken = 'token';

  String? _token;
  Map<String, dynamic>? usuario;

  bool get logado => _token != null;

  // ============================================
  // autenticação
  // ============================================
  Future<void> login(String email, String senha) async {
    final resposta = await post('/usuario/login', {
      'email': email,
      'senha': senha,
    });

    _token = resposta['token'] as String;
    usuario = resposta['usuario'] as Map<String, dynamic>;

    await _storage.write(key: _chaveToken, value: _token);
  }

  Future<void> logout() async {
    _token = null;
    usuario = null;
    await _storage.delete(key: _chaveToken);
  }

  // Retorna true se já existe uma sessão válida.
  Future<bool> restaurarSessao() async {
    try {
      final token = await _storage.read(key: _chaveToken);

      if (token == null || _tokenExpirado(token)) {
        await logout();
        return false;
      }

      _token = token;

      final perfil = await get('/usuario/perfil');
      usuario = perfil as Map<String, dynamic>;
      return true;

    } catch (_) {
      // 401: o _enviar já apagou o token guardado.
      // Sem conexão: mantém o token guardado e cai no login desta vez.
      _token = null;
      usuario = null;
      return false;
    }
  }

  bool _tokenExpirado(String token) {
    try {
      final partes = token.split('.');
      if (partes.length != 3) return true;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))),
      );

      final exp = payload['exp'];
      if (exp is! int) return true;

      final agora = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return agora >= exp;
    } catch (_) {
      return true;
    }
  }

  // ============================================
  // métodos genéricos (usados pelas telas)
  // ============================================
  Future<dynamic> get(String caminho) => _enviar('GET', caminho);

  Future<dynamic> post(String caminho, [Map<String, dynamic>? corpo]) =>
      _enviar('POST', caminho, corpo);

  Future<dynamic> put(String caminho, [Map<String, dynamic>? corpo]) =>
      _enviar('PUT', caminho, corpo);

  Future<dynamic> patch(String caminho, [Map<String, dynamic>? corpo]) =>
      _enviar('PATCH', caminho, corpo);

  Future<dynamic> delete(String caminho) => _enviar('DELETE', caminho);

  // ============================================
  // envio e tratamento de erros
  // ============================================
  Future<dynamic> _enviar(
    String metodo,
    String caminho, [
    Map<String, dynamic>? corpo,
  ]) async {
    final requisicao = http.Request(metodo, Uri.parse('$baseUrl$caminho'));

    requisicao.headers['Content-Type'] = 'application/json';
    if (_token != null) {
      requisicao.headers['Authorization'] = 'Bearer $_token';
    }
    if (corpo != null) {
      requisicao.body = jsonEncode(corpo);
    }

    // TODO: Substituir as mensagens de erro
    try {
      final stream = await requisicao.send().timeout(_timeout);
      final resposta = await http.Response.fromStream(stream);

      final dados =
          resposta.body.isEmpty ? null : jsonDecode(resposta.body);

      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        return dados;
      }

      if (resposta.statusCode == 401 && _token != null) {
        await logout();
      }

      final mensagem = (dados is Map && dados['erro'] != null)
          ? dados['erro'].toString()
          : 'Erro inesperado (${resposta.statusCode})';

      throw ApiException(mensagem, resposta.statusCode);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('O servidor demorou para responder. Tente novamente.');
    } on SocketException {
      throw ApiException('Sem conexão com o servidor. Verifique se o backend está rodando.');
    } on http.ClientException {
      throw ApiException('Sem conexão com o servidor. Verifique se o backend está rodando.');
    } on FormatException {
      throw ApiException('Resposta inválida do servidor.');
    }
  }
}