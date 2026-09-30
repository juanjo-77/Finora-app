import '../../core/network/api_client.dart';
import 'inversion.dart';

class InversionesService {
  static Future<List<Inversion>> obtenerTodas() async {
    final data = await ApiClient.get('/inversiones') as List;
    return data.map((e) => Inversion.fromJson(e)).toList();
  }

  static Future<void> crear(Inversion i) => ApiClient.post('/inversiones', i.toJson());

  static Future<void> actualizar(int id, Inversion i) => ApiClient.put('/inversiones/$id', i.toJson());

  static Future<void> eliminar(int id) => ApiClient.delete('/inversiones/$id');
}