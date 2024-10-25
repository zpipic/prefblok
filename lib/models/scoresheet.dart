import 'package:pref_blok/models/base_model.dart';

class ScoreSheet implements BaseModel<ScoreSheet>{
  int? id;
  int playerId; //foreign
  int gameId; //foreign
  bool refe;
  bool refeLeft;
  bool refeRight;
  bool? refeRight2;
  int totalScore;
  int leftSoupTotal;
  int rightSoupTotal;
  int? rightSoupTotal2;
  int position;

  ScoreSheet({
    this.id,
    required this.playerId,
    required this.gameId,
    this.refe = false,
    this.refeLeft = false,
    this.refeRight = false,
    this.refeRight2,
    required this.totalScore,
    this.leftSoupTotal = 0,
    this.rightSoupTotal = 0,
    this.rightSoupTotal2,
    required this.position,
  });



  @override
  ScoreSheet fromMap(Map<String, dynamic> map) {
    return ScoreSheet.fromMap(map);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playerId': playerId,
      'gameId': gameId,
      'refe': refe ? 1 : 0,
      'refeLeft': refeLeft ? 1 : 0,
      'refeRight': refeRight ? 1 : 0,
      'refeRight2': refeRight2 != null ? (refeRight2! ? 1 : 0) : null,
      'totalScore': totalScore,
      'leftSoupTotal': leftSoupTotal,
      'rightSoupTotal': rightSoupTotal,
      'rightSoupTotal2': rightSoupTotal2,
      'position': position,
    };
  }

  factory ScoreSheet.fromMap(Map<String, dynamic> map) {
    return ScoreSheet(
      id: map['id'],
      playerId: map['playerId'],
      gameId: map['gameId'],
      refe: map['refe'] == 1,
      refeLeft: map['refeLeft'] == 1,
      refeRight: map['refeRight'] == 1,
      refeRight2: map['refeRight2'] != null ? (map['refeRight2'] == 1) : null,
      totalScore: map['totalScore'],
      leftSoupTotal: map['leftSoupTotal'],
      rightSoupTotal: map['rightSoupTotal'],
      rightSoupTotal2: map['rightSoupTotal2'],
      position: map['position'],
    );
  }
}