import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Piezas visuales del diseño "Grabado".

final _pesos = NumberFormat('\$#,##0', 'es_CO');
String pesos(double n) => _pesos.format(n);

/// $6.200.000 -> "$6,2 M" para espacios angostos.
String pesosCortos(double n) {
  if (n.abs() < 1e6) return pesos(n);
  final m = NumberFormat('#,##0.##', 'es_CO').format(n.abs() / 1e6);
  return '${n < 0 ? '-' : ''}\$$m M';
}

bool sinAnimaciones(BuildContext context) => MediaQuery.of(context).disableAnimations;

// ---------------------------------------------------------------------------
// Aparición escalonada (solo en la secuencia de apertura)
// ---------------------------------------------------------------------------

class Rise extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const Rise({super.key, required this.child, this.delay = Duration.zero});
  @override
  State<Rise> createState() => _RiseState();
}

class _RiseState extends State<Rise> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (sinAnimaciones(context)) return widget.child;
    final t = CurvedAnimation(parent: _c, curve: AppTheme.ease);
    return FadeTransition(
      opacity: t,
      child: AnimatedBuilder(
        animation: t,
        builder: (_, child) => Transform.translate(offset: Offset(0, 14 * (1 - t.value)), child: child),
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Odómetro: cada dígito gira desde su valor anterior al nuevo
// ---------------------------------------------------------------------------

class RollingAmount extends StatefulWidget {
  final double value;
  final TextStyle style;
  final String Function(double) format;
  /// En la apertura los dígitos dan una vuelta completa.
  final bool spin;
  final Duration delay;
  /// Al terminar de girar, un brillo de oro recorre la cifra.
  final bool metal;

  const RollingAmount({
    super.key,
    required this.value,
    required this.style,
    this.format = pesos,
    this.spin = false,
    this.delay = Duration.zero,
    this.metal = false,
  });

  @override
  State<RollingAmount> createState() => _RollingAmountState();
}

class _RollingAmountState extends State<RollingAmount> with TickerProviderStateMixin {
  static const _rollMs = 1500, _staggerMs = 45;
  late final _roll = AnimationController(vsync: this, duration: const Duration(milliseconds: _rollMs));
  late final _shine = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  late String _from, _to;
  late bool _spin;

  @override
  void initState() {
    super.initState();
    _from = widget.format(0);
    _to = widget.format(widget.value);
    _spin = widget.spin;
    Future.delayed(widget.delay, () {
      if (mounted) _start();
    });
  }

  @override
  void didUpdateWidget(RollingAmount old) {
    super.didUpdateWidget(old);
    final nuevo = widget.format(widget.value);
    if (nuevo != _to) {
      _from = _to;
      _to = nuevo;
      _spin = false;
      _start();
    }
  }

  void _start() {
    final digitos = _to.replaceAll(RegExp(r'\D'), '').length;
    _roll.duration = Duration(milliseconds: _rollMs + digitos * _staggerMs);
    _shine.value = 0;
    _roll.forward(from: 0).whenComplete(() {
      if (mounted && widget.metal) _shine.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _roll.dispose();
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducido = sinAnimaciones(context);
    final style = widget.style.copyWith(fontFeatures: AppText.tabular);
    final texto = AnimatedBuilder(
      animation: _roll,
      builder: (context, _) {
        if (reducido || _roll.isCompleted || (!_roll.isAnimating && _roll.value == 0 && _from == _to)) {
          return Text(_to, style: style, maxLines: 1, softWrap: false);
        }
        return _columnas(style);
      },
    );
    if (!widget.metal || reducido) return texto;
    return AnimatedBuilder(
      animation: _shine,
      builder: (context, child) {
        if (_shine.value == 0) return child!;
        final p = 1 - AppTheme.ease.transform(_shine.value);
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (b) => AppColors.gildedGradient
              .createShader(Rect.fromLTWH(-1.5 * b.width * p, 0, 2.5 * b.width, b.height)),
          child: child,
        );
      },
      child: texto,
    );
  }

  Widget _columnas(TextStyle style) {
    final alto = (style.fontSize ?? 14) * (style.height ?? 1.15);
    final viejo = _from.padLeft(_to.length);
    final total = _roll.duration!.inMilliseconds * _roll.value;
    final chars = _to.split('');
    final digitos = chars.where((c) => RegExp(r'\d').hasMatch(c)).length;
    var k = 0;
    final hijos = <Widget>[];
    for (var i = 0; i < chars.length; i++) {
      final c = chars[i];
      final d = int.tryParse(c);
      if (d == null) {
        hijos.add(Text(c, style: style));
        continue;
      }
      final desdeDerecha = digitos - 1 - k++;
      final inicio = int.tryParse(viejo[i]) ?? 0;
      final meta = d + ((_spin || d < inicio) ? 10 : 0);
      final local = ((total - desdeDerecha * _staggerMs) / _rollMs).clamp(0.0, 1.0);
      final pos = inicio + (meta - inicio) * AppTheme.ease.transform(local);
      hijos.add(ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1 / 20,
          child: Transform.translate(
            offset: Offset(0, -pos * alto),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var n = 0; n < 20; n++)
                  SizedBox(height: alto, child: Text('${n % 10}', style: style.copyWith(height: style.height ?? 1.15))),
              ],
            ),
          ),
        ),
      ));
    }
    return Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: hijos);
  }
}

