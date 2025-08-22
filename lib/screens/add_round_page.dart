import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pref_blok/database/database_helper.dart';
import '../models/models.dart';
import '../enums/player_position.dart';
import 'dart:math';

class AddRoundPage extends StatefulWidget {
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

class _AddRoundPageState extends State<AddRoundPage> {
  final _formKey = GlobalKey<FormState>();
  int _selectedCaller = -1;
  List<bool> _played = List.filled(3, true);
  int _selectedContract = -1;
  final List<TextEditingController> _pointsControllers =
      List.generate(3, (_) => TextEditingController());
  final List<FocusNode> _pointsFocusNodes = List.generate(3, (_) => FocusNode());
  bool _isGame = false;
  int _multiplier = 1;
  bool _pozvanDrugi = false;
  bool? _passedBetl;
  String? _pointsError;
  final GlobalKey _toolbarKey = GlobalKey();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  final _cardColors = {'pik': 2, 'karo': 3, 'herc': 4, 'tref': 5};
  final _otherGames = {'betl': 6, 'sans': 7, 'dalje': 0};
  final _kontre = {
    'kontra': 2,
    'rekontra': 4,
    'subkontra': 8,
    'mortkontra': 16
  };

  void _saveGame() async {
    if ((_formKey.currentState == null || !_formKey.currentState!.validate()) && _selectedContract != 0) {
      return;
    }

    int totalPoints = 0;
    for (int i = 0; i < 3; i++) {
      if (_played[i]) totalPoints += int.tryParse(_pointsControllers[i].text) ?? 0;
    }
    if (_selectedContract == -1) {
      setState(() {
        _pointsError = 'Odaberite zvanje';
      });
      return;
    }

    if (_selectedContract == 6 && _passedBetl == null) {
      setState(() {
        _pointsError = 'Odaberite prolazak/pad betla';
      });
      return;
    }

    if ((_multiplier == 2 || _multiplier == 8 || _pozvanDrugi) && _played.where((p) => p).length != 2) {
      setState(() {
        _pointsError = 'Osaberite samo jednog igrača koji je došao';
      });
      return;
    }

    if (totalPoints != 10 && _selectedContract != 0 && _selectedContract != 6) {
      setState(() {
        _pointsError = 'Zbroj štihova ($totalPoints) nije 10';
      });
      return;
    } else if (_selectedContract == 0 && _played.any((x) => x)) {
      setState(() {
        _pointsError = 'Nitko nije zvao, a odabrani su igrači koji su igrali';
      });
      return;
    } else if (_selectedCaller == -1 && _selectedContract != 0) {
      setState(() {
        _pointsError = 'Odaberite pozivatelja';
      });
      return;
    } else {
      setState(() {
        _pointsError = null;
      });
    }

    int totalMultiplier = _multiplier * 2;

    Round round = Round(
      gameId: widget.game.id!,
      roundNumber: widget.roundNumber,
      callerId:
          _selectedCaller >= 0 ? widget.players[_selectedCaller].id! : null,
      isIgra: _isGame,
      multiplier: totalMultiplier,
      calledGame: _selectedContract,
    );

    if (_selectedContract == 0) {
      var roundId = await _dbHelper.insertRound(round);
      round.id = roundId;

      List<RoundScore> scores = [];
      for (var scoreSheet in widget.allScoreSheets) {
        if (scoreSheet.refesUsed < widget.game.maxRefes &&
            !scoreSheet.refe &&
            scoreSheet.totalScore < 0) {
          scoreSheet.refe = true;
          scoreSheet.refesUsed += 1;
          _dbHelper.updateScoreSheet(scoreSheet);
        }

        RoundScore score =
            RoundScore(roundId: roundId, scoreSheetId: scoreSheet.id!);

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

    if (callerScoreSheet.refe) {
      round.multiplier = round.multiplier * 2;
      totalMultiplier *= 2;

      round.refeUsed = true;

      callerScoreSheet.refe = false;
      _dbHelper.updateScoreSheet(callerScoreSheet);
    }

    var roundId = await _dbHelper.insertRound(round);
    round.id = roundId;

    var callerPoints = int.tryParse(_pointsControllers[_selectedCaller].text) ?? 0;
    //bool passed = callerPoints >= 6;

    List<bool> passed = [];
    for (int i = 0; i < _played.length; i++) {
      if (!_played[i]) {
        passed.add(true);
      } else if (i == _selectedCaller) {
        if (_selectedContract != 6) {
          passed.add(callerPoints >= 6);
        } else {
          passed.add(_passedBetl!);
        }
      } else if (_multiplier == 2 || _multiplier == 8) {
        round.kontra = true;
        if (_selectedContract == 6) {
          passed.add(!_passedBetl!);
        } else {
          passed.add(callerPoints < 6);
        }
      } else if (_selectedContract == 6) {
        passed.add(true);
      } else if (callerPoints <= 6) {
        passed.add(true);
      } else if (_pozvanDrugi) {
        passed.add(callerPoints <= 6);
      } else {
        int playerPoints = int.parse(_pointsControllers[i].text);
        passed.add(playerPoints >= 2);
      }
    }

    int contractValue;
    if (!passed.any((item) => item == false)) {
      contractValue = min(
          totalMultiplier * (_selectedContract + (_isGame ? 1 : 0)),
          widget.maxContract);
    } else {
      contractValue = totalMultiplier * (_selectedContract + (_isGame ? 1 : 0));
    }

    List<RoundScore> scores = [];

    for (int i = 0; i < widget.scoreSheets.length; i++) {
      var scoreSheet = widget.scoreSheets[i];
      RoundScore score =
          RoundScore(roundId: roundId, scoreSheetId: scoreSheet.id!);

      if (!_played[i] || _selectedContract == 0) {
        score.totalScore = scoreSheet.totalScore;
        int scoreId = await _dbHelper.insertRoundScore(score);
        score.id = scoreId;
        scores.add(score);
        continue;
      }

      var callerPosition = PlayerPosition.getRelativePosition(
          scoreSheet.position,
          callerScoreSheet.position,
          widget.game.noOfPlayers);
      int soup = _selectedContract != 6
          ? min(contractValue * int.parse(_pointsControllers[i].text),
              contractValue * 5)
          : (passed[_selectedCaller] ? 0 : contractValue * 5);
      switch (callerPosition) {
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

      if (score.score != null) {
        score.totalScore = scoreSheet.totalScore + score.score!;
      } else {
        score.totalScore = scoreSheet.totalScore;
      }

      int? points = int.tryParse(_pointsControllers[i].text);

      if (points == null || _selectedContract == 6) {
        if (_selectedContract == 6) {
          if (callerPosition == PlayerPosition.center) {
            points = _passedBetl! ? 0 : 10;
          } else {
            points = _passedBetl! ? (round.kontra ? 10 : 0) : 0;
          }
        } else {
          points = 0;
        }
      }

      score.totalPoints = points;

      int id = await _dbHelper.insertRoundScore(score);
      score.id = id;

      scores.add(score);

      if (score.score != null) {
        scoreSheet.totalScore += score.score!;
      }

      if (score.leftSoup != null) {
        scoreSheet.leftSoupTotal += score.leftSoup!;
      }

      if (score.rightSoup != null) {
        scoreSheet.rightSoupTotal += score.rightSoup!;
      }

      if (score.rightSoup2 != null && widget.game.noOfPlayers == 4) {
        scoreSheet.rightSoupTotal2 =
            scoreSheet.rightSoupTotal2! + score.rightSoup2!;
      }

      _dbHelper.updateScoreSheet(scoreSheet);
    }

    round.multiplier = totalMultiplier;
    _dbHelper.updateRound(round);

    widget.onRoundCreated(round, scores);
    Navigator.pop(context);
  }

  ScoreSheet getScoreSheet(int playerId) {
    return widget.scoreSheets.firstWhere((x) => x.playerId == playerId);
  }

  void _setCallerPoints([int index = -1]) {
    if (_selectedCaller == -1 || index == _selectedCaller) return;

    int total = 0;
    for (int i = 0; i < _pointsControllers.length; i++) {
      if (i == _selectedCaller) continue;
      var points =
          (_played[i]) ? int.tryParse(_pointsControllers[i].text) ?? 0 : 0;
      total += points;
    }
    setState(() {
      var callerPoints = 10 - total;
      _pointsControllers[_selectedCaller].text = callerPoints.toString();
    });
  }

  bool? _getCallerPassed() {
    if (_selectedCaller == -1 || _pointsControllers[_selectedCaller].text.isEmpty) return null;
    if (_selectedContract == 6) return _passedBetl;

    return int.parse(_pointsControllers[_selectedCaller].text) >= 6;
  }

  @override
  void initState() {
    super.initState();
    for (var node in _pointsFocusNodes) {
      node.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _pointsControllers) {
      controller.dispose();
    }
    for (var node in _pointsFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.existingRound == null ? 'Nova runda' : 'Uredi rundu'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Zvanja',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(
                height: 20.0,
              ),
              _contractWrap(),
              const SizedBox(
                height: 30.0,
              ),
              ClipRect(
                child: AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: _selectedContract > 0
                        ? Column(
                            children: [
                              const Text(
                                'Štihovi',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Form(
                                key: _formKey,
                                child: _playersColumn(context),
                              ),
                              if (_pointsError != null) ...[
                                const SizedBox(
                                  height: 12,
                                ),
                                Text(
                                  _pointsError!,
                                  style: TextStyle(
                                      color: cs.error, fontSize: 16.0),
                                ),
                              ],
                              const Text(
                                'Kontre',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 16,),
                              _kontraWrap()
                            ],
                          )
                        : const SizedBox.shrink()),
              ),
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
              onPressed: () {
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
      bottomSheet: _buildKeyboardToolbar(context),
    );
  }

  Widget _playersColumn(BuildContext context) {
    final tbH = ( _toolbarKey.currentContext?.findRenderObject() as RenderBox? )?.size.height ?? 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + tbH,
        ),
        child: Column(
          children: List.generate(3, (index) {
            return PlayerCard(
              key: ValueKey('player_$index'),
              player: widget.players[index],
              isCaller: _selectedCaller == index,
              played: _played[index],
              showPoints: _selectedContract != 6,
              refe: widget.scoreSheets[index].refe,
              pointsController: _pointsControllers[index],
              focusNode: _pointsFocusNodes[index],
              passed: _getCallerPassed(),
              toolbarKey: _toolbarKey,
              onTogglePassed: (v){
                setState(() {
                  _passedBetl = v;
                });
              },
              onMakeCaller: () {
                setState(() {
                  _selectedCaller = index;
                  _played[index] = true;
                  _passedBetl = null;
                  _pointsError = null;
                });
                _setCallerPoints();
              },
              onTogglePlayed: () {
                setState(() {
                  _played[index] = !_played[index];
                  _pointsError = null;
                });

                if (_played[index] && _pointsControllers[index].text.isEmpty) {
                  _pointsFocusNodes[index].requestFocus();
                }
                _setCallerPoints(index);
              },
              onPointsChanged: (v) {
                if (index != _selectedCaller) {
                  _setCallerPoints(index);           // same as your onChanged branch
                }
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _contractWrap() {
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
            const SizedBox(
              height: 16.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var game in _otherGames.entries)
                  _otherGameWidget(game.key, game.value),
              ],
            ),
          ],
        ),
        const SizedBox(
          height: 16,
        ),
        _isGameWidget(),
      ],
    );
  }

  Widget _kontraWrap() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var kontra in _kontre.entries)
          _kontraWidget(kontra.key, kontra.value),
      ],
    );
  }

  Widget _cardColorWidget(String color, int value) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedContract = value;
          _pointsError = null;
          _passedBetl = null;
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
                    )
                  : null,
              child: Image.asset(
                'assets/karte/$color.png',
                fit: BoxFit.contain,
              ),
            ),
            Text(
                '(${(value + (_isGame && value != 0 ? 1 : 0)) * _multiplier})'),
          ],
        ),
      ),
    );
  }

  Widget _otherGameWidget(String game, int value) {
    return GestureDetector(
        onTap: () {
          setState(() {
            _selectedContract = value;
            _pointsError = null;
            _passedBetl = null;
            if (value == 0) {
              _selectedCaller = -1;
              _played = List.filled(3, false);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
          child: Container(
            padding: EdgeInsets.all(_selectedContract == value ? 12 : 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedContract == value ? Colors.blue : Colors.grey,
                width: _selectedContract == value ? 2 : 1,
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
                    ]
                  : null,
            ),
            child: Text(
                '$game (${(value + (_isGame && value != 0 ? 1 : 0)) * _multiplier})'),
          ),
        ));
  }

  Widget _isGameWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
            value: _isGame,
            onChanged: (value) {
              setState(() {
                _isGame = value!;
              });
            }),
        const Text('Igra?'),
        const SizedBox(
          width: 24.0,
        ),
        Checkbox(
            value: _pozvanDrugi,
            onChanged: (value) {
              setState(() {
                _pozvanDrugi = value!;
              });
            }),
        const Text('Pozvan drugi?'),
      ],
    );
  }

  Widget _kontraWidget(String kontra, int value) {
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
                color: _multiplier == value ? Colors.blue : Colors.grey,
                width: _multiplier == value ? 2 : 1,
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
                    ]
                  : null,
            ),
            child: Text('$kontra (x$value)'),
          ),
        ));
  }

  int? _prevIndex(int from) {
    for (int i = from - 1; i >= 0; i--) {
      if (i != _selectedCaller && _played[i]) return i;
    }
    return null;
  }
  int? _nextIndex(int from) {
    for (int i = from + 1; i < _pointsFocusNodes.length; i++) {
      if (i != _selectedCaller && _played[i]) return i;
    }
    return null;
  }

  Widget _buildKeyboardToolbar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final kbOpen = viewInsets > 0;
    final current = _pointsFocusNodes.indexWhere((n) => n.hasFocus);
    final hasFocus = current != -1;
    final int? prev = current == -1 ? null : _prevIndex(current);
    final int? next = current == -1 ? null : _nextIndex(current);

    return Offstage(
      offstage: !(kbOpen && hasFocus),
      child: Material(
        key: _toolbarKey,
        elevation: 3,
        color: cs.surface,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: cs.outlineVariant)),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Previous',
                onPressed: (prev != null)
                    ? () => _pointsFocusNodes[prev].requestFocus()
                    : null,
                icon: const Icon(Icons.arrow_left),
                color: cs.primary,
              ),
              IconButton(
                tooltip: 'Next',
                onPressed: (next != null)
                    ? () => _pointsFocusNodes[next].requestFocus()
                    : null,
                icon: const Icon(Icons.arrow_right),
                color: cs.primary,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => FocusScope.of(context).unfocus(),
                icon: const Icon(Icons.keyboard_hide),
                label: const Text('Done'),
                style: TextButton.styleFrom(foregroundColor: cs.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class PlayerCard extends StatelessWidget {
  final Player player;
  final bool isCaller; // _selectedCaller == index
  final bool played; // _played[index]
  final bool showPoints; // betl
  final bool refe;
  final TextEditingController pointsController; // _pointsControllers[index]
  final VoidCallback onMakeCaller;
  final VoidCallback onTogglePlayed;
  final ValueChanged<String>? onPointsChanged;
  final FocusNode focusNode;
  final bool? passed;
  final ValueChanged<bool> onTogglePassed;
  final GlobalKey toolbarKey;

  const PlayerCard({
    super.key,
    required this.player,
    required this.isCaller,
    required this.played,
    required this.showPoints,
    required this.refe,
    required this.pointsController,
    required this.onMakeCaller,
    required this.onTogglePlayed,
    this.onPointsChanged,
    required this.focusNode,
    required this.passed,
    required this.onTogglePassed,
    required this.toolbarKey,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final isCallerRefetl = isCaller && refe;

    final cardBg = isCallerRefetl
        ? cs.tertiaryContainer.withOpacity(Theme.of(context).brightness == Brightness.dark ? .25 : .18)
        : (isCaller
        ? cs.secondaryContainer.withOpacity(.18)
        : Theme.of(context).cardColor);

    final borderColor = isCallerRefetl
        ? cs.tertiary
        : (isCaller ? cs.secondary : cs.outlineVariant);

    final borderWidth = isCallerRefetl ? 1.8 : 1.2;
    final elev = isCallerRefetl ? 2.0 : 0.0;

    return Card(
      elevation: elev,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: cardBg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
              color: borderColor, width: borderWidth)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(
              height: 12,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isCaller) ...[
                  Expanded(flex: 1, child: _buildActions(context)),
                  const SizedBox(width: 10),
                ],
                isCaller && showPoints
                    ? Expanded(child: _buildPointsField())
                    : Flexible(flex: 0, child: _buildPointsField()),
              ],
            ),
            if (isCaller && !showPoints)
              _buildBetlField(context),
          ],
        ),
      ),
    );

  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          isCaller
              ? ((passed == null || passed == true)
                  ? Icons.emoji_events
                  : Icons.sentiment_dissatisfied_outlined
                )
              : Icons.person_outline_outlined,
          size: 18,
          color: isCaller ? cs.secondary : cs.onSurfaceVariant,
        ),
        const SizedBox(
          width: 6,
        ),
        Expanded(
          child: Row(
            children: [
              Text(player.name, style: Theme.of(context).textTheme.titleMedium),
              if (refe && isCaller) ...[
                const SizedBox(width: 6),
                Icon(MdiIcons.triangleOutline, size: 18, color: cs.onSurfaceVariant),
              ],
            ],
          ),
        ),
        if (refe && !isCaller) ...[
          const SizedBox(width: 8,),
          Icon (MdiIcons.triangleOutline, size: 18, color: cs.onSurfaceVariant,)
        ],
        if (isCaller) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(999)),
            child: Text(
              'Pozivatelj',
              style: TextStyle(color: cs.onSecondaryContainer),
            ),
          )]
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (isCaller) return const SizedBox(height: 4,);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onMakeCaller,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Zvao'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: played
              ? FilledButton(
            onPressed: onTogglePlayed,
            style: FilledButton.styleFrom(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Došao'),
          )
              : OutlinedButton(
            onPressed: onTogglePlayed,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Nije došao'),
          ),
        ),
      ],
    );
  }

  Widget _buildPointsField() {
    final toolbarBox = toolbarKey.currentContext?.findRenderObject() as RenderBox?;
    final toolbarH = toolbarBox?.size.height ?? 0;

    return ClipRect(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        child: (showPoints && played)
            ? SizedBox(
                width: 80,
                child: TextFormField(
                  scrollPadding: EdgeInsets.only(bottom: toolbarH + 24),
                  focusNode: focusNode,
                  controller: pointsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Štihovi',
                    isDense: true,
                  ),
                  onChanged: (v) => onPointsChanged?.call(v),
                  validator: (value) {
                    if (!(showPoints && played)) return null;
                    if (value == null || value.trim().isEmpty) {
                      return 'Unesite broj štihova';
                    }
                    final n = int.tryParse(value);
                    if (n == null) return 'Nije unesen broj';
                    if (n < 0 || n > 10) return 'Ilegalan broj štihova';
                    return null;
                  },
                  onTapOutside: (event) {
                    final toolbarBox = toolbarKey.currentContext?.findRenderObject() as RenderBox?;
                    if (toolbarBox != null) {
                      final offset = toolbarBox.localToGlobal(Offset.zero);
                      final rect = offset & toolbarBox.size;
                      if (rect.contains(event.position)) {
                        return;
                      }
                    }

                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                ),
            )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildBetlField(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => onTogglePassed(true),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Prošao'),
            style: FilledButton.styleFrom(
              backgroundColor: passed == true
                  ? cs.primaryContainer
                  : cs.surface,
              foregroundColor: passed == true
                  ? cs.onPrimaryContainer
                  : cs.onSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
          ),
        )
      ),
        const SizedBox(width: 10,),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => onTogglePassed(false),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Pao'),
            style: FilledButton.styleFrom(
              backgroundColor: passed == false
                  ? cs.errorContainer
                  : cs.surface,
              foregroundColor: passed == false
                  ? cs.onErrorContainer
                  : cs.onSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
