import 'package:flutter/material.dart';

class AppColors {
  static const obsidian = Color(0xFF08080A);
  static const onyx     = Color(0xFF040406);
  static const carbon   = Color(0xFF121317);
  static const graphite = Color(0xFF1C1D22);
  static const slate    = Color(0xFF2E3038);
  static const smoke    = Color(0xFF464853);
  static const ash      = Color(0xFF5E616E);
  static const steel    = Color(0xFF777A88);
  static const fog      = Color(0xFF9194A1);
  static const mist     = Color(0xFFACAFB9);
  static const silver   = Color(0xFFC7C9D1);
  static const bone     = Color(0xFFE2E3E9);
  static const paperWhite = Color(0xFFFFFFFF);
  static const copper   = Color(0xFFCC9166);

  static const gildedGradient = LinearGradient(
    begin: Alignment(-1, -0.3),
    end: Alignment(1, 0.3),
    colors: [
      Color(0xFFAE9357),
      Color(0xFFFFF0CC),
      Color(0xFFAE9357),
    ],
    stops: [0.0, 0.4, 1.0],
  );
}