// ---------------------------------------------------------------------------
// Bóveda del saldo: grabado de billete que se dibuja, gira lento
// y se inclina con un reflejo dorado que sigue el dedo
// ---------------------------------------------------------------------------

class GuillocheVault extends StatefulWidget {
  final Widget child;
  final double height;
  const GuillocheVault({super.key, required this.child, this.height = 236});
  @override
  State<GuillocheVault> createState() => _GuillocheVaultState();
}

class _GuillocheVaultState extends State<GuillocheVault> with TickerProviderStateMixin {
  static const _anillos = 18;
  late final _dibujo = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700 + _anillos * 40));
  late final _giro = AnimationController(vsync: this, duration: const Duration(seconds: 160));
  Offset? _puntero; // 0..1 dentro de la tarjeta

  @override
  void initState() {
    super.initState();
    _dibujo.forward();
    _giro.repeat();
  }

  @override
  void dispose() {
    _dibujo.dispose();
    _giro.dispose();
    super.dispose();
  }

  void _mover(Offset local, Size size) {
    if (sinAnimaciones(context)) return;
    setState(() => _puntero = Offset(
          (local.dx / size.width).clamp(0.0, 1.0),
          (local.dy / size.height).clamp(0.0, 1.0),
        ));
  }

  void _soltar() => setState(() => _puntero = null);

  @override
  Widget build(BuildContext context) {
    final reducido = sinAnimaciones(context);
    if (reducido) {
      _dibujo.value = 1;
      _giro.stop();
    }
    final p = _puntero ?? const Offset(.5, .5);
    final vivo = _puntero != null;
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, widget.height);
      return MouseRegion(
        onHover: (e) => _mover(e.localPosition, size),
        onExit: (_) => _soltar(),
        child: GestureDetector(
          onPanDown: (e) => _mover(e.localPosition, size),
          onPanUpdate: (e) => _mover(e.localPosition, size),
          onPanEnd: (_) => _soltar(),
          onPanCancel: _soltar,
          child: TweenAnimationBuilder<Offset>(
            tween: Tween(end: p),
            duration: Duration(milliseconds: vivo ? 120 : 700),
            curve: AppTheme.ease,
            builder: (context, t, child) {
              final dx = t.dx - .5, dy = t.dy - .5;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0011)
                  ..rotateX(dy * -9 * math.pi / 180)
                  ..rotateY(dx * 11 * math.pi / 180),
                child: Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                      bottomLeft: Radius.circular(8),
                    ),
                    border: Border.all(color: AppColors.seam),
                    gradient: const RadialGradient(
                      center: Alignment(0.7, -0.8),
                      radius: 1.3,
                      colors: [Color(0xFF1D1810), Color(0xFF0A0806), Colors.black],
                      stops: [0, .55, 1],
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(children: [
                    Positioned(
                      right: -110 + dx * -18,
                      top: -90 + dy * -14,
                      width: 430,
                      height: 430,
                      child: RepaintBoundary(
                        child: CustomPaint(painter: _GuillochePainter(_dibujo, _giro, _anillos)),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: vivo ? 1 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment(t.dx * 2 - 1, t.dy * 2 - 1),
                                radius: .9,
                                colors: [AppColors.goldHi.withValues(alpha: .16), Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(child: child!),
                  ]),
                ),
              );
            },
            child: widget.child,
          ),
        ),
      );
    });
  }
}

