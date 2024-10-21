import '../models/base_model.dart';

class DbUtils{
  static List<T> mapToList<T extends BaseModel<T>>(List<Map<String, dynamic>> data,
      T Function(Map<String, dynamic>) fromMap) {
    return data.map((map) => fromMap(map)).toList();
  }
}
