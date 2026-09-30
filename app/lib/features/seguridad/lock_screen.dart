import 'package:flutter/material.dart';
import '../../core/security/biometric_service.dart';
import '../../core/security/pin_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  String? _error;
  bool _biometricoDisponible = false;

  @override
  void initState() {
    super.initState();
    _prepararBiometria();
  }

  Future<void> _prepararBiometria() async {
    final disponible = await BiometricService.isAvailable();
    final activado = await PinService.isBiometricEnabled();
    if (!mounted) return;
    setState(() => _biometricoDisponible = disponible && activado);
    if (_biometricoDisponible) _intentarBiometria();
  }

  Future<void> _intentarBiometria() async {
    final ok = await BiometricService.authenticate();
    if (ok) widget.onUnlocked();
  }

  void _agregarDigito(String d) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == 4) _verificar();
  }

  void _borrar() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verificar() async {
    final ok = await PinService.verifyPin(_pin);
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = 'PIN incorrecto';
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('FINORA', style: AppText.eyebrow.copyWith(color: AppColors.fog)),
              const SizedBox(height: 8),
              Text('Ingresa tu PIN', style: AppText.heading.copyWith(fontSize: 28)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final lleno = i < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: lleno ? AppColors.copper : Colors.transparent,
                      border: Border.all(color: lleno ? AppColors.copper : AppColors.steel),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 20,
                child: _error != null
                    ? Text(_error!, style: AppText.caption.copyWith(color: Colors.redAccent))
                    : null,
              ),
              const SizedBox(height: 24),
              _teclado(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teclado() {
    final filas = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final fila in filas)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: fila.map(_botonTecla).toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: _biometricoDisponible
                    ? IconButton(
                        onPressed: _intentarBiometria,
                        icon: const Icon(Icons.fingerprint, color: AppColors.copper, size: 26),
                      )
                    : null,
              ),
              _botonTecla('0'),
              SizedBox(
                width: 64,
                height: 64,
                child: IconButton(
                  onPressed: _borrar,
                  icon: const Icon(Icons.backspace_outlined, color: AppColors.fog, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _botonTecla(String digito) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _agregarDigito(digito),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Center(
            child: Text(digito, style: AppText.heading.copyWith(fontSize: 24)),
          ),
        ),
      ),
    );
  }
}