class _GuillochePainter extends CustomPainter {
  final Animation<double> dibujo, giro;
  final int anillos;
  _GuillochePainter(this.dibujo, this.giro, this.anillos) : super(repaint: Listenable.merge([dibujo, giro]));

  static List<ui.PathMetric>? _cache;

  List<ui.PathMetric> _metricas() => _cache ??= List.generate(anillos, (k) {
        final path = Path();
        final r0 = 70 + k * 7.5;
        for (var i = 0; i <= 360; i++) {
          final t = i * math.pi / 180;
          final r = r0 + 9 * math.sin(12 * t + k * .55) + 4 * math.sin(5 * t - k * .3);
          final pt = Offset(r * math.cos(t), r * math.sin(t));
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        path.close();
        return path.computeMetrics().first;
      });

  @override
  void paint(Canvas canvas, Size size) {
    final trazo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .6
      ..color = AppColors.gold.withValues(alpha: .32);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(giro.value * 2 * math.pi);
    final ms = (dibujo.value * (1700 + anillos * 40));
    final metricas = _metricas();
    for (var k = 0; k < metricas.length; k++) {
      final local = ((ms - k * 40) / 1700).clamp(0.0, 1.0);
      if (local == 0) continue;
      final m = metricas[k];
      canvas.drawPath(m.extractPath(0, m.length * AppTheme.ease.transform(local)), trazo);
    }
  }

  @override
  bool shouldRepaint(covariant _GuillochePainter old) => false;
}

// ---------------------------------------------------------------------------
// Esfera de reloj para el puntaje financiero
// ---------------------------------------------------------------------------

class ScoreDial extends StatefulWidget {
  final int score; // 0..100
  final double size;
  final Duration delay;
  const ScoreDial({super.key, required this.score, this.size = 128, this.delay = const Duration(milliseconds: 1050)});
  @override
  State<ScoreDial> createState() => _ScoreDialState();
}

class _ScoreDialState extends State<ScoreDial> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  int _desde = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void didUpdateWidget(ScoreDial old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _desde = old.score;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducido = sinAnimaciones(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = reducido ? 1.0 : _c.value;
        // La aguja se pasa un poco y vuelve, como un reloj real.
        final aguja = const Cubic(.25, 1.12, .4, 1).transform(t);
        final marcas = Curves.easeOutCubic.transform(t);
        final valor = _desde + (widget.score - _desde) * marcas;
        return SizedBox.square(
          dimension: widget.size,
          child: CustomPaint(
            painter: _DialPainter(
              aguja: (_desde + (widget.score - _desde) * aguja) / 100,
              encendidas: valor / 100,
            ),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(height: 8),
                Text('${valor.round()}', style: AppText.statNumber.copyWith(fontSize: 26, fontWeight: FontWeight.w700)),
                Text('de 100', style: AppText.caption.copyWith(fontSize: 11)),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _DialPainter extends CustomPainter {
  final double aguja, encendidas;
  _DialPainter({required this.aguja, required this.encendidas});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 128;
    final c = Offset(size.width / 2, size.height / 2);
    const n = 41;
    for (var i = 0; i < n; i++) {
      final a = (-210 + i * 6) * math.pi / 180;
      final mayor = i % 5 == 0;
      final r1 = (mayor ? 50 : 53) * s, r2 = 59 * s;
      final on = i / (n - 1) <= encendidas + 0.0001 && encendidas > 0;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * r1,
        c + Offset(math.cos(a), math.sin(a)) * r2,
        Paint()
          ..color = on ? AppColors.gold : AppColors.seam
          ..strokeWidth = (mayor ? 2 : 1.4) * s
          ..strokeCap = StrokeCap.round,
      );
    }
    final a = (-210 + aguja.clamp(0.0, 1.05) * 240) * math.pi / 180;
    final dir = Offset(math.cos(a), math.sin(a));
    final punta = Paint()
      ..color = AppColors.goldHi
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c + dir * 43 * s, c + dir * 55 * s, punta);
    canvas.drawCircle(c + dir * 57 * s, 2.4 * s, punta);
  }

  @override
  bool shouldRepaint(covariant _DialPainter o) => o.aguja != aguja || o.encendidas != encendidas;
}

// ---------------------------------------------------------------------------
// Íconos de línea fina (dibujados en una cuadrícula de 24)
// ---------------------------------------------------------------------------

enum Trazo { inicio, lista, meta, chat, subir, bajar, escanear, mas, moneda, comida, transporte, hogar, ocio, salud, salario, flecha, perfil, deuda, inversion, presupuesto, candado, salir, sol }

class LineIcon extends StatelessWidget {
  final Trazo icono;
  final double size;
  final Color? color;
  final double grosor;
  const LineIcon(this.icono, {super.key, this.size = 22, this.color, this.grosor = 1.4});

  /// Ícono según el nombre de la categoría.
  static Trazo deCategoria(String categoria, {bool ingreso = false}) {
    final c = categoria.toLowerCase();
    if (ingreso) return c.contains('salar') || c.contains('sueldo') || c.contains('nómina') ? Trazo.salario : Trazo.moneda;
    if (c.contains('comi') || c.contains('restau') || c.contains('almuer') || c.contains('merca') && c.contains('comi')) return Trazo.comida;
    if (c.contains('transp') || c.contains('gasol') || c.contains('uber') || c.contains('taxi') || c.contains('moto') || c.contains('carro')) return Trazo.transporte;
    if (c.contains('hogar') || c.contains('casa') || c.contains('arriendo') || c.contains('servic') || c.contains('merca')) return Trazo.hogar;
    if (c.contains('ocio') || c.contains('cine') || c.contains('entreten') || c.contains('salida') || c.contains('suscrip')) return Trazo.ocio;
    if (c.contains('salud') || c.contains('médic') || c.contains('medic') || c.contains('farma') || c.contains('gym')) return Trazo.salud;
    return Trazo.moneda;
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _LineIconPainter(icono, color ?? IconTheme.of(context).color ?? AppColors.gold, grosor),
      );
}

class _LineIconPainter extends CustomPainter {
  final Trazo i;
  final Color color;
  final double grosor;
  _LineIconPainter(this.i, this.color, this.grosor);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void l(List<double> pts) {
      final path = Path()..moveTo(pts[0], pts[1]);
      for (var k = 2; k < pts.length; k += 2) {
        path.lineTo(pts[k], pts[k + 1]);
      }
      canvas.drawPath(path, p);
    }

    void circ(double x, double y, double r) => canvas.drawCircle(Offset(x, y), r, p);
    void rect(double x, double y, double w, double h, double r) =>
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)), p);

    switch (i) {
      case Trazo.inicio:
        l([4, 11, 12, 5, 20, 11, 20, 20, 15, 20, 15, 14, 9, 14, 9, 20, 4, 20, 4, 11]);
      case Trazo.lista:
        l([5, 7, 19, 7]);
        l([5, 12, 19, 12]);
        l([5, 17, 14, 17]);
      case Trazo.meta:
        circ(12, 12, 8);
        circ(12, 12, 3.5);
      case Trazo.chat:
        l([5, 6, 19, 6, 19, 15, 10, 15, 6, 18, 6, 15, 5, 15, 5, 6]);
      case Trazo.subir:
        l([12, 19, 12, 5]);
        l([6, 11, 12, 5, 18, 11]);
      case Trazo.bajar:
        l([12, 5, 12, 19]);
        l([6, 13, 12, 19, 18, 13]);
      case Trazo.escanear:
        l([4, 8, 4, 4, 8, 4]);
        l([16, 4, 20, 4, 20, 8]);
        l([20, 16, 20, 20, 16, 20]);
        l([8, 20, 4, 20, 4, 16]);
        l([7, 12, 17, 12]);
      case Trazo.mas:
        l([12, 5, 12, 19]);
        l([5, 12, 19, 12]);
      case Trazo.moneda:
        circ(12, 12, 8);
        l([12, 7.5, 12, 16.5]);
        l([14.5, 9.5, 10.5, 9.5]);
        canvas.drawArc(Rect.fromCircle(center: const Offset(10.5, 11), radius: 1.5), math.pi / 2, math.pi, false, p);
        l([10.5, 12.5, 13.5, 12.5]);
        canvas.drawArc(Rect.fromCircle(center: const Offset(13.5, 14), radius: 1.5), -math.pi / 2, math.pi, false, p);
        l([13.5, 15.5, 9.5, 15.5]);
      case Trazo.comida:
        l([6, 3, 6, 11]);
        l([12, 3, 12, 11]);
        canvas.drawArc(Rect.fromLTWH(6, 8, 6, 6), 0, math.pi, false, p);
        l([9, 14, 9, 21]);
        l([17, 21, 17, 3]);
        canvas.drawArc(Rect.fromLTWH(14, 3, 6, 10), math.pi / 2, math.pi, false, p);
      case Trazo.transporte:
        rect(4, 6, 16, 9, 2);
        l([4, 11, 20, 11]);
        circ(8, 18, 1.6);
        circ(16, 18, 1.6);
      case Trazo.hogar:
        l([3, 4, 5, 4, 7.5, 15, 17.5, 15, 20, 8, 7, 8]);
        circ(9, 19.5, .6);
        circ(17, 19.5, .6);
      case Trazo.ocio:
        rect(3, 6, 18, 12, 2);
        l([7, 6, 7, 18]);
        l([17, 6, 17, 18]);
      case Trazo.salud:
        l([12, 20, 4.5, 12.5]);
        canvas.drawArc(Rect.fromLTWH(3, 5, 9, 9), math.pi * .75, math.pi * 1.15, false, p);
        canvas.drawArc(Rect.fromLTWH(12, 5, 9, 9), math.pi * 1.1, math.pi * 1.15, false, p);
        l([19.5, 12.5, 12, 20]);
      case Trazo.salario:
        rect(3, 7, 18, 13, 2);
        l([8, 7, 8, 5, 16, 5, 16, 7]);
      case Trazo.flecha:
        l([9, 6, 15, 12, 9, 18]);
      case Trazo.perfil:
        circ(12, 8.5, 3.5);

        canvas.drawArc(Rect.fromLTWH(5, 13, 14, 14), math.pi, math.pi, false, p);
      case Trazo.deuda:
        rect(3, 6, 18, 12, 2);
        l([3, 10, 21, 10]);
        l([7, 14.5, 10, 14.5]);
      case Trazo.inversion:
        l([4, 17, 9, 12, 13, 15, 20, 7]);
        l([15, 7, 20, 7, 20, 12]);
      case Trazo.presupuesto:
        circ(12, 12, 8);
        l([12, 4, 12, 12, 18, 17]);
      case Trazo.candado:
        rect(5, 11, 14, 9, 2);
        l([8, 11, 8, 8]);
        canvas.drawArc(Rect.fromLTWH(8, 4, 8, 8), math.pi, math.pi, false, p);
        l([16, 8, 16, 11]);
      case Trazo.salir:
        l([10, 4, 5, 4, 5, 20, 10, 20]);
        l([14, 8, 18, 12, 14, 16]);
        l([18, 12, 9, 12]);
      case Trazo.sol:
        circ(12, 12, 4);
        for (var k = 0; k < 8; k++) {
          final a = k * math.pi / 4;
          l([12 + 7 * math.cos(a), 12 + 7 * math.sin(a), 12 + 9 * math.cos(a), 12 + 9 * math.sin(a)]);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _LineIconPainter o) => o.i != i || o.color != color;
}

