import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'alertas_engine.dart';

class AlertasWidget extends StatelessWidget {
  final List<Alerta> alertas;
  const AlertasWidget({super.key, required this.alertas});

  @override
  Widget build(BuildContext context) {
    if (alertas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: alertas.map((a) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _colorFondo(a.tipo),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _colorBorde(a.tipo)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icono(a.tipo), size: 16, color: _colorBorde(a.tipo)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(a.texto, style: AppText.body.copyWith(fontSize: 13, color: AppColors.bone)),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Color _colorFondo(TipoAlerta t) {
    switch (t) {
      case TipoAlerta.peligro: return Colors.redAccent.withOpacity(0.08);
      case TipoAlerta.aviso: return AppColors.copper.withOpacity(0.08);
      case TipoAlerta.exito: return Colors.greenAccent.withOpacity(0.08);
    }
  }

  Color _colorBorde(TipoAlerta t) {
    switch (t) {
      case TipoAlerta.peligro: return Colors.redAccent;
      case TipoAlerta.aviso: return AppColors.copper;
      case TipoAlerta.exito: return Colors.greenAccent;
    }
  }

  IconData _icono(TipoAlerta t) {
    switch (t) {
      case TipoAlerta.peligro: return Icons.error_outline;
      case TipoAlerta.aviso: return Icons.warning_amber_rounded;
      case TipoAlerta.exito: return Icons.check_circle_outline;
    }
  }
}