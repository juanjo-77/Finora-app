import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data_bus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/feedback.dart';
import '../../core/widgets/grabado.dart';
import 'movimiento.dart';
import 'movimiento_sheet.dart';
import 'movimientos_service.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});
  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  static const _filtros = [(null, 'Todos'), ('Ingreso', 'Ingresos'), ('Gasto', 'Gastos')];
  List<Movimiento> _movimientos = [];
  bool _cargando = true;
  String? _error;
  String? _filtro;
  int? _nuevoId;
  bool _aterrizado = true;
  final _llaves = <int, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _cargar();
    DataBus.cambios.addListener(_alCambiar);
  }

  @override
  void dispose() {
    DataBus.cambios.removeListener(_alCambiar);
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }
    try {
      final lista = await MovimientosService.obtenerTodos();
      lista.sort((a, b) => b.fecha.compareTo(a.fecha));
      if (!mounted) return;
      DataBus.categorias = lista.map((m) => m.categoria.trim()).where((c) => c.isNotEmpty).toSet().toList();
      setState(() {
        _movimientos = lista;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (silencioso && _error == null) {
        mostrarError(context, e);
        return;
      }
      setState(() {
        _error = mensajeDeError(e, 'No pudimos cargar tus movimientos.');
        _cargando = false;
      });
    }
  }

  /// Otro lugar guardó un movimiento: recarga y, si esta pantalla está
  /// a la vista, hace volar el monto hasta su fila.
  Future<void> _alCambiar() async {
    final guardado = DataBus.ultimo;
    final visible = TickerMode.valuesOf(context).enabled;
    await _cargar(silencioso: true);
    final id = guardado?.movimiento.id;
    if (!mounted || id == null) return;
    final volar = visible && guardado!.origen != null && !sinAnimaciones(context);
    setState(() {
      _filtro = null;
      _nuevoId = id;
      _aterrizado = !volar;
    });
    if (!volar) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final destino = _llaves[id] == null ? null : rectGlobal(_llaves[id]!);
      if (destino == null || !mounted) {
        setState(() => _aterrizado = true);
        return;
      }
      final m = guardado.movimiento;
      await volarMonto(context, texto: pesos(m.monto), desde: guardado.origen!, hasta: destino);
      if (!mounted) return;
      setState(() => _aterrizado = true);
      chispas(context, destino.center);
    });
  }

  Future<void> _eliminar(Movimiento m) async {
    final i = _movimientos.indexOf(m);
    setState(() => _movimientos.remove(m));
    try {
      await MovimientosService.eliminar(m.id!);
      DataBus.avisar();
    } catch (e) {
      if (!mounted) return;
      setState(() => _movimientos.insert(i.clamp(0, _movimientos.length), m));
      mostrarError(context, e);
    }
  }

  String _dia(DateTime f) {
    final hoy = DateTime.now();
    final d = DateTime(f.year, f.month, f.day);
    final diff = DateTime(hoy.year, hoy.month, hoy.day).difference(d).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return DateFormat(f.year == hoy.year ? "d 'de' MMMM" : "d 'de' MMMM 'de' y", 'es').format(f);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ErrorReintentar(mensaje: _error!, alReintentar: _cargar)
                : RefreshIndicator(onRefresh: () => _cargar(silencioso: true), child: _lista()),
      ),
    );
  }

  Widget _lista() {
    final ahora = DateTime.now();
    bool esMes(DateTime f) => f.year == ahora.year && f.month == ahora.month;
    double suma(String tipo) => _movimientos.where((m) => m.tipo == tipo && esMes(m.fecha)).fold(0.0, (s, m) => s + m.monto);

    final grupos = <String, List<Movimiento>>{};
    for (final m in _movimientos) {
      grupos.putIfAbsent(_dia(m.fecha.toLocal()), () => []).add(m);
    }
    final indice = _filtros.indexWhere((f) => f.$1 == _filtro);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(context).padding.bottom + 20),
      children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(toBeginningOfSentenceCase(DateFormat("MMMM 'de' y", 'es').format(ahora)), style: AppText.body.copyWith(fontSize: 14)),
              Text('Movimientos', style: AppText.heading),
            ]),
          ),
          IconButton(
            tooltip: 'Escanear recibo',
            onPressed: () => escanearRecibo(context),
            icon: const LineIcon(Trazo.escanear, color: AppColors.gold),
          ),
        ]),
        const SizedBox(height: 18),
        Container(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.seam))),
          child: Stack(children: [
            Row(children: [
              for (final f in _filtros)
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _filtro = f.$1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: AppText.bodyStrong.copyWith(fontSize: 14, color: _filtro == f.$1 ? AppColors.ivory : AppColors.dust),
                          child: Text(f.$2),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
            Positioned.fill(
              child: AnimatedAlign(
                duration: Duration(milliseconds: sinAnimaciones(context) ? 0 : 450),
                curve: AppTheme.ease,
                alignment: Alignment(-1 + indice.toDouble(), 1),
                child: FractionallySizedBox(widthFactor: 1 / 3, child: Container(height: 2, color: AppColors.gold)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.vault,
            border: Border.all(color: AppColors.seam),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(6),
            ),
          ),
          child: Row(children: [
            Expanded(child: _total('Entró este mes', suma('Ingreso'), oro: true)),
            Expanded(child: _total('Salió este mes', suma('Gasto'), derecha: true)),
          ]),
        ),
        if (_movimientos.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Text(
              'Aún no tienes movimientos.\nRegistra el primero con el botón dorado.',
              textAlign: TextAlign.center,
              style: AppText.body,
            ),
          ),
        for (final g in grupos.entries)
          Fold(
            visible: g.value.any(_pasa),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 22, bottom: 2),
                child: Text(g.key, style: AppText.caption.copyWith(fontSize: 13)),
              ),
              for (final m in g.value) Fold(key: ValueKey('f${m.id}'), visible: _pasa(m), child: _fila(m)),
            ]),
          ),
        if (_movimientos.isNotEmpty && !_movimientos.any(_pasa))
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Text(
              _filtro == 'Ingreso' ? 'No hay ingresos registrados.' : 'No hay gastos registrados.',
              textAlign: TextAlign.center,
              style: AppText.body,
            ),
          ),
      ],
    );
  }

  bool _pasa(Movimiento m) => _filtro == null || m.tipo == _filtro;

  Widget _total(String label, double valor, {bool oro = false, bool derecha = false}) => Column(
        crossAxisAlignment: derecha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption.copyWith(color: AppColors.sand, fontSize: 13)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RollingAmount(
              value: valor,
              spin: true,
              delay: Duration(milliseconds: derecha ? 380 : 300),
              style: AppText.amount.copyWith(fontSize: 17, color: oro ? AppColors.goldHi : AppColors.ivory),
            ),
          ),
        ],
      );

  Widget _fila(Movimiento m) {
    final ingreso = m.tipo == 'Ingreso';
    final nuevo = m.id != null && m.id == _nuevoId;
    final llave = m.id == null ? null : _llaves.putIfAbsent(m.id!, GlobalKey.new);

    Widget fila = Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1A1712)))),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.seam)),
          child: LineIcon(LineIcon.deCategoria(m.categoria, ingreso: ingreso), size: 18, color: AppColors.sand, grosor: 1.3),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.nota?.isNotEmpty == true ? m.nota! : m.categoria, style: AppText.bodyStrong, overflow: TextOverflow.ellipsis),
            Text(
              nuevo ? 'Hace un momento' : (m.nota?.isNotEmpty == true ? m.categoria : (ingreso ? 'Ingreso' : 'Gasto')),
              style: AppText.caption,
            ),
          ]),
        ),
        AnimatedOpacity(
          opacity: nuevo && !_aterrizado ? 0 : 1,
          duration: const Duration(milliseconds: 120),
          child: Text(
            '${ingreso ? '+' : '−'}${pesos(m.monto)}',
            key: llave,
            style: AppText.amount.copyWith(color: ingreso ? AppColors.goldHi : AppColors.ivory),
          ),
        ),
      ]),
    );

    if (nuevo) {
      fila = Stack(children: [
        Positioned.fill(
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: 0),
              duration: const Duration(milliseconds: 2100),
              curve: const Interval(.25, 1, curve: Curves.easeOut),
              builder: (_, o, _) => Opacity(
                opacity: o,
                child: const DecoratedBox(
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0x29C9A961), Colors.transparent], stops: [0, .8])),
                ),
              ),
            ),
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: sinAnimaciones(context) ? 1 : 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: AppTheme.ease,
          builder: (_, t, child) => ClipRect(child: Align(alignment: Alignment.topCenter, heightFactor: t, child: child)),
          child: fila,
        ),
      ]);
    }

    return Dismissible(
      key: ValueKey('m${m.id}'),
      direction: DismissDirection.endToStart,
      background: fondoEliminar(),
      confirmDismiss: (_) => confirmarEliminar(context, 'este movimiento'),
      onDismissed: (_) => _eliminar(m),
      child: InkWell(
        onTap: () => abrirRegistro(context, existente: m),
        child: fila,
      ),
    );
  }
}
