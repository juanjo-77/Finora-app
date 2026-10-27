import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/data_bus.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/feedback.dart';
import '../../core/widgets/grabado.dart';
import '../deudas/deuda.dart';
import '../deudas/deudas_screen.dart';
import '../deudas/deudas_service.dart';
import '../inversiones/inversion.dart';
import '../inversiones/inversiones_service.dart';
import '../metas/meta.dart';
import '../metas/metas_service.dart';
import '../movimientos/movimiento.dart';
import '../movimientos/movimiento_sheet.dart';
import '../movimientos/movimientos_service.dart';
import '../presupuestos/presupuesto.dart';
import '../presupuestos/presupuestos_service.dart';
import '../shell/main_shell.dart';
import 'widgets/alertas_engine.dart';
import 'widgets/financial_score_engine.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Movimiento> _movimientos = [];
  List<Deuda> _deudas = [];
  List<Inversion> _inversiones = [];
  List<Presupuesto> _presupuestos = [];
  List<Meta> _metas = [];
  bool _cargando = true;
  String? _error;
  String _iniciales = '';
  int? _categoriaFoco;
  bool _verAlertas = false;

  @override
  void initState() {
    super.initState();
    _cargar();
    DataBus.cambios.addListener(_recargarEnSilencio);
    ApiClient.obtenerEmail().then((e) {
      if (mounted && e != null && e.isNotEmpty) {
        setState(() => _iniciales = e.substring(0, e.length < 2 ? e.length : 2).toUpperCase());
      }
    });
  }

  @override
  void dispose() {
    DataBus.cambios.removeListener(_recargarEnSilencio);
    super.dispose();
  }

  void _recargarEnSilencio() => _cargar(silencioso: true);

  /// En silencio no muestra la carga: los números giran a su nuevo valor.
  Future<void> _cargar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }
    try {
      final r = await Future.wait([
        MovimientosService.obtenerTodos(),
        DeudasService.obtenerTodas(),
        InversionesService.obtenerTodas(),
        PresupuestosService.obtenerTodos(),
        MetasService.obtenerTodas(),
      ]);
      if (!mounted) return;
      setState(() {
        _movimientos = r[0] as List<Movimiento>;
        DataBus.categorias = _movimientos.map((m) => m.categoria.trim()).where((c) => c.isNotEmpty).toSet().toList();
        _deudas = r[1] as List<Deuda>;
        _inversiones = r[2] as List<Inversion>;
        _presupuestos = r[3] as List<Presupuesto>;
        _metas = r[4] as List<Meta>;
        _error = null;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (silencioso && _error == null) {
        mostrarError(context, e);
        return;
      }
      setState(() {
        _error = mensajeDeError(e, 'No pudimos cargar tus datos.');
        _cargando = false;
      });
    }
  }

  String _saludo() {
    final h = DateTime.now().hour;
    return h < 12 ? 'Buenos días' : (h < 19 ? 'Buenas tardes' : 'Buenas noches');
  }

  @override
  Widget build(BuildContext context) {
    final shell = Shell.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ErrorReintentar(mensaje: _error!, alReintentar: _cargar)
                : RefreshIndicator(
                    onRefresh: () => _cargar(silencioso: true),
                    child: _contenido(context, shell),
                  ),
      ),
    );
  }

  Widget _contenido(BuildContext context, Shell? shell) {
    final ahora = DateTime.now();
    bool esMes(DateTime f) => f.year == ahora.year && f.month == ahora.month;
    double suma(Iterable<Movimiento> l) => l.fold(0.0, (s, m) => s + m.monto);

    final ingresos = suma(_movimientos.where((m) => m.tipo == 'Ingreso'));
    final gastos = suma(_movimientos.where((m) => m.tipo == 'Gasto'));
    final saldoActual = ingresos - gastos;
    final entroMes = suma(_movimientos.where((m) => m.tipo == 'Ingreso' && esMes(m.fecha)));
    final salioMes = suma(_movimientos.where((m) => m.tipo == 'Gasto' && esMes(m.fecha)));

    final limite = ahora.add(const Duration(days: 30));
    final proximas = _deudas.where((d) => d.proximaFecha.isBefore(limite)).toList()
      ..sort((a, b) => a.proximaFecha.compareTo(b.proximaFecha));
    final porPagar = proximas.fold(0.0, (s, d) => s + d.cuotaMensual);
    final disponibleReal = saldoActual - porPagar;

    final totalInversiones = _inversiones.fold(0.0, (s, i) => s + i.valorActual);
    final totalDeudas = _deudas.fold(0.0, (s, d) => s + d.montoTotal);
    final patrimonio = saldoActual + totalInversiones - totalDeudas;

    final alertas = AlertasEngine.generar(movimientos: _movimientos, presupuestos: _presupuestos, deudas: _deudas);
    final score = FinancialScoreEngine.calcular(
      movimientos: _movimientos,
      deudas: _deudas,
      inversiones: _inversiones,
      metas: _metas,
      presupuestos: _presupuestos,
    );
    final categorias = _categoriasDelMes(esMes);

    Duration paso(int i) => Duration(milliseconds: 650 + 60 * i);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(context).padding.bottom + 20),
      children: [
        Rise(
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_saludo(), style: AppText.body.copyWith(fontSize: 14)),
                Text(toBeginningOfSentenceCase(DateFormat('MMMM', 'es').format(ahora)), style: AppText.subheading.copyWith(fontSize: 19)),
              ]),
            ),
            Semantics(
              button: true,
              label: 'Más opciones',
              child: InkWell(
                onTap: shell?.abrirMas,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.bronze)),
                  child: _iniciales.isEmpty
                      ? const LineIcon(Trazo.perfil, size: 20, color: AppColors.gold)
                      : Text(_iniciales, style: AppText.amount.copyWith(fontSize: 13, color: AppColors.gold)),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 26),
        GuillocheVault(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Disponible real', style: AppText.body.copyWith(fontSize: 14)),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: RollingAmount(
                  value: disponibleReal,
                  style: AppText.display.copyWith(fontSize: 42),
                  spin: true,
                  metal: true,
                  delay: const Duration(milliseconds: 250),
                ),
              ),
              const SizedBox(height: 18),
              Row(children: [
                _cifraVault('Entró', entroMes, 0, oro: true),
                const SizedBox(width: 22),
                _cifraVault('Salió', salioMes, 1),
                const SizedBox(width: 22),
                _cifraVault('Por pagar', porPagar, 2),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 26),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Rise(delay: paso(0), child: QuickAction(icono: Trazo.subir, label: 'Ingreso', empuje: const Offset(0, -4), onTap: () => shell?.registrar(tipo: 'Ingreso'))),
          Rise(delay: paso(1), child: QuickAction(icono: Trazo.bajar, label: 'Gasto', empuje: const Offset(0, 4), onTap: () => shell?.registrar(tipo: 'Gasto'))),
          Rise(delay: paso(2), child: QuickAction(icono: Trazo.escanear, label: 'Escanear', onTap: () => escanearRecibo(context))),
          Rise(delay: paso(3), child: QuickAction(icono: Trazo.meta, label: 'Metas', onTap: () => shell?.irA(2))),
        ]),
        if (alertas.isNotEmpty) ...[
          const SizedBox(height: 24),
          Rise(delay: paso(4), child: _alertas(alertas)),
        ],
        const SizedBox(height: 30),
        Rise(
          delay: paso(5),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionHeader('Salud financiera', enlace: 'Cómo subirla', alTocar: () => _detalleScore(score)),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.vault,
                border: Border.all(color: AppColors.seam),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(children: [
                ScoreDial(score: score.puntaje),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_veredicto(score.puntaje), style: AppText.bodyStrong),
                    const SizedBox(height: 4),
                    Text(
                      score.factoresNegativos.isNotEmpty
                          ? score.factoresNegativos.first
                          : (score.factoresPositivos.isNotEmpty ? score.factoresPositivos.first : 'Registra tus movimientos para calcularla.'),
                      style: AppText.body.copyWith(fontSize: 14),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 30),
        Rise(delay: paso(6), child: _enQueSeFue(categorias, salioMes)),
        const SizedBox(height: 30),
        Rise(
          delay: paso(7),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader('Patrimonio neto'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RollingAmount(value: patrimonio, style: AppText.statNumber.copyWith(fontSize: 24), spin: true, delay: const Duration(milliseconds: 900)),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  _mini('Dinero', pesosCortos(saldoActual)),
                  _mini('Inversiones', pesosCortos(totalInversiones)),
                  _mini('Deudas', pesosCortos(totalDeudas)),
                ]),
              ]),
            ),
          ]),
        ),
        if (proximas.isNotEmpty) ...[
          const SizedBox(height: 30),
          Rise(delay: paso(8), child: _ProximosPagos(deudas: proximas, hoy: ahora)),
        ],
      ],
    );
  }

  Widget _cifraVault(String label, double valor, int i, {bool oro = false}) => Flexible(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppText.caption.copyWith(color: AppColors.sand, fontSize: 13)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RollingAmount(
              value: valor,
              format: pesosCortos,
              spin: true,
              delay: Duration(milliseconds: 500 + i * 90),
              style: AppText.amount.copyWith(fontSize: 15, color: oro ? AppColors.goldHi : AppColors.ivory),
            ),
          ),
        ]),
      );

  Widget _mini(String label, String valor) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppText.caption),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, child: Text(valor, style: AppText.amount.copyWith(fontSize: 13))),
        ]),
      );

  String _veredicto(int p) => p >= 80 ? 'Excelente' : p >= 60 ? 'Vas bien' : p >= 40 ? 'Hay que ajustar' : 'Necesita atención';

  Widget _alertas(List<Alerta> alertas) {
    Widget una(Alerta a) {
      final color = switch (a.tipo) {
        TipoAlerta.peligro => AppColors.ember,
        TipoAlerta.aviso => AppColors.gold,
        TipoAlerta.exito => AppColors.goldHi,
      };
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 2)),
          gradient: const LinearGradient(colors: [Color(0xFF15110A), Colors.transparent]),
        ),
        child: Text(a.texto, style: AppText.body.copyWith(fontSize: 14, color: AppColors.ivory)),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      una(alertas.first),
      if (alertas.length > 1) ...[
        Fold(visible: _verAlertas, child: Column(children: alertas.skip(1).map(una).toList())),
        TextButton(
          onPressed: () => setState(() => _verAlertas = !_verAlertas),
          child: Text(_verAlertas ? 'Ver menos' : 'Ver ${alertas.length - 1} ${alertas.length == 2 ? 'aviso' : 'avisos'} más'),
        ),
      ],
    ]);
  }

  List<MapEntry<String, double>> _categoriasDelMes(bool Function(DateTime) esMes) {
    final mapa = <String, double>{};
    for (final m in _movimientos.where((m) => m.tipo == 'Gasto' && esMes(m.fecha))) {
      final c = m.categoria.trim().isEmpty ? 'Otros' : m.categoria.trim();
      mapa[c] = (mapa[c] ?? 0) + m.monto;
    }
    final orden = mapa.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (orden.length <= 4) return orden;
    final resto = orden.skip(3).fold(0.0, (s, e) => s + e.value);
    return [...orden.take(3), MapEntry('Otros', resto)];
  }

  Widget _enQueSeFue(List<MapEntry<String, double>> cats, double total) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader('En qué se fue', enlace: 'Ver movimientos', alTocar: () => Shell.of(context)?.irA(1)),
      if (cats.isEmpty || total <= 0)
        Text('Aún no registras gastos este mes.', style: AppText.body.copyWith(fontSize: 14))
      else ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 12,
            child: LayoutBuilder(builder: (context, c) {
              final ancho = c.maxWidth - 2 * (cats.length - 1);
              return Row(children: [
                for (var i = 0; i < cats.length; i++) ...[
                  if (i > 0) const SizedBox(width: 2),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: cats[i].value / total),
                    duration: Duration(milliseconds: sinAnimaciones(context) ? 0 : 1100 + i * 60),
                    curve: AppTheme.ease,
                    builder: (context, f, _) => AnimatedOpacity(
                      opacity: _categoriaFoco == null || _categoriaFoco == i ? 1 : .45,
                      duration: const Duration(milliseconds: 200),
                      child: Container(width: (ancho * f).clamp(0, ancho), color: AppColors.categorias[i]),
                    ),
                  ),
                ],
              ]);
            }),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          children: [
            for (var i = 0; i < cats.length; i++)
              FractionallySizedBox(
                widthFactor: .5,
                child: InkWell(
                  onTap: () => setState(() => _categoriaFoco = _categoriaFoco == i ? null : i),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedOpacity(
                    opacity: _categoriaFoco == null || _categoriaFoco == i ? 1 : .4,
                    duration: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 6, i.isEven ? 18 : 0, 6),
                      child: Row(children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: AppColors.categorias[i], borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(cats[i].key,
                              style: AppText.bodyStrong.copyWith(fontSize: 14, fontWeight: FontWeight.w400), overflow: TextOverflow.ellipsis),
                        ),
                        Text('${(cats[i].value / total * 100).round()}%', style: AppText.body.copyWith(fontSize: 14, fontFeatures: AppText.tabular)),
                      ]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ]);
  }

  void _detalleScore(FinancialScoreResult r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tu salud financiera: ${r.puntaje} de 100', style: AppText.subheading),
            const SizedBox(height: 16),
            if (r.factoresPositivos.isNotEmpty) ...[
              Text('Lo que haces bien', style: AppText.eyebrow),
              const SizedBox(height: 6),
              ...r.factoresPositivos.map((f) => _factor(f, AppColors.goldHi)),
              const SizedBox(height: 14),
            ],
            if (r.factoresNegativos.isNotEmpty) ...[
              Text('Para subirla', style: AppText.eyebrow),
              const SizedBox(height: 6),
              ...r.factoresNegativos.map((f) => _factor(f, AppColors.sand)),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _factor(String texto, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: AppText.body.copyWith(fontSize: 14, color: AppColors.ivory))),
        ]),
      );
}

