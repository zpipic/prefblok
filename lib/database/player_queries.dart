import 'database_helper.dart';
import '../models/models.dart';
import '../utils/db_utils.dart';

class PlayerQueries{
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<Player?> GetPlayerByName(String name) async {
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> playersData = await db.query(
      'players',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (playersData.isNotEmpty){
      return Player.fromMap(playersData.first);
    }
    return null;
  }
}