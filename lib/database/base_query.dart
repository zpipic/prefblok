import 'database_helper.dart';

abstract class BaseQuery{
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<List<Map<String, dynamic>>> getAll(String tableName,
      String attribute, int targetValue) async{
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> data = await db.query(
      tableName,
      where: '$attribute = ?',
      whereArgs: [targetValue],
    );

    return data;
  }

  Future<Map<String, dynamic>?> getByIdBase(String tableName,
      String attribute, int id) async{
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> data = await db.query(
      tableName,
      where: '$attribute = ?',
      whereArgs: [id],
    );

    if (data.isNotEmpty){
      return data.first;
    }
    return null;
  }
}