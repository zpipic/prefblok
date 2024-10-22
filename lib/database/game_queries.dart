import 'database_helper.dart';
import '../models/models.dart';
import '../utils/db_utils.dart';

class GameQueries {
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future <List<Round>> getRoundsGame(int gameId) async{
    final db = await dbHelper.database;

    List<Map<String, dynamic>> roundsData= await db.query(
        'rounds',
        where: 'gameId = ?',
        whereArgs: [gameId]
    );

    List<Round> rounds = DbUtils.mapToList(roundsData, Round.fromMap);
    rounds.sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
    return rounds;
  }

  Future <List<ScoreSheet>> getScoreSheetsGame(int? gameId) async{
    final db = await dbHelper.database;

    List<Map<String, dynamic>> scoreSheetsData= await db.query(
        'scoreSheets',
        where: 'gameId = ?',
        whereArgs: [gameId]
    );

   List<ScoreSheet> scoreSheets = DbUtils.mapToList(scoreSheetsData, ScoreSheet.fromMap);
   scoreSheets.sort((a, b) => a.position.compareTo(b.position));
   return scoreSheets;
  }

  Future<List<Player>> getPlayersInGame(int? gameId) async {
    final db = await dbHelper.database;

    List<ScoreSheet> scoreSheets = await getScoreSheetsGame(gameId);

    List<Player> players = [];

    for (var scoreSheet in scoreSheets) {
      List<Map<String, dynamic>> playerData = await db.query(
        'players',
        where: 'id = ?',
        whereArgs: [scoreSheet.playerId],
      );
      
      if (playerData.isNotEmpty){
        Player player = Player.fromMap(playerData.first);
        players.add(player);
      }
    }

    return players;
  }
}