class Presupuesto {
  final int? id;
  final String categoria;
  final double limiteMensual;

  Presupuesto({this.id, required this.categoria, required this.limiteMensual});

  factory Presupuesto.fromJson(Map<String, dynamic> json) => Presupuesto(
    id: json['id'],
    categoria: json['categoria'],
    limiteMensual: (json['limiteMensual'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'categoria': categoria,
    'limiteMensual': limiteMensual,
  };
}