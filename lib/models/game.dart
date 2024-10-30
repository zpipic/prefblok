import 'package:intl/intl.dart';
import 'package:pref_blok/models/base_model.dart';

class Game implements BaseModel<Game>{
  int? id;
  String? name;
  DateTime date;
  int noOfPlayers;
  bool isFinished;
  int startingScore;
  int maxRefes;

  Game({
    this.id,
    this.name,
    required this.date,
    required this.noOfPlayers,
    this.isFinished = false,
    required this.startingScore,
    required this.maxRefes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': dateToString(),
      'noOfPlayers': noOfPlayers,
      'isFinished': isFinished ? 1 : 0,
      'startingScore': startingScore,
      'maxRefes': maxRefes,
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'],
      name: map['name'],
      date: stringToDate(map['date']),
      noOfPlayers: map['noOfPlayers'],
      isFinished: map['isFinished'] == 1,
      startingScore: map['startingScore'],
      maxRefes: map['maxRefes'],
    );
  }

  String dateToString(){
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static stringToDate(String dateString){
    return DateFormat('dd/MM/yyyy HH:mm').parse(dateString);
  }

  @override
  Game fromMap(Map<String, dynamic> map) {
    return Game.fromMap(map);
  }
}
