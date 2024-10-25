import 'package:pref_blok/database/game_queries.dart';
import 'package:pref_blok/database/scoresheet_queries.dart';
import 'package:pref_blok/screens/add_round_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class GameScreen extends StatefulWidget{
  Game game;

  GameScreen({super.key, required this.game});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>{
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final GameQueries _gameQueries = GameQueries();
  final ScoreSheetQueries _scoreSheetQueries = ScoreSheetQueries();
  final PageController _pageController = PageController();

  bool _isLoading = true;

  List<Round> _rounds = [];
  List<Player> _players = [];
  List<ScoreSheet> _scoreSheets = [];
  List<RoundScore> _roundScores = [];
  int _shuffler = 0;
  // Map<int, List<RoundScore>> _roundScores = {};

  @override
  void initState(){
    _initData();
    _loadShuffler();
    super.initState();
  }

  void _loadShuffler() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? storedShuffler = prefs.getInt('shuffler_${widget.game.id}');

    if (storedShuffler == null){
      setState(() {
        _shuffler = Random().nextInt(widget.game.noOfPlayers);
      });
      await _saveShuffler();
    } else {
      setState(() {
        _shuffler = storedShuffler;
      });
    }
  }

  _deleteShuffler() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('shuffler_${widget.game.id}');
  }

  Future<void> _saveShuffler() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('shuffler_${widget.game.id}', _shuffler);
  }

  void _incrementShuffler(){
    setState(() {
      _shuffler = (_shuffler + 1) % widget.game.noOfPlayers;
    });
    _saveShuffler();
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
    final rounds = await _gameQueries.getRoundsGame(widget.game.id!);
    setState(() {
      _rounds = rounds;
    });
  }

  Future<void> _loadPlayers() async{
    final players = await _gameQueries.getPlayersInGame(widget.game.id);
    setState(() {
      _players = players;
    });
  }

  Future<void> _loadScoreSheets() async {
    final scoreSheets = await _gameQueries.getScoreSheetsGame(widget.game.id);
    setState(() {
      _scoreSheets = scoreSheets;
    });
  }

  Future<void> _loadRoundScores() async {
    final scores = await _scoreSheetQueries.getRoundScoresGame(widget.game.id!);
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
    List<Player> playersPlaying = List.from(_players);
    if (widget.game.noOfPlayers == 4){
      playersPlaying.removeAt(_shuffler);
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>
          AddRoundPage(
              game: widget.game,
              scoreSheets: _scoreSheets,
              players: playersPlaying,
              roundNumber: _rounds.length + 1,
              shuffler: _shuffler,
          ),
      )
    );
  }


  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shuffle),
                const SizedBox(width: 5,),
                Text(
                  _players[_shuffler].name,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16,),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SmoothPageIndicator(
                  controller: _pageController,
                  count: widget.game.noOfPlayers,
                effect: const WormEffect(
                  dotHeight: 8.0,
                  dotWidth: 8.0,
                  activeDotColor: Colors.indigo,
                  dotColor: Colors.grey,
                ),
              ),
            ),
            Expanded(
                child:
                  PageView.builder(
                  controller: _pageController,
                  itemCount: widget.game.noOfPlayers,
                  itemBuilder: (context, index) {
                    return _buildTable(_scoreSheets[index]);
                  },
                )
            ),
          ],
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

        return SizedBox(
          width: width,
          height: height,
          // decoration: BoxDecoration(
          //   border: Border.all(color: Colors.grey),
          //   borderRadius: BorderRadius.circular(8.0),
          // ),
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
                    border: const TableBorder(
                      verticalInside: BorderSide(
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                      horizontalInside: BorderSide(
                        width: 1,
                        style: BorderStyle.solid,
                      )
                    ),
                    columns: _buildColumns(scoreSheet.position),
                    rows: const [],
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
      _buildDataColumn('${_players[left].name} juhe'),
      _buildDataColumn('Bule'),
      _buildDataColumn('${_players[right].name} juhe'),
    ];

    if (n == 4){
      int right2 = (position + 2) % n;
      columns.add(
        _buildDataColumn('${_players[right2].name} juhe'),
      );
    }

    return columns;
  }

  DataColumn _buildDataColumn(String text){
    return DataColumn(
        label: Flexible(
          child: Text(
            text,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        )
    );
  }


}