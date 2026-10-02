import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;
import '../../core/theme/app_colors.dart';

/// En web, Google exige renderizar su propio botón (no se puede re-estilar
/// el contenido interno por seguridad), pero sí podemos enmarcarlo para que
/// combine con el resto de la UI en vez de quedar flotando solo.
Widget buildGoogleButton() {
  return Center(
    child: Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.onyx,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.graphite),
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: web.renderButton(),
      ),
    ),
  );
}