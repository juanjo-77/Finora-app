import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_input_formatter.dart';
import '../../core/widgets/app_drawer.dart';
import 'deuda.dart';
import 'deudas_service.dart';

class DeudasScreen extends StatefulWidget {
  const DeudasScreen({super.key});
  @override
  State<DeudasScreen> createState() => _DeudasScreenState();
}

class _DeudasScreenState extends State<DeudasScreen> {
  List<Deuda> _deudas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    _deudas = await DeudasService.obtenerTodas();
    setState(() => _cargando = false);
  }

  Future<void> _abrirFormulario({Deuda? existente}) async {
    final nombreCtrl = TextEditingController(text: existente?.nombre ?? '');
    final totalCtrl = TextEditingController(
      text: existente != null ? NumberFormat.decimalPattern('es_CO').format(existente.montoTotal) : '',
    );
    final cuotaCtrl = TextEditingController(
      text: existente != null ? NumberFormat.decimalPattern('es_CO').format(existente.cuotaMensual) : '',
    );
    DateTime fecha = existente?.proximaFecha ?? DateTime.now().add(const Duration(days: 30));
    final editando = existente != null;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.onyx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(editando ? 'Editar deuda' : 'Nueva deuda', style: AppText.subheading),
              const SizedBox(height: 16),
              TextField(
                controller: nombreCtrl,
                style: AppText.body.copyWith(color: AppColors.bone, fontSize: 15),
                decoration: const InputDecoration(hintText: 'Nombre (ej. Tarjeta de crédito)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: totalCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                style: AppText.body.copyWith(color: AppColors.bone, fontSize: 15),
                decoration: const InputDecoration(hintText: 'Monto total restante'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cuotaCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                style: AppText.body.copyWith(color: AppColors.bone, fontSize: 15),
                decoration: const InputDecoration(hintText: 'Cuota mensual'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Próximo pago:', style: AppText.body.copyWith(fontSize: 14)),
                  TextButton(
                    onPressed: () async {
                      final seleccionada = await showDatePicker(
                        context: ctx,
                        initialDate: fecha,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (seleccionada != null) setModalState(() => fecha = seleccionada);
                    },
                    child: Text(DateFormat('d MMM yyyy', 'es').format(fecha),
                        style: AppText.bodyStrong.copyWith(color: AppColors.copper)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final total = CurrencyInputFormatter.parse(totalCtrl.text);
                    final cuota = CurrencyInputFormatter.parse(cuotaCtrl.text);
                    if (nombreCtrl.text.trim().isEmpty || total <= 0 || cuota <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Completa todos los campos')),
                      );
                      return;
                    }
                    try {
                      final nueva = Deuda(
                        id: existente?.id,
                        nombre: nombreCtrl.text.trim(),
                        montoTotal: total,
                        cuotaMensual: cuota,
                        proximaFecha: fecha.toUtc(),
                      );
                      if (editando) {
                        await DeudasService.actualizar(existente!.id!, nueva);
                      } else {
                        await DeudasService.crear(nueva);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      _cargar();
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: Text(editando ? 'Guardar cambios' : 'Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirAbono(Deuda d) async {
    final montoCtrl = TextEditingController();

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
            Text('Abonar a ${d.nombre}', style: AppText.subheading),
            const SizedBox(height: 4),
            Text(
              'Saldo actual: ${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(d.montoTotal)}',
              style: AppText.caption,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: montoCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              style: AppText.body.copyWith(color: AppColors.bone, fontSize: 15),
              decoration: const InputDecoration(hintText: 'Monto del abono'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final monto = CurrencyInputFormatter.parse(montoCtrl.text);
                  if (monto <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ingresa un monto válido')),
                    );
                    return;
                  }
                  if (monto > d.montoTotal) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(
                        'El abono no puede superar el saldo pendiente '
                        '(${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(d.montoTotal)})',
                      )),
                    );
                    return;
                  }
                  try {
                    await DeudasService.abonar(d.id!, monto);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _cargar();
                    if (context.mounted && monto >= d.montoTotal) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('🎉 ${d.nombre} quedó saldada')),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('Abonar'),
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
      appBar: AppBar(title: const Text('Deudas y pagos')),
      drawer: AppDrawer(actual: DrawerRuta.deudas),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.copper,
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _deudas.isEmpty
              ? Center(child: Text('No tienes deudas o pagos pendientes registrados', style: AppText.body))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _deudas.length,
                  itemBuilder: (ctx, i) {
                    final d = _deudas[i];
                    return Dismissible(
                      key: ValueKey(d.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.redAccent),
                      ),
                      onDismissed: (_) => DeudasService.eliminar(d.id!),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.graphite),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => _abrirFormulario(existente: d),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(d.nombre, style: AppText.bodyStrong),
                                  Text(formato.format(d.cuotaMensual),
                                      style: AppText.bodyStrong.copyWith(color: AppColors.copper)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Próximo pago: ${DateFormat('d MMM', 'es').format(d.proximaFecha)} · Total restante: ${formato.format(d.montoTotal)}',
                              style: AppText.caption,
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _abrirAbono(d),
                                icon: const Icon(Icons.payments_outlined, size: 16),
                                label: const Text('Abonar'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  textStyle: AppText.bodyStrong.copyWith(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}