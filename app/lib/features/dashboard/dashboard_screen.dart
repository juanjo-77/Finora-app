import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_drawer.dart';
import '../deudas/deuda.dart';
import '../deudas/deudas_service.dart';
import '../inversiones/inversion.dart';
import '../inversiones/inversiones_service.dart';
import '../metas/meta.dart';
import '../metas/metas_service.dart';
import '../movimientos/movimiento.dart';
import '../movimientos/movimientos_service.dart';
import '../presupuestos/presupuesto.dart';
import '../presupuestos/presupuestos_service.dart';
import 'widgets/alertas_engine.dart';
import 'widgets/alertas_widget.dart';
import 'widgets/category_spending_chart.dart';
import 'widgets/financial_score_engine.dart';
import 'widgets/financial_score_widget.dart';

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

  static const _paletaCategorias = [
    AppColors.copper,
    AppColors.silver,
    AppColors.steel,
    AppColors.mist,
    AppColors.smoke,
    AppColors.fog,
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final resultados = await Future.wait([
      MovimientosService.obtenerTodos(),
      DeudasService.obtenerTodas(),
      InversionesService.obtenerTodas(),
      PresupuestosService.obtenerTodos(),
      MetasService.obtenerTodas(),
    ]);
    _movimientos = resultados[0] as List<Movimiento>;
    _deudas = resultados[1] as List<Deuda>;
    _inversiones = resultados[2] as List<Inversion>;
    _presupuestos = resultados[3] as List<Presupuesto>;
    _metas = resultados[4] as List<Meta>;
    setState(() => _cargando = false);
  }

  Map<String, double> _gastosPorCategoria() {
    final mapa = <String, double>{};
    for (final m in _movimientos.where((m) => m.tipo == 'Gasto')) {
      mapa[m.categoria] = (mapa[m.categoria] ?? 0) + m.monto;
    }
    final entradas = mapa.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entradas.take(6));
  }

  @override
  Widget build(BuildContext context) {
    final formato = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final ingresos = _movimientos.where((m) => m.tipo == 'Ingreso').fold(0.0, (s, m) => s + m.monto);
    final gastos = _movimientos.where((m) => m.tipo == 'Gasto').fold(0.0, (s, m) => s + m.monto);
    final saldoActual = ingresos - gastos;

    final limite = DateTime.now().add(const Duration(days: 30));
    final cuotasProximas = _deudas.where((d) => d.proximaFecha.isBefore(limite)).toList();
    final totalCuotasProximas = cuotasProximas.fold(0.0, (s, d) => s + d.cuotaMensual);
    final disponibleReal = saldoActual - totalCuotasProximas;

    final totalInversiones = _inversiones.fold(0.0, (s, i) => s + i.valorActual);
    final totalDeudas = _deudas.fold(0.0, (s, d) => s + d.montoTotal);
    final patrimonioNeto = saldoActual + totalInversiones - totalDeudas;

    final gastosPorCategoria = _gastosPorCategoria();
    final categorias = gastosPorCategoria.keys.toList();

    final alertas = AlertasEngine.generar(
      movimientos: _movimientos,
      presupuestos: _presupuestos,
      deudas: _deudas,
    );

    final score = FinancialScoreEngine.calcular(
      movimientos: _movimientos,
      deudas: _deudas,
      inversiones: _inversiones,
      metas: _metas,
      presupuestos: _presupuestos,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Finora')),
      drawer: AppDrawer(actual: DrawerRuta.dashboard),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _cargar,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BALANCE', style: AppText.eyebrow),
                      const SizedBox(height: 8),
                      Text('Disponible real', style: AppText.body),
                      ShaderMask(
                        shaderCallback: (b) => AppColors.gildedGradient.createShader(b),
                        child: Text(formato.format(disponibleReal),
                            style: AppText.display.copyWith(color: Colors.white, fontSize: 56)),
                      ),
                      const SizedBox(height: 8),
                      Text('Saldo actual: ${formato.format(saldoActual)}', style: AppText.caption),
                      const SizedBox(height: 24),

                      FinancialScoreWidget(resultado: score),
                      const SizedBox(height: 20),

                      if (alertas.isNotEmpty) ...[
                        AlertasWidget(alertas: alertas),
                        const SizedBox(height: 8),
                      ],

                      Row(children: [
                        Expanded(child: _statCard('Ingresos', formato.format(ingresos), AppColors.copper)),
                        const SizedBox(width: 12),
                        Expanded(child: _statCard('Gastos', formato.format(gastos), AppColors.bone)),
                      ]),

                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.carbon,
                          border: Border.all(color: AppColors.graphite),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PATRIMONIO NETO', style: AppText.eyebrow.copyWith(color: AppColors.fog)),
                            const SizedBox(height: 6),
                            Text(formato.format(patrimonioNeto),
                                style: AppText.statNumber.copyWith(fontSize: 26)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _miniStat('Dinero', formato.format(saldoActual)),
                                _miniStat('Inversiones', formato.format(totalInversiones)),
                                _miniStat('Deudas', '-${formato.format(totalDeudas)}'),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (gastosPorCategoria.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Text('GASTOS POR CATEGORÍA', style: AppText.eyebrow.copyWith(color: AppColors.fog)),
                        const SizedBox(height: 16),
                        CategorySpendingChart(
                          formato: formato,
                          categorias: List.generate(categorias.length, (i) {
                            final cat = categorias[i];
                            final valor = gastosPorCategoria[cat]!;
                            return CategoriaGasto(
                              nombre: cat,
                              monto: valor,
                              porcentaje: gastos > 0 ? valor / gastos : 0.0,
                              color: _paletaCategorias[i % _paletaCategorias.length],
                            );
                          }),
                        ),
                      ],

                      if (cuotasProximas.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Text('PRÓXIMOS PAGOS (30 días)', style: AppText.eyebrow.copyWith(color: AppColors.fog)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.graphite),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: cuotasProximas.map((d) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(d.nombre, style: AppText.body.copyWith(fontSize: 14)),
                                  Text('-${formato.format(d.cuotaMensual)}',
                                      style: AppText.bodyStrong.copyWith(fontSize: 14)),
                                ],
                              ),
                            )).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _statCard(String label, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.onyx,
        border: Border.all(color: AppColors.graphite),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption),
          const SizedBox(height: 4),
          Text(valor, style: AppText.bodyStrong.copyWith(color: color, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption.copyWith(fontSize: 11)),
        const SizedBox(height: 2),
        Text(valor, style: AppText.body.copyWith(fontSize: 13, color: AppColors.bone)),
      ],
    );
  }
}