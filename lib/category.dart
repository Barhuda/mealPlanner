import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'injection.dart';

class Category {
  DatabaseHelper _databaseHelper = Injection.injector.get();

  int id;
  String categoryName;
  String colorValue;

  Category({this.id, this.categoryName, this.colorValue});

  Map<String, dynamic> toMapWithoutId() {
    final map = new Map<String, dynamic>();
    map["category_name"] = categoryName;
    map["color"] = colorValue;
    return map;
  }

  Map<String, dynamic> toMap() {
    final map = new Map<String, dynamic>();
    map["id"] = id;
    map["category_name"] = categoryName;
    map["color"] = colorValue;
    return map;
  }

  void saveToDB() async {
    await _databaseHelper.db.insert(
      "category",
      this.toMapWithoutId(),
    );
  }

  Future<void> deleteFromDB() async {
    await _databaseHelper.db.delete(
      "category",
      where: "id = ?",
      whereArgs: [this.id],
    );
  }

  Future<void> updateInDB(String newName, String newColor) async {
    await _databaseHelper.db.update(
        "category", Category(id: this.id, categoryName: newName ?? this.categoryName, colorValue: newColor ?? this.colorValue).toMap(),
        where: "id = ?", whereArgs: [this.id], conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Category>> generateCategoryList() async {
    final List<Map<String, dynamic>> maps = await _databaseHelper.db.query("category");
    return List.generate(maps.length, (i) {
      return Category(id: maps[i]['id'], categoryName: maps[i]['category_name'], colorValue: maps[i]['color']);
    });
  }
}
