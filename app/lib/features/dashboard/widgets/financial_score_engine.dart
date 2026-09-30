import '../../deudas/deuda.dart';
import '../../inversiones/inversion.dart';
import '../../metas/meta.dart';
import '../../movimientos/movimiento.dart';
import '../../presupuestos/presupuesto.dart';

class FinancialScoreResult {
  final int puntaje; // 0-100
  final List<String> factoresPositivos;
  final List<String> factoresNegativos;
  FinancialScoreResult(this.puntaje, this.factoresPositivos, this.factoresNegativos);

  String get etiqueta {
    if (puntaje >= 80) return 'Excelente';
    if (puntaje >= 60) return 'Saludable';
    if (puntaje >= 40) return 'En progreso';
    return 'Necesita atención';
  }
}

class FinancialScoreEngine {
  /// Cada factor aporta hasta un máximo de puntos. Suman 100 en total.
  static FinancialScoreResult calcular({
    required List<Movimiento> movimientos,
    required List<Deuda> deudas,
    required List<Inversion> inversiones,
    required List<Meta> metas,
    required List<Presupuesto> presupuestos,
  }) {
    final positivos = <String>[];
    final negativos = <String>[];
    double puntaje = 0;

    final ahora = DateTime.now();
    bool esMesActual(DateTime f) => f.year == ahora.year && f.month == ahora.month;

    final ingresos = movimientos.where((m) => m.tipo == 'Ingreso' && esMesActual(m.fecha)).fold(0.0, (s, m) => s + m.monto);
    final gastos = movimientos.where((m) => m.tipo == 'Gasto' && esMesActual(m.fecha)).fold(0.0, (s, m) => s + m.monto);

    // 1. Ahorro mensual (hasta 30 pts): % de ingresos que no gastaste este mes.
    if (ingresos > 0) {
      final ahorroPct = ((ingresos - gastos) / ingresos).clamp(0, 1);
      final pts = ahorroPct * 30;
      puntaje += pts;
      if (ahorroPct >= 0.2) {
        positivos.add('Ahorras ${(ahorroPct * 100).toStringAsFixed(0)}% de tus ingresos este mes.');
      } else if (ahorroPct < 0.05) {
        negativos.add('Estás ahorrando muy poco o nada este mes.');
      }
    }

    // 2. Nivel de deuda vs. ingreso (hasta 25 pts): menos deuda relativa = mejor.
    final totalDeuda = deudas.fold(0.0, (s, d) => s + d.montoTotal);
    if (ingresos > 0) {
      final ratioDeuda = totalDeuda / (ingresos * 12); // deuda vs. ingreso anualizado aproximado
      final pts = (1 - ratioDeuda.clamp(0, 1)) * 25;
      puntaje += pts;
      if (ratioDeuda > 0.5) {
        negativos.add('Tu nivel de deuda es alto respecto a tus ingresos.');
      } else if (totalDeuda == 0) {
        positivos.add('No tienes deudas activas.');
      }
    } else if (totalDeuda == 0) {
      puntaje += 25;
      positivos.add('No tienes deudas activas.');
    }

    // 3. Cumplimiento de presupuesto (hasta 20 pts): promedio de categorías dentro del límite.
    if (presupuestos.isNotEmpty) {
      int dentro = 0;
      for (final p in presupuestos) {
        final gastado = movimientos
            .where((m) => m.tipo == 'Gasto' && m.categoria == p.categoria && esMesActual(m.fecha))
            .fold(0.0, (s, m) => s + m.monto);
        if (p.limiteMensual > 0 && gastado <= p.limiteMensual) dentro++;
      }
      final ratio = dentro / presupuestos.length;
      puntaje += ratio * 20;
      if (ratio == 1.0) {
        positivos.add('Estás dentro de todos tus presupuestos este mes.');
      } else if (ratio < 0.5) {
        negativos.add('Te pasaste en varios de tus presupuestos.');
      }
    } else {
      // Sin presupuestos definidos: puntaje neutro (mitad), para no castigar a quien recién empieza.
      puntaje += 10;
    }

    // 4. Inversión activa (hasta 15 pts): tener algo invertido suma.
    final totalInvertido = inversiones.fold(0.0, (s, i) => s + i.montoInvertido);
    if (totalInvertido > 0) {
      puntaje += 15;
      positivos.add('Tienes inversiones activas.');
    } else {
      negativos.add('Aún no tienes inversiones registradas.');
    }

    // 5. Progreso en metas (hasta 10 pts): promedio de avance de todas las metas.
    if (metas.isNotEmpty) {
      final promedioProgreso = metas.fold(0.0, (s, m) => s + m.progreso) / metas.length;
      puntaje += promedioProgreso * 10;
      if (promedioProgreso >= 0.5) {
        positivos.add('Vas bien encaminado con tus metas financieras.');
      }
    } else {
      puntaje += 5;
    }

    return FinancialScoreResult(
      puntaje.round().clamp(0, 100),
      positivos,
      negativos,
    );
  }
}