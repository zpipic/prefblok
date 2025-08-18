import 'package:flutter/material.dart';
import 'package:pref_blok/main.dart';
import 'package:pref_blok/screens/game_screen.dart';
import 'package:pref_blok/screens/new_game_dialog.dart';
import 'package:pref_blok/screens/players_list_page.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../database/game_queries.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
  
class GameWithPlayers {
  final Game game;
  final List<Player> players;

  GameWithPlayers(this.game, this.players);
}

// key is in format '1|2|3...'
String playersKey(List<Player> players) =>
    (players..sort((a, b) => a.id!.compareTo(b.id!)))
        .map((p) => p.id).join('|');

// format; '1|2|3...|FIN'
String groupKey(List<Player> players, bool isFinished) =>
    '${playersKey(List<Player>.from(players))}|${isFinished ? 'FIN' : 'RUN'}';

class PlayersGroup{
  final String key;
  final List<Player> players;
  final List<GameWithPlayers> games;
  final bool isFinished;

  PlayersGroup(this.key, this.players, this.games, this.isFinished);
}

class Homepage extends StatefulWidget{
  final FlutterLocalNotificationsPlugin notifications;

  const Homepage({super.key, required this.notifications});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<Homepage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final GameQueries gameQueries = GameQueries();
  List<Game> _games = [];
  List<PlayersGroup> _gameGroups = [];

