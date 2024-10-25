import 'package:pref_blok/database/base_query.dart';
import 'package:pref_blok/database/game_queries.dart';
import '../utils/db_utils.dart';
import '../models/models.dart';

class PlayerQueries extends BaseQuery{
  final GameQueries _gameQueries = GameQueries();

  Future<Player?> getPlayerByName(String name) async {
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

  Future<List<ScoreSheet>> getScoreSheets(int playerId) async{
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> data = await db.query(
      'scoreSheets',
      where: 'playerId = ?',
      whereArgs: [playerId],
    );

    var scoreSheets = DbUtils.mapToList(data, ScoreSheet.fromMap);
    return scoreSheets;
  }

  Future<List<Game>> getGames(int playerId) async {
    var scoreSheets = await getScoreSheets(playerId);

    var gameIds = scoreSheets.map((x) => x.gameId).toList();
    List<Game> games = [];
    for (var gameId in gameIds){
      var game = await _gameQueries.getById(gameId);
      if (game != null) {
        games.add(game);
      }
    }
    return games;
  }
}