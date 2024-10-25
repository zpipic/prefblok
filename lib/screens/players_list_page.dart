import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';
import 'add_player_dialog.dart';

class PlayersListPage extends StatefulWidget{
  const PlayersListPage({super.key});


  @override
  _PlayersListPageState createState() => _PlayersListPageState();
}

class _PlayersListPageState extends State<PlayersListPage>{
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Player> _players = [];

  @override
  void initState(){
    super.initState();
    _loadPlayers();
  }

  void _loadPlayers() async {
    final playersData = await dbHelper.getPlayers();
    setState(() {
      _players = playersData;
    });
  }

  void _showAddPlayerDialog({Player? existingPlayer}) {
    showDialog(
        context: context,
        builder: (context) => AddPlayerDialog(
          player: existingPlayer,
          onPlayerAdded: (Player player){
            setState(() {
              if (existingPlayer != null){
                _loadPlayers();
              } else {
                _players.add(player);
              }
            });
          },
        )
    );
  }

  void _deletePlayer(Player player) async {
    bool? confirmDelete = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Brisanje igrača'),
          content: Text('Obrisati igrača "${player.name}" i sve povezane partije?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Odustani'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Obriši'),
            )
          ],
        )
    );

    if (confirmDelete == true) {
      await dbHelper.deletePlayer(player.id!);
      _loadPlayers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Igrači'),
      ),
      body: _players.isEmpty
        ? const Center(child: Text('Igrači nisu pronađeni'))
        : ListView.builder(
            itemCount: _players.length,
            itemBuilder: (context, index){
              Player player = _players[index];
              return ListTile(
                title: Text(player.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showAddPlayerDialog(existingPlayer: player),
                      tooltip: 'Uredi igrača',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deletePlayer(player),
                      tooltip: 'Brisanje igrača',
                    )
                  ],
                ),
              );
            },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPlayerDialog,
        tooltip: 'Novi igrač',
        child: const Icon(Icons.add),
      ),
    );
  }
}