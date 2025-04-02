import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pref_blok/database/database_helper.dart';
import '../models/models.dart';
import '../enums/player_position.dart';
import 'dart:math';

class AddRoundPage extends StatefulWidget{
  Game game;
  List<ScoreSheet> scoreSheets;
  List<ScoreSheet> allScoreSheets;
  List<Player> players;
  Round? existingRound;
  int roundNumber;
  int shuffler;
  int maxContract;
  final Function(Round, List<RoundScore>) onRoundCreated;

  AddRoundPage({
    required this.game,
    required this.scoreSheets,
    super.key,
    this.existingRound,
    required this.players,
    required this.roundNumber,
    required this.shuffler,
    required this.onRoundCreated,
    required this.maxContract,
    required this.allScoreSheets,
  });

  @override
  _AddRoundPageState createState() => _AddRoundPageState();
}

class _AddRoundPageState extends State<AddRoundPage>{
  final _formKey = GlobalKey<FormState>();
  int _selectedCaller = -1;
  List<bool> _played = List.filled(3, true);
  int _selectedContract = -1;
  final List<TextEditingController> _pointsControllers = List.generate(3, (_) => TextEditingController());
  bool _isGame = false;
  int _multiplier = 1;
  bool _pozvanDrugi = false;

  String? _pointsError;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  final _cardColors = {'pik': 2, 'karo': 3, 'herc': 4, 'tref': 5};
  final _otherGames = {'betl': 6, 'sans': 7, 'dalje': 0};
  final _kontre = {'kontra': 2, 'rekontra': 4, 'subkontra': 8, 'mortkontra' : 16};



