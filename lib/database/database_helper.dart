import 'package:pref_blok/database/player_queries.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/db_utils.dart';
import '../models/models.dart';

class DatabaseHelper{
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> deleteDatabaseFile() async {
    String path = join(await getDatabasesPath(), 'preferans.db');
    await deleteDatabase(path);
  }

  Future<Database> _initDatabase() async {
    //await deleteDatabaseFile();

    String path = join(await getDatabasesPath(), 'preferans.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async{
        await db.execute('PRAGMA foreign_keys = ON');

        await db.execute('''
          CREATE TABLE players (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE COLLATE NOCASE
          )
        ''');

        await db.execute('''
          CREATE TABLE games (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            date TEXT,
            noOfPlayers INTEGER,
            isFinished INTEGER DEFAULT 0,
            startingScore INTEGER,
            maxRefes INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE scoreSheets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            gameId INTEGER,
            playerId INTEGER,
            refe INTEGER DEFAULT 0,
            totalScore INTEGER,
            leftSoupTotal INTEGER DEFAULT 0,
            rightSoupTotal INTEGER DEFAULT 0,
            rightSoupTotal2 INTEGER,
            position INTEGER,
            isUnderHat INTEGER DEFAULT 0,
            refesUsed INTEGER DEFAULT 0,
            FOREIGN KEY(gameId) REFERENCES games(id) ON DELETE CASCADE,
            FOREIGN KEY(playerId) REFERENCES players(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE roundScores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            roundId INTEGER,
            scoreSheetId INTEGER,
            score INTEGER DEFAULT 0,
            leftSoup INTEGER DEFAULT 0,
            rightSoup INTEGER DEFAULT 0,
            rightSoup2 INTEGER DEFAULT 0,
            totalScore INTEGER DEFAULT 0,
            totalPoints INTEGER,
            FOREIGN KEY(roundId) REFERENCES rounds(id) ON DELETE CASCADE,
            FOREIGN KEY(scoreSheetId) REFERENCES scoreSheets(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE rounds (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            gameId INTEGER,
            roundNumber INTEGER,
            callerId INTEGER,
            calledGame INTEGER,
            isIgra INTEGER DEFAULT 0,
            multiplier INTEGER DEFAULT 2,
            refeUsed INTEGER DEFAULT 0,
            kontra INTEGER DEFAULT 0,
            FOREIGN KEY(callerId) REFERENCES players(id) ON DELETE CASCADE,
            FOREIGN KEY (gameId) REFERENCES games(id) ON DELETE CASCADE
          )
        ''');
      }
    );
  }

  // CRUD for Players Table
  Future<int?> insertPlayer(Player player) async {
    final db = await database;
    try {
      return await db.insert(
        'players',
        player.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      return null;
    }
  }

  Future<List<Player>> getPlayers() async {
    final db = await database;
    final data = await db.query('players');
    return DbUtils.mapToList(data, Player.fromMap);
  }

  Future<int> updatePlayer(Player player) async {
    final db = await database;
    return await db.update('players', player.toMap(), where: 'id = ?', whereArgs: [player.id]);
  }

  Future<int> deletePlayer(int id) async {
    final db = await database;
    final PlayerQueries playerQueries = PlayerQueries();

    var games = await playerQueries.getGames(id);
    for (var game in games){
      await deleteGame(game.id!);
    }
    return await db.delete('players', where: 'id = ?', whereArgs: [id]);
  }

// CRUD for Games Table
  Future<int> insertGame(Game game) async {
    final db = await database;
    return await db.insert('games', game.toMap());
  }

  Future<List<Game>> getGames() async {
    final db = await database;
    final data = await db.query('games');
    return DbUtils.mapToList(data, Game.fromMap);
  }

  Future<int> updateGame(Game game) async {
    final db = await database;
    return await db.update('games', game.toMap(), where: 'id = ?', whereArgs: [game.id]);
  }

  Future<int> deleteGame(int id) async {
    final db = await database;
    return await db.delete('games', where: 'id = ?', whereArgs: [id]);
  }

// CRUD for ScoreSheets Table
  Future<int> insertScoreSheet(ScoreSheet scoreSheet) async {
    final db = await database;
    return await db.insert('scoreSheets', scoreSheet.toMap());
  }

  Future<List<ScoreSheet>> getScoreSheets() async {
    final db = await database;
    final data = await db.query('scoreSheets');
    return DbUtils.mapToList(data, ScoreSheet.fromMap);
  }

  Future<int> updateScoreSheet(ScoreSheet scoreSheet) async {
    final db = await database;
    return await db.update('scoreSheets', scoreSheet.toMap(), where: 'id = ?', whereArgs: [scoreSheet.id]);
  }

  Future<int> deleteScoreSheet(int id) async {
    final db = await database;
    return await db.delete('scoreSheets', where: 'id = ?', whereArgs: [id]);
  }

// CRUD for Rounds Table
  Future<int> insertRound(Round round) async {
    final db = await database;
    return await db.insert('rounds', round.toMap());
  }

  Future<List<Round>> getRounds() async {
    final db = await database;
    final data = await db.query('rounds');
    return DbUtils.mapToList(data, Round.fromMap);
  }

  Future<int> updateRound(Round round) async {
    final db = await database;
    return await db.update('rounds', round.toMap(), where: 'id = ?', whereArgs: [round.id]);
  }

  Future<int> deleteRound(int id) async {
    final db = await database;
    return await db.delete('rounds', where: 'id = ?', whereArgs: [id]);
  }

// CRUD for RoundScores Table
  Future<int> insertRoundScore(RoundScore roundScore) async {
    final db = await database;
    return await db.insert('roundScores', roundScore.toMap());
  }

  Future<List<RoundScore>> getRoundScores() async {
    final db = await database;
    final data = await db.query('roundScores');
    return DbUtils.mapToList(data, RoundScore.fromMap);
  }

  Future<int> updateRoundScore(RoundScore roundScore) async {
    final db = await database;
    return await db.update('roundScores', roundScore.toMap(), where: 'id = ?', whereArgs: [roundScore.id]);
  }

  Future<int> deleteRoundScore(int id) async {
    final db = await database;
    return await db.delete('roundScores', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}