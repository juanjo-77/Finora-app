import 'package:flutter/material.dart';

/// En pantallas angostas (celular) muestra solo el ícono.
/// En pantallas anchas (web/tablet) muestra ícono + texto.
class ResponsiveFab extends StatelessWidget {
  final String heroTag;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const ResponsiveFab({
    super.key,
    required this.heroTag,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  static const _anchoMovil = 600.0;

  @override
  Widget build(BuildContext context) {
    final esMovil = MediaQuery.of(context).size.width < _anchoMovil;

    if (esMovil) {
      return FloatingActionButton(
        heroTag: heroTag,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        onPressed: onPressed,
        child: Icon(icon),
      );
    }
    return FloatingActionButton.extended(
      heroTag: heroTag,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}