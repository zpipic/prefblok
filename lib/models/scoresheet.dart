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
    this.rightSoupTotal2
  });



  @override
  ScoreSheet fromMap(Map<String, dynamic> map) {
    return ScoreSheet.fromMap(map);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'playerId': this.playerId,
      'gameId': this.gameId,
      'refe': this.refe,
      'refeLeft': this.refeLeft,
      'refeRight': this.refeRight,
      'refeRight2': this.refeRight2,
      'totalScore': this.totalScore,
      'leftSoupTotal': this.leftSoupTotal,
      'rightSoupTotal': this.rightSoupTotal,
      'rightSoupTotal2': this.rightSoupTotal2,
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
      refeRight2: map['refeRight2'] == 1,
      totalScore: map['totalScore'],
      leftSoupTotal: map['leftSoupTotal'],
      rightSoupTotal: map['rightSoupTotal'],
      rightSoupTotal2: map['rightSoupTotal2'],
    );
  }
}