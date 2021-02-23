import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mealpy/meal.dart';
import 'package:mealpy/injection.dart';
import 'package:mealpy/database_helper.dart';
import 'package:mealpy/screens/food_list.dart';
import 'package:mealpy/day_meals.dart';
import 'package:mealpy/constants.dart' as Constants;
import 'package:sqflite/sqflite.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share/share.dart';
import 'package:path_provider/path_provider.dart';

class MainScreen extends StatefulWidget {
  MainScreen({Key key}) : super(key: key);
  static const String id = 'main_screen';

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  DatabaseHelper _databaseHelper = Injection.injector.get();
  DateTime currentDate;
  DateTime datePeriod = DateTime.now().add(Duration(days: 6));
  int mealDate = DateTime.now().millisecondsSinceEpoch;
  final DateFormat formatter = DateFormat("EEEE");
  String mealTime = 'Breakfast';
  DateTime selectedDate;
  String mealName = '';
  String editBreakfast = null;
  String editLunch = null;
  String editEvening = null;
  List<Meal> mealList = [];
  FocusNode focusNode = FocusNode();
  ScreenshotController screenshotController = ScreenshotController();
  Uint8List _imageFile;

  Map<DateTime, Map<String, Meal>> weekMap = {};
  Meal defaultMeal = Meal(
      mealName: "-",
      date: DateTime.utc(2000, 1, 1).millisecondsSinceEpoch,
      dayTime: "Breakfast");
  List<Meal> meals = [
    new Meal(
        id: 0,
        mealName: 'TestMeal',
        date: DateTime.now().millisecondsSinceEpoch,
        dayTime: "Breakfast"),
  ];
  TextEditingController dateCtl = TextEditingController(
      text:
          '${DateFormat('EE').format(DateTime.now())} ${DateTime.now().day.toString()}.${DateTime.now().month.toString()}.${DateTime.now().year.toString()}');

  @override
  void initState() {
    super.initState();
    currentDate = DateTime.now();
    DatabaseHelper _databaseHelper = Injection.injector.get();
    asyncMethod().then((value) {
      setState(() {});
    });
  }

  Future asyncMethod() async {
    weekMap = await Meal().generateWeekList(currentDate);
  }

  void addWeek() {
    currentDate = currentDate.add(Duration(days: 7));
    datePeriod = currentDate.add(Duration(days: 6));
    asyncMethod().then((value) {
      setState(() {});
    });
  }

  void subtractWeek() {
    currentDate = currentDate.subtract(Duration(days: 7));
    datePeriod = currentDate.subtract(Duration(days: 6));
    asyncMethod().then((value) {
      setState(() {});
    });
  }

  void backToCurrentDate() {
    currentDate = DateTime.now();
    datePeriod = currentDate.add(Duration(days: 6));
    asyncMethod().then((value) {
      setState(() {});
    });
  }

