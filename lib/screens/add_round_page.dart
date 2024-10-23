import 'package:flutter/material.dart';
import '../models/models.dart';
import '../database/database_helper.dart';

class AddRoundPage extends StatefulWidget{
  Game game;
  List<ScoreSheet> scoreSheets;
  List<Player> players;
  Round? existingRound;


  AddRoundPage({
    required this.game,
    required this.scoreSheets,
    super.key,
    this.existingRound,
    required this.players
  });

  @override
  _AddRoundPageState createState() => _AddRoundPageState();
}

class _AddRoundPageState extends State<AddRoundPage>{
  int _selectedCaller = -1;
  List<bool> _played = List.filled(3, true);
  int _selectedContract = 0;
  List<TextEditingController> _pointsControllers = List.generate(3, (_) => TextEditingController());
  bool _isGame = false;

  final _cardColors = {'pik': 2, 'karo': 3, 'herc': 4, 'tref': 5};
  final _otherGames = {'betl': 6, 'sans': 7, 'dalje': 0};

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
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    SizedBox(width:  5,),
                    Text('Zvao', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 16,),
                    Text('Došao', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              _playersColumn(),
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
          onChanged: (value) {
            setState(() {
              _selectedCaller = value as int;
              _played[index] = true;
            });
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
            validator: (value) {
              if ((value == null || value.trim().isEmpty) && _played[index]){
                return 'Unesite broj štihova';
              }
              try {
                int n = int.parse(value!);
                if (n < 0 || n > 10){
                  return 'Ilegalan broj štihova';
                }
              } catch (e){
                return 'Nije unesen broj';
              }

              return null;
            },
          ),
        )
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
                'assets/karte/${color}.png',
                fit: BoxFit.contain,
              ),
            ),

            Text('(${value + (_isGame ? 1 : 0)})'),
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
          child: Text('$game (${value + (_isGame && value != 0 ? 1 : 0)})'),
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
      ],
    );
  }
}