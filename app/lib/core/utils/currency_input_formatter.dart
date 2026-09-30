import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formatea un campo de texto con puntos de mil mientras el usuario escribe.
/// Ej: escribes "150000" y se muestra "150.000".
class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('es_CO');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final numero = int.parse(digitsOnly);
    final textoFormateado = _formatter.format(numero);
    return TextEditingValue(
      text: textoFormateado,
      selection: TextSelection.collapsed(offset: textoFormateado.length),
    );
  }

  /// Convierte el texto ya formateado (ej. "150.000") de vuelta a número (150000.0)
  static double parse(String textoFormateado) {
    final digitsOnly = textoFormateado.replaceAll(RegExp(r'[^\d]'), '');
    return digitsOnly.isEmpty ? 0 : double.parse(digitsOnly);
  }
}