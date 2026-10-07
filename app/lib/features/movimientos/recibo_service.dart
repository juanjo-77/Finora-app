import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/app_config.dart';

class DatosRecibo {
  final String comercio;
  final DateTime fecha;
  final double monto;
  final String categoria;

  DatosRecibo({
    required this.comercio,
    required this.fecha,
    required this.monto,
    required this.categoria,
  });

  factory DatosRecibo.fromJson(Map<String, dynamic> json) => DatosRecibo(
    comercio: json['comercio'] ?? 'Recibo',
    fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
    monto: (json['monto'] as num?)?.toDouble() ?? 0,
    categoria: json['categoria'] ?? 'Otros',
  );
}

class ReciboService {
  static final _url = '${AppConfig.aiBaseUrl}/escanear-recibo';
  // Debe coincidir exactamente con INTERNAL_API_KEY en Render y en asistente_service.dart
  static const _internalKey = 'cambia-esto-por-algo-largo-y-aleatorio-123456';

  static Future<DatosRecibo> escanear(Uint8List imagenBytes) async {
    final base64Imagen = base64Encode(imagenBytes);

    final res = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'X-Internal-Key': _internalKey,
      },
      body: jsonEncode({'imagen_base64': base64Imagen}),
    );

    if (res.statusCode == 429) {
      throw Exception('Espera un momento antes de intentar de nuevo');
    }
    if (res.statusCode >= 400) {
      final cuerpo = jsonDecode(res.body);
      throw Exception(cuerpo['detail'] ?? 'No se pudo leer el recibo');
    }

    return DatosRecibo.fromJson(jsonDecode(res.body));
  }
}