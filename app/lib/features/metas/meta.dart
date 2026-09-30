class Meta {
  final int? id;
  final String nombre;
  final double montoObjetivo;
  final double montoAhorrado;
  final double ahorroMensualPlaneado;

  Meta({
    this.id,
    required this.nombre,
    required this.montoObjetivo,
    required this.montoAhorrado,
    required this.ahorroMensualPlaneado,
  });

  double get progreso => montoObjetivo > 0 ? (montoAhorrado / montoObjetivo).clamp(0, 1) : 0;
  double get faltante => (montoObjetivo - montoAhorrado).clamp(0, double.infinity);

  /// Meses estimados para llegar a la meta, o null si no hay ahorro mensual planeado.
  int? get mesesEstimados {
    if (ahorroMensualPlaneado <= 0 || faltante <= 0) return null;
    return (faltante / ahorroMensualPlaneado).ceil();
  }

  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
    id: json['id'],
    nombre: json['nombre'],
    montoObjetivo: (json['montoObjetivo'] as num).toDouble(),
    montoAhorrado: (json['montoAhorrado'] as num).toDouble(),
    ahorroMensualPlaneado: (json['ahorroMensualPlaneado'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'montoObjetivo': montoObjetivo,
    'montoAhorrado': montoAhorrado,
    'ahorroMensualPlaneado': ahorroMensualPlaneado,
  };
}