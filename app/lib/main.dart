import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/network/api_client.dart';
import 'core/security/pin_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/seguridad/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  runApp(const FinoraApp());
}

class FinoraApp extends StatelessWidget {
  const FinoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AppEntry(),
    );
  }
}

/// Decide qué mostrar al abrir la app: pantalla de bloqueo (si hay PIN
/// activo), el dashboard (si ya hay sesión), o el login.
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> with WidgetsBindingObserver {
  bool _cargando = true;
  bool _bloqueado = false;
  bool _autenticado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _iniciar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && !_cargando) {
      final pinActivo = await PinService.isPinEnabled();
      if (pinActivo && mounted) setState(() => _bloqueado = true);
    }
  }

  Future<void> _iniciar() async {
    final token = await ApiClient.obtenerToken();
    final pinActivo = await PinService.isPinEnabled();
    if (!mounted) return;
    setState(() {
      _autenticado = token != null;
      _bloqueado = pinActivo;
      _cargando = false;
    });
  }

  void _desbloquear() => setState(() => _bloqueado = false);

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: AppColors.obsidian,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_bloqueado) {
      return LockScreen(onUnlocked: _desbloquear);
    }
    return _autenticado ? const DashboardScreen() : const LoginScreen();
  }
}