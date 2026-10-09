import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_controller.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/movimientos/movimientos_screen.dart';
import '../../features/deudas/deudas_screen.dart';
import '../../features/inversiones/inversiones_screen.dart';
import '../../features/metas/metas_screen.dart';
import '../../features/presupuestos/presupuestos_screen.dart';
import '../../features/asistente/asistente_screen.dart';
import '../../features/seguridad/seguridad_screen.dart';
import '../../features/auth/login_screen.dart';
import '../network/api_client.dart';

class DrawerRuta {
  static const dashboard = 'dashboard';
  static const movimientos = 'movimientos';
  static const deudas = 'deudas';
  static const inversiones = 'inversiones';
  static const metas = 'metas';
  static const presupuestos = 'presupuestos';
  static const asistente = 'asistente';
  static const seguridad = 'seguridad';
}

class AppDrawer extends StatefulWidget {
  final String actual;
  const AppDrawer({super.key, required this.actual});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? _email;

  @override
  void initState() {
    super.initState();
    ApiClient.obtenerEmail().then((e) {
      if (mounted) setState(() => _email = e);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.obsidian,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: AppColors.gildedGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_graph, size: 16, color: Colors.black),
                  ),
                  const SizedBox(width: 10),
                  Text('Finora', style: AppText.bodyStrong.copyWith(fontSize: 17, color: AppColors.paperWhite)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _item(context, Icons.space_dashboard_outlined, 'Dashboard', DrawerRuta.dashboard,
                      const DashboardScreen(), esRaiz: true),
                  _item(context, Icons.list, 'Movimientos', DrawerRuta.movimientos, const MovimientosScreen()),
                  _item(context, Icons.credit_card, 'Deudas', DrawerRuta.deudas, const DeudasScreen()),
                  _item(context, Icons.trending_up, 'Inversiones', DrawerRuta.inversiones, const InversionesScreen()),
                  _item(context, Icons.flag_outlined, 'Metas', DrawerRuta.metas, const MetasScreen()),
                  _item(context, Icons.pie_chart_outline, 'Presupuestos', DrawerRuta.presupuestos, const PresupuestosScreen()),
                  _item(context, Icons.auto_awesome, 'Asistente', DrawerRuta.asistente, const AsistenteScreen()),
                  _item(context, Icons.lock_outline, 'Seguridad', DrawerRuta.seguridad, const SeguridadScreen()),
                ],
              ),
            ),
            const Divider(color: AppColors.graphite, height: 1),
            ValueListenableBuilder<bool>(
              valueListenable: ThemeController.modoClaro,
              builder: (context, claro, _) => SwitchListTile(
                dense: true,
                secondary: Icon(
                  claro ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: AppColors.fog,
                  size: 18,
                ),
                title: Text('Modo claro', style: AppText.body.copyWith(fontSize: 14, color: AppColors.bone)),
                value: claro,
                activeThumbColor: AppColors.copper,
                onChanged: ThemeController.establecer,
              ),
            ),
            const Divider(color: AppColors.graphite, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Text(_email ?? '', style: AppText.caption.copyWith(fontSize: 12)),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.logout, color: AppColors.fog, size: 18),
              title: Text('Cerrar sesión', style: AppText.body.copyWith(fontSize: 14, color: AppColors.fog)),
              onTap: () async {
                await ApiClient.cerrarSesion();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, String ruta, Widget destino, {bool esRaiz = false}) {
    final activo = widget.actual == ruta;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: activo ? AppColors.copper.withOpacity(0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: activo
              ? () => Navigator.pop(context)
              : () {
                  Navigator.pop(context);
                  if (esRaiz) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => destino),
                      (route) => false,
                    );
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => destino));
                  }
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon, size: 19, color: activo ? AppColors.copper : AppColors.fog),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: AppText.body.copyWith(
                    fontSize: 14,
                    color: activo ? AppColors.copper : AppColors.bone,
                    fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}