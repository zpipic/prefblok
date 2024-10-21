import 'package:flutter/material.dart';
import 'package:pref_blok/database/database_helper.dart';
import '../models/models.dart';
import 'package:dropdown_search/dropdown_search.dart';

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
  final List<TextEditingController> _playerControllers = List.generate(3, (_) => TextEditingController());

  final DatabaseHelper dbHelper = DatabaseHelper();

  List<Player> _players = [];
  List<Player?> _selectedPlayers = List.filled(3, null);
  List<Player> _placeholderPlayers = List.generate(3, (_) => Player(name: ''));

  @override
  void initState(){
    super.initState();
    _loadPlayers();
    for (int i = 0; i < _playerControllers.length; i++){
      _playerControllers[i].addListener( () {
          _placeholderPlayers[i].name = _playerControllers[i].text;
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


  @override
  void dispose() {
    _nameController.dispose();
    for(var controlller in _playerControllers){
      controlller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
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

                    //const SizedBox(height: 16.0),

                    for (int i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          //mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            DropdownMenu<Player>(
                              width: MediaQuery.of(context).size.width,
                              initialSelection: _selectedPlayers[i],
                              controller: _playerControllers[i],
                              enableFilter: true,
                              requestFocusOnTap: true,
                              leadingIcon: const Icon(Icons.person),
                              label: Text('Igrač ${i}'),
                              onSelected: (Player? player){
                                setState(() {
                                  if (player != null){
                                    _selectedPlayers[i] = player;
                                  }
                                });
                              },
                              dropdownMenuEntries: _players.map(
                                      (Player player) {
                                    if (player.id == null){
                                      return DropdownMenuEntry<Player>(
                                          value: _placeholderPlayers[i],
                                          label: _placeholderPlayers[i].name,
                                          leadingIcon: Icon(Icons.person_add)
                                      );
                                    } else {
                                      return DropdownMenuEntry<Player>(
                                        value: player,
                                        label: player.name,
                                      );
                                    }
                                  }
                              ).toList(),

                            ),
                          ],
                        )
                      )
                  ],
                ),
              ),
            ],
          )
        ),
      ),
    );
  }
  
}