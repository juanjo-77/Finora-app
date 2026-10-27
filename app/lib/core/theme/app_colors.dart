import 'package:flutter/material.dart';

/// Paleta "Grabado": negro puro y oro.
/// Los nombres anteriores se conservan como alias para que todas las
/// pantallas adopten la paleta nueva sin tocar su código.
class AppColors {
  static const black    = Color(0xFF000000);
  static const vault    = Color(0xFF0F0D09); // superficies
  static const vault2   = Color(0xFF18150F);
  static const seam     = Color(0xFF2A251B); // bordes
  static const ivory    = Color(0xFFEFE8D8); // texto principal
  static const sand     = Color(0xFF9A917D); // texto secundario
  static const dust     = Color(0xFF8A8170); // texto terciario
  static const gold     = Color(0xFFC9A961);
  static const goldHi   = Color(0xFFF4DDA0);
  static const bronze   = Color(0xFF7A6230);
  static const ember    = Color(0xFFD9725B); // solo errores

  static const obsidian = black;
  static const onyx     = vault;
  static const carbon   = vault;
  static const graphite = seam;
  static const slate    = Color(0xFF3A3220);
  static const smoke    = Color(0xFF4A3B1E);
  static const ash      = dust;
  static const steel    = Color(0xFF8C6F35);
  static const fog      = sand;
  static const mist     = Color(0xFFB8AE97);
  static const silver   = Color(0xFFD6CDB8);
  static const bone     = ivory;
  static const paperWhite = ivory;
  static const copper   = gold;

  /// Oro metálico para la cifra principal.
  static const gildedGradient = LinearGradient(
    colors: [bronze, gold, goldHi, gold, bronze],
    stops: [0.0, 0.3, 0.46, 0.6, 1.0],
  );

  /// Oro para botones principales.
  static const goldButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldHi, gold, Color(0xFFA88A48)],
  );

  /// Tonos para categorías, del más claro al más oscuro.
  static const categorias = [goldHi, gold, steel, smoke, mist, slate];
}