// ---------------------------------------------------------------------------
// Acción rápida circular con halo al tocar
// ---------------------------------------------------------------------------

class QuickAction extends StatefulWidget {
  final Trazo icono;
  final String label;
  final VoidCallback onTap;
  /// Hacia dónde se empuja el ícono al tocar (ingreso sube, gasto baja).
  final Offset empuje;
  const QuickAction({super.key, required this.icono, required this.label, required this.onTap, this.empuje = Offset.zero});
  @override
  State<QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<QuickAction> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  bool _presionado = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _tap() {
    if (!sinAnimaciones(context)) _c.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _presionado = true),
        onTapCancel: () => setState(() => _presionado = false),
        onTapUp: (_) => setState(() => _presionado = false),
        onTap: _tap,
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedScale(
            scale: _presionado ? .9 : 1,
            duration: const Duration(milliseconds: 140),
            curve: AppTheme.ease,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = AppTheme.ease.transform(_c.value);
                final ida = math.sin(_c.value * math.pi);
                return Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _presionado ? const Color(0xFF120F09) : Colors.transparent,
                      border: Border.all(color: _presionado ? AppColors.gold : AppColors.seam),
                    ),
                  ),
                  if (_c.isAnimating)
                    Transform.scale(
                      scale: 1 + .7 * t,
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.goldHi.withValues(alpha: .9 * (1 - t))),
                        ),
                      ),
                    ),
                  Transform.translate(
                    offset: widget.empuje * ida,
                    child: LineIcon(widget.icono, color: AppColors.gold, grosor: 1.3),
                  ),
                ]);
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(widget.label, style: AppText.caption.copyWith(color: AppColors.sand, fontSize: 12.5)),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Plegar y desplegar (filtros, filas nuevas)
// ---------------------------------------------------------------------------

