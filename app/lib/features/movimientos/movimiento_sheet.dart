import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/data_bus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/feedback.dart';
import '../../core/widgets/grabado.dart';
import 'movimiento.dart';
import 'movimientos_service.dart';
import 'recibo_service.dart';

const _categoriasBase = ['Comida', 'Transporte', 'Hogar', 'Ocio', 'Salud', 'Otros'];
const _maxDigitos = 12; // hasta 999.999.999.999

/// Abre el registro de un movimiento. Si se guarda, avisa a las pantallas
/// y devuelve el movimiento.
Future<MovimientoGuardado?> abrirRegistro(
  BuildContext context, {
  Movimiento? existente,
  Movimiento? borrador,
  String tipoInicial = 'Gasto',
  List<String>? categoriasUsadas,
}) async {
  final usadas = categoriasUsadas ?? DataBus.categorias;
  final guardado = await showModalBottomSheet<MovimientoGuardado>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _RegistroSheet(
      existente: existente,
      borrador: borrador,
      tipoInicial: tipoInicial,
      categoriasUsadas: usadas,
    ),
  );
  if (guardado != null) DataBus.avisar(guardado);
  return guardado;
}

/// Toma o elige la foto de un recibo, la lee y abre el registro con los datos.
Future<void> escanearRecibo(BuildContext context) async {
  final fuente = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const LineIcon(Trazo.escanear, color: AppColors.gold),
            title: Text('Tomar foto del recibo', style: AppText.bodyStrong),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const LineIcon(Trazo.subir, color: AppColors.gold),
            title: Text('Subir una imagen', style: AppText.bodyStrong),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ]),
      ),
    ),
  );
  if (fuente == null || !context.mounted) return;

  final archivo = await ImagePicker().pickImage(source: fuente, imageQuality: 80, maxWidth: 1600);
  if (archivo == null || !context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    final datos = await ReciboService.escanear(await archivo.readAsBytes());
    if (!context.mounted) return;
    Navigator.pop(context);
    await abrirRegistro(
      context,
      borrador: Movimiento(
        tipo: 'Gasto',
        categoria: datos.categoria,
        monto: datos.monto,
        fecha: datos.fecha,
        nota: datos.comercio,
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.pop(context);
    mostrarError(context, e, 'No pudimos leer el recibo. Intenta con una foto más nítida.');
  }
}

class _RegistroSheet extends StatefulWidget {
  final Movimiento? existente, borrador;
  final String tipoInicial;
  final List<String> categoriasUsadas;
  const _RegistroSheet({this.existente, this.borrador, required this.tipoInicial, required this.categoriasUsadas});
  @override
  State<_RegistroSheet> createState() => _RegistroSheetState();
}

class _RegistroSheetState extends State<_RegistroSheet> with SingleTickerProviderStateMixin {
  final _montoKey = GlobalKey();
  final _otraCtrl = TextEditingController();
  late final _temblor = AnimationController(vsync: this, duration: const Duration(milliseconds: 340));
  final _foco = FocusNode();
  late String _tipo;
  late String _digitos;
  late List<String> _categorias;
  String? _categoria;
  bool _otra = false;
  bool _guardando = false;
  String? _error;

  Movimiento? get _base => widget.existente ?? widget.borrador;

  @override
  void initState() {
    super.initState();
    _tipo = _base?.tipo ?? widget.tipoInicial;
    _digitos = _base != null && _base!.monto > 0 ? _base!.monto.round().toString() : '';
    _categorias = {..._categoriasBase, ...widget.categoriasUsadas.map((c) => c.trim()).where((c) => c.isNotEmpty)}.toList();
    final actual = _base?.categoria.trim();
    if (actual != null && actual.isNotEmpty) {
      if (!_categorias.contains(actual)) _categorias.insert(0, actual);
      _categoria = actual;
    } else {
      _categoria = _categorias.first;
    }
  }

  @override
  void dispose() {
    _otraCtrl.dispose();
    _temblor.dispose();
    _foco.dispose();
    super.dispose();
  }

  double get _monto => _digitos.isEmpty ? 0 : double.parse(_digitos);

  void _tecla(String t) {
    HapticFeedback.selectionClick();
    setState(() {
      _error = null;
      if (t == '<') {
        if (_digitos.isNotEmpty) _digitos = _digitos.substring(0, _digitos.length - 1);
      } else {
        _digitos = (_digitos + t).replaceFirst(RegExp(r'^0+'), '');
        if (_digitos.length > _maxDigitos) _digitos = _digitos.substring(0, _maxDigitos);
      }
    });
  }

  void _fallo(String mensaje) {
    HapticFeedback.heavyImpact();
    setState(() => _error = mensaje);
    if (!sinAnimaciones(context)) _temblor.forward(from: 0);
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    final categoria = (_otra ? _otraCtrl.text : _categoria ?? '').trim();
    if (_monto <= 0) return _fallo('Escribe un monto mayor a cero');
    if (categoria.isEmpty) return _fallo('Escribe el nombre de la categoría');
    if (categoria.length > 40) return _fallo('El nombre de la categoría es muy largo');

    setState(() => _guardando = true);
    final origen = rectGlobal(_montoKey);
    final editando = widget.existente != null;
    final nuevo = Movimiento(
      id: widget.existente?.id,
      tipo: _tipo,
      categoria: categoria,
      monto: _monto,
      fecha: (widget.existente?.fecha ?? widget.borrador?.fecha ?? DateTime.now()).toUtc(),
      nota: _base?.nota,
    );
    try {
      final Movimiento resultado;
      if (editando) {
        await MovimientosService.actualizar(widget.existente!.id!, nuevo);
        resultado = nuevo;
      } else {
        resultado = await MovimientosService.crear(nuevo);
      }
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context, MovimientoGuardado(resultado, editando ? null : origen));
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _fallo(mensajeDeError(e, 'No se pudo guardar. Revisa tu conexión e intenta de nuevo.'));
    }
  }

  KeyEventResult _teclado(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent || _otra) return KeyEventResult.ignored;
    final c = e.character;
    if (c != null && RegExp(r'^\d$').hasMatch(c)) {
      _tecla(c);
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.backspace) {
      _tecla('<');
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.enter) {
      _guardar();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.existente != null;
    final ingreso = _tipo == 'Ingreso';
    final titulo = editando
        ? 'Editar movimiento'
        : widget.borrador != null
            ? 'Revisa lo que leímos del recibo'
            : null;

    return Focus(
      focusNode: _foco,
      autofocus: true,
      onKeyEvent: _teclado,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (titulo != null) ...[
              Text(titulo, style: AppText.subheading.copyWith(fontSize: 15), textAlign: TextAlign.center),
              if (widget.borrador?.nota != null)
                Text('Comercio: ${widget.borrador!.nota}', style: AppText.caption),
              const SizedBox(height: 12),
            ],
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final t in const ['Ingreso', 'Gasto'])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _Pastilla(
                    texto: t,
                    activa: _tipo == t,
                    alTocar: () => setState(() {
                      _tipo = t;
                      _error = null;
                    }),
                  ),
                ),
            ]),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _temblor,
              builder: (context, child) {
                final t = _temblor.value;
                final dx = math.sin(t * math.pi * 4) * 9 * (1 - t);
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: TweenAnimationBuilder<double>(
                key: ValueKey(_digitos),
                tween: Tween(begin: _digitos.isEmpty ? 1 : 1.06, end: 1),
                duration: const Duration(milliseconds: 140),
                curve: AppTheme.ease,
                builder: (context, s, child) => Transform.scale(scale: s, child: child),
                child: FittedBox(
                  key: _montoKey,
                  fit: BoxFit.scaleDown,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: AppText.display.copyWith(
                      color: _monto == 0 ? AppColors.dust : (ingreso ? AppColors.goldHi : AppColors.ivory),
                    ),
                    child: Text(pesos(_monto), maxLines: 1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 20,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _error == null
                    ? const SizedBox.shrink()
                    : Text(_error!, key: ValueKey(_error), style: AppText.caption.copyWith(color: AppColors.ember, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final c in _categorias)
                    _Etiqueta(
                      texto: c,
                      activa: !_otra && _categoria == c,
                      alTocar: () => setState(() {
                        _categoria = c;
                        _otra = false;
                        _error = null;
                      }),
                    ),
                  _Etiqueta(
                    texto: 'Otra',
                    activa: _otra,
                    alTocar: () => setState(() {
                      _otra = true;
                      _error = null;
                    }),
                  ),
                ],
              ),
            ),
            Fold(
              visible: _otra,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextField(
                  controller: _otraCtrl,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppText.bodyStrong,
                  decoration: const InputDecoration(hintText: 'Nombre de la categoría', counterText: ''),
                  onChanged: (_) => setState(() => _error = null),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.4,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                for (final t in const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '000', '0', '<'])
                  _Tecla(texto: t, alTocar: () => _tecla(t)),
              ],
            ),
            const SizedBox(height: 10),
            BotonOro(
              texto: editando ? 'Guardar cambios' : 'Guardar ${_tipo.toLowerCase()}',
              cargando: _guardando,
              alTocar: _guardar,
            ),
          ]),
        ),
      ),
    );
  }
}

