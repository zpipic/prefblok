import 'package:pref_blok/models/base_model.dart';

class Round implements BaseModel<Round>{
  int? id;
  int gameId; //foreign
  int roundNumber;
  int? callerId; //foreign
  int? calledGame;
  bool isIgra;
  int multiplier;
  bool refeUsed;
  bool kontra;

  Round({
    this.id,
    required this.gameId, //foreign
    required this.roundNumber,
    this.callerId, //foreign
    this.calledGame,
    this.isIgra = false,
    this.multiplier = 2,
    this.refeUsed = false,
    this.kontra = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameId': gameId,
      'roundNumber': roundNumber,
      'callerId': callerId,
      'calledGame': calledGame,
      'isIgra': isIgra ? 1 : 0,
      'multiplier': multiplier,
      'refeUsed': refeUsed ? 1 : 0,
      'kontra': kontra ? 1 : 0,
    };
  }

  factory Round.fromMap(Map<String, dynamic> map) {
    return Round(
      id: map['id'],
      gameId: map['gameId'],
      roundNumber: map['roundNumber'],
      callerId: map['callerId'],
      calledGame: map['calledGame'],
      isIgra: map['isIgra'] == 1,
      multiplier: map['multiplier'],
      refeUsed: map['refeUsed'] == 1,
      kontra: map['kontra'] == 1,
    );
  }

  @override
  Round fromMap(Map<String, dynamic> map) {
    return Round.fromMap(map);
  }
}