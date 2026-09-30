import '../../core/network/api_client.dart';
import 'movimiento.dart';

class MovimientosService {
  static Future<List<Movimiento>> obtenerTodos() async {
    final data = await ApiClient.get('/movimientos') as List;
    return data.map((e) => Movimiento.fromJson(e)).toList();
  }

  static Future<void> crear(Movimiento m) => ApiClient.post('/movimientos', m.toJson());

  static Future<void> actualizar(int id, Movimiento m) => ApiClient.put('/movimientos/$id', m.toJson());

  static Future<void> eliminar(int id) => ApiClient.delete('/movimientos/$id');
}