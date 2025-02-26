import 'package:pref_blok/database/game_queries.dart';
import 'package:pref_blok/database/scoresheet_queries.dart';
import 'package:pref_blok/enums/player_position.dart';
import 'package:pref_blok/screens/add_round_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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

  final _cardColors = {2 : 'pik', 3: 'karo', 4: 'herc', 5: 'tref',
    6: 'betl', 7: 'sans', 0: 'dalje'};

  bool _isLoading = true;

  List<Round> _rounds = [];
  List<Player> _players = [];
  List<ScoreSheet> _scoreSheets = [];
  List<RoundScore> _roundScores = [];
  Map<int, List<RoundScore>> _roundScoresSheet = {};
  int _shuffler = 0;
  // Map<int, List<RoundScore>> _roundScores = {};

  int _totalSum = 0;

  @override
  void initState(){
    _initData();
    _loadShuffler();
    super.initState();
  }

  void _loadShuffler() async {
    //await _deleteShuffler();

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

  void _decrementShuffler(){
    setState(() {
      _shuffler = (_shuffler + widget.game.noOfPlayers - 1) % widget.game.noOfPlayers;
    });
    _saveShuffler();
  }

  void _setTotalSum(){
    _totalSum = 0;
    for (var scoreSheet in _scoreSheets){
      _totalSum += scoreSheet.totalScore;
    }
  }

  void _initData() async{
    await _loadRounds();
    await _loadPlayers();
    await _loadScoreSheets();
    await _loadRoundScores();
    _setTotalSum();

    for (var scoreSheet in _scoreSheets){
      _roundScoresSheet[scoreSheet.id!] = [];
    }

    _loadRoundScoreSheets();

    setState(() {
      _isLoading = false;
    });

    _checkGameOver();
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

  void _loadRoundScoreSheets() {
    for (var roundScore in _roundScores){
      setState(() {
        _roundScoresSheet[roundScore.scoreSheetId]?.add(roundScore);
      });
    }
  }

  List<RoundScore> _getScoresRound(int roundId){
    return _roundScores.where((x) => x.roundId == roundId).toList();
  }

  RoundScore? _getRoundScore(int roundId, int scoreSheetId){
    if (_roundScoresSheet[scoreSheetId] == null){
      return RoundScore(roundId: roundId, scoreSheetId: scoreSheetId);
    }
    return _roundScoresSheet[scoreSheetId]?.
      firstWhere((x) => x.roundId == roundId,
        orElse: () => RoundScore(roundId: roundId, scoreSheetId: scoreSheetId));
  }

  List<RoundScore> _getScoresSheet(int scoreSheetId){
    return _roundScores.where((x) => x.scoreSheetId == scoreSheetId).toList();
  }

  ScoreSheet _getScoreSheet(int id){
    return _scoreSheets.firstWhere((x) => x.id == id);
  }

  Player _getPlayer(int playerId){
    return _players.firstWhere((p) => p.id == playerId);
  }

  ScoreSheet _getScoreSheetPlayerId(int playerId){
    return _scoreSheets.firstWhere((x) => x.playerId == playerId);
  }

  void _addRound(){
    List<Player> playersPlaying = List.from(_players);
    List<ScoreSheet> activeScoresheets = List.from(_scoreSheets);
    if (widget.game.noOfPlayers == 4){
      playersPlaying.removeAt(_shuffler);
      activeScoresheets.removeAt(_shuffler);
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>
          AddRoundPage(
              game: widget.game,
              scoreSheets: activeScoresheets,
              players: playersPlaying,
              roundNumber: _rounds.length + 1,
              shuffler: _shuffler,
              onRoundCreated: onRoundAdded,
              maxContract: _totalSum.abs(),
              allScoreSheets: _scoreSheets,
          ),
      )
    );
  }

  void _checkGameOver() async{
    if (_totalSum != 0){
      return;
    }

    widget.game.isFinished = true;
    await _dbHelper.updateGame(widget.game);

    var scores = _calculatePlayerScores();
    Player winner = scores.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Gotova partija'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pobjednik: ${winner.name}'),
              SizedBox(height: 10,),
              Text('Rezultati:'),
              ...scores.entries.toList().map((entry) => Text("${entry.key.name}: ${entry.value}")),
            ],
          ),
          actions: [
            TextButton(
              onPressed: (){
                Navigator.of(context).pop();
              },
              child: const Text('Povratak')
            ),
            FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context);
              },
              child:const Text("OK"),
            ),
          ],
        );
      }
    );
  }

  Map<Player, int> _calculatePlayerScores(){
    Map<Player, int> scores = {};
    for (var scoreSheet in _scoreSheets){
      int score = scoreSheet.totalScore * 10 +
          scoreSheet.rightSoupTotal +
          scoreSheet.leftSoupTotal +
          (scoreSheet.rightSoupTotal2 ?? 0);

      for (var otherSheet in _scoreSheets){
        var position = PlayerPosition.getRelativePosition(otherSheet.position,
            scoreSheet.position, widget.game.noOfPlayers);
        switch (position){
          case PlayerPosition.left:
            score -= otherSheet.leftSoupTotal;
            break;
          case PlayerPosition.right:
            score -= otherSheet.rightSoupTotal;
            break;
          case PlayerPosition.right2:
            score -= otherSheet.rightSoupTotal2!;
            break;
          default:
            break;
        }
      }

      scores[_getPlayer(scoreSheet.playerId)] = score;
    }

    Map<Player, int> sortedScores = Map.fromEntries(
      scores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)), // Sort by values in descending order
    );
    return sortedScores;
  }

  void onRoundAdded(Round round, List<RoundScore> scores) async{
    await _loadScoreSheets();
    setState((){
      _setTotalSum();
      _rounds.add(round);
      _incrementShuffler();
    });

    for (var score in scores){
      setState(() {
        _roundScores.add(score);
        _roundScoresSheet[score.scoreSheetId]?.add(score);
      });
    }

    _checkGameOver();
  }

  void _handleRoundDelete(Round round){
    showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: const Text('Obriši?'),
          content: const Text('Obrisati rundu?'),
          actions: [
            TextButton(
              onPressed: () {
                // If the user cancels, close the dialog
                Navigator.of(context).pop();
              },
              child: const Text('Odustani'),
            ),
            TextButton(
              onPressed: () {
                _deleteRound(round);

                Navigator.of(context).pop();
              },
              child: const Text(
                'Obriši',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      });
  }

  void _deleteRound(Round round) async{
    _decrementShuffler();
    var scores = _getScoresRound(round.id!);

    for (var score in scores){
      var sheet = _getScoreSheet(score.scoreSheetId);

      if (score.score != null){
        sheet.totalScore -= score.score!;
      }
      if (score.rightSoup != null){
        sheet.rightSoupTotal -= score.rightSoup!;
      }
      if (score.leftSoup != null){
        sheet.leftSoupTotal -= score.leftSoup!;
      }
      if (score.rightSoup2 != null){
        sheet.rightSoupTotal2 = sheet.rightSoupTotal2! + score.rightSoup2!;
      }

      if (round.refeUsed && sheet.playerId == round.callerId){
        sheet.refe = true;
      }

      _dbHelper.updateScoreSheet(sheet);
      await _dbHelper.deleteRoundScore(score.id!);
    }
    await _dbHelper.deleteRound(round.id!);

    setState(() {
      _initData();
    });

    Navigator.pop(context);
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
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return _buildRoundsTable();
                  }
                );
              },
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.functions_rounded),
                const SizedBox(width: 5,),
                Text(
                  _totalSum.toString(),
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

  Widget _buildRoundsTable(){
    return Container(
      padding: EdgeInsets.all(32),
      height: MediaQuery.of(context).size.height * 0.8,
      //width: MediaQuery.of(context).size.width * 0.8,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            columnWidths: {
              0: FixedColumnWidth(40)
            },
            defaultColumnWidth: const FixedColumnWidth(80),
            border: const TableBorder(
              horizontalInside: BorderSide(width: 1, color: Colors.grey),
              verticalInside: BorderSide(width: 1, color: Colors.grey),
            ),
            children: [
              TableRow(
                children: [
                  _centerWidget(text: ''),
                  for (var player in _players)
                    _centerWidget(text: player.name, bold: true, fontsize: 16),
                  _centerWidget(text: 'Zvao', bold: true, fontsize: 16),
                  _centerWidget(text: 'Igra', bold: true, fontsize: 16),
                  _centerWidget(text: 'Kontra', bold: true, fontsize: 16),
                  _centerWidget(text: 'Refe', bold: true, fontsize: 16),
                ],
              ),
              ..._rounds.map((round){
                var caller = round.callerId != null ? _getPlayer(round.callerId!) : null;

                String gameText = '';
                if (round.calledGame == null){
                  gameText = 'dalje';
                }
                else{
                  if (round.isIgra){
                    gameText = 'igra ';
                  }
                  gameText += _cardColors[round.calledGame]!;
                }

                return TableRow(
                  children: [
                    GestureDetector(
                      onTap: (){
                        _handleRoundDelete(round);
                      },
                      child: const Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.delete),
                          )
                      ),
                    ),
                    ..._players.map((player) {
                      var score = _getRoundScore(
                          round.id!, _getScoreSheetPlayerId(player.id!).id!);
                      return _centerWidget(text:  score?.totalPoints != null ? score!.totalPoints
                          .toString() : '-');
                    }),
                    _centerWidget(text: caller != null ? caller.name : '-'),
                    _centerWidget(text: gameText),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          round.kontra ? Icons.check : Icons.close,
                      ),
                    )
                    ),
                    Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            round.refeUsed ? Icons.check : Icons.close,
                          ),
                        )
                    ),
                  ]
                );
              }),
            ],
          ),
        ),
      ),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getPlayer(scoreSheet.playerId).name.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22.0),
                    ),
                    const SizedBox(width: 8.0,),
                    if (scoreSheet.refe)
                      Icon(MdiIcons.triangleOutline)
                  ],
                )
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Table(
                      border: const TableBorder(
                        verticalInside: BorderSide(
                          width: 2,
                          style: BorderStyle.solid,
                          color: Colors.grey,
                        ),
                      ),
                      children: [
                        TableRow(
                          children: _buildHeader(scoreSheet.position),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey,
                                width: 4,
                              ),
                            )
                          ),
                        ),
                        _buildFirsRow(),
                        for (int i = 0; i < _roundScoresSheet[scoreSheet.id]!.length; i++)
                          ...[
                            if (i > 0)
                              if ((_roundScoresSheet[scoreSheet.id]![i-1].totalScore ?? 0) < 0 &&
                                  (_roundScoresSheet[scoreSheet.id]![i].totalScore ?? 0) >= 0)
                                _hatRow()
                              else if ((_roundScoresSheet[scoreSheet.id]![i-1].totalScore ?? 0) >= 0 &&
                                  (_roundScoresSheet[scoreSheet.id]![i].totalScore ?? 0) < 0)
                                _hatRow(reverse: true),
                            _roundScoreToRow(_roundScoresSheet[scoreSheet.id]![i]),
                          ],
                        _dividerRow(),
                        _sumsRow(scoreSheet),
                      ],
                    ),
                  ),
                ),
              )
            ],
          )
        );
      },
    );
  }

  List<TableCell> _buildHeader(int position) {
    int n = widget.game.noOfPlayers;
    int left = ((position - 1) % n + n) % n;
    int right = (position + 1) % n;
    List<TableCell> columns = [
      _buildDataCellHeader('${_players[left].name} juhe',
          _getScoreSheetPlayerId(_players[left].id!).refe),
      _buildDataCell('Bule'),
      _buildDataCellHeader('${_players[right].name} juhe',
          _getScoreSheetPlayerId(_players[right].id!).refe),
    ];

    if (n == 4){
      int right2 = (position + 2) % n;
      columns.add(
        _buildDataCell('${_players[right2].name} juhe'),
      );
    }

    return columns;
  }

  TableRow _buildFirsRow(){
    return TableRow(
      children: [
        const Text(''),
        _buildDataCell(widget.game.startingScore.abs().toString()),
        const Text(''),
        if (widget.game.noOfPlayers == 4)
          const Text(''),
      ],
    );
  }

  TableCell _buildDataCellHeader(String text, bool refe){
    return TableCell(
        child: Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  if (refe) ...[
                    const SizedBox(width: 8,),
                    Icon(MdiIcons.triangleOutline),
                  ]
                ],
              ),

            ))
    );
  }

  TableCell _buildDataCell(String text){
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Text(
            text,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ))
    );
  }

  TableRow? _roundScoreToRowIds(Round round, ScoreSheet scoreSheet){
    var score = _getRoundScore(round.id!, scoreSheet.id!);
    if (score == null) return null;

    return _roundScoreToRow(score);
  }

  TableRow _roundScoreToRow(RoundScore score,){
    return TableRow(
        children: [
          _scoreToCell(score.leftSoup),
          _buleToCell(score),
          _scoreToCell(score.rightSoup),
          if (widget.game.noOfPlayers == 4)
            _scoreToCell(score.rightSoup2),
        ]
    );
  }

  TableCell _scoreToCell(int? score){
    String text = score != null ? score.toString() : '-';
    return _buildDataCell(text);
  }

  TableCell _buleToCell(RoundScore score){
    String text = score.score != null ? '${score.totalScore!.abs()} (${score.score.toString()})' : '-';
    return _buildDataCell(text);
  }

  TableRow _dividerRow(){
    return TableRow(
      children: [
        for (int i = 0; i < widget.game.noOfPlayers; i++)
          const Divider(thickness: 4, color: Colors.grey,),
      ]
    );
  }

  TableRow _hatRow({bool reverse = false}){
    return TableRow(
      children: [
        const Text(''),
        Transform.rotate(
          angle: reverse ? pi : 0,
          child: Icon(
            MdiIcons.hatFedora,
            color: reverse ? Colors.red : Colors.green,
          ),
        ),
        const Text(''),
        if (widget.game.noOfPlayers == 4)
          const Text(''),
      ]
    );
  }

  TableRow _sumsRow(ScoreSheet scoreSheet){
    return TableRow(
      children: [
        _buildDataCell(scoreSheet.leftSoupTotal.toString()),
        _buildDataCell(scoreSheet.totalScore.toString()),
        _buildDataCell(scoreSheet.rightSoupTotal.toString()),
        if (widget.game.noOfPlayers == 4)
          _buildDataCell(scoreSheet.rightSoupTotal2!.toString()),
      ]
    );
  }

  Center _centerWidget({required String text, double fontsize = 14, bool bold = false}){
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          text,
          style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontsize),
        ),
      ),
    );
  }
}