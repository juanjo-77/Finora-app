import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Texto claro para el usuario a partir de cualquier error.
String mensajeDeError(Object e, [String porDefecto = 'Algo salió mal. Intenta de nuevo.']) {
  if (e is TimeoutException) return 'El servidor tardó demasiado. Revisa tu conexión e intenta de nuevo.';
  final texto = e.toString().replaceFirst('Exception: ', '').trim();
  if (texto.contains('SocketException') || texto.contains('ClientException') || texto.contains('Failed to fetch')) {
    return 'Sin conexión con el servidor. Revisa tu internet.';
  }
  if (texto.isEmpty || texto.length > 160 || texto.contains('Error de red')) return porDefecto;
  return texto;
}

void mostrarError(BuildContext context, Object e, [String? porDefecto]) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensajeDeError(e, porDefecto ?? 'Algo salió mal. Intenta de nuevo.'))));
}

void mostrarAviso(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}

/// Pregunta antes de borrar. Devuelve true si el usuario confirma.
Future<bool> confirmarEliminar(BuildContext context, String que) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('¿Eliminar $que?'),
      content: const Text('No se puede deshacer.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: AppText.bodyStrong.copyWith(color: AppColors.sand))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Eliminar', style: AppText.bodyStrong.copyWith(color: AppColors.ember))),
      ],
    ),
  );
  return ok ?? false;
}

/// Fondo rojo discreto al deslizar para borrar.
Widget fondoEliminar() => Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Text('Eliminar', style: AppText.bodyStrong.copyWith(color: AppColors.ember, fontSize: 13)),
    );

/// Estado de error con botón para reintentar.
class ErrorReintentar extends StatelessWidget {
  final String mensaje;
  final VoidCallback alReintentar;
  const ErrorReintentar({super.key, required this.mensaje, required this.alReintentar});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(mensaje, style: AppText.body, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: alReintentar, child: const Text('Reintentar')),
          ]),
        ),
      );
}
