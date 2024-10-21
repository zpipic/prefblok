import 'package:pref_blok/models/base_model.dart';

class ScoreSheet implements BaseModel<ScoreSheet>{
  int? id;
  int playerId; //foreign
  int gameId; //foreign
  bool refe;
  bool refeLeft;
  bool refeRight;
  bool? refeRight2;

  ScoreSheet({
    this.id,
    required this.playerId,
    required this.gameId,
    this.refe = false,
    this.refeLeft = false,
    this.refeRight = false,
    this.refeRight2,
  });

  Map<String, dynamic> toMap() {
    return {
      'Id': id,
      'PlayerId': playerId,
      'GameId': gameId,
      'refe': refe ? 1 : 0,
      'refeLeft': refeLeft ? 1 : 0,
      'refeRight': refeRight ? 1 : 0,
      'refeRight2': refeRight2 == null ? null : (refeRight2! ? 1 : 0),
    };
  }

  factory ScoreSheet.fromMap(Map<String, dynamic> map) {
    return ScoreSheet(
      id: map['Id'] as int,
      playerId: map['PlayerId'] as int,
      gameId: map['GameId'] as int,
      refe: map['refe'] == 1,
      refeLeft: map['refeLeft'] == 1,
      refeRight: map['refeRight'] == 1,
      refeRight2: map['refeRight2'] == null ? null : map['refeRight2'] == 1,
    );
  }

  @override
  ScoreSheet fromMap(Map<String, dynamic> map) {
    return ScoreSheet.fromMap(map);
  }
}