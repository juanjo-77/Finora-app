import 'package:flutter/material.dart';
import '../../core/security/biometric_service.dart';
import '../../core/security/pin_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_drawer.dart';
import 'set_pin_screen.dart';

class SeguridadScreen extends StatefulWidget {
  const SeguridadScreen({super.key});

  @override
  State<SeguridadScreen> createState() => _SeguridadScreenState();
}

class _SeguridadScreenState extends State<SeguridadScreen> {
  bool _pinActivo = false;
  bool _biometricoActivo = false;
  bool _biometricoDisponible = false;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final pinActivo = await PinService.isPinEnabled();
    final bioActivo = await PinService.isBiometricEnabled();
    final bioDisponible = await BiometricService.isAvailable();
    setState(() {
      _pinActivo = pinActivo;
      _biometricoActivo = bioActivo;
      _biometricoDisponible = bioDisponible;
      _cargando = false;
    });
  }

  Future<void> _activarPin() async {
    final resultado = await Navigator.push<bool>(
      context, MaterialPageRoute(builder: (_) => const SetPinScreen()),
    );
    if (resultado == true) _cargar();
  }

  Future<void> _desactivarPin() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.onyx,
        title: Text('Desactivar bloqueo', style: AppText.bodyStrong.copyWith(color: AppColors.paperWhite)),
        content: Text('Ya no se pedirá PIN ni biometría al entrar a la app.', style: AppText.body.copyWith(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Desactivar')),
        ],
      ),
    );
    if (confirmar == true) {
      await PinService.disablePin();
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad')),
      drawer: AppDrawer(actual: DrawerRuta.seguridad),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('BLOQUEO LOCAL', style: AppText.eyebrow.copyWith(color: AppColors.fog)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.graphite),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text('Bloqueo con PIN', style: AppText.body.copyWith(fontSize: 14, color: AppColors.bone)),
                        subtitle: Text('Pide un PIN de 4 dígitos al abrir la app', style: AppText.caption),
                        value: _pinActivo,
                        activeThumbColor: AppColors.copper,
                        onChanged: (val) => val ? _activarPin() : _desactivarPin(),
                      ),
                      if (_pinActivo) ...[
                        const Divider(color: AppColors.graphite, height: 1),
                        ListTile(
                          title: Text('Cambiar PIN', style: AppText.body.copyWith(fontSize: 14, color: AppColors.bone)),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.fog, size: 18),
                          onTap: _activarPin,
                        ),
                        const Divider(color: AppColors.graphite, height: 1),
                        SwitchListTile(
                          title: Text('Desbloquear con biometría', style: AppText.body.copyWith(fontSize: 14, color: AppColors.bone)),
                          subtitle: Text(
                            _biometricoDisponible
                                ? 'Usa tu huella o Face ID en vez del PIN'
                                : 'No disponible en este dispositivo o navegador',
                            style: AppText.caption,
                          ),
                          value: _biometricoActivo,
                          activeThumbColor: AppColors.copper,
                          onChanged: _biometricoDisponible
                              ? (val) async {
                                  await PinService.setBiometricEnabled(val);
                                  _cargar();
                                }
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}