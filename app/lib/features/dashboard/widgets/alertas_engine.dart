import '../../deudas/deuda.dart';
import '../../movimientos/movimiento.dart';
import '../../presupuestos/presupuesto.dart';

enum TipoAlerta { peligro, aviso, exito }

class Alerta {
  final String texto;
  final TipoAlerta tipo;
  Alerta(this.texto, this.tipo);
}

class AlertasEngine {
  static List<Alerta> generar({
    required List<Movimiento> movimientos,
    required List<Presupuesto> presupuestos,
    required List<Deuda> deudas,
  }) {
    final alertas = <Alerta>[];
    final ahora = DateTime.now();
    final mesAnterior = DateTime(ahora.year, ahora.month - 1);

    bool esMesActual(DateTime f) => f.year == ahora.year && f.month == ahora.month;
    bool esMesAnterior(DateTime f) => f.year == mesAnterior.year && f.month == mesAnterior.month;

    // 1. Presupuestos cerca o pasados del límite
    for (final p in presupuestos) {
      final gastado = movimientos
          .where((m) => m.tipo == 'Gasto' && m.categoria == p.categoria && esMesActual(m.fecha))
          .fold(0.0, (s, m) => s + m.monto);
      if (p.limiteMensual <= 0) continue;
      final pct = gastado / p.limiteMensual;
      if (pct > 1.0) {
        alertas.add(Alerta(
          'Ya te pasaste del presupuesto de ${p.categoria} en ${((pct - 1) * 100).toStringAsFixed(0)}%.',
          TipoAlerta.peligro,
        ));
      } else if (pct >= 0.9) {
        alertas.add(Alerta(
          'Ya usaste el ${(pct * 100).toStringAsFixed(0)}% de tu presupuesto de ${p.categoria}.',
          TipoAlerta.aviso,
        ));
      }
    }

    // 2. Gasto por categoría vs. mes anterior (solo si sube más de 20%)
    final gastosActual = <String, double>{};
    final gastosAnterior = <String, double>{};
    for (final m in movimientos.where((m) => m.tipo == 'Gasto')) {
      if (esMesActual(m.fecha)) gastosActual[m.categoria] = (gastosActual[m.categoria] ?? 0) + m.monto;
      if (esMesAnterior(m.fecha)) gastosAnterior[m.categoria] = (gastosAnterior[m.categoria] ?? 0) + m.monto;
    }
    gastosActual.forEach((categoria, actual) {
      final anterior = gastosAnterior[categoria];
      if (anterior != null && anterior > 0) {
        final cambio = ((actual - anterior) / anterior) * 100;
        if (cambio >= 20) {
          alertas.add(Alerta(
            'Gastaste ${cambio.toStringAsFixed(0)}% más en $categoria que el mes pasado.',
            TipoAlerta.aviso,
          ));
        }
      }
    });

    // 3. Deudas venciendo en 3 días o menos
    for (final d in deudas) {
      final diasRestantes = d.proximaFecha.difference(ahora).inDays;
      if (diasRestantes >= 0 && diasRestantes <= 3) {
        final cuando = diasRestantes == 0 ? 'hoy' : 'en $diasRestantes ${diasRestantes == 1 ? 'día' : 'días'}';
        alertas.add(Alerta('Tu pago de ${d.nombre} vence $cuando.', TipoAlerta.peligro));
      }
    }

    // 4. Ahorro del mes (positivo) comparado con el anterior
    final ingresosActual = movimientos.where((m) => m.tipo == 'Ingreso' && esMesActual(m.fecha)).fold(0.0, (s, m) => s + m.monto);
    final gastoTotalActual = gastosActual.values.fold(0.0, (s, v) => s + v);
    final ingresosAnterior = movimientos.where((m) => m.tipo == 'Ingreso' && esMesAnterior(m.fecha)).fold(0.0, (s, m) => s + m.monto);
    final gastoTotalAnterior = gastosAnterior.values.fold(0.0, (s, v) => s + v);

    if (ingresosActual > 0) {
      final ahorroPctActual = ((ingresosActual - gastoTotalActual) / ingresosActual) * 100;
      if (ingresosAnterior > 0) {
        final ahorroPctAnterior = ((ingresosAnterior - gastoTotalAnterior) / ingresosAnterior) * 100;
        if (ahorroPctActual > ahorroPctAnterior && ahorroPctActual > 0) {
          alertas.add(Alerta(
            'Este mes vas ahorrando ${ahorroPctActual.toStringAsFixed(0)}%, mejor que el mes pasado.',
            TipoAlerta.exito,
          ));
        }
      }
    }

    return alertas;
  }
}