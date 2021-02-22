import 'database_helper.dart';
import 'injection.dart';

class Meallist {
  DatabaseHelper _databaseHelper = Injection.injector.get();

  int id;
  String mealName;

  String note;

  Meallist({this.id, this.mealName, this.note});

  Map<String, dynamic> toMapWithoutId() {
    final map = new Map<String, dynamic>();
    map["meal_name"] = mealName;
    map["note"] = note;
    return map;
  }

  Map<String, dynamic> toMap() {
    final map = new Map<String, dynamic>();
    map["id"] = id;
    map["meal_name"] = mealName;
    map["note"] = note;
    return map;
  }

  factory Meallist.fromMap(Map<String, dynamic> data) => new Meallist(
        id: data['id'],
        mealName: data['meal_name'],
        note: data['note'],
      );

  Future<List<Meallist>> generateMealList() async {
    final List<Map<String, dynamic>> maps =
        await _databaseHelper.db.query("meallist");
    return List.generate(maps.length, (i) {
      return Meallist(
          id: maps[i]['id'],
          mealName: maps[i]['meal_name'],
          note: maps[i]['note']);
    });
  }
}
