import 'dart:io' as io;

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = new DatabaseHelper.internal();

  factory DatabaseHelper() => _instance;
  static Database? _db;

  DatabaseHelper.internal();

  initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();

    String path = join(documentsDirectory.path, "meal_database.db");
    _db = await openDatabase(path, version: 8, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Database? get db {
    return _db;
  }

  void _onCreate(Database db, int version) async {
    // When creating the db, create the table
    await db.execute('CREATE TABLE meals (id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'meal_name TEXT,'
        'date INTEGER,'
        'daytime TEXT,'
        'recipe TEXT,'
        'image TEXT,'
        'UNIQUE (date, daytime))');
    await db.execute('CREATE TABLE meallist (id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'meal_name TEXT,'
        'note TEXT,'
        'recipe TEXT,'
        'image TEXT,'
        'category INTEGER)');
    await db.execute('CREATE TABLE category (id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'category_name TEXT,'
        'color TEXT)');
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('CREATE TABLE meallist (id INTEGER PRIMARY KEY AUTOINCREMENT,'
          'meal_name TEXT,'
          'note TEXT)');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE meals ADD recipe TEXT');
      await db.execute('ALTER TABLE meallist ADD recipe TEXT');
    }
    if (oldVersion < 6) {
      await db.execute('CREATE TABLE category (id INTEGER PRIMARY KEY AUTOINCREMENT,'
          'category_name TEXT,'
          'color TEXT)');
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE meallist ADD COLUMN category INTEGER');
    }
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE meals ADD COLUMN image TEXT');
      await db.execute('ALTER TABLE meallist ADD COLUMN image TEXT');
    }
  }
}
