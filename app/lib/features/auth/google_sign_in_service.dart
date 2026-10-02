import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/network/api_client.dart';

/// Reemplaza con el mismo Client ID que usaste en el meta tag y en appsettings.json
const String kGoogleClientId = '723765714016-9s6i2o4mcit3cv5pv063nfqct6sv1tq9.apps.googleusercontent.com';

class GoogleSignInService {
  static bool _inicializado = false;
  static final _controladorExito = StreamController<void>.broadcast();

  /// Emite un evento cada vez que el login con Google termina bien
  /// (token ya guardado, listo para navegar al dashboard).
  static Stream<void> get alIniciarSesion => _controladorExito.stream;

  static Future<void> inicializar() async {
    if (_inicializado) return;
    _inicializado = true;

    await GoogleSignIn.instance.initialize(clientId: kGoogleClientId);

    GoogleSignIn.instance.authenticationEvents.listen((evento) async {
      if (evento is GoogleSignInAuthenticationEventSignIn) {
        final auth = evento.user.authentication;
        final idToken = auth.idToken;
        if (idToken == null) return;
        await _enviarAlBackend(idToken);
      }
    });
  }

  static Future<void> _enviarAlBackend(String idToken) async {
    final data = await ApiClient.post('/auth/google', {'idToken': idToken}, auth: false);
    await ApiClient.guardarToken(data['token']);
    await ApiClient.guardarEmail(data['email']);
    _controladorExito.add(null);
  }

  /// Solo para plataformas nativas (Android/iOS/desktop) donde SÍ se puede
  /// disparar el flujo mediante un botón propio.
  static Future<void> autenticarNativo() async {
    if (GoogleSignIn.instance.supportsAuthenticate()) {
      await GoogleSignIn.instance.authenticate();
    }
  }
}