/// Línea de 30 días con una marca por cada pago, enlazada a la lista.
class _ProximosPagos extends StatefulWidget {
  final List<Deuda> deudas;
  final DateTime hoy;
  const _ProximosPagos({required this.deudas, required this.hoy});
  @override
  State<_ProximosPagos> createState() => _ProximosPagosState();
}

class _ProximosPagosState extends State<_ProximosPagos> {
  int? _foco;

  int _dias(Deuda d) => DateTime(d.proximaFecha.year, d.proximaFecha.month, d.proximaFecha.day)
      .difference(DateTime(widget.hoy.year, widget.hoy.month, widget.hoy.day))
      .inDays;

  @override
  Widget build(BuildContext context) {
    final rapido = sinAnimaciones(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader('Próximos pagos',
          enlace: 'Ver deudas', alTocar: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeudasScreen()))),
      SizedBox(
        height: 46,
        child: LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth - 8;
          return Stack(clipBehavior: Clip.none, children: [
            Positioned(left: 4, top: 0, child: Text('hoy', style: AppText.caption.copyWith(fontSize: 11, color: AppColors.gold))),
            Positioned(
              left: 4,
              right: 4,
              top: 22,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: rapido ? 0 : 1000),
                curve: AppTheme.ease,
                builder: (_, t, _) => Align(
                  alignment: Alignment.centerLeft,
                  child: Container(height: 1, width: w * t, color: AppColors.seam),
                ),
              ),
            ),
            for (var d = 0; d <= 30; d++)
              Positioned(left: 4 + w * d / 30, top: 18, child: Container(width: 1, height: 9, color: const Color(0xFF221E16))),
            for (var i = 0; i < widget.deudas.length; i++)
              Positioned(
                left: 4 + w * _dias(widget.deudas[i]).clamp(0, 30) / 30 - 10.5,
                top: 12,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: rapido ? 0 : 500 + i * 120),
                  curve: const Cubic(.3, 1.4, .5, 1),
                  builder: (_, s, child) => Transform.scale(scale: s * (_foco == i ? 1.2 : 1), child: child),
                  child: _pin(i),
                ),
              ),
          ]);
        }),
      ),
      const SizedBox(height: 8),
      for (var i = 0; i < widget.deudas.length; i++) _fila(i),
    ]);
  }

  Widget _pin(int i) {
    final color = _dias(widget.deudas[i]) < 0 ? AppColors.ember : AppColors.gold;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 21,
      height: 21,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
        border: Border.all(color: color),
        boxShadow: [if (_foco == i) BoxShadow(color: AppColors.gold.withValues(alpha: .18), spreadRadius: 5)],
      ),
      child: Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    );
  }

  Widget _fila(int i) {
    final d = widget.deudas[i];
    final dias = _dias(d);
    final vencida = dias < 0;
    return MouseRegion(
      onEnter: (_) => setState(() => _foco = i),
      onExit: (_) => setState(() => _foco = null),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _foco = i),
        onTapCancel: () => setState(() => _foco = null),
        onTapUp: (_) => setState(() => _foco = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
          decoration: BoxDecoration(
            color: _foco == i ? const Color(0xFF120F09) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            SizedBox(
              width: 42,
              child: Column(children: [
                Text(DateFormat('dd').format(d.proximaFecha),
                    style: AppText.amount.copyWith(fontSize: 16, color: vencida ? AppColors.ember : AppColors.gold)),
                const SizedBox(height: 4),
                Text(DateFormat('MMM', 'es').format(d.proximaFecha).replaceAll('.', ''), style: AppText.caption.copyWith(fontSize: 11)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.nombre, style: AppText.bodyStrong, overflow: TextOverflow.ellipsis),
                Text(
                  vencida
                      ? 'Vencida hace ${-dias} ${dias == -1 ? 'día' : 'días'}'
                      : (dias == 0 ? 'Vence hoy' : 'Saldo ${pesosCortos(d.montoTotal)}'),
                  style: AppText.caption.copyWith(color: vencida ? AppColors.ember : AppColors.dust),
                ),
              ]),
            ),
            Text(pesos(d.cuotaMensual), style: AppText.amount),
          ]),
        ),
      ),
    );
  }
}
