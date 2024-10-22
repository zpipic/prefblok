import 'package:pref_blok/database/game_queries.dart';
import 'package:pref_blok/database/scoresheet_queries.dart';

import '../models/models.dart';
import '../database/database_helper.dart';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget{
  Game game;

  GameScreen({super.key, required this.game});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>{
  final DatabaseHelper dbHelper = DatabaseHelper();
  final GameQueries gameQueries = GameQueries();
  final ScoreSheetQueries scoreSheetQueries = ScoreSheetQueries();

  bool _isLoading = true;

  List<Round> _rounds = [];
  List<Player> _players = [];
  List<ScoreSheet> _scoreSheets = [];
  List<RoundScore> _roundScores = [];
  // Map<int, List<RoundScore>> _roundScores = {};

  @override
  void initState(){
    _initData();
    super.initState();
  }

  void _initData() async{
    await _loadRounds();
    await _loadPlayers();
    await _loadScoreSheets();
    await _loadRoundScores();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadRounds() async{
    final rounds = await gameQueries.getRoundsGame(widget.game.id!);
    setState(() {
      _rounds = rounds;
    });
  }

  Future<void> _loadPlayers() async{
    final players = await gameQueries.getPlayersInGame(widget.game.id);
    setState(() {
      _players = players;
    });
  }

  Future<void> _loadScoreSheets() async {
    final scoreSheets = await gameQueries.getScoreSheetsGame(widget.game.id);
    setState(() {
      _scoreSheets = scoreSheets;
    });
  }

  Future<void> _loadRoundScores() async {
    final scores = await scoreSheetQueries.getRoundScoresGame(widget.game.id!);
    setState(() {
      _roundScores = scores;
    });
  }

  List<RoundScore> _getScoresRound(int roundId){
    return _roundScores.where((x) => x.roundId == roundId).toList();
  }

  List<RoundScore> _getScoresSheet(int scoreSheetId){
    return _roundScores.where((x) => x.scoreSheetId == scoreSheetId).toList();
  }

  Player _getPlayer(int playerId){
    return _players.firstWhere((p) => p.id == playerId);
  }

  void _addRound(){

  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading){
      return Scaffold(
        appBar: AppBar(title: const Text('Učitavanje...')),
        body: const Center(child: CircularProgressIndicator(),)
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text('Partija ${widget.game.name}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Povijest rundi',
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {},
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildTablesBody(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addRound,
          tooltip: 'Nova runda',
          child: const Icon(Icons.add),
        ),
      );
    }
  }

  Widget _buildTablesBody(){
    return Column(
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          alignment: WrapAlignment.start,
          children: widget.game.noOfPlayers == 3
            ? [
              _buildTable(_scoreSheets[0]),
              _buildTable(_scoreSheets[1]),
              Center(
                child: _buildTable(_scoreSheets[2])
              )
            ]
            : _scoreSheets.map((scoreSheet) => _buildTable(scoreSheet)).toList(),
        )
      ],
    );
  }

  Widget _buildTable(ScoreSheet scoreSheet){
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double width = constraints.maxWidth * 0.45;
        double height = MediaQuery.of(context).size.height * 0.40;

        List<RoundScore> scores = _getScoresSheet(scoreSheet.id!);

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _getPlayer(scoreSheet.playerId).name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: _buildColumns(scoreSheet.position),
                    rows: [],
                  ),
                ),
              )
            ],
          )
        );
      },
    );
  }

  List<DataColumn> _buildColumns(int position) {
    int n = widget.game.noOfPlayers;
    int left = ((position - 1) % n + n) % n;
    int right = (position + 1) % n;
    List<DataColumn> columns = [
      DataColumn(label: Text('${_players[left].name} juhe')),
      const DataColumn(label: Text('Bule')),
      DataColumn(label: Text('${_players[right].name} juhe')),
    ];

    if (n == 4){
      int right2 = (position + 2) % n;
      columns.add(
        DataColumn(label: Text('${_players[right2].name} juhe')),
      );
    }

    return columns;
  }


}