class Meal {
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
}
