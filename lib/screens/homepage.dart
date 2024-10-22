import 'package:flutter/material.dart';
import 'package:pref_blok/screens/new_game_dialog.dart';
import 'package:pref_blok/screens/players_list_page.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../database/game_queries.dart';

class Homepage extends StatefulWidget{
  const Homepage({super.key});


  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<Homepage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final GameQueries gameQueries = GameQueries();
  List<Game> _games = [];

  @override
  void initState() {
    super.initState();
    _refreshGameList();
  }

  void _refreshGameList() async {
    final data = await dbHelper.getGames();
    setState(() {
      _games = data;
      _games.sort((a, b) {
        if (a.isFinished != b.isFinished){
          return a.isFinished ? 1 : -1;
        }

        return b.date.compareTo(a.date);
      });
    });
  }

  void _addNewGame(){
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return NewGameDialog(onCreateGame: (newGame) {
            setState(() {
              _games.add(newGame);
            });
          });
        },
    );
  }

  void _navigateToPlayerListPage(){
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PlayersListPage())
    );
  }

  void _openMenu(BuildContext context){
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Nova igra'),
                onTap: () {
                  Navigator.pop(context);
                  _addNewGame();
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Popis igrača'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToPlayerListPage();
                },
              )
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partije'),
        actions: [
          IconButton(
            icon: const Icon(Icons.drag_handle),
            onPressed: () => _openMenu(context),
          )
        ],
      ),
      body: _games.isEmpty
        ? const Center(
          child: Text('Nema partija.'))
        : ListView.builder(
            itemCount: _games.length,
            itemBuilder: (context, index){
              Game game = _games[index];
              return FutureBuilder<List<Player>>(
                future: gameQueries.getPlayersInGame(game.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting){
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  else if (snapshot.hasData){
                    List<Player>? players = snapshot.data;
                    String playerNames = players!.map((p) => p.name).join(', ');
                    return ListTile(
                      title: Text(
                        (game.name?.trim().isNotEmpty ?? false) ? game.name! : '<nema ime>',
                        style: (game.name?.trim().isNotEmpty ?? false)
                            ? TextStyle(fontSize: 16, color: Colors.black)
                            : TextStyle(fontSize: 16, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                      subtitle: Text(
                          '''Datum: ${game.dateToString()}\nIgrači: $playerNames'''
                      ),
                      trailing: Icon(
                        game.isFinished ? Icons.check_circle : Icons.access_time,
                        color: game.isFinished ? Colors.green : Colors.orange,
                      ),
                      onTap: () {

                      },
                    );
                  } else{
                    return ListTile(
                      title: Text(game.name ?? 'Nema ime'),
                      subtitle: Text(
                          'Date: ${game.dateToString()}'
                      ),
                      trailing: Icon(
                        game.isFinished ? Icons.check_circle : Icons.access_time,
                        color: game.isFinished ? Colors.green : Colors.orange,
                      ),
                      onTap: () {

                      },
                    );
                  }
                }
              );

          },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewGame,
        tooltip: 'Nova igra',
        child: const Icon(Icons.add),
      ),
    );
  }
}