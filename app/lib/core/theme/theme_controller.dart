import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static const _clave = 'modo_claro';
  static final ValueNotifier<bool> modoClaro = ValueNotifier(false);

  static Future<void> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      modoClaro.value = prefs.getBool(_clave) ?? false;
    } catch (_) {}
  }

  static Future<void> establecer(bool valor) async {
    modoClaro.value = valor;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_clave, valor);
    } catch (_) {}
  }

  /// No cambia nada (se usa en modo oscuro para que el árbol de widgets
  /// no se reconstruya al alternar y no se pierda la navegación).
  static const ColorFilter filtroOscuro = ColorFilter.mode(Colors.transparent, BlendMode.dst);

  /// Invierte el brillo de todo y conserva los tonos (equivale a
  /// invert(1) + hue-rotate(180deg) de CSS).
  static const ColorFilter filtroClaro = ColorFilter.matrix(<double>[
    0.574, -1.430, -0.144, 0, 255,
    -0.426, -0.430, -0.144, 0, 255,
    -0.426, -1.430, 0.856, 0, 255,
    0, 0, 0, 1, 0,
  ]);
}