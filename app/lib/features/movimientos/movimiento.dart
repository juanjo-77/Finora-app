class Movimiento {
  final int? id;
  final String tipo;
  final String categoria;
  final double monto;
  final DateTime fecha;
  final String? nota;

  Movimiento({
    this.id,
    required this.tipo,
    required this.categoria,
    required this.monto,
    required this.fecha,
    this.nota,
  });

  factory Movimiento.fromJson(Map<String, dynamic> json) => Movimiento(
    id: json['id'],
    tipo: json['tipo'] == 0 ? 'Ingreso' : 'Gasto',
    categoria: json['categoria'],
    monto: (json['monto'] as num).toDouble(),
    fecha: DateTime.parse(json['fecha']),
    nota: json['nota'],
  );

  Map<String, dynamic> toJson() => {
    'tipo': tipo == 'Ingreso' ? 0 : 1,
    'categoria': categoria,
    'monto': monto,
    'fecha': fecha.toIso8601String(),
    'nota': nota,
  };
}