  void _saveGame() async{
    if (!_formKey.currentState!.validate()){
      return;
    }

    int totalPoints = 0;
    for (int i = 0; i < 3; i++){
      if (_played[i]) totalPoints += int.parse(_pointsControllers[i].text);
    }
    if (_selectedContract == -1){
      setState(() {
        _pointsError = 'Odaberite zvanje';
      });
      return;
    }
    if (totalPoints != 10 && _selectedContract != 0){
      setState(() {
        _pointsError = 'Zbroj štihova ($totalPoints) nije 10';
      });
      return;
    }
    else if (_selectedContract == 0 && _played.any((x) => x)){
      setState(() {
        _pointsError = 'Nitko nije zvao, a odabrani su igrači koji su igrali';
      });
      return;
    }
    else if (_selectedCaller == -1 && _selectedContract != 0){
      setState(() {
        _pointsError = 'Odaberite pozivatelja';
      });
      return;
    }
    else{
      setState(() {
        _pointsError = null;
      });
    }


    int totalMultiplier = _multiplier*2;

    Round round = Round(
      gameId: widget.game.id!,
      roundNumber: widget.roundNumber,
      callerId: _selectedCaller >= 0 ? widget.players[_selectedCaller].id! : null,
      isIgra: _isGame,
      multiplier: totalMultiplier,
      calledGame: _selectedContract,
    );

    if (_selectedContract == 0){
      var roundId = await _dbHelper.insertRound(round);
      round.id = roundId;

      List<RoundScore> scores = [];
      for (var scoreSheet in widget.allScoreSheets){  
        if (scoreSheet.refesUsed < widget.game.maxRefes && !scoreSheet.refe && scoreSheet.totalScore < 0){
          scoreSheet.refe = true;
          scoreSheet.refesUsed += 1;
          _dbHelper.updateScoreSheet(scoreSheet);
        }

        RoundScore score = RoundScore(roundId: roundId, scoreSheetId: scoreSheet.id!);

        score.totalScore = scoreSheet.totalScore;
        int scoreId = await _dbHelper.insertRoundScore(score);
        score.id = scoreId;
        scores.add(score);

      }
      widget.onRoundCreated(round, scores);
      Navigator.pop(context);
      return;
    }

    var caller = widget.players[_selectedCaller];
    var callerScoreSheet = getScoreSheet(caller.id!);

    if (callerScoreSheet.refe){
      round.multiplier = round.multiplier*2;
      totalMultiplier *= 2;

      round.refeUsed = true;

      callerScoreSheet.refe = false;
      _dbHelper.updateScoreSheet(callerScoreSheet);
      // for (var scoreSheet in widget.scoreSheets){
      //   var position = PlayerPosition.getRelativePosition(scoreSheet.position,
      //       callerScoreSheet.position, widget.game.noOfPlayers);
      //
      //   switch (position){
      //     case PlayerPosition.left:
      //       scoreSheet.refeLeft = false;
      //       break;
      //     case PlayerPosition.right:
      //       scoreSheet.refeRight = false;
      //       break;
      //     case PlayerPosition.right2:
      //       scoreSheet.refeRight2 = false;
      //       break;
      //     default:
      //       break;
      //   }
      //
      //   _dbHelper.updateScoreSheet(scoreSheet);
      // }
    }

    var roundId = await _dbHelper.insertRound(round);
    round.id = roundId;

    var callerPoints = int.parse(_pointsControllers[_selectedCaller].text);
    //bool passed = callerPoints >= 6;

    List<bool> passed = [];
    for (int i = 0; i < _played.length; i++){
      if (!_played[i]) {
        passed.add(true);
      }
      else if (i == _selectedCaller) {
        if(_selectedContract != 6) {
          passed.add(callerPoints >= 6);
        }
        else {
          passed.add(callerPoints < 1);
        }
      }
      else if (_multiplier == 2 || _multiplier == 8){
        round.kontra = true;
        if (_selectedContract == 6){
          passed.add(callerPoints > 0);
        }
        else{
          passed.add(callerPoints < 6);
        }
      }
      else if(_selectedContract == 6){
        passed.add(true);
      }
      else if (callerPoints <= 6){
        passed.add(true);
      }
      else if (_pozvanDrugi) {
        passed.add(callerPoints <= 6);
      }
      else{
        int playerPoints = int.parse(_pointsControllers[i].text);
        passed.add(playerPoints >= 2);
      }
    }

    int contractValue;
    if (!passed.any((item) => item == false)){
      contractValue = min(totalMultiplier * (_selectedContract + (_isGame ? 1 : 0)),
          widget.maxContract);
    } else {
      contractValue = totalMultiplier * (_selectedContract + (_isGame ? 1 : 0));
    }


    List<RoundScore> scores = [];

    for (int i = 0; i < widget.scoreSheets.length; i++){
      var scoreSheet = widget.scoreSheets[i];
      RoundScore score = RoundScore(roundId: roundId, scoreSheetId: scoreSheet.id!);

      if (!_played[i] || _selectedContract == 0){
        score.totalScore = scoreSheet.totalScore;
        int scoreId = await _dbHelper.insertRoundScore(score);
        score.id = scoreId;
        scores.add(score);
        continue;
      }

      var callerPosition = PlayerPosition.getRelativePosition(scoreSheet.position,
          callerScoreSheet.position, widget.game.noOfPlayers);
      int soup = _selectedContract != 6 ?
        min(contractValue * int.parse(_pointsControllers[i].text), contractValue * 5)
        : (passed[_selectedCaller] ? 0 : contractValue * 5);
      switch (callerPosition){
        case PlayerPosition.left:
          score.leftSoup = soup;
          break;
        case PlayerPosition.right:
          score.rightSoup = soup;
          break;
        case PlayerPosition.right2:
          score.rightSoup2 = soup;
          break;
        case PlayerPosition.center:
          score.score = passed[i] ? contractValue : -contractValue;
          break;
      }
      if (!passed[i]) score.score = -contractValue;

      if (score.score != null){
        score.totalScore = scoreSheet.totalScore + score.score!;
      } else {
        score.totalScore = scoreSheet.totalScore;
      }

      score.totalPoints = int.parse(_pointsControllers[i].text);

      int id = await _dbHelper.insertRoundScore(score);
      score.id = id;

      scores.add(score);

      if (score.score != null) {
        scoreSheet.totalScore += score.score!;
      }

      if (score.leftSoup != null){
        scoreSheet.leftSoupTotal += score.leftSoup!;
      }

      if (score.rightSoup != null){
        scoreSheet.rightSoupTotal += score.rightSoup!;
      }

      if (score.rightSoup2 != null && widget.game.noOfPlayers == 4){
        scoreSheet.rightSoupTotal2 = scoreSheet.rightSoupTotal2! + score.rightSoup2!;
      }

      _dbHelper.updateScoreSheet(scoreSheet);
    }

    round.multiplier = totalMultiplier;
    _dbHelper.updateRound(round);

    widget.onRoundCreated(round, scores);
    Navigator.pop(context);
  }

  ScoreSheet getScoreSheet(int playerId){
    return widget.scoreSheets.firstWhere((x) => x.playerId == playerId);
  }

  void _setCallerPoints([int index = -1]){
    if (_selectedCaller == -1 || index == _selectedCaller) return;

    int total = 0;
    for (int i = 0; i < _pointsControllers.length; i++){
      if (i == _selectedCaller) continue;
      var points = (_played[i])
          ? int.tryParse(_pointsControllers[i].text) ?? 0
          : 0;
      total += points;
    }
    setState(() {
      var callerPoints = 10 - total;
      _pointsControllers[_selectedCaller].text = callerPoints.toString();
    });
  }

