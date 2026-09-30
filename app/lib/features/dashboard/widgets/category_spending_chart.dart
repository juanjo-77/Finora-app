import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CategoriaGasto {
  final String nombre;
  final double monto;
  final double porcentaje; // 0..1
  final Color color;
  CategoriaGasto({
    required this.nombre,
    required this.monto,
    required this.porcentaje,
    required this.color,
  });
}

/// Panel de gastos por categoría: barras horizontales sobre una pista con
/// guías punteadas verticales (0/25/50/75/100%) y un badge tipo "pill"
/// con el porcentaje, inspirado en el estilo del tooltip de fecha.
class CategorySpendingChart extends StatelessWidget {
  final List<CategoriaGasto> categorias;
  final NumberFormat formato;

  const CategorySpendingChart({
    super.key,
    required this.categorias,
    required this.formato,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.onyx,
        border: Border.all(color: AppColors.graphite),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < categorias.length; i++) ...[
            _fila(categorias[i]),
            if (i != categorias.length - 1) const SizedBox(height: 22),
          ],
          const SizedBox(height: 16),
          _escalaInferior(),
        ],
      ),
    );
  }

  Widget _fila(CategoriaGasto cat) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            cat.nombre,
            style: AppText.body.copyWith(fontSize: 13, color: AppColors.bone),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 24,
            child: Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                // Pista con guías punteadas verticales cada 25%
                CustomPaint(
                  size: const Size(double.infinity, 24),
                  painter: _GuiasPunteadasPainter(),
                ),
                // Barra animada
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: cat.porcentaje.clamp(0, 1)),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, valorAnimado, _) => FractionallySizedBox(
                    widthFactor: valorAnimado == 0 ? 0.001 : valorAnimado,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          colors: [cat.color.withOpacity(0.5), cat.color],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Badge tipo "pill" oscuro con el porcentaje, estilo tooltip de fecha
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.paperWhite,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${(cat.porcentaje * 100).toStringAsFixed(0)}%',
            style: AppText.bodyStrong.copyWith(fontSize: 12, color: Colors.black),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            formato.format(cat.monto),
            textAlign: TextAlign.right,
            style: AppText.caption.copyWith(fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _escalaInferior() {
    return Padding(
      padding: const EdgeInsets.only(left: 84),
      child: Row(
        children: const [
          Expanded(child: _EtiquetaEscala('0%', alinear: TextAlign.left)),
          Expanded(child: _EtiquetaEscala('50%', alinear: TextAlign.center)),
          Expanded(child: _EtiquetaEscala('100%', alinear: TextAlign.right)),
        ],
      ),
    );
  }
}

class _EtiquetaEscala extends StatelessWidget {
  final String texto;
  final TextAlign alinear;
  const _EtiquetaEscala(this.texto, {required this.alinear});

  @override
  Widget build(BuildContext context) {
    return Text(texto, textAlign: alinear, style: AppText.caption.copyWith(fontSize: 10));
  }
}

/// Dibuja 5 líneas verticales punteadas (0%, 25%, 50%, 75%, 100%) como
/// guía visual, igual al estilo de grid punteado de la referencia.
class _GuiasPunteadasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.graphite
      ..strokeWidth = 1;
    const dashAlto = 3.0;
    const espacio = 3.0;

    for (final frac in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final x = size.width * frac;
      double y = 0;
      while (y < size.height) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, (y + dashAlto).clamp(0, size.height)),
          paint,
        );
        y += dashAlto + espacio;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}