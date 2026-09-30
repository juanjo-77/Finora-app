import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const baseUrl = 'http://localhost:5009/api';
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

  static Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: await _headers());
    return _procesar(res);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _procesar(res);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _procesar(res);
  }

  static Future<void> delete(String path) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'), headers: await _headers());
    if (res.statusCode >= 400) throw Exception('Error al eliminar');
  }

  static dynamic _procesar(http.Response res) {
    if (res.statusCode >= 400) {
      final cuerpo = res.body.isNotEmpty ? jsonDecode(res.body) : null;
      throw Exception(cuerpo?['mensaje'] ?? 'Error de red (${res.statusCode})');
    }
    return res.body.isNotEmpty ? jsonDecode(res.body) : null;
  }
}