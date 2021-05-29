import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'injection.dart';

class Meallist {
  DatabaseHelper _databaseHelper = Injection.injector.get();

  int id;
  String mealName;

  String note;
  String recipe;
  int categoryId;

  Meallist({this.id, this.mealName, this.note, this.recipe, this.categoryId});

  Map<String, dynamic> toMapWithoutId() {
    final map = new Map<String, dynamic>();
    map["meal_name"] = mealName;
    map["note"] = note;
    map["recipe"] = recipe;
    map["category"] = categoryId;
    return map;
  }

  Map<String, dynamic> toMap() {
    final map = new Map<String, dynamic>();
    map["id"] = id;
    map["meal_name"] = mealName;
    map["note"] = note;
    map["recipe"] = recipe;
    map["category"] = categoryId;
    return map;
  }

  void saveMealtoDB() async {
    await _databaseHelper.db.insert(
      "meallist",
      this.toMapWithoutId(),
    );
  }

  Future<void> deleteMealFromDB() async {
    await _databaseHelper.db.delete(
      "meallist",
      where: "id = ?",
      whereArgs: [this.id],
    );
  }

  Future<void> updateMealInDB(String newName, String newNote, String newRecipe, int newCategory) async {
    await _databaseHelper.db.update("meallist",
        Meallist(id: this.id, mealName: newName ?? this.mealName, note: newNote ?? "", recipe: newRecipe ?? "", categoryId: newCategory).toMap(),
        where: "id = ?", whereArgs: [this.id], conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCategoryId(int categoryId) async {
    await _databaseHelper.db.rawUpdate('UPDATE meallist SET category = ? WHERE category = ?', [null, '${categoryId}']);
  }

  factory Meallist.fromMap(Map<String, dynamic> data) =>
      new Meallist(id: data['id'], mealName: data['meal_name'], note: data['note'], recipe: data['recipe'], categoryId: data["category"]);

  Future<List<Meallist>> generateMealList(int id) async {
    List<Map<String, dynamic>> maps = [];
    print(id);
    if (id == 0) {
      maps = await _databaseHelper.db.query("meallist");
    } else {
      int newID = id - 1;
      // id-1, weil 0 bereits durch den defaultwert besetzt ist. Mit -1 wird die korrekte Kategorie gewählt.
      maps = await _databaseHelper.db.query("meallist", where: "category = ?", whereArgs: [newID]);
    }

    return List.generate(maps.length, (i) {
      return Meallist(
          id: maps[i]['id'], mealName: maps[i]['meal_name'], note: maps[i]['note'], recipe: maps[i]['recipe'], categoryId: maps[i]["category"]);
    });
  }
}
