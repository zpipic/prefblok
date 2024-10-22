import 'package:flutter/material.dart';
import 'package:pref_blok/database/database_helper.dart';
import '../models/models.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'add_player_dialog.dart';
import '../database/player_queries.dart';

class NewGameDialog extends StatefulWidget {
  final Function(Game) onCreateGame;

  const NewGameDialog({
    required this.onCreateGame,
    super.key
  });

  @override
  _NewGameDialogState createState() => _NewGameDialogState();
}

class _NewGameDialogState extends State<NewGameDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _startScoreController = TextEditingController();
  final List<TextEditingController> _playerControllers = List.generate(3, (_) => TextEditingController());
  final ScrollController _scrollController = ScrollController();
  List<FocusNode> _dropdownFocusNodes = List.generate(3, (index) => FocusNode());

  final DatabaseHelper dbHelper = DatabaseHelper();
  final PlayerQueries playerQueries = PlayerQueries();

  List<Player> _players = [];
  List<Player?> _selectedPlayers = List.filled(3, null);
  List<Player> _placeholderPlayers = List.generate(3, (_) => Player(name: ''));
  List<bool> _dropdownValid = List.filled(3, true);

  @override
  void initState(){
    super.initState();
    _loadPlayers();
    for (int i = 0; i < _playerControllers.length; i++){
      _playerControllers[i].addListener( () {
          setState(() {
            _selectedPlayers[i] = new Player(name: _playerControllers[i].text);
            _dropdownValid = List.filled(3, true);
          });
        }
      );
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
    for (int i = 0; i < 3; i++){
      if (_selectedPlayers[i] != null){
        _selectedPlayers[i] = await playerQueries.GetPlayerByName(_selectedPlayers[i]!.name);
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

    int startingScore = int.parse(_startScoreController.text);

    Game game = Game(
        date: DateTime.now(),
        noOfPlayers: _selectedPlayers.length,
        startingScore: startingScore,
        name: _nameController.text,
    );

    int gameId = await dbHelper.insertGame(game);

    game.id = gameId;

    for (int i = 0; i < _selectedPlayers.length; i++){
      ScoreSheet scoreSheet = ScoreSheet(
        playerId: _selectedPlayers[i]!.id!,
        gameId: gameId,
        totalScore: startingScore,
      );

      dbHelper.insertScoreSheet(scoreSheet);
    }

    widget.onCreateGame(game);
    Navigator.of(context).pop();
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
                        for (int i = 0; i < 3; i++)
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
                                    style: TextStyle(color: Colors.red, fontSize: 12.0),
                                  )
                                ),
                            ]),
                      ],
                    ),
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
                        child: Text('Spremi'),
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