  List<Player> allPlayers = [];
  final Set<int> _selectedPlayers = {};
  DateTimeRange? _range;
  GameSearchQuery? _activeQuery;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }


  Future<void> _loadGames() async {
    final games = await dbHelper.getGames();

    final items = <GameWithPlayers>[];
    for (final g in games) {
      final plyrs = await gameQueries.getPlayersInGame(g.id);
      items.add(GameWithPlayers(g, plyrs));
    }

    //grouping
    final byKey = <String, List<GameWithPlayers>>{};
    final playersByKey = <String, List<Player>>{};
    final statusByKey = <String, bool>{};
    for (final gwp in items) {
      final key = groupKey(gwp.players, gwp.game.isFinished);
      byKey.putIfAbsent(key, () => []).add(gwp);
      playersByKey[key] = gwp.players;
      statusByKey[key] = gwp.game.isFinished;
    }

    final groups = <PlayersGroup>[];
    byKey.forEach((k, gamesList) {
      gamesList.sort((a, b) => b.game.date.compareTo(a.game.date));
      groups.add(PlayersGroup(k, playersByKey[k]!, gamesList, statusByKey[k]!));
    });

    groups.sort((a, b) {
      if (a.isFinished != b.isFinished) return a.isFinished ? 1 : -1;
      return b.games.first.game.date.compareTo(a.games.first.game.date);
    });

    setState(() {
      _games = games;
      _games.sort((a, b) {
        if (a.isFinished != b.isFinished){
          return a.isFinished ? 1 : -1;
        }

        return b.date.compareTo(a.date);
      });
      _gameGroups = groups;
    });
  }

  Future<void> _loadPlayers() async {
    final players = await dbHelper.getPlayers();

    setState(() {
      allPlayers = players;
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
      MaterialPageRoute(builder: (context) => GameScreen(game: game, notifications: notifications,))
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
            icon: const Icon(Icons.search),
            onPressed: () async {
              final players = await dbHelper.getPlayers();

              if (!mounted) return;

              setState(() {
                allPlayers = players;
              });

              final result = await _openFilters(context);

              if (result != null) {
                setState(() {
                  _activeQuery = result;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _openMenu(context),
          )
        ],
      ),
      body: Theme(
          data: Theme.of(context).copyWith(
            dividerTheme: const DividerThemeData(thickness: 1, space: 0),
            listTileTheme: const ListTileThemeData(visualDensity: VisualDensity.compact),
            expansionTileTheme: ExpansionTileThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
              collapsedBackgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
              textColor: Theme.of(context).colorScheme.onSurface,
              iconColor: Theme.of(context).colorScheme.primary,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
          child: _buildGroupedBody()),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewGame,
        tooltip: 'Nova igra',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGroupedBody() {
    if (_gameGroups.isEmpty){
      return const Center(child: Text('Nema partija.'),);
    }

    final groups = _activeQuery == null
        ? _gameGroups
        : _filterGroups(_gameGroups, _activeQuery!);

    final running = groups.where((g) => !g.isFinished).toList();
    final finished = groups.where((g) => g.isFinished).toList();

    return ListView(
      children: [
        if (running.isNotEmpty) ...[
          _SectionHeader(label: 'Aktivne'),
          ..._buildGroupTiles(running),
          const SizedBox(height: 8,)
        ],

        if (finished.isNotEmpty) ...[
          _SectionHeader(label: 'Završene'),
          ..._buildGroupTiles(finished),
        ]
      ],
    );
  }

  String partijaLabel(int n) {
    final lastTwo = n % 100;
    final lastOne = n % 10;

    if (lastOne == 1 && lastTwo != 11) {
      return '$n partija';
    } else if ([2, 3, 4].contains(lastOne) && !(lastTwo >= 12 && lastTwo <= 14)) {
      return '$n partije';
    } else {
      return '$n partija';
    }
  }

  List<Widget> _buildGroupTiles(List<PlayersGroup> groups){
    return List.generate(groups.length, (i){
      final group = groups[i];
      final playersLabel = (group.players..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())))
          .map((p) => p.name)
          .join(', ');

      // multiple games
      final countLabel = partijaLabel(group.games.length);
      final lastDate = group.games.first.game.dateToString();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ExpansionTile(
          leading: const Icon(Icons.groups),
          title: Text(
            playersLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface, // stronger
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              children: [
                TextSpan(
                  text: countLabel,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary), // accent
                ),
                TextSpan(text: ' • Zadnja: $lastDate'),
              ],
            ),
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: group.games.length,
                separatorBuilder: (_, __) => const Divider(height: 1,),
                itemBuilder: (_, idx) {
                  final gwp = group.games[idx];
                  return _GameTile(
                      gwp: gwp,
                      onOpen: () => _navigateToGamePage(gwp.game),
                      onEdit: () => _addNewGame(existingGame: gwp.game, players: group.players),
                      onDelete: () => _deleteGame(gwp.game)
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<GameSearchQuery?> _openFilters(BuildContext context) async {
    final controller = TextEditingController();
    Set<int> tempSelected = {...(_activeQuery?.playerIds ?? {})};
    DateTimeRange? tempRange = _activeQuery?.dateRange;

    final result = await showModalBottomSheet<GameSearchQuery?>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          String queryPlayers = '';
          List<Player> filtered = List<Player>.from(allPlayers);

          void applyFilter() {
            filtered = allPlayers
                .where((p) =>
                p.name.toLowerCase().contains(queryPlayers.toLowerCase()))
                .toList()
              ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          }

          applyFilter();

          return StatefulBuilder(
              builder: (ctx, setModalState) {
                void onSearchChanged(String v) {
                  setModalState(() {
                    queryPlayers = v;
                    applyFilter();
                  });
                }

                return Padding(
                  padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: MediaQuery.of(ctx).viewInsets.bottom
                  ),

                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              const Icon(Icons.filter_list),
                              const SizedBox(width: 8,),
                              Text('Filtri', style: Theme.of(ctx).textTheme.bodyMedium,),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8,),

                          // selected players
                          if (tempSelected.isNotEmpty) ...[
                            Text('Odabrani igrači', style: Theme.of(ctx).textTheme.bodyLarge,),
                            const SizedBox(height: 6,),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: allPlayers
                                  .where((p) => tempSelected.contains(p.id))
                                  .map((p) => InputChip(
                                label: Text(p.name),
                                onDeleted: () {
                                  setModalState(() => tempSelected.remove(p.id));
                                },
                              ))
                                  .toList(),
                            ),
                            const SizedBox(height: 12,)
                          ],

                          // player search
                          TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: 'Upiši ime igrača...'
                            ),
                            onChanged: (value) {
                              setModalState(() {
                                queryPlayers = value;
                                applyFilter();
                              });
                            },
                          ),
                          const SizedBox(height: 8,),

                          SizedBox(
                            height: 150,
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: filtered.map((p) {
                                  final selected = tempSelected.contains(p.id);
                                  return FilterChip(
                                    label: Text(p.name),
                                    selected: selected,
                                    onSelected: (sel) {
                                      setModalState((){
                                        if (sel){
                                          tempSelected.add(p.id!);
                                        }
                                        else{
                                          tempSelected.remove(p.id);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12,),

                          // DAte range
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18,),
                              const SizedBox(width: 8,),
                              Expanded(
                                child: Text(
                                  tempRange == null
                                      ? 'Svi datumi'
                                      : '${tempRange!.start.toString().split(" ").first}  –  ${tempRange!.end.toString().split(" ").first}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton(
                                child: const Text('Odaberi'),
                                onPressed: () async {
                                  final picked = await showDateRangePicker(
                                      context: ctx,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now()
                                  );
                                  if (picked != null) setModalState(() => tempRange = picked);
                                },
                              ),
                              if (tempRange != null)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => setModalState(() => tempRange = null),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12,),

                          //Actions
                          Row(
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.clear),
                                label: const Text('Reset'),
                                onPressed: () {
                                  setModalState(() {
                                    controller.clear();
                                    tempSelected.clear();
                                    tempRange = null;
                                    queryPlayers = '';
                                  });
                                },
                              ),
                              const Spacer(),
                              TextButton(
                                child: const Text('Traži'),
                                onPressed: () {
                                  _selectedPlayers
                                    ..clear()
                                    ..addAll(tempSelected);
                                  _range = tempRange;

                                  Navigator.pop(
                                    ctx,
                                    GameSearchQuery(
                                      playerIds: _selectedPlayers,
                                      dateRange: _range,
                                      text: '',
                                    ),
                                  );
                                },
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );


              }
          );
        }
    );

    return result ??
        GameSearchQuery(
          playerIds: tempSelected,
          dateRange: tempRange,
          text: '', // or keep a name field if you add one later
        );
  }

  List<PlayersGroup> _filterGroups(List<PlayersGroup> groups, GameSearchQuery q) {
    bool playersOk(PlayersGroup g) =>
        q.playerIds.isEmpty ||
            q.playerIds.every((id) => g.players.any((p) => p.id == id));

    bool dateOk(PlayersGroup g) =>
        q.dateRange == null ||
            g.games.any((gwp) =>
            gwp.game.date.isAfter(q.dateRange!.start) &&
                gwp.game.date.isBefore(q.dateRange!.end));

    bool textOk(PlayersGroup g) =>
        q.text.isEmpty ||
            g.games.any((gwp) =>
                (gwp.game.name ?? '').toLowerCase().contains(q.text.toLowerCase()));

    return groups.where((g) => playersOk(g) && dateOk(g) && textOk(g)).toList();
  }
}

class _SectionHeader extends StatelessWidget{
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IntrinsicWidth(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cs.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  final GameWithPlayers gwp;
  final bool dense;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String? playersLabel;

  const _GameTile({
    required this.gwp,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    this.dense = false,
    this.playersLabel
  });

  @override
  Widget build(BuildContext context) {
    final g = gwp.game;
    final hasName = (g.name?.trim().isNotEmpty ?? false);
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      dense: dense,
      leading: Icon(
        g.isFinished ? Icons.check_circle : Icons.access_time,
        color: g.isFinished ? Colors.green : cs.primary,
      ),
      title: Text(
        hasName ? g.name! : '<nema ime>',
        style: hasName
            ? Theme.of(context).textTheme.bodyLarge
            : const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (playersLabel != null && playersLabel!.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.people, size: 16,),
                const SizedBox(width: 4,),
                Flexible(
                    child: Text(
                      playersLabel!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    )
                ),
              ],
            ),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16),
              const SizedBox(width: 4),
              Text(
                g.dateToString().split(' ')[0],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16),
              const SizedBox(width: 4),
              Text(
                g.dateToString().split(' ')[1],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
      trailing: Wrap(spacing: 0, children: [
        IconButton(
          tooltip: 'Uredi',
          icon: const Icon(Icons.edit),
          onPressed: onEdit,
        ),
        IconButton(
          tooltip: 'Obriši',
          icon: const Icon(Icons.delete),
          onPressed: onDelete,
        ),
      ]),
      onTap: onOpen,
    );
  }
}

class GameSearchQuery {
  final Set<int> playerIds;
  final DateTimeRange? dateRange;
  final String text;

  const GameSearchQuery({
    this.playerIds = const {},
    this.dateRange,
    this.text = '',
  });
}