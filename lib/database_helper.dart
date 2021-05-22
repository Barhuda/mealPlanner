import 'dart:io' as io;

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = new DatabaseHelper.internal();

  factory DatabaseHelper() => _instance;
  static Database _db;

  DatabaseHelper.internal();

  initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();

    String path = join(documentsDirectory.path, "meal_database.db");
    _db = await openDatabase(path, version: 5, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Database get db {
    return _db;
  }

  void _onCreate(Database db, int version) async {
    // When creating the db, create the table
    await db.execute('CREATE TABLE meals (id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'meal_name TEXT,'
        'date INTEGER,'
        'daytime TEXT,'
        'recipe TEXT,'
        'UNIQUE (date, daytime))');
    await db.execute('CREATE TABLE meallist (id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'meal_name TEXT,'
        'note TEXT,'
        'recipe TEXT)');
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('CREATE TABLE meallist (id INTEGER PRIMARY KEY AUTOINCREMENT,'
          'meal_name TEXT,'
          'note TEXT)');
    }
  }
}
