import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/grabado.dart';
import '../asistente/asistente_screen.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../deudas/deudas_screen.dart';
import '../inversiones/inversiones_screen.dart';
import '../metas/metas_screen.dart';
import '../movimientos/movimiento_sheet.dart';
import '../movimientos/movimientos_screen.dart';
import '../presupuestos/presupuestos_screen.dart';
import '../seguridad/seguridad_screen.dart';

/// Acciones de la estructura principal disponibles para cualquier pantalla.
class Shell extends InheritedWidget {
  final void Function(int pestana) irA;
  final Future<void> Function({String tipo}) registrar;
  final VoidCallback abrirMas;
  const Shell({super.key, required this.irA, required this.registrar, required this.abrirMas, required super.child});

  static Shell? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<Shell>();

  @override
  bool updateShouldNotify(Shell old) => false;
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  static const _pestanas = [(Trazo.inicio, 'Inicio'), (Trazo.lista, 'Movimientos'), (Trazo.meta, 'Metas'), (Trazo.chat, 'Asistente')];
  int _actual = 0;
  final _visitadas = {0};
  bool _registroAbierto = false;
  late final _entrada = AnimationController(vsync: this, duration: const Duration(milliseconds: 380), value: 1);

  @override
  void dispose() {
    _entrada.dispose();
    super.dispose();
  }

  void _irA(int i) {
    if (i == _actual) return;
    HapticFeedback.selectionClick();
    setState(() {
      _actual = i;
      _visitadas.add(i);
    });
    _entrada.forward(from: 0);
  }

  Future<void> _registrar({String tipo = 'Gasto'}) async {
    setState(() => _registroAbierto = true);
    await abrirRegistro(context, tipoInicial: tipo);
    if (mounted) setState(() => _registroAbierto = false);
  }

