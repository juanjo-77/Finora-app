import '../../core/network/api_client.dart';
import 'deuda.dart';

class DeudasService {
  static Future<List<Deuda>> obtenerTodas() async {
    final data = await ApiClient.get('/deudas') as List;
    return data.map((e) => Deuda.fromJson(e)).toList();
  }

  static Future<void> crear(Deuda d) => ApiClient.post('/deudas', d.toJson());

  static Future<void> actualizar(int id, Deuda d) => ApiClient.put('/deudas/$id', d.toJson());

  static Future<void> abonar(int id, double monto) =>
      ApiClient.post('/deudas/$id/abonar', {'monto': monto});

  static Future<void> eliminar(int id) => ApiClient.delete('/deudas/$id');
}