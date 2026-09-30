import 'package:flutter/material.dart';
import '../../core/security/pin_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  String _primerPin = '';
  String _actual = '';
  bool _confirmando = false;
  String? _error;

  void _agregarDigito(String d) {
    if (_actual.length >= 4) return;
    setState(() {
      _actual += d;
      _error = null;
    });
    if (_actual.length == 4) _procesar();
  }

  void _borrar() {
    if (_actual.isEmpty) return;
    setState(() => _actual = _actual.substring(0, _actual.length - 1));
  }

  Future<void> _procesar() async {
    if (!_confirmando) {
      setState(() {
        _primerPin = _actual;
        _actual = '';
        _confirmando = true;
      });
      return;
    }

    if (_actual == _primerPin) {
      await PinService.setPin(_primerPin);
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _error = 'Los PIN no coinciden, intenta de nuevo';
        _primerPin = '';
        _actual = '';
        _confirmando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_confirmando ? 'Confirma tu PIN' : 'Crea un PIN',
                  style: AppText.heading.copyWith(fontSize: 26)),
              const SizedBox(height: 8),
              Text('4 dígitos, para bloquear el acceso local a la app',
                  style: AppText.caption, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final lleno = i < _actual.length;
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
              const SizedBox(width: 64, height: 64),
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