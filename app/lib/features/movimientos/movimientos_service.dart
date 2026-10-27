import '../../core/network/api_client.dart';
import 'movimiento.dart';

class MovimientosService {
  static Future<List<Movimiento>> obtenerTodos() async {
    final data = await ApiClient.get('/movimientos') as List;
    return data.map((e) => Movimiento.fromJson(e)).toList();
  }

  static Future<Movimiento> crear(Movimiento m) async {
    final data = await ApiClient.post('/movimientos', m.toJson());
    return data is Map<String, dynamic> ? Movimiento.fromJson(data) : m;
  }

  static Future<void> actualizar(int id, Movimiento m) => ApiClient.put('/movimientos/$id', m.toJson());

  static Future<void> eliminar(int id) => ApiClient.delete('/movimientos/$id');
}