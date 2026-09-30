import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'financial_score_engine.dart';

class FinancialScoreWidget extends StatelessWidget {
  final FinancialScoreResult resultado;
  const FinancialScoreWidget({super.key, required this.resultado});

  Color get _color {
    if (resultado.puntaje >= 80) return AppColors.copper;
    if (resultado.puntaje >= 60) return AppColors.silver;
    if (resultado.puntaje >= 40) return AppColors.steel;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.onyx,
        border: Border.all(color: AppColors.graphite),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: resultado.puntaje / 100),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, valor, _) => CustomPaint(
                painter: _AnilloScorePainter(progreso: valor, color: _color),
                child: Center(
                  child: Text(
                    '${(valor * 100).round()}',
                    style: AppText.statNumber.copyWith(fontSize: 22),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SALUD FINANCIERA', style: AppText.eyebrow.copyWith(color: AppColors.fog)),
                const SizedBox(height: 4),
                Text(resultado.etiqueta, style: AppText.bodyStrong.copyWith(fontSize: 16, color: _color)),
                if (resultado.factoresPositivos.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    resultado.factoresPositivos.first,
                    style: AppText.caption.copyWith(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else if (resultado.factoresNegativos.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    resultado.factoresNegativos.first,
                    style: AppText.caption.copyWith(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class _AnilloScorePainter extends CustomPainter {
  final double progreso; // 0..1
  final Color color;
  _AnilloScorePainter({required this.progreso, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = size.width / 2 - 6;

    final fondo = Paint()
      ..color = AppColors.graphite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(centro, radio, fondo);

    final trazo = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final anguloInicio = -math.pi / 2;
    final anguloBarrido = 2 * math.pi * progreso;
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: radio),
      anguloInicio,
      anguloBarrido,
      false,
      trazo,
    );
  }

  @override
  bool shouldRepaint(covariant _AnilloScorePainter oldDelegate) =>
      oldDelegate.progreso != progreso || oldDelegate.color != color;
}