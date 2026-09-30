class Inversion {
  final int? id;
  final String nombre;
  final String tipo;
  final double montoInvertido;
  final double valorActual;

  Inversion({
    this.id,
    required this.nombre,
    required this.tipo,
    required this.montoInvertido,
    required this.valorActual,
  });

  double get rentabilidad => valorActual - montoInvertido;
  double get rentabilidadPct => montoInvertido > 0 ? (rentabilidad / montoInvertido) * 100 : 0;

  factory Inversion.fromJson(Map<String, dynamic> json) => Inversion(
    id: json['id'],
    nombre: json['nombre'],
    tipo: json['tipo'],
    montoInvertido: (json['montoInvertido'] as num).toDouble(),
    valorActual: (json['valorActual'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'tipo': tipo,
    'montoInvertido': montoInvertido,
    'valorActual': valorActual,
  };
}