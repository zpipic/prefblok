import 'package:pref_blok/models/base_model.dart';

class Player implements BaseModel<Player>{
  int? id;
  String name;

  Player({this.id, required this.name});

  Map<String, dynamic> toMap(){
    return {
      'id': id,
      'name': name,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map){
    return Player(
      id: map['id'],
      name: map['name'],
    );
  }

  @override
  Player fromMap(Map<String, dynamic> map) {
    return Player.fromMap(map);
  }
}