  Widget _pantalla(int i) => switch (i) {
    0 => const DashboardScreen(),
    1 => const MovimientosScreen(),
    2 => const MetasScreen(),
    _ => const AsistenteScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final entrada = CurvedAnimation(parent: _entrada, curve: AppTheme.ease);
    // Las pantallas ven la barra inferior como margen, así sus botones
    // flotantes y campos de texto quedan por encima de ella.
    final mq = MediaQuery.of(context);
    final margenBarra = mq.padding.copyWith(bottom: 112 + mq.viewPadding.bottom);
    return Shell(
      irA: _irA,
      registrar: _registrar,
      abrirMas: () => abrirMas(context),
      child: Scaffold(
        extendBody: true,
        body: MediaQuery(
          data: mq.copyWith(padding: margenBarra),
          child: Stack(
            children: [
              for (var i = 0; i < _pestanas.length; i++)
                Offstage(
                  offstage: i != _actual,
                  child: TickerMode(
                    enabled: i == _actual,
                    child: FadeTransition(
                      opacity: i == _actual ? entrada : kAlwaysCompleteAnimation,
                      child: AnimatedBuilder(
                        animation: entrada,
                        builder: (context, child) =>
                            Transform.translate(offset: Offset(0, i == _actual ? 8 * (1 - entrada.value) : 0), child: child),
                        child: _visitadas.contains(i) ? _pantalla(i) : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: _Dock(
          actual: _actual,
          pestanas: _pestanas,
          registroAbierto: _registroAbierto,
          alElegir: _irA,
          alRegistrar: () => _registrar(),
        ),
      ),
    );
  }
}

class _Dock extends StatelessWidget {
  final int actual;
  final List<(Trazo, String)> pestanas;
  final bool registroAbierto;
  final ValueChanged<int> alElegir;
  final VoidCallback alRegistrar;
  const _Dock({
    required this.actual,
    required this.pestanas,
    required this.registroAbierto,
    required this.alElegir,
    required this.alRegistrar,
  });

  @override
  Widget build(BuildContext context) {
    final abajo = MediaQuery.of(context).viewPadding.bottom;
    final duracion = sinAnimaciones(context) ? Duration.zero : const Duration(milliseconds: 500);
    // Posición en la barra: el botón dorado ocupa el centro.
    final ranura = actual < 2 ? actual : actual + 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, 18 + abajo),
      child: SizedBox(
        height: 100,
        child: LayoutBuilder(
          builder: (context, c) {
            final ancho = c.maxWidth / 5;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 70,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xD10C0A07),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: AppColors.seam),
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: duracion,
                  curve: AppTheme.ease,
                  left: ancho * ranura + ancho / 2 - 2,
                  bottom: 5,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(color: AppColors.goldHi, shape: BoxShape.circle),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 70,
                  child: Row(
                    children: [
                      for (var r = 0; r < 5; r++)
                        Expanded(
                          child: r == 2
                              ? const SizedBox.shrink()
                              : _ItemDock(
                                  icono: pestanas[r < 2 ? r : r - 1].$1,
                                  texto: pestanas[r < 2 ? r : r - 1].$2,
                                  activo: ranura == r,
                                  alTocar: () => alElegir(r < 2 ? r : r - 1),
                                ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: ancho * 2 + (ancho - 58) / 2,
                  bottom: 70 - 30,
                  child: _BotonRegistrar(abierto: registroAbierto, alTocar: alRegistrar),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ItemDock extends StatefulWidget {
  final Trazo icono;
  final String texto;
  final bool activo;
  final VoidCallback alTocar;
  const _ItemDock({required this.icono, required this.texto, required this.activo, required this.alTocar});
  @override
  State<_ItemDock> createState() => _ItemDockState();
}

class _ItemDockState extends State<_ItemDock> {
  bool _abajo = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.activo ? AppColors.goldHi : AppColors.dust;
    return Semantics(
      button: true,
      selected: widget.activo,
      label: widget.texto,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _abajo = true),
        onTapUp: (_) => setState(() => _abajo = false),
        onTapCancel: () => setState(() => _abajo = false),
        onTap: widget.alTocar,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: _abajo ? .9 : 1,
              duration: const Duration(milliseconds: 140),
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: color),
                duration: const Duration(milliseconds: 250),
                builder: (_, c, _) => LineIcon(widget.icono, color: c),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w500, color: color),
              child: Text(widget.texto, maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonRegistrar extends StatefulWidget {
  final bool abierto;
  final VoidCallback alTocar;
  const _BotonRegistrar({required this.abierto, required this.alTocar});
  @override
  State<_BotonRegistrar> createState() => _BotonRegistrarState();
}

class _BotonRegistrarState extends State<_BotonRegistrar> {
  bool _abajo = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Registrar movimiento',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _abajo = true),
        onTapUp: (_) => setState(() => _abajo = false),
        onTapCancel: () => setState(() => _abajo = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.alTocar();
        },
        child: AnimatedScale(
          scale: _abajo ? .92 : 1,
          duration: const Duration(milliseconds: 140),
          child: AnimatedRotation(
            turns: widget.abierto ? 135 / 360 : 0,
            duration: const Duration(milliseconds: 450),
            curve: AppTheme.ease,
            child: Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.goldHi, AppColors.gold, AppColors.bronze],
                  stops: [0, .45, 1],
                ),
                boxShadow: [BoxShadow(color: Color(0xCC000000), blurRadius: 20, offset: Offset(0, 10), spreadRadius: -8)],
              ),
              child: const Center(child: LineIcon(Trazo.mas, size: 24, color: Colors.black, grosor: 1.8)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Menú con las demás secciones, ajustes y cierre de sesión.
Future<void> abrirMas(BuildContext context) async {
  final email = await ApiClient.obtenerEmail();
  if (!context.mounted) return;
  void ir(Widget destino) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => destino));
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (email != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(email, style: AppText.caption),
              ),
            _FilaMas(Trazo.deuda, 'Deudas', () => ir(const DeudasScreen())),
            _FilaMas(Trazo.inversion, 'Inversiones', () => ir(const InversionesScreen())),
            _FilaMas(Trazo.presupuesto, 'Presupuestos', () => ir(const PresupuestosScreen())),
            _FilaMas(Trazo.candado, 'Seguridad', () => ir(const SeguridadScreen())),
            const Divider(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: ThemeController.modoClaro,
              builder: (context, claro, _) => SwitchListTile(
                secondary: const LineIcon(Trazo.sol, color: AppColors.gold),
                title: Text('Modo claro', style: AppText.bodyStrong),
                value: claro,
                onChanged: ThemeController.establecer,
              ),
            ),
            _FilaMas(Trazo.salir, 'Cerrar sesión', () async {
              await ApiClient.cerrarSesion();
              if (ctx.mounted) {
                Navigator.of(ctx).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
              }
            }, peligro: true),
          ],
        ),
      ),
    ),
  );
}

class _FilaMas extends StatelessWidget {
  final Trazo icono;
  final String texto;
  final VoidCallback alTocar;
  final bool peligro;
  const _FilaMas(this.icono, this.texto, this.alTocar, {this.peligro = false});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: LineIcon(icono, color: peligro ? AppColors.ember : AppColors.gold),
    title: Text(texto, style: AppText.bodyStrong.copyWith(color: peligro ? AppColors.ember : AppColors.ivory)),
    trailing: peligro ? null : const LineIcon(Trazo.flecha, size: 18, color: AppColors.dust),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    onTap: alTocar,
  );
}
