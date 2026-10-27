import 'package:flutter/widgets.dart';
import '../features/movimientos/movimiento.dart';

/// Un movimiento recién guardado y dónde estaba su monto en pantalla,
/// para que la lista lo haga volar hasta su fila.
class MovimientoGuardado {
  final Movimiento movimiento;
  final Rect? origen;
  const MovimientoGuardado(this.movimiento, this.origen);
}

/// Avisa a las pantallas que los datos cambiaron para que se recarguen.
class DataBus {
  static final cambios = ValueNotifier<int>(0);
  static MovimientoGuardado? ultimo;
  /// Categorías que el usuario ya usó, para sugerirlas en el registro.
  static List<String> categorias = const [];

  static void avisar([MovimientoGuardado? guardado]) {
    ultimo = guardado;
    cambios.value++;
  }
}
