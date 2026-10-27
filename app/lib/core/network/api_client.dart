import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../app_config.dart';

class ApiClient {
  static const baseUrl = AppConfig.apiBaseUrl;
  static final _storage = const FlutterSecureStorage();

  static Future<void> guardarToken(String token) =>
      _storage.write(key: 'token', value: token);

  static Future<String?> obtenerToken() => _storage.read(key: 'token');

  static Future<void> guardarEmail(String email) =>
      _storage.write(key: 'email', value: email);

  static Future<String?> obtenerEmail() => _storage.read(key: 'email');

  static Future<void> cerrarSesion() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'email');
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await obtenerToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // El servidor gratuito puede tardar en despertar, por eso el margen amplio.
  static const _limite = Duration(seconds: 45);

  static Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: await _headers()).timeout(_limite);
    return _procesar(res);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final res = await http
        .post(Uri.parse('$baseUrl$path'), headers: await _headers(auth: auth), body: jsonEncode(body))
        .timeout(_limite);
    return _procesar(res, auth: auth);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http
        .put(Uri.parse('$baseUrl$path'), headers: await _headers(), body: jsonEncode(body))
        .timeout(_limite);
    return _procesar(res);
  }

  static Future<void> delete(String path) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'), headers: await _headers()).timeout(_limite);
    if (res.statusCode >= 400) throw Exception('No se pudo eliminar. Intenta de nuevo.');
  }

  static dynamic _decodificar(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  static dynamic _procesar(http.Response res, {bool auth = true}) {
    if (res.statusCode >= 400) {
      final cuerpo = _decodificar(res.body);
      final mensaje = cuerpo is Map ? cuerpo['mensaje'] : null;
      if (res.statusCode == 401 && auth) throw Exception('Tu sesión expiró. Vuelve a iniciar sesión.');
      throw Exception(mensaje ?? 'Error de red (${res.statusCode})');
    }
    return _decodificar(res.body);
  }
}