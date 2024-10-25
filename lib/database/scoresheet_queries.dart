import 'package:pref_blok/database/game_queries.dart';

import 'database_helper.dart';
import '../models/models.dart';
import '../utils/db_utils.dart';

class ScoreSheetQueries{
  final DatabaseHelper dbHelper = DatabaseHelper();
  final GameQueries gameQueries = GameQueries();

  Future<List<RoundScore>> getRoundScores(int scoreSheetId) async{
    final db = await dbHelper.database;

    List<Map<String, dynamic>> data= await db.query(
        'rounds',
        where: 'scoreSheetId = ?',
        whereArgs: [scoreSheetId]
    );

    List<RoundScore> roundScores = DbUtils.mapToList(data, RoundScore.fromMap);
    roundScores.sort((a, b) => a.id!.compareTo(b.id!));
    return roundScores;
  }

  Future<List<RoundScore>> getRoundScoresGame(int gameId) async{
    final db = await dbHelper.database;

    List<ScoreSheet> scoreSheets = await gameQueries.getScoreSheetsGame(gameId);
    List<int> ids = scoreSheets.map((x) => x.id!).toList();

    String placeholders = List.filled(ids.length, '?').join(',');

    List<Map<String, dynamic>> data = await db.rawQuery(
      'SELECT * from roundScores WHERE scoreSheetId IN ($placeholders)',
      ids
    );

    List<RoundScore> roundScores = DbUtils.mapToList(data, RoundScore.fromMap);
    roundScores.sort((a, b) => a.id!.compareTo(b.id!));
    return roundScores;
  }
}