  @override
  void dispose() {
    for (var controller in _pointsControllers){
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingRound == null ?  'Nova runda' : 'Uredi rundu'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Štihovi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
              const SizedBox(height: 16.0,),
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    SizedBox(width:  5,),
                    Text('Zvao', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 16,),
                    Text('Došao', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Form(
                key: _formKey,
                child: _playersColumn(),
              ),
              if (_pointsError != null) ...[
                const SizedBox(height: 8,),
                Text(
                  _pointsError!,
                  style: const TextStyle(color: Colors.red, fontSize: 14.0),
                ),
              ],
              const SizedBox(height: 40,),
              const Text('Zvanja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
              const SizedBox(height: 20.0,),
              _contractWrap(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: (){
                Navigator.pop(context);
              },
              child: const Text('Odustani'),
            ),
            ElevatedButton(
              onPressed: () {
                _saveGame();
              },
              child: const Text('Spremi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playersColumn() {
    return Column(
      children: List.generate(3, (index) {
        return _playersRow(index);
      }),
    );
  }

  Widget _playersRow(int index) {
    return Row(
      children: [
        Radio(
          value: index,
          groupValue: _selectedCaller,
          toggleable: true,
          onChanged: (value) {
            int caller = value ?? -1;
            setState(() {
              _selectedCaller = caller;
              if (caller != -1){
                _played[index] = true;
              } else{
                _selectedContract = 0;
                _played = List.filled(_played.length, false);
              }
            });
            _setCallerPoints();
          },
        ),
        Checkbox(
          value: _played[index],
          onChanged: _selectedCaller == index
              ? null
              : (value) {
                  setState(() {
                    _played[index] = value!;
                  });
                  _setCallerPoints();
              },
        ),
        Expanded(
          child: TextFormField(
            controller: _pointsControllers[index],
            decoration: InputDecoration(
              labelText: '${widget.players[index].name} štihovi'
            ),
            enabled: _played[index],
            keyboardType: TextInputType.number,
            onChanged: (value) {
              if (index != _selectedCaller){
                _setCallerPoints(index);
              }
            },
            validator: (value) {
              if (!_played[index] || _selectedContract == 0) return null;

              if ((value == null || value.trim().isEmpty)){
                return 'Unesite broj štihova';
              }
              try {
                int n = int.parse(value);
                if (n < 0 || n > 10){
                  return 'Ilegalan broj štihova';
                }
              } catch (e){
                return 'Nije unesen broj';
              }
              return null;
            },
            onTapOutside: (_) => {
              FocusManager.instance.primaryFocus?.unfocus()
            },
          ),
        ),
        if (widget.scoreSheets[index].refe) ...[
          const SizedBox(width: 8,),
          Icon(MdiIcons.triangleOutline),
        ]
      ],
    );
  }

  Widget _contractWrap(){
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: [
        Wrap(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var color in _cardColors.entries)
                  _cardColorWidget(color.key, color.value),
              ],
            ),
            const SizedBox(height: 16.0,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var game in _otherGames.entries)
                  _otherGameWidget(game.key, game.value),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16,),
        _isGameWidget(),

        const SizedBox(height: 16,),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var kontra in _kontre.entries)
              _kontraWidget(kontra.key, kontra.value),
          ],
        ),
      ],
    );
  }
  
  Widget _cardColorWidget(String color, int value) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedContract = value;
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 16.0),
        child: Column(
          children: [
            Container(
              width: _selectedContract == value ? 60 : 50,
              height: _selectedContract == value ? 60 : 50,
              decoration: _selectedContract == value
                ? BoxDecoration(
                    border: Border.all(
                      color: Colors.blue,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        spreadRadius: 2,
                        offset: Offset(0, 3),
                      )
                    ],
                ) : null,
              child: Image.asset(
                'assets/karte/$color.png',
                fit: BoxFit.contain,
              ),
            ),

            Text('(${(value + (_isGame && value != 0 ? 1 : 0)) * _multiplier})'),
          ],
        ),
      ),
    );
  }

  Widget _otherGameWidget(String game, int value){
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedContract = value;
          if (value == 0){
            _selectedCaller = -1;
            _played = List.filled(3, false);
          }
          else if (value == 6){
            _played = List.filled(3, true);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
        child: Container(
          padding:  EdgeInsets.all(_selectedContract == value ? 12 : 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedContract == value
                  ? Colors.blue
                  : Colors.grey,
              width: _selectedContract == value
                ? 2
                : 1,
            ),
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: _selectedContract == value
              ? [
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  spreadRadius: 2,
                  offset: Offset(0, 3),
                )
                ] : null,
          ),
          child: Text('$game (${(value + (_isGame && value != 0 ? 1 : 0)) * _multiplier})'),
        ),
      )
    );
  }

  Widget _isGameWidget(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: _isGame,
          onChanged: (value){
            setState(() {
              _isGame = value!;
            });
          }
        ),
        const Text('Igra?'),
        const SizedBox(width: 24.0,),
        Checkbox(
            value: _pozvanDrugi,
            onChanged: (value){
              setState(() {
                _pozvanDrugi = value!;
              });
            }
        ),
        const Text('Pozvan drugi?'),
      ],
    );
  }

  Widget _kontraWidget(String kontra, int value){
    return GestureDetector(
        onTap: () {
          setState(() {
            _multiplier = _multiplier != value ? value : 1;
          });
        },
        child: Padding(
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color: _multiplier == value
                    ? Colors.blue
                    : Colors.grey,
                width: _multiplier == value
                    ? 2
                    : 1,
              ),
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: _multiplier == value
                  ? [
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  spreadRadius: 2,
                  offset: Offset(0, 3),
                )
              ] : null,
            ),
            child: Text('$kontra (x$value)'),
          ),
        )
    );
  }
}