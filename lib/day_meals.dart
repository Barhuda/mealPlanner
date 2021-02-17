class DayMeal {
  int id;
  int date;
  String mealMorning;
  String mealLunch;
  String mealEvening;

  DayMeal(
      {this.id, this.date, this.mealMorning, this.mealLunch, this.mealEvening});

  Map<String, dynamic> toMapWithoutId() {
    final map = new Map<String, dynamic>();
    map["date"] = date;
    map["mealMorning"] = mealMorning;
    map["mealLunch"] = mealLunch;
    map["mealEvening"] = mealEvening;
    return map;
  }

  Map<String, dynamic> toMap() {
    final map = new Map<String, dynamic>();
    map["id"] = id;
    map["date"] = date;
    map["mealMorning"] = mealMorning;
    map["mealLunch"] = mealLunch;
    map["mealEvening"] = mealEvening;
    return map;
  }

  factory DayMeal.fromMap(Map<String, dynamic> data) => new DayMeal(
      id: data['id'],
      date: data['date'],
      mealMorning: data['mealMorning'],
      mealLunch: data['mealLunch'],
      mealEvening: data['mealEvening']);
}