  bool allEntriesEmpty(Map mapToCheck) {
    if (mapToCheck["Breakfast"] == null &&
        mapToCheck["Lunch"] == null &&
        mapToCheck["Dinner"] == null) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> editDay(
      Meal breakfast, Meal lunch, Meal evening, DateTime date) async {
    print(editBreakfast);
    print(editEvening);
    print(editLunch);
    Batch batch = _databaseHelper.db.batch();
    if (breakfast.id != null && editBreakfast != null) {
      print("updated Breakfast");
      batch.update(
        "meals",
        Meal(
          id: breakfast.id,
          mealName: editBreakfast,
          date: breakfast.date,
          dayTime: breakfast.dayTime,
        ).toMap(),
        where: "id = ?",
        whereArgs: [breakfast.id],
      );
    } else {
      if (editBreakfast != null) {
        batch.insert(
            "meals",
            Meal(
              mealName: editBreakfast,
              date: date.millisecondsSinceEpoch,
              dayTime: "Breakfast",
            ).toMapWithoutId(),
            conflictAlgorithm: ConflictAlgorithm.replace);
        print("neu Breakfast");
      }
    }
    if (lunch.id != null && editLunch != null) {
      print("updated Lunch");
      batch.update(
          "meals",
          Meal(
            id: lunch.id,
            mealName: editLunch,
            date: lunch.date,
            dayTime: lunch.dayTime,
          ).toMap(),
          where: 'id = ?',
          whereArgs: [lunch.id]);
    } else {
      if (editLunch != null) {
        batch.insert(
          "meals",
          Meal(
            mealName: editLunch,
            date: date.millisecondsSinceEpoch,
            dayTime: "Lunch",
          ).toMapWithoutId(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print("neu Lunch");
      }
    }
    if (evening.id != null && editEvening != null) {
      print("updated Dinner");
      batch.update(
          "meals",
          Meal(
            id: evening.id,
            mealName: editEvening,
            date: evening.date,
            dayTime: evening.dayTime,
          ).toMap(),
          where: "id = ?",
          whereArgs: [evening.id]);
    } else {
      if (editEvening != null) {
        batch.insert(
            "meals",
            Meal(
              mealName: editEvening,
              date: date.millisecondsSinceEpoch,
              dayTime: "Dinner",
            ).toMapWithoutId(),
            conflictAlgorithm: ConflictAlgorithm.replace);
        print("neu Dinner");
      }
    }
    await batch.commit(noResult: true, continueOnError: true);
    weekMap = await Meal().generateWeekList(currentDate);

    setState(() {});
    Navigator.of(context).pop();
    editBreakfast = null;
    editLunch = null;
    editEvening = null;
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: screenshotController,
      child: Scaffold(
        backgroundColor: Constants.secondaryColor,
        appBar: AppBar(
          backgroundColor: Constants.mainColor,
          actionsIconTheme: IconThemeData(size: 40),
          title: Text(
            'Mealplaner',
          ),
          centerTitle: true,
          leading: Padding(
            padding: EdgeInsets.only(left: 10),
            child: GestureDetector(
              onTap: () {
                backToCurrentDate();
              },
              child: Icon(Icons.today),
            ),
          ),
          actions: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 30),
              child: GestureDetector(
                onTap: () async {
                  final directory =
                      (await getApplicationDocumentsDirectory()).path;
                  screenshotController
                      .captureAndSave(directory, fileName: "Mealplan.jpg")
                      .then((path) => Share.shareFiles([path],
                          text:
                              "Look at my Mealplan from ${currentDate.day.toString()}.${currentDate.month.toString()}.${currentDate.year.toString()} to ${datePeriod.day.toString()}.${datePeriod.month.toString()}.${datePeriod.year.toString()}"));
                },
                child: Icon(
                  Icons.share,
                  size: 25,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () async {
                  Navigator.of(context).pushNamed(FoodList.id);
                },
                child: Icon(Icons.list),
              ),
            ),
          ],
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    RaisedButton(
                      color: Constants.fourthColor,
                      child: Text("<",
                          style: TextStyle(color: Colors.white, fontSize: 25)),
                      onPressed: () {
                        subtractWeek();
                      },
                    ),
                    Text(
                      '${currentDate.day.toString()}.${currentDate.month.toString()}.${currentDate.year.toString()}  -  '
                      '${datePeriod.day.toString()}.${datePeriod.month.toString()}.${datePeriod.year.toString()}',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    RaisedButton(
                      color: Constants.fourthColor,
                      onPressed: () {
                        addWeek();
                      },
                      child: Text(
                        ">",
                        style: TextStyle(color: Colors.white, fontSize: 25),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: weekMap.length ?? 1,
                  itemBuilder: (context, int index) {
                    DateTime key = weekMap.keys.elementAt(index);
                    Map currentMap = weekMap[key];
                    Meal breakfast = currentMap["Breakfast"] ?? Meal();
                    Meal lunch = currentMap["Lunch"] ?? Meal();
                    Meal evening = currentMap["Dinner"] ?? Meal();
                    return GestureDetector(
                      onTap: () {
                        editBreakfast = null;
                        editLunch = null;
                        editEvening = null;
                        var breakfastCtrl =
                            TextEditingController(text: breakfast.mealName);
                        var lunchCtrl =
                            TextEditingController(text: lunch.mealName);
                        var dinnerCtrl =
                            TextEditingController(text: evening.mealName);
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: Constants.secondaryColor,
                                scrollable: false,
                                title: Text(
                                  '${formatter.format(weekMap.keys.elementAt(index))} ${weekMap.keys.elementAt(index).day.toString()}.${weekMap.keys.elementAt(index).month.toString()}.${weekMap.keys.elementAt(index).year.toString()}',
                                  textAlign: TextAlign.center,
                                ),
                                content: StatefulBuilder(builder:
                                    (BuildContext context,
                                        StateSetter setState) {
                                  return Container(
                                    height: 250,
                                    child: Form(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: <Widget>[
                                          TextFormField(
                                            keyboardType: TextInputType.text,
                                            controller: breakfastCtrl,
                                            decoration: InputDecoration(
                                                labelText: 'Breakfast',
                                                suffixIcon: IconButton(
                                                  onPressed: () {
                                                    breakfast.deleteMeal();
                                                    breakfastCtrl.clear();
                                                    editBreakfast = null;
                                                  },
                                                  icon: Icon(
                                                      Icons.delete_forever),
                                                )),
                                            textAlign: TextAlign.left,
                                            onChanged: (value) {
                                              editBreakfast = value;
                                            },
                                          ),
                                          TextFormField(
                                            keyboardType: TextInputType.text,
                                            controller: lunchCtrl,
                                            decoration: InputDecoration(
                                              labelText: 'Lunch',
                                              suffixIcon: IconButton(
                                                onPressed: () {
                                                  lunch.deleteMeal();
                                                  lunchCtrl.clear();
                                                  editLunch = null;
                                                },
                                                icon:
                                                    Icon(Icons.delete_forever),
                                              ),
                                            ),
                                            textAlign: TextAlign.left,
                                            onChanged: (value) {
                                              editLunch = value;
                                            },
                                          ),
                                          TextFormField(
                                            keyboardType: TextInputType.text,
                                            controller: dinnerCtrl,
                                            decoration: InputDecoration(
                                              labelText: 'Dinner',
                                              suffixIcon: IconButton(
                                                onPressed: () {
                                                  evening.deleteMeal();
                                                  dinnerCtrl.clear();
                                                  editEvening = null;
                                                },
                                                icon:
                                                    Icon(Icons.delete_forever),
                                              ),
                                            ),
                                            textAlign: TextAlign.left,
                                            onChanged: (value) {
                                              editEvening = value;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text(
                                      'Cancel',
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      asyncMethod().then((value) {
                                        setState(() {});
                                      });
                                    },
                                  ),
                                  TextButton(
                                    child: Text(
                                      'Save',
                                    ),
                                    onPressed: () {
                                      editDay(breakfast, lunch, evening,
                                          weekMap.keys.elementAt(index));
                                    },
                                  ),
                                ],
                              );
                            });
                      },
                      child: Card(
                        color: index % 2 == 0
                            ? Constants.thirdColor
                            : Constants.thirdColor,
                        elevation: 6,
                        key: ValueKey(index),
                        margin: EdgeInsets.all(6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: allEntriesEmpty(currentMap)
                            ? Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Text(
                                      '${formatter.format(weekMap.keys.elementAt(index))} ${weekMap.keys.elementAt(index).day.toString()}.${weekMap.keys.elementAt(index).month.toString()}.${weekMap.keys.elementAt(index).year.toString()}',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold)),
                                  Text(""),
                                  Text("-"),
                                  Text(""),
                                ],
                              )
                            : Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Text(
                                      '${formatter.format(weekMap.keys.elementAt(index))} ${weekMap.keys.elementAt(index).day.toString()}.${weekMap.keys.elementAt(index).month.toString()}.${weekMap.keys.elementAt(index).year.toString()}',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold)),
                                  Text(breakfast.mealName ?? "-"),
                                  Text(lunch.mealName ?? "-"),
                                  Text(evening.mealName ?? "-"),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Constants.secondaryColor,
                    scrollable: true,
                    title: Text(
                      'Mealplan',
                      textAlign: TextAlign.center,
                    ),
                    content: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                      return Container(
                        height: 400,
                        child: Form(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              TextFormField(
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(labelText: 'Meal'),
                                textAlign: TextAlign.left,
                                onChanged: (value) {
                                  mealName = value;
                                },
                              ),
                              TextFormField(
                                readOnly: true,
                                decoration: InputDecoration(labelText: 'Date'),
                                controller: dateCtl,
                                onTap: () async {
                                  DateTime date = DateTime(1900);
                                  FocusScope.of(context)
                                      .requestFocus(FocusNode());

                                  date = await showDatePicker(
                                      context: context,
                                      locale: const Locale('en'),
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime(2100));

                                  dateCtl.text =
                                      '${DateFormat('EE').format(date)} ${date.day.toString()}.${date.month.toString()}.${date.year.toString()}';
                                  mealDate =
                                      DateTime(date.year, date.month, date.day)
                                          .millisecondsSinceEpoch;
                                },
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Container(
                                alignment: Alignment.centerLeft,
                                child: DropdownButton(
                                  value: mealTime,
                                  icon: Icon(Icons.local_dining),
                                  elevation: 16,
                                  onChanged: (String newValue) {
                                    setState(() {
                                      mealTime = newValue;
                                    });
                                  },
                                  items: <String>[
                                    'Breakfast',
                                    'Lunch',
                                    'Dinner',
                                  ].map<DropdownMenuItem<String>>(
                                    (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    },
                                  ).toList(),
                                ),
                              ),
                              TextFormField(
                                textCapitalization:
                                    TextCapitalization.sentences,
                                keyboardType: TextInputType.multiline,
                                minLines: 2,
                                maxLines: 5,
                                decoration: InputDecoration(labelText: 'Notes'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    actions: <Widget>[
                      FlatButton(
                        child: Text(
                          'Cancel',
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      FlatButton(
                        child: Text(
                          'Save',
                        ),
                        onPressed: () async {
                          _databaseHelper.db.insert(
                              "meals",
                              Meal(
                                mealName: mealName,
                                date: mealDate,
                                dayTime: mealTime,
                              ).toMapWithoutId(),
                              conflictAlgorithm: ConflictAlgorithm.ignore);

                          Navigator.of(context).pop();
                          asyncMethod().then((value) {
                            setState(() {});
                          });
                        },
                      ),
                    ],
                  );
                });
          },
          child: Icon(Icons.schedule),
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }
}
