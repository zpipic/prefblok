import 'package:flutter/material.dart';
import 'package:pref_blok/screens/game_screen.dart';
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
    _loadGames();
  }

  void _loadGames() async {
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

  void _addNewGame({Game? existingGame, List<Player>? players}){
    showDialog(
        context: context,
        builder: (BuildContext context) {
          if (existingGame != null && players != null){
            return NewGameDialog(onCreateGame: (newGame) {
              setState(() {
                _loadGames();
              });
            },
              game: existingGame,
              players: players,
            );
          }
          else {
            return NewGameDialog(onCreateGame: (newGame) {
              setState(() {
                _games.insert(0, newGame);
              });
          });
        }
      },
    );
  }

  void _navigateToPlayerListPage(){
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PlayersListPage())
    );
  }

  void _navigateToGamePage(Game game){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GameScreen(game: game))
    ).then((_) => setState(() { }));
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

  void _deleteGame(Game game) async {
    bool? confirmDelete = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Brisanje partije'),
          content: Text('Obrisati partiju "${game.name}"?'),
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
      await dbHelper.deleteGame(game.id!);
      _loadGames();
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partije'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
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
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  else if (snapshot.hasData){
                    List<Player>? players = snapshot.data;
                    String playerNames = players!.map((p) => p.name).join(', ');
                    return ListTile(
                      leading: Icon(
                        game.isFinished ? Icons.check_circle : Icons.access_time,
                        color: game.isFinished ? Colors.green : Colors.orange,
                      ),
                      title: Text(
                        (game.name?.trim().isNotEmpty ?? false) ? game.name! : '<nema ime>',
                          style: (game.name?.trim().isNotEmpty ?? false)
                              ? TextStyle(
                                fontSize: 16,
                                color: (game.name?.trim().isNotEmpty ?? false)
                                  ? Theme.of(context).textTheme.bodyMedium?.color
                                  : Colors.grey,)
                              : const TextStyle(fontSize: 16, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                      subtitle: Text(
                          '''Datum: ${game.dateToString()}\nIgrači: $playerNames'''
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _addNewGame(existingGame: game, players: players),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteGame(game),
                          )
                        ],
                      ),
                      onTap: () {
                        _navigateToGamePage(game);
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
                        _navigateToGamePage(game);
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