import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'injection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Category {
  DatabaseHelper _databaseHelper = Injection.injector.get();

  int? id;
  String? categoryName;
  String? colorValue;

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
    await _databaseHelper.db!.insert(
      "category",
      this.toMapWithoutId(),
    );
  }

  Future<void> deleteFromDB() async {
    await _databaseHelper.db!.delete(
      "category",
      where: "id = ?",
      whereArgs: [this.id],
    );
  }

  Future<void> updateInDB(String? newName, String? newColor) async {
    await _databaseHelper.db!.update(
        "category",
        Category(
                id: this.id,
                categoryName: newName ?? this.categoryName,
                colorValue: newColor ?? this.colorValue)
            .toMap(),
        where: "id = ?",
        whereArgs: [this.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Category>> generateCategoryList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool sortAlphabetical = prefs.getBool('sort') ?? false;
    final List<Map<String, dynamic>> maps = await _databaseHelper.db!.query(
        "category",
        orderBy: sortAlphabetical ? "category_name ASC" : null);
    return List.generate(maps.length, (i) {
      return Category(
          id: maps[i]['id'],
          categoryName: maps[i]['category_name'],
          colorValue: maps[i]['color']);
    });
  }



  List<DropdownMenuItem> createDropdownMenuItems() {
    List<DropdownMenuItem> resultList = [];
    resultList.add(
      DropdownMenuItem(
        child: Text("No category").tr(),
        value: -1,
      ),
    );
    generateCategoryList().then(((categoryList) {
      for (var category in categoryList) {
        print(category.categoryName);
        resultList.add(DropdownMenuItem(
          child: Text(category.categoryName!),
          value: category.id,
        ));
      }
    }));
    print(resultList.length);
    return resultList;
  }
}