class Fold extends StatelessWidget {
  final bool visible;
  final Widget child;
  final Duration duration;
  const Fold({super.key, required this.visible, required this.child, this.duration = const Duration(milliseconds: 420)});

  @override
  Widget build(BuildContext context) {
    final d = sinAnimaciones(context) ? Duration.zero : (visible ? duration : const Duration(milliseconds: 280));
    final curva = visible ? AppTheme.ease : const Cubic(.4, 0, 1, 1);
    return ClipRect(
      child: AnimatedAlign(
        alignment: Alignment.topCenter,
        heightFactor: visible ? 1 : 0,
        duration: d,
        curve: curva,
        child: AnimatedOpacity(opacity: visible ? 1 : 0, duration: d, curve: curva, child: child),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Efectos sobre toda la pantalla: monto que vuela y chispas de oro
// ---------------------------------------------------------------------------

Rect? rectGlobal(GlobalKey key) {
  final box = key.currentContext?.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize || !box.attached) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Lleva el texto del monto en arco desde [desde] hasta [hasta].
Future<void> volarMonto(BuildContext context, {required String texto, required Rect desde, required Rect hasta}) async {
  if (sinAnimaciones(context)) return;
  final overlay = Overlay.of(context);
  late OverlayEntry entrada;
  final listo = Completer<void>();
  entrada = OverlayEntry(
    builder: (_) => _Vuelo(texto: texto, desde: desde, hasta: hasta, alTerminar: () {
      entrada.remove();
      listo.complete();
    }),
  );
  overlay.insert(entrada);
  return listo.future;
}

class _Vuelo extends StatefulWidget {
  final String texto;
  final Rect desde, hasta;
  final VoidCallback alTerminar;
  const _Vuelo({required this.texto, required this.desde, required this.hasta, required this.alTerminar});
  @override
  State<_Vuelo> createState() => _VueloState();
}

class _VueloState extends State<_Vuelo> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 760))
    ..forward().whenComplete(widget.alTerminar);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.desde.center, b = widget.hasta.center;
    final control = Offset((a.dx + b.dx) / 2 + 40, math.min(a.dy, b.dy) - 90);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = const Cubic(.4, 0, .2, 1).transform(_c.value);
          final u = 1 - t;
          final pos = a * (u * u) + control * (2 * u * t) + b * (t * t);
          return Stack(children: [
            Positioned(
              left: pos.dx,
              top: pos.dy,
              child: FractionalTranslation(
                translation: const Offset(-.5, -.5),
                child: Transform.scale(scale: 1 - .64 * t, child: child),
              ),
            ),
          ]);
        },
        child: Material(
          type: MaterialType.transparency,
          child: Text(widget.texto, style: AppText.display.copyWith(color: AppColors.goldHi)),
        ),
      ),
    );
  }
}

