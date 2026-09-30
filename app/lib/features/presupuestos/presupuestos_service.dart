import '../../core/network/api_client.dart';
import 'presupuesto.dart';

class PresupuestosService {
  static Future<List<Presupuesto>> obtenerTodos() async {
    final data = await ApiClient.get('/presupuestos') as List;
    return data.map((e) => Presupuesto.fromJson(e)).toList();
  }

  static Future<void> guardar(Presupuesto p) => ApiClient.post('/presupuestos', p.toJson());

  static Future<void> eliminar(int id) => ApiClient.delete('/presupuestos/$id');
}