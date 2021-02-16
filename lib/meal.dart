import 'database_helper.dart';
import 'injection.dart';

class Meal {
  DatabaseHelper _databaseHelper = Injection.injector.get();
  
  int id;
  String mealName;
  String date;

  //0 = breakfast, 1 = lunch, 2 = dinner, 4 = other
  String dayTime;

  Meal({this.id, this.mealName, this.date, this.dayTime});

  Map<String, dynamic> toMapWithoutId() {
    final map = new Map<String, dynamic>();
    map["meal_name"] = mealName;
    map["date"] = date;
    map["daytime"] = dayTime;
    return map;
  }

  Map<String, dynamic> toMap() {
    final map = new Map<String, dynamic>();
    map["id"] = id;
    map["meal_name"] = mealName;
    map["date"] = date;
    map["daytime"] = dayTime;
    return map;
  }

  factory Meal.fromMap(Map<String, dynamic> data) => new Meal(
      id: data['id'],
      mealName: data['meal_name'],
      date: data['date'],
      dayTime: data['daytime']);

  Map<DateTime, Meal> getWeekList(DateTime firstWeekDay) async{
    List<Map> dbResult = await _databaseHelper.db.rawQuery('SELECT * FROM meals WHERE date >= "${firstWeekDay}" AND date <= "${firstWeekDay.add(new Duration(days: 6))}"');
    final map = new Map<DateTime, Meal>();
    forEach()
  }
}
