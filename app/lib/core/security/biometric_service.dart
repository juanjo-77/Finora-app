import 'package:local_auth/local_auth.dart';

/// Envuelve local_auth con manejo de errores: en plataformas sin soporte
/// (como Flutter web) simplemente reporta "no disponible" en vez de fallar.
class BiometricService {
  static final _auth = LocalAuthentication();

  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final soportado = await _auth.isDeviceSupported();
      return canCheck && soportado;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Confirma tu identidad para entrar a Finora',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}