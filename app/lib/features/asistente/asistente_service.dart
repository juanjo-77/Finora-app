import 'dart:convert';
import 'package:http/http.dart' as http;
import '../deudas/deuda.dart';
import '../movimientos/movimiento.dart';

class AsistenteService {
  static const _url = 'http://localhost:8001/asistente';
  // Debe coincidir exactamente con INTERNAL_API_KEY en ai-service/.env
  static const _internalKey = 'cambia-esto-por-algo-largo-y-aleatorio-123456';

  static Future<String> preguntar({
    required String pregunta,
    required List<Movimiento> movimientos,
    required List<Deuda> deudas,
  }) async {
    final ingresos = movimientos.where((m) => m.tipo == 'Ingreso').fold(0.0, (s, m) => s + m.monto);
    final gastos = movimientos.where((m) => m.tipo == 'Gasto').fold(0.0, (s, m) => s + m.monto);
    final saldoActual = ingresos - gastos;

    final limite = DateTime.now().add(const Duration(days: 30));
    final cuotasProximas = deudas.where((d) => d.proximaFecha.isBefore(limite)).toList();
    final totalCuotas = cuotasProximas.fold(0.0, (s, d) => s + d.cuotaMensual);
    final disponibleReal = saldoActual - totalCuotas;

    final gastosPorCategoria = <String, double>{};
    for (final m in movimientos.where((m) => m.tipo == 'Gasto')) {
      gastosPorCategoria[m.categoria] = (gastosPorCategoria[m.categoria] ?? 0) + m.monto;
    }

    final res = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'X-Internal-Key': _internalKey,
      },
      body: jsonEncode({
        'pregunta': pregunta,
        'disponible_real': disponibleReal,
        'saldo_actual': saldoActual,
        'proximos_pagos': cuotasProximas.map((d) => {'nombre': d.nombre, 'monto': d.cuotaMensual}).toList(),
        'gastos_por_categoria': gastosPorCategoria,
      }),
    );

    if (res.statusCode == 429) {
      throw Exception('Espera un momento antes de preguntar de nuevo');
    }
    if (res.statusCode >= 400) {
      throw Exception('El asistente no respondió (${res.statusCode})');
    }
    final data = jsonDecode(res.body);
    return data['respuesta'] as String;
  }
}