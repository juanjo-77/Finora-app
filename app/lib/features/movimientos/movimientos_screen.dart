import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_input_formatter.dart';
import '../../core/widgets/app_drawer.dart';
import 'movimiento.dart';
import 'movimientos_service.dart';
import 'recibo_service.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});
  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  List<Movimiento> _movimientos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    _movimientos = await MovimientosService.obtenerTodos();
    setState(() => _cargando = false);
  }

  Future<void> _elegirFuenteYEscanear() async {
    final fuente = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.onyx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.copper),
              title: Text('Tomar foto', style: AppText.body.copyWith(color: AppColors.bone, fontSize: 15)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined, color: AppColors.copper),
              title: Text('Subir imagen', style: AppText.body.copyWith(color: AppColors.bone, fontSize: 15)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (fuente == null) return;

    final picker = ImagePicker();
    final archivo = await picker.pickImage(source: fuente, imageQuality: 80, maxWidth: 1600);
    if (archivo == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.copper)),
    );

    try {
      final bytes = await archivo.readAsBytes();
      final datos = await ReciboService.escanear(bytes);
      if (mounted) Navigator.pop(context); // cierra el loading
      if (!mounted) return;
      _abrirFormulario(
        borrador: Movimiento(
          tipo: 'Gasto',
          categoria: datos.categoria,
          monto: datos.monto,
          fecha: datos.fecha,
          nota: datos.comercio,
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _abrirFormulario({Movimiento? existente, Movimiento? borrador}) async {
    final base = existente ?? borrador;
    final categoriaCtrl = TextEditingController(text: base?.categoria ?? '');
    final montoCtrl = TextEditingController(
      text: base != null ? NumberFormat.decimalPattern('es_CO').format(base.monto) : '',
    );
    String tipo = base?.tipo ?? 'Gasto';
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
              Text(
                editando ? 'Editar movimiento' : (borrador != null ? 'Confirma los datos del recibo' : 'Nuevo movimiento'),
                style: AppText.subheading,
              ),
              if (borrador?.nota != null) ...[
                const SizedBox(height: 4),
                Text('Detectado: ${borrador!.nota}', style: AppText.caption),
              ],
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: ChoiceChip(
                  label: const Text('Gasto'),
                  selected: tipo == 'Gasto',
                  onSelected: (_) => setModalState(() => tipo = 'Gasto'),
                )),
                const SizedBox(width: 8),
                Expanded(child: ChoiceChip(
                  label: const Text('Ingreso'),
                  selected: tipo == 'Ingreso',
                  onSelected: (_) => setModalState(() => tipo = 'Ingreso'),
                )),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: categoriaCtrl,
                style: AppText.body.copyWith(color: AppColors.bone, fontSize: 15),
                decoration: const InputDecoration(hintText: 'Categoría (ej. Comida)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: montoCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                style: AppText.body.copyWith(color: AppColors.bone, fontSize: 15),
                decoration: const InputDecoration(hintText: 'Monto'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final monto = CurrencyInputFormatter.parse(montoCtrl.text);
                    if (monto <= 0 || categoriaCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Completa categoría y un monto válido')),
                      );
                      return;
                    }
                    try {
                      final nuevo = Movimiento(
                        id: existente?.id,
                        tipo: tipo,
                        categoria: categoriaCtrl.text.trim(),
                        monto: monto,
                        fecha: (existente?.fecha ?? borrador?.fecha ?? DateTime.now()).toUtc(),
                      );
                      if (editando) {
                        await MovimientosService.actualizar(existente!.id!, nuevo);
                      } else {
                        await MovimientosService.crear(nuevo);
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
      appBar: AppBar(title: const Text('Movimientos')),
      drawer: AppDrawer(actual: DrawerRuta.movimientos),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'escanear',
            backgroundColor: AppColors.carbon,
            foregroundColor: AppColors.bone,
            onPressed: _elegirFuenteYEscanear,
            child: const Icon(Icons.document_scanner_outlined),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'agregar',
            backgroundColor: AppColors.copper,
            onPressed: () => _abrirFormulario(),
            child: const Icon(Icons.add, color: Colors.black),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _movimientos.isEmpty
              ? Center(child: Text('Aún no tienes movimientos', style: AppText.body))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _movimientos.length,
                  itemBuilder: (ctx, i) {
                    final m = _movimientos[i];
                    final esGasto = m.tipo == 'Gasto';
                    return Dismissible(
                      key: ValueKey(m.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.redAccent),
                      ),
                      onDismissed: (_) => MovimientosService.eliminar(m.id!),
                      child: InkWell(
                        onTap: () => _abrirFormulario(existente: m),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.graphite),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.categoria, style: AppText.bodyStrong),
                                  Text(DateFormat('d MMM', 'es').format(m.fecha), style: AppText.caption),
                                ],
                              ),
                              Text(
                                '${esGasto ? '-' : '+'}${formato.format(m.monto)}',
                                style: AppText.bodyStrong.copyWith(
                                  color: esGasto ? AppColors.bone : AppColors.copper,
                                ),
                              ),
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