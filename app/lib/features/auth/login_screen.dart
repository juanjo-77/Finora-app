import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../dashboard/dashboard_screen.dart';
import 'auth_service.dart';
import 'google_button.dart';
import 'google_sign_in_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _cargando = false;
  bool _esRegistro = false;
  String? _error;
  StreamSubscription? _googleSub;

  @override
  void initState() {
    super.initState();
    GoogleSignInService.inicializar();
    _googleSub = GoogleSignInService.alIniciarSesion.listen((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    });
  }

  @override
  void dispose() {
    _googleSub?.cancel();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      if (_esRegistro) {
        await AuthService.registrar(_emailCtrl.text.trim(), _passCtrl.text);
      } else {
        await AuthService.login(_emailCtrl.text.trim(), _passCtrl.text);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FINORA', style: AppText.eyebrow.copyWith(color: AppColors.fog)),
                const SizedBox(height: 12),
                Text(_esRegistro ? 'Crea tu cuenta' : 'Bienvenido de vuelta',
                    style: AppText.heading.copyWith(fontSize: 40)),
                const SizedBox(height: 6),
                Text(
                  _esRegistro ? 'Toma el control de tu dinero.' : 'Entra para ver tu disponible real.',
                  style: AppText.body.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailCtrl,
                  style: AppText.body.copyWith(color: AppColors.bone, fontSize: 15, height: 1),
                  decoration: const InputDecoration(hintText: 'Correo electrónico'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  style: AppText.body.copyWith(color: AppColors.bone, fontSize: 15, height: 1),
                  decoration: const InputDecoration(hintText: 'Contraseña'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                    ),
                    child: Text(_error!, style: AppText.caption.copyWith(color: Colors.redAccent)),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _enviar,
                    child: Text(_cargando ? 'Un momento...' : (_esRegistro ? 'Registrarme' : 'Entrar')),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.graphite)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('o continúa con', style: AppText.caption),
                    ),
                    Expanded(child: Divider(color: AppColors.graphite)),
                  ],
                ),
                const SizedBox(height: 20),
                buildGoogleButton(),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _esRegistro = !_esRegistro),
                    child: Text(
                      _esRegistro ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate',
                      style: AppText.caption.copyWith(color: AppColors.fog),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}