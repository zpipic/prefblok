import 'package:intl/intl.dart';
import 'package:pref_blok/models/base_model.dart';

class Game implements BaseModel<Game>{
  int? id;
  String? name;
  DateTime date;
  int noOfPlayers;
  bool isFinished;
  int startingScore;

  Game({
    this.id,
    this.name,
    required this.date,
    required this.noOfPlayers,
    this.isFinished = false,
    required this.startingScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'noOfPlayers': noOfPlayers,
      'isFinished': isFinished ? 1 : 0,
      'startingScore': startingScore,
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'] as int,
      name: map['name'] as String,
      date: map['date'] as DateTime,
      noOfPlayers: map['noOfPlayers'] as int,
      isFinished: map['isFinished'] as bool,
      startingScore: map['startingScore'] as int,
    );
  }

  String dateToString(){
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Game fromMap(Map<String, dynamic> map) {
    return Game.fromMap(map);
  }
}
