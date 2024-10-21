import 'package:pref_blok/models/base_model.dart';

class RoundScore implements BaseModel<RoundScore>{
  int? id;
  int roundId; //foreign
  int scoreSheetId; // foreign
  int score;
  int leftSoup;
  int rightSoup;
  int? rightSoup2;

  RoundScore({
    this.id,
    required this.roundId,
    required this.scoreSheetId,
    this.score = 0,
    this.leftSoup = 0,
    this.rightSoup = 0,
    this.rightSoup2,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roundId': roundId,
      'scoreSheetId': scoreSheetId,
      'score': score,
      'leftSoup': leftSoup,
      'rightSoup': rightSoup,
      'rightSoup2': rightSoup2,
    };
  }

  factory RoundScore.fromMap(Map<String, dynamic> map) {
    return RoundScore(
      id: map['id'] as int,
      roundId: map['roundId'] as int,
      scoreSheetId: map['scoreSheetId'] as int,
      score: map['score'] as int,
      leftSoup: map['leftSoup'] as int,
      rightSoup: map['rightSoup'] as int,
      rightSoup2: map['rightSoup2'] as int,
    );
  }

  @override
  RoundScore fromMap(Map<String, dynamic> map) {
    return RoundScore.fromMap(map);
  }
}