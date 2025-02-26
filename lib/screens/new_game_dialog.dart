import 'package:flutter/material.dart';
import 'package:pref_blok/database/database_helper.dart';
import 'package:pref_blok/database/game_queries.dart';
import '../models/models.dart';
import 'add_player_dialog.dart';
import '../database/player_queries.dart';

class NewGameDialog extends StatefulWidget {
  final Function(Game) onCreateGame;
  final Game? game;
  final List<Player>? players;

  const NewGameDialog({
    required this.onCreateGame,
    this.game,
    this.players,
    super.key
  });

  @override
  _NewGameDialogState createState() => _NewGameDialogState();
}

class _NewGameDialogState extends State<NewGameDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _startScoreController = TextEditingController();
  final _maxRefesController = TextEditingController();
  final List<TextEditingController> _playerControllers = List.generate(4, (_) => TextEditingController());
  final ScrollController _scrollController = ScrollController();
  final List<FocusNode> _dropdownFocusNodes = List.generate(4, (index) => FocusNode());

  final DatabaseHelper dbHelper = DatabaseHelper();
  final PlayerQueries playerQueries = PlayerQueries();
  final GameQueries gameQueries = GameQueries();

  List<Player> _players = [];
  final List<Player?> _selectedPlayers = List.filled(4, null);
  final List<Player> _placeholderPlayers = List.generate(4, (_) => Player(name: ''));
  List<bool> _dropdownValid = List.filled(4, true);

  final List<GlobalKey> _dropdownKeys = List.generate(4, (index) => GlobalKey());

  int _noOfPlayers =  3;

  @override
  void initState(){
    super.initState();
    _loadPlayers();
    for (int i = 0; i < _playerControllers.length; i++){
      _playerControllers[i].addListener( () {
          setState(() {
            _selectedPlayers[i] = Player(name: _playerControllers[i].text);
            _dropdownValid = List.filled(4, true);
          });
        }
      );

      setState(() {
        if (widget.game != null && widget.players != null){
          if (widget.game!.name != null) _nameController.text = widget.game!.name!;
          for (int i = 0; i < widget.game!.noOfPlayers; i++){
            Player player = widget.players![i];
            _playerControllers[i].text = player.name;
            _selectedPlayers[i] = player;
            _noOfPlayers = widget.players!.length;
            _startScoreController.text = widget.game!.startingScore.toString();
            _maxRefesController.text = widget.game!.maxRefes.toString();
          }
        } else{
          _maxRefesController.text = '1';
        }
      });
    }
  }

  void _loadPlayers () async {
    final playersData = await dbHelper.getPlayers();
    playersData.sort((a, b) => a.name.compareTo(b.name));
    setState(() {
      _players = playersData;
    });
  }

  Future<bool> _checkPlayers() async{
    bool valid = true;
    for (int i = 0; i < _noOfPlayers; i++){
      if (_selectedPlayers[i] != null){
        _selectedPlayers[i] = await playerQueries.getPlayerByName(_selectedPlayers[i]!.name);
      }
      if (_selectedPlayers[i] == null || _selectedPlayers[i]!.id == null){
        setState(() {
          _dropdownValid[i] = false;
        });
        valid = false;
      }
    }
    return valid;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scrollController.dispose();
    _startScoreController.dispose();
    _maxRefesController.dispose();
    for(var controlller in _playerControllers){
      controlller.dispose();
    }
    super.dispose();
  }

  void _showAddPlayerDialog(Player? player, int i) {
    showDialog(
        context: context,
        builder: (context) => AddPlayerDialog(
          player: player,
          onPlayerAdded: (Player player){
            setState(() {
              _selectedPlayers[i] = player;
              _playerControllers[i].text = player.name;
              _loadPlayers();
            });
          },
        )
    );
  }

  void _saveGame() async{
    if (!_formKey.currentState!.validate()){
      return;
    }

    bool valid = true;
    valid = await _checkPlayers();

    if (!valid) return;

    int startingScore = -int.parse(_startScoreController.text).abs();
    int maxRefes = int.parse(_maxRefesController.text);

    if (widget.game != null  && widget.game!.id != null){
      Game updatedGame = widget.game!;
      updatedGame.name = _nameController.text;
      updatedGame.noOfPlayers = _noOfPlayers;
      updatedGame.startingScore = startingScore.abs();
      updatedGame.maxRefes = maxRefes;

      List<ScoreSheet> scoreSheets = await gameQueries.getScoreSheetsGame(updatedGame.id);
      for (int i = 0; i < scoreSheets.length; i++){
        ScoreSheet scoreSheet = scoreSheets[i];
        if (_selectedPlayers[i] != null && _selectedPlayers[i]!.id != null){
          scoreSheet.playerId = _selectedPlayers[i]!.id!;
          scoreSheet.position = i;

          await dbHelper.updateScoreSheet(scoreSheet);
        }
      }

      if (scoreSheets.length < _noOfPlayers) {
        ScoreSheet newScoreSheet = ScoreSheet(
          playerId: _selectedPlayers.last!.id!,
          gameId: updatedGame.id!,
          totalScore: updatedGame.startingScore,
          position: 3
        );

        dbHelper.insertScoreSheet(newScoreSheet);
      }

      if (scoreSheets.length > _noOfPlayers) {
         dbHelper.deleteScoreSheet(scoreSheets.last.id!);
      }

      await dbHelper.updateGame(updatedGame);
      widget.onCreateGame(updatedGame);

    }
    else {
      Game game = Game(
        date: DateTime.now(),
        noOfPlayers: _noOfPlayers,
        startingScore: startingScore,
        name: _nameController.text,
        maxRefes: maxRefes,
      );

      int gameId = await dbHelper.insertGame(game);

      game.id = gameId;

      for (int i = 0; i < _noOfPlayers; i++) {
        ScoreSheet scoreSheet = ScoreSheet(
          playerId: _selectedPlayers[i]!.id!,
          gameId: gameId,
          totalScore: startingScore,
          position: i,
          rightSoupTotal2: _noOfPlayers == 4 ? 0 : null,
          //refeRight2: _noOfPlayers == 4 ? false : null,
        );

        dbHelper.insertScoreSheet(scoreSheet);
      }
      widget.onCreateGame(game);

    }

    Navigator.of(context).pop();
  }

  double _calculateDropdownHeight(BuildContext context, GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return 200; // Default height if calculation fails

    final dropdownPosition = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeightBelow = screenHeight - dropdownPosition.dy - 20; // 20px padding

    return availableHeightBelow.clamp(150, 300); // Ensure min 150px and max 300px height
  }


  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.game == null ? 'Nova partija' : 'Uređivanje partije',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16,),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Naziv partije',
                          ),
                        ),
                        TextFormField(
                          controller: _startScoreController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Početne bule',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty){
                              return 'Ne smije biti prazno';
                            }
                            try{
                              if (int.parse(value) <= 0){
                                return 'Nedozvoljena vrijednost';
                              }
                            } catch (e) {
                                return 'Nije broj';
                            }

                            return null;
                          },
                          onChanged: (value){
                            _formKey.currentState?.validate();
                          },
                        ),
                        TextFormField(
                          controller: _maxRefesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Maksimalan broj refea',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty){
                              return 'Ne smije biti prazno';
                            }
                            try{
                              if (int.parse(value) <= 0){
                                return 'Nedozvoljena vrijednost';
                              }
                            } catch (e) {
                              return 'Nije broj';
                            }

                            return null;
                          },
                          onChanged: (value){
                            _formKey.currentState?.validate();
                          },
                        ),
                        for (int i = 0; i < _noOfPlayers; i++)
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    if(_players.isNotEmpty)
                                      Focus(
                                          focusNode: _dropdownFocusNodes[i],
                                          onFocusChange: (hasFocus) {
                                            if (hasFocus) {
                                              // Scroll the dropdown into view when it gains focus
                                              _scrollController.animateTo(
                                                _scrollController.position.pixels + 100, // Adjust as needed for smooth scrolling
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                          },
                                          child: DropdownMenu<Player>(
                                            width: constraints.maxWidth - 56, // Set the width to fill the dialog
                                            key: _dropdownKeys[i],
                                            menuHeight: 150,
                                            initialSelection: _selectedPlayers[i],
                                            controller: _playerControllers[i],
                                            enableFilter: true,
                                            requestFocusOnTap: true,
                                            leadingIcon: const Icon(Icons.person),
                                            label: Text('Igrač ${i + 1}'),
                                            onSelected: (Player? player) {
                                              setState(() {
                                                if (player != null) {
                                                  _selectedPlayers[i] = player;
                                                }
                                              });
                                            },
                                            dropdownMenuEntries: _players.map(
                                                  (Player player) {
                                                return DropdownMenuEntry<Player>(
                                                  value: player,
                                                  label: player.name,
                                                );
                                              },
                                            ).toList(),
                                      )),
                                    IconButton(
                                      icon: const Icon(Icons.person_add),
                                      onPressed: (){
                                        _showAddPlayerDialog(_selectedPlayers[i], i);
                                      },
                                    )
                                  ],
                                ),
                              ),
                              if (!_dropdownValid[i])
                                Container(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Igrač ${i+1} nije odabran',
                                    style: const TextStyle(color: Colors.red, fontSize: 12.0),
                                  )
                                ),
                            ]),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(_noOfPlayers == 4 ? "Ukloni 4. igrača" : "Dodaj 4. igrača"),
                      IconButton(
                        icon: Icon(_noOfPlayers == 4 ? Icons.remove_circle : Icons.add_circle),
                        color: _noOfPlayers == 4 ? Colors.red : Colors.green,
                        onPressed: () {
                          setState(() {
                            if (_noOfPlayers == 4){
                              _noOfPlayers = 3;
                              _selectedPlayers[3] = null;
                              _dropdownValid[3] = true;
                            } else {
                              _noOfPlayers = 4;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Odustani')
                      ),
                      const SizedBox(width: 8.0,),
                      ElevatedButton(
                        onPressed: _saveGame,
                        child: const Text('Spremi'),
                      ),
                    ],
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }


}