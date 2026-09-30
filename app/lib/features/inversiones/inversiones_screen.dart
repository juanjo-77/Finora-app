import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_input_formatter.dart';
import '../../core/widgets/app_drawer.dart';
import 'inversion.dart';
import 'inversiones_service.dart';

class InversionesScreen extends StatefulWidget {
  const InversionesScreen({super.key});
  @override
  State<InversionesScreen> createState() => _InversionesScreenState();
}

class _InversionesScreenState extends State<InversionesScreen> {
  List<Inversion> _inversiones = [];
  bool _cargando = true;

  static const _tipos = ['Acciones', 'ETF', 'Fondo', 'CDT', 'Cripto', 'Otro'];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    _inversiones = await InversionesService.obtenerTodas();
    setState(() => _cargando = false);
  }

  Future<void> _abrirFormulario({Inversion? existente}) async {
    final nombreCtrl = TextEditingController(text: existente?.nombre ?? '');
    final invertidoCtrl = TextEditingController(
      text: existente != null ? NumberFormat.decimalPattern('es_CO').format(existente.montoInvertido) : '',
    );
    final actualCtrl = TextEditingController(
      text: existente != null ? NumberFormat.decimalPattern('es_CO').format(existente.valorActual) : '',
    );
    String tipo = existente?.tipo ?? _tipos.first;
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
              Text(editando ? 'Editar inversión' : 'Nueva inversión', style: AppText.subheading),
              const SizedBox(height: 16),
              TextField(
                controller: nombreCtrl,
                style: AppText.body.copyWith(color: AppColors.bone, fontSize: 15),
                decoration: const InputDecoration(hintText: 'Nombre (ej. S&P 500)'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tipos.map((t) => ChoiceChip(
                  label: Text(t),
                  selected: tipo == t,
                  onSelected: (_) => setModalState(() => tipo = t),
                )).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: invertidoCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                style: AppText.body.copyWith(color: AppColors.bone, fontSize: 15),
                decoration: const InputDecoration(hintText: 'Monto invertido (total aportado)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: actualCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                style: AppText.body.copyWith(color: AppColors.bone, fontSize: 15),
                decoration: const InputDecoration(hintText: 'Valor actual'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final invertido = CurrencyInputFormatter.parse(invertidoCtrl.text);
                    final actual = CurrencyInputFormatter.parse(actualCtrl.text);
                    if (nombreCtrl.text.trim().isEmpty || invertido <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Completa nombre y monto invertido')),
                      );
                      return;
                    }
                    try {
                      final nueva = Inversion(
                        id: existente?.id,
                        nombre: nombreCtrl.text.trim(),
                        tipo: tipo,
                        montoInvertido: invertido,
                        valorActual: actual,
                      );
                      if (editando) {
                        await InversionesService.actualizar(existente!.id!, nueva);
                      } else {
                        await InversionesService.crear(nueva);
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
    final totalInvertido = _inversiones.fold(0.0, (s, i) => s + i.montoInvertido);
    final totalActual = _inversiones.fold(0.0, (s, i) => s + i.valorActual);
    final rentabilidadTotal = totalActual - totalInvertido;

    return Scaffold(
      appBar: AppBar(title: const Text('Inversiones')),
      drawer: AppDrawer(actual: DrawerRuta.inversiones),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.copper,
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _inversiones.isEmpty
              ? Center(child: Text('Aún no tienes inversiones registradas', style: AppText.body))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.onyx,
                        border: Border.all(color: AppColors.graphite),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('VALOR TOTAL', style: AppText.eyebrow.copyWith(color: AppColors.fog)),
                              const SizedBox(height: 4),
                              Text(formato.format(totalActual), style: AppText.statNumber.copyWith(fontSize: 28)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('RENTABILIDAD', style: AppText.eyebrow.copyWith(color: AppColors.fog)),
                              const SizedBox(height: 4),
                              Text(
                                '${rentabilidadTotal >= 0 ? '+' : ''}${formato.format(rentabilidadTotal)}',
                                style: AppText.bodyStrong.copyWith(
                                  fontSize: 16,
                                  color: rentabilidadTotal >= 0 ? AppColors.copper : Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._inversiones.map((i) => Dismissible(
                      key: ValueKey(i.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.redAccent),
                      ),
                      onDismissed: (_) => InversionesService.eliminar(i.id!),
                      child: InkWell(
                        onTap: () => _abrirFormulario(existente: i),
                        borderRadius: BorderRadius.circular(10),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(i.nombre, style: AppText.bodyStrong),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppColors.steel),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(i.tipo, style: AppText.caption.copyWith(fontSize: 10)),
                                      ),
                                    ],
                                  ),
                                  Text(formato.format(i.valorActual), style: AppText.bodyStrong),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${i.rentabilidad >= 0 ? '+' : ''}${formato.format(i.rentabilidad)} '
                                '(${i.rentabilidadPct >= 0 ? '+' : ''}${i.rentabilidadPct.toStringAsFixed(1)}%)',
                                style: AppText.caption.copyWith(
                                  color: i.rentabilidad >= 0 ? AppColors.copper : Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
    );
  }
}