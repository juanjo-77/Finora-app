import '../../core/network/api_client.dart';
import 'meta.dart';

class MetasService {
  static Future<List<Meta>> obtenerTodas() async {
    final data = await ApiClient.get('/metas') as List;
    return data.map((e) => Meta.fromJson(e)).toList();
  }

  static Future<void> crear(Meta m) => ApiClient.post('/metas', m.toJson());

  static Future<void> actualizar(int id, Meta m) => ApiClient.put('/metas/$id', m.toJson());

  static Future<void> eliminar(int id) => ApiClient.delete('/metas/$id');
}