import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'google_sign_in_service.dart';

Widget buildGoogleButton() {
  return SizedBox(
    height: 48,
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: GoogleSignInService.autenticarNativo,
      icon: const Icon(Icons.login, size: 18, color: AppColors.bone),
      label: const Text('Continuar con Google'),
    ),
  );
}