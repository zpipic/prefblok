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
      id: map['id'],
      roundId: map['roundId'],
      scoreSheetId: map['scoreSheetId'],
      score: map['score'],
      leftSoup: map['leftSoup'],
      rightSoup: map['rightSoup'],
      rightSoup2: map['rightSoup2'],
    );
  }

  @override
  RoundScore fromMap(Map<String, dynamic> map) {
    return RoundScore.fromMap(map);
  }
}