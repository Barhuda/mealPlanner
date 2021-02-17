import 'package:intl/intl.dart';

import 'database_helper.dart';
import 'injection.dart';

class Meal {
  DatabaseHelper _databaseHelper = Injection.injector.get();

  int id;
  String mealName;
  int date;

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

  Future<List<Meal>> getWeekList(DateTime firstWeekDay) async {
    List<Map> dbResult = await _databaseHelper.db.rawQuery(
        'SELECT * FROM meals WHERE date >= "${firstWeekDay.subtract(Duration(days: 1)).millisecondsSinceEpoch}" AND date <= "${(firstWeekDay.add(new Duration(days: 6))).millisecondsSinceEpoch}"');
    return List.generate(
        dbResult.length,
        (index) => Meal(
            id: dbResult[index]['id'],
            mealName: dbResult[index]['meal_name'],
            date: dbResult[index]['date'],
            dayTime: dbResult[index]['daytime']));
  }

  Map<DateTime, Meal> generateMealMap(DateTime startDate) {
    Map<DateTime, Meal> mealMap = {};
    for (int i = 0; i < 7; i++) {
      mealMap[startDate.add(Duration(days: i))] = null;
    }
    return mealMap;
  }

  Future<Map<int, Map<String, Meal>>> generateWeekList(
      DateTime firstWeekDay) async {
    List<Meal> weekList = [];
    Map<int, Map<String, Meal>> resultMap = {};
    await getWeekList(firstWeekDay).then(
        (value) => Future.forEach(value, (element) => weekList.add(element)));
    for (int i = 0; i < weekList.length; i++) {
      Meal meal = weekList[i];
      DateTime inputDate = DateTime.fromMillisecondsSinceEpoch(meal.date);
      int formattedDate =
          DateTime(inputDate.day, inputDate.month, inputDate.year)
              .millisecondsSinceEpoch;
      Map<String, Meal> mapToAdd = {};
      mapToAdd[meal.dayTime] = meal;
      if (resultMap.containsKey(formattedDate)) {
        resultMap[formattedDate][meal.dayTime] = meal;
      } else {
        resultMap[formattedDate] = mapToAdd;
      }
    }
    return resultMap;
  }
}

// 17.02.2021 - Lunch - Spaghetti
