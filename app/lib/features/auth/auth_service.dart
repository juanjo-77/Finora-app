import '../../core/network/api_client.dart';

class AuthService {
  static Future<void> login(String email, String password) async {
    final data = await ApiClient.post('/auth/login', {
      'email': email,
      'password': password,
    }, auth: false);
    await ApiClient.guardarToken(data['token']);
    await ApiClient.guardarEmail(data['email']);
  }

  static Future<void> registrar(String email, String password) async {
    final data = await ApiClient.post('/auth/register', {
      'email': email,
      'password': password,
    }, auth: false);
    await ApiClient.guardarToken(data['token']);
    await ApiClient.guardarEmail(data['email']);
  }
}