class _Pastilla extends StatelessWidget {
  final String texto;
  final bool activa;
  final VoidCallback alTocar;
  const _Pastilla({required this.texto, required this.activa, required this.alTocar});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: alTocar,
        borderRadius: BorderRadius.circular(99),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: activa ? AppColors.gold : AppColors.seam),
          ),
          child: Text(texto, style: AppText.bodyStrong.copyWith(fontSize: 13, color: activa ? AppColors.goldHi : AppColors.sand)),
        ),
      );
}

class _Etiqueta extends StatelessWidget {
  final String texto;
  final bool activa;
  final VoidCallback alTocar;
  const _Etiqueta({required this.texto, required this.activa, required this.alTocar});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          onTap: alTocar,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.vault2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: activa ? AppColors.gold : Colors.transparent),
            ),
            child: Text(texto, style: AppText.bodyStrong.copyWith(fontSize: 13, color: activa ? AppColors.ivory : AppColors.sand)),
          ),
        ),
      );
}

class _Tecla extends StatelessWidget {
  final String texto;
  final VoidCallback alTocar;
  const _Tecla({required this.texto, required this.alTocar});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: alTocar,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.vault2,
          highlightColor: AppColors.vault2,
          child: Center(
            child: texto == '<'
                ? Semantics(label: 'Borrar', child: const Icon(Icons.backspace_outlined, size: 20, color: AppColors.ivory))
                : Text(texto, style: AppText.statNumber.copyWith(fontSize: 20, fontWeight: FontWeight.w400)),
          ),
        ),
      );
}

/// Botón principal en oro.
class BotonOro extends StatelessWidget {
  final String texto;
  final VoidCallback? alTocar;
  final bool cargando;
  const BotonOro({super.key, required this.texto, this.alTocar, this.cargando = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.goldButton, borderRadius: BorderRadius.circular(18)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: cargando ? null : alTocar,
              borderRadius: BorderRadius.circular(18),
              child: Center(
                child: cargando
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text(texto, style: AppText.bodyStrong.copyWith(color: Colors.black, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ),
      );
}
