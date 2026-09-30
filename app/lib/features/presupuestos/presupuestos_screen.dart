import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_input_formatter.dart';
import '../../core/widgets/app_drawer.dart';
import '../movimientos/movimiento.dart';
import '../movimientos/movimientos_service.dart';
import 'presupuesto.dart';
import 'presupuestos_service.dart';

class PresupuestosScreen extends StatefulWidget {
  const PresupuestosScreen({super.key});
  @override
  State<PresupuestosScreen> createState() => _PresupuestosScreenState();
}

class _PresupuestosScreenState extends State<PresupuestosScreen> {
  List<Presupuesto> _presupuestos = [];
  List<Movimiento> _movimientos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final resultados = await Future.wait([
      PresupuestosService.obtenerTodos(),
      MovimientosService.obtenerTodos(),
    ]);
    _presupuestos = resultados[0] as List<Presupuesto>;
    _movimientos = resultados[1] as List<Movimiento>;
    setState(() => _cargando = false);
  }

  double _gastadoEnCategoria(String categoria) {
    final ahora = DateTime.now();
    return _movimientos
        .where((m) =>
            m.tipo == 'Gasto' &&
            m.categoria == categoria &&
            m.fecha.month == ahora.month &&
            m.fecha.year == ahora.year)
        .fold(0.0, (s, m) => s + m.monto);
  }

  Future<void> _abrirFormulario() async {
    final categoriaCtrl = TextEditingController();
    final limiteCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.onyx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nuevo presupuesto', style: AppText.subheading),
            const SizedBox(height: 4),
            Text('Si la categoría ya existe, se actualiza su límite.', style: AppText.caption),
            const SizedBox(height: 16),
            TextField(
              controller: categoriaCtrl,
              style: AppText.body.copyWith(color: AppColors.bone, fontSize: 15),
              decoration: const InputDecoration(hintText: 'Categoría (ej. Comida)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: limiteCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              style: AppText.body.copyWith(color: AppColors.bone, fontSize: 15),
              decoration: const InputDecoration(hintText: 'Límite mensual'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final limite = CurrencyInputFormatter.parse(limiteCtrl.text);
                  if (categoriaCtrl.text.trim().isEmpty || limite <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Completa categoría y un límite válido')),
                    );
                    return;
                  }
                  try {
                    await PresupuestosService.guardar(Presupuesto(
                      categoria: categoriaCtrl.text.trim(),
                      limiteMensual: limite,
                    ));
                    if (ctx.mounted) Navigator.pop(ctx);
                    _cargar();
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formato = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Presupuestos')),
      drawer: AppDrawer(actual: DrawerRuta.presupuestos),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.copper,
        onPressed: _abrirFormulario,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _presupuestos.isEmpty
              ? Center(child: Text('Aún no tienes presupuestos definidos', style: AppText.body))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _presupuestos.length,
                  itemBuilder: (ctx, i) {
                    final p = _presupuestos[i];
                    final gastado = _gastadoEnCategoria(p.categoria);
                    final pct = p.limiteMensual > 0 ? gastado / p.limiteMensual : 0.0;
                    final excedido = pct > 1.0;
                    final color = excedido
                        ? Colors.redAccent
                        : (pct > 0.8 ? AppColors.copper : AppColors.bone);

                    return Dismissible(
                      key: ValueKey(p.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.redAccent),
                      ),
                      onDismissed: (_) => PresupuestosService.eliminar(p.id!),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.graphite),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(p.categoria, style: AppText.bodyStrong.copyWith(fontSize: 15)),
                                Text(
                                  '${formato.format(gastado)} / ${formato.format(p.limiteMensual)}',
                                  style: AppText.caption,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: pct.clamp(0, 1)),
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.easeOutCubic,
                                builder: (context, valorAnimado, _) => LinearProgressIndicator(
                                  value: valorAnimado,
                                  minHeight: 8,
                                  backgroundColor: AppColors.graphite,
                                  valueColor: AlwaysStoppedAnimation(color),
                                ),
                              ),
                            ),
                            if (excedido) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Te pasaste ${formato.format(gastado - p.limiteMensual)} del límite',
                                style: AppText.caption.copyWith(color: Colors.redAccent),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}