/// Doce chispas que salen del punto [centro].
void chispas(BuildContext context, Offset centro) {
  if (sinAnimaciones(context)) return;
  late OverlayEntry entrada;
  entrada = OverlayEntry(builder: (_) => _Chispas(centro: centro, alTerminar: () => entrada.remove()));
  Overlay.of(context).insert(entrada);
}

class _Chispas extends StatefulWidget {
  final Offset centro;
  final VoidCallback alTerminar;
  const _Chispas({required this.centro, required this.alTerminar});
  @override
  State<_Chispas> createState() => _ChispasState();
}

class _ChispasState extends State<_Chispas> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 780))
    ..forward().whenComplete(widget.alTerminar);
  final _azar = math.Random();
  late final _datos = List.generate(12, (i) => (
        angulo: 2 * math.pi * i / 12 + _azar.nextDouble() * .4,
        distancia: 18 + _azar.nextDouble() * 26,
        ritmo: .66 + _azar.nextDouble() * .34,
      ));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(children: [
          for (final d in _datos)
            Builder(builder: (_) {
              final t = const Cubic(.1, .8, .3, 1).transform((_c.value / d.ritmo).clamp(0.0, 1.0));
              final o = widget.centro + Offset(math.cos(d.angulo), math.sin(d.angulo)) * d.distancia * t;
              return Positioned(
                left: o.dx - 2,
                top: o.dy - 2,
                child: Opacity(
                  opacity: 1 - t,
                  child: Transform.scale(
                    scale: 1 - .8 * t,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(color: AppColors.goldHi, shape: BoxShape.circle),
                    ),
                  ),
                ),
              );
            }),
        ]),
      ),
    );
  }
}

/// Encabezado de sección: título a la izquierda, enlace a la derecha.
class SectionHeader extends StatelessWidget {
  final String titulo;
  final String? enlace;
  final VoidCallback? alTocar;
  const SectionHeader(this.titulo, {super.key, this.enlace, this.alTocar});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Expanded(child: Text(titulo, style: AppText.subheading.copyWith(fontSize: 15))),
          if (enlace != null)
            InkWell(
              onTap: alTocar,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(enlace!, style: AppText.eyebrow),
              ),
            ),
        ]),
      );
}
