class Deuda {
  final int? id;
  final String nombre;
  final double montoTotal;
  final double cuotaMensual;
  final DateTime proximaFecha;
  final double? tasaInteres;

  Deuda({
    this.id,
    required this.nombre,
    required this.montoTotal,
    required this.cuotaMensual,
    required this.proximaFecha,
    this.tasaInteres,
  });

  factory Deuda.fromJson(Map<String, dynamic> json) => Deuda(
    id: json['id'],
    nombre: json['nombre'],
    montoTotal: (json['montoTotal'] as num).toDouble(),
    cuotaMensual: (json['cuotaMensual'] as num).toDouble(),
    proximaFecha: DateTime.parse(json['proximaFecha']),
    tasaInteres: json['tasaInteres'] != null ? (json['tasaInteres'] as num).toDouble() : null,
  );

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'montoTotal': montoTotal,
    'cuotaMensual': cuotaMensual,
    'proximaFecha': proximaFecha.toIso8601String(),
    'tasaInteres': tasaInteres,
  };
}