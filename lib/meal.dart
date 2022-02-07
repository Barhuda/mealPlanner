import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'injection.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Meal {
  DatabaseHelper _databaseHelper = Injection.injector.get();

  int id;
  String mealName;
  int date;
  String recipe;
  String dayTime;

  Meal({this.id, this.mealName, this.date, this.dayTime, this.recipe});

  final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');

  Map<String, dynamic> toMapWithoutId() {
    final map = new Map<String, dynamic>();
    map["meal_name"] = mealName;
    map["date"] = date;
    map["daytime"] = dayTime;
    map["recipe"] = recipe;
    return map;
  }

  Map<String, dynamic> toMap() {
    final map = new Map<String, dynamic>();
    map["id"] = id;
    map["meal_name"] = mealName;
    map["date"] = date;
    map["daytime"] = dayTime;
    map["recipe"] = recipe;
    return map;
  }

  factory Meal.fromMap(Map<String, dynamic> data) => new Meal(
      id: data['id'],
      mealName: data['meal_name'],
      date: data['date'],
      dayTime: data['daytime'],
      recipe: data['recipe']);
  
  factory Meal.fromFirebaseMap(Map<dynamic, dynamic> data, String dayTime) => new Meal(
      mealName: data['name'],
      date: data['date'],
      dayTime: data['daytime'],
      recipe: data['recipe']);

  Future<List<Meal>> getWeekList(DateTime firstWeekDay) async {
    List<Map> dbResult = await _databaseHelper.db.rawQuery(
        'SELECT * FROM meals WHERE date >= "${firstWeekDay.subtract(Duration(days: 1)).millisecondsSinceEpoch}" AND date <= "${(firstWeekDay.add(new Duration(days: 6))).millisecondsSinceEpoch}"');
    return List.generate(
        dbResult.length,
        (index) => Meal(
            id: dbResult[index]['id'],
            mealName: dbResult[index]['meal_name'],
            date: dbResult[index]['date'],
            dayTime: dbResult[index]['daytime'],
            recipe: dbResult[index]['recipe']));
  }

  Map<DateTime, Meal> generateMealMap(DateTime startDate) {
    Map<DateTime, Meal> mealMap = {};
    for (int i = 0; i < 7; i++) {
      mealMap[startDate.add(Duration(days: i))] = null;
    }
    return mealMap;
  }

  Future<void> deleteMeal() async {
    await _databaseHelper.db.delete(
      "meals",
      where: "id = ?",
      whereArgs: [this.id],
    );
  }

  Future<void> saveMeal(
      String mealName, DateTime date, String dayTime, String link) async {
    await _databaseHelper.db.insert(
        "meals",
        Meal(
          mealName: mealName,
          date: date.millisecondsSinceEpoch,
          dayTime: dayTime,
          recipe: link,
        ).toMapWithoutId(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<DateTime, Map<String, Meal>>> generateWeekList(
      DateTime firstWeekDay) async {
    List<Meal> weekList = [];
    Map<DateTime, Map<String, Meal>> resultMap = {};
    for (int i = 0; i < 7; i++) {
      DateTime defaultDate = firstWeekDay.add(Duration(days: i));
      DateTime formattedDefaultDate =
          new DateTime(defaultDate.year, defaultDate.month, defaultDate.day);
      resultMap[formattedDefaultDate] = <String, Meal>{};
    }
    await getWeekList(firstWeekDay).then(
        (value) => Future.forEach(value, (element) => weekList.add(element)));
    for (int i = 0; i < weekList.length; i++) {
      Meal meal = weekList[i];
      DateTime inputDate = DateTime.fromMillisecondsSinceEpoch(meal.date);
      DateTime formattedDate =
          new DateTime(inputDate.year, inputDate.month, inputDate.day);
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

  deleteMealFromFirebase(String userDb) {
    print("User DB: $userDb");
    String dateFormatted =
        dateFormatter.format(DateTime.fromMillisecondsSinceEpoch(this.date));
    FirebaseDatabase.instance
        .ref("mealDbs")
        .child(userDb)
        .child("weekdays")
        .child(dateFormatted)
        .child(this.dayTime.toLowerCase())
        .remove();
    print("deleted at: " + dateFormatted);
  }

  saveMealToFirebase(String dbUID) {
    String dateFormatted =
        dateFormatter.format(DateTime.fromMillisecondsSinceEpoch(this.date));
    FirebaseDatabase.instance
        .ref("mealDbs")
        .child(dbUID)
        .child("weekdays")
        .child(dateFormatted)
        .child(this.dayTime.toLowerCase())
        .update({"link": this.recipe, "name": this.mealName});
  }
}

// 17.02.2021 - Lunch - Spaghetti
