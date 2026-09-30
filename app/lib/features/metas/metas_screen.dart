import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_input_formatter.dart';
import '../../core/widgets/app_drawer.dart';
import 'meta.dart';
import 'metas_service.dart';

class MetasScreen extends StatefulWidget {
  const MetasScreen({super.key});
  @override
  State<MetasScreen> createState() => _MetasScreenState();
}

class _MetasScreenState extends State<MetasScreen> {
  List<Meta> _metas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    _metas = await MetasService.obtenerTodas();
    setState(() => _cargando = false);
  }

  Future<void> _abrirFormulario({Meta? existente}) async {
    final nombreCtrl = TextEditingController(text: existente?.nombre ?? '');
    final objetivoCtrl = TextEditingController(
      text: existente != null ? NumberFormat.decimalPattern('es_CO').format(existente.montoObjetivo) : '',
    );
    final ahorradoCtrl = TextEditingController(
      text: existente != null ? NumberFormat.decimalPattern('es_CO').format(existente.montoAhorrado) : '0',
    );
    final mensualCtrl = TextEditingController(
      text: existente != null ? NumberFormat.decimalPattern('es_CO').format(existente.ahorroMensualPlaneado) : '',
    );
    final editando = existente != null;

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(editando ? 'Editar meta' : 'Nueva meta', style: AppText.subheading),
              const SizedBox(height: 16),
              TextField(
                controller: nombreCtrl,
                style: AppText.body.copyWith(color: AppColors.bone, fontSize: 15),
                decoration: const InputDecoration(hintText: 'Nombre (ej. Fondo de emergencia)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: objetivoCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                style: AppText.body.copyWith(color: AppColors.bone, fontSize: 15),
                decoration: const InputDecoration(hintText: 'Monto objetivo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ahorradoCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                style: AppText.body.copyWith(color: AppColors.bone, fontSize: 15),
                decoration: const InputDecoration(hintText: 'Ya tienes ahorrado (opcional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mensualCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                style: AppText.body.copyWith(color: AppColors.bone, fontSize: 15),
                decoration: const InputDecoration(hintText: 'Cuánto planeas ahorrar al mes (opcional)'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                onPressed: () async {
                  final objetivo = CurrencyInputFormatter.parse(objetivoCtrl.text);
                  final ahorrado = CurrencyInputFormatter.parse(ahorradoCtrl.text);
                  final mensual = CurrencyInputFormatter.parse(mensualCtrl.text);
                  if (nombreCtrl.text.trim().isEmpty || objetivo <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Completa nombre y monto objetivo')),
                    );
                    return;
                  }
                  if (ahorrado > objetivo) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lo ahorrado no puede superar el monto objetivo')),
                    );
                    return;
                  }
                  try {
                    final nueva = Meta(
                      id: existente?.id,
                      nombre: nombreCtrl.text.trim(),
                      montoObjetivo: objetivo,
                      montoAhorrado: ahorrado,
                      ahorroMensualPlaneado: mensual,
                    );
                    if (editando) {
                      await MetasService.actualizar(existente!.id!, nueva);
                    } else {
                      await MetasService.crear(nueva);
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

  @override
  Widget build(BuildContext context) {
    final formato = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Metas financieras')),
      drawer: AppDrawer(actual: DrawerRuta.metas),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.copper,
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _metas.isEmpty
              ? Center(child: Text('Aún no tienes metas definidas', style: AppText.body))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _metas.length,
                  itemBuilder: (ctx, i) {
                    final m = _metas[i];
                    final cumplida = m.progreso >= 1.0;

                    return Dismissible(
                      key: ValueKey(m.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.redAccent),
                      ),
                      onDismissed: (_) => MetasService.eliminar(m.id!),
                      child: InkWell(
                        onTap: () => _abrirFormulario(existente: m),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: cumplida ? AppColors.copper : AppColors.graphite),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(m.nombre, style: AppText.bodyStrong.copyWith(fontSize: 15)),
                                      if (cumplida) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.check_circle, size: 16, color: AppColors.copper),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '${(m.progreso * 100).toStringAsFixed(0)}%',
                                    style: AppText.bodyStrong.copyWith(
                                      color: cumplida ? AppColors.copper : AppColors.bone,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${formato.format(m.montoAhorrado)} / ${formato.format(m.montoObjetivo)}',
                                style: AppText.caption,
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: m.progreso.toDouble()),
                                  duration: const Duration(milliseconds: 700),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, valorAnimado, _) => LinearProgressIndicator(
                                    value: valorAnimado,
                                    minHeight: 8,
                                    backgroundColor: AppColors.graphite,
                                    valueColor: AlwaysStoppedAnimation(
                                      cumplida ? AppColors.copper : AppColors.silver,
                                    ),
                                  ),
                                ),
                              ),
                              if (!cumplida && m.mesesEstimados != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Ahorrando ${formato.format(m.ahorroMensualPlaneado)}/mes, la alcanzas en '
                                  '${m.mesesEstimados} ${m.mesesEstimados == 1 ? 'mes' : 'meses'}',
                                  style: AppText.caption.copyWith(color: AppColors.fog),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}