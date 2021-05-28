import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:mealpy/meal.dart';
import 'package:mealpy/injection.dart';
import 'package:mealpy/database_helper.dart';
import 'package:mealpy/screens/food_list.dart';
import 'package:mealpy/meallist.dart';
import 'package:mealpy/constants.dart' as Constants;
import 'package:sqflite/sqflite.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share/share.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mealpy/buttons/buttonStyles.dart';

class MainScreen extends StatefulWidget {
  MainScreen({Key key, this.analytics, this.observer}) : super(key: key);
  static const String id = 'main_screen';

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _initialized = false;
  bool _error = false;
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
  List<Meallist> ideaList = [];
  FocusNode focusNode = FocusNode();
  ScreenshotController screenshotController = ScreenshotController();
  var mealTimeListDropdown = <String>[
    'Breakfast'.tr(),
    'Lunch'.tr(),
    'Dinner'.tr(),
  ];
  String selectedLocalMealTime;

  Map<DateTime, Map<String, Meal>> weekMap = {};
  Meal defaultMeal = Meal(mealName: "-", date: DateTime.utc(2000, 1, 1).millisecondsSinceEpoch, dayTime: "Breakfast");
  List<Meal> meals = [
    new Meal(id: 0, mealName: 'TestMeal', date: DateTime.now().millisecondsSinceEpoch, dayTime: "Breakfast"),
  ];
  TextEditingController dateCtl = TextEditingController(
      text:
          '${DateFormat('EE').format(DateTime.now())} ${DateTime.now().day.toString()}.${DateTime.now().month.toString()}.${DateTime.now().year.toString()}');

  void initializeFlutterFire() async {
    try {
      // Wait for Firebase to initialize and set `_initialized` state to true
      await Firebase.initializeApp();
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      // Set `_error` state to true if Firebase initialization fails
      setState(() {
        _error = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initializeFlutterFire();
    currentDate = DateTime.now();
    DatabaseHelper _databaseHelper = Injection.injector.get();
    asyncMethod().then((value) {
      setState(() {});
    });
  }

  Future asyncMethod() async {
    weekMap = await Meal().generateWeekList(currentDate);
    ideaList = await Meallist().generateMealList();
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
    datePeriod = currentDate.add(Duration(days: 6));
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
    if (mapToCheck["Breakfast"] == null && mapToCheck["Lunch"] == null && mapToCheck["Dinner"] == null) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> editDay(Meal breakfast, Meal lunch, Meal evening, DateTime date) async {
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
        await _databaseHelper.db.insert(
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
        await _databaseHelper.db.insert(
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
        await _databaseHelper.db.insert(
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
    editBreakfast = null;
    editLunch = null;
    editEvening = null;
    Navigator.of(context).pop();
    asyncMethod().then((value) {
      setState(() {});
    });
  }

  Future<void> _sendAnalyticsEvent(mealName) async {
    await widget.analytics.logEvent(
      name: 'created_Meal',
      parameters: <String, dynamic>{
        'Meal': mealName,
      },
    );
    print('logEvent succeeded');
  }

  double countLinks(breakfast, lunch, evening) {
    double numberOfLinks = 0;
    if (breakfast.recipe != null && breakfast.recipe != "") {
      numberOfLinks++;
    }
    if (lunch.recipe != null && lunch.recipe != "") {
      numberOfLinks++;
    }
    if (evening.recipe != null && evening.recipe != "") {
      numberOfLinks++;
    }
    print(numberOfLinks);
    return numberOfLinks;
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
                  final directory = (await getApplicationDocumentsDirectory()).path;
                  screenshotController.captureAndSave(directory, fileName: "Mealplan.jpg").then((path) => Share.shareFiles([path],
                      text:
                          "Mealplan: ${currentDate.day.toString()}.${currentDate.month.toString()}.${currentDate.year.toString()} - ${datePeriod.day.toString()}.${datePeriod.month.toString()}.${datePeriod.year.toString()}"));
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
                  Navigator.of(context).pushNamed(FoodList.id).then((value) => setState(() {
                        asyncMethod();
                      }));
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
                      child: Text("<", style: TextStyle(color: Colors.white, fontSize: 25)),
                      onPressed: () {
                        subtractWeek();
                      },
                    ),
                    Text(
                      '${currentDate.day.toString()}.${currentDate.month.toString()}.${currentDate.year.toString()}  -  '
                      '${datePeriod.day.toString()}.${datePeriod.month.toString()}.${datePeriod.year.toString()}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                        var breakfastCtrl = TextEditingController(text: breakfast.mealName);
                        var lunchCtrl = TextEditingController(text: lunch.mealName);
                        var dinnerCtrl = TextEditingController(text: evening.mealName);
                        print(lunch.recipe);
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20.0))),
                                backgroundColor: Constants.secondaryColor,
                                scrollable: true,
                                title: Text(
                                  '${formatter.format(weekMap.keys.elementAt(index))} ${weekMap.keys.elementAt(index).day.toString()}.${weekMap.keys.elementAt(index).month.toString()}.${weekMap.keys.elementAt(index).year.toString()}',
                                  textAlign: TextAlign.center,
                                ),
                                content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                                  return Container(
                                    height: 350 + (20 * (countLinks(breakfast, lunch, evening))),
                                    child: Form(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: <Widget>[
                                          TextFormField(
                                            keyboardType: TextInputType.text,
                                            textCapitalization: TextCapitalization.sentences,
                                            controller: breakfastCtrl,
                                            decoration: InputDecoration(
                                                labelText: 'Breakfast'.tr(),
                                                suffixIcon: IconButton(
                                                  onPressed: () {
                                                    breakfast.deleteMeal();
                                                    breakfastCtrl.clear();
                                                    editBreakfast = null;
                                                  },
                                                  icon: Icon(Icons.delete),
                                                )),
                                            textAlign: TextAlign.left,
                                            onChanged: (value) {
                                              editBreakfast = value;
                                            },
                                          ),
                                          Visibility(
                                            visible: (breakfast.recipe != "" && breakfast.recipe != null),
                                            child: ElevatedButton(
                                              child: Text("Link to recipe").tr(),
                                              onPressed: () {
                                                launch("https://" + breakfast.recipe);
                                              },
                                              style: recipeButtonStyle,
                                            ),
                                          ),
                                          TextFormField(
                                            keyboardType: TextInputType.text,
                                            textCapitalization: TextCapitalization.sentences,
                                            controller: lunchCtrl,
                                            decoration: InputDecoration(
                                              labelText: 'Lunch'.tr(),
                                              suffixIcon: IconButton(
                                                onPressed: () {
                                                  lunch.deleteMeal();
                                                  lunchCtrl.clear();
                                                  editLunch = null;
                                                },
                                                icon: Icon(Icons.delete),
                                              ),
                                            ),
                                            textAlign: TextAlign.left,
                                            onChanged: (value) {
                                              editLunch = value;
                                            },
                                          ),
                                          Visibility(
                                            visible: (lunch.recipe != "" && lunch.recipe != null),
                                            child: ElevatedButton(
                                              child: Text("Link to recipe").tr(),
                                              onPressed: () {
                                                launch("https://" + lunch.recipe);
                                              },
                                              style: recipeButtonStyle,
                                            ),
                                          ),
                                          TextFormField(
                                            keyboardType: TextInputType.text,
                                            textCapitalization: TextCapitalization.sentences,
                                            controller: dinnerCtrl,
                                            decoration: InputDecoration(
                                              labelText: 'Dinner'.tr(),
                                              suffixIcon: IconButton(
                                                onPressed: () {
                                                  evening.deleteMeal();
                                                  dinnerCtrl.clear();
                                                  editEvening = null;
                                                },
                                                icon: Icon(Icons.delete),
                                              ),
                                            ),
                                            textAlign: TextAlign.left,
                                            onChanged: (value) {
                                              editEvening = value;
                                            },
                                          ),
                                          Visibility(
                                            visible: (evening.recipe != "" && evening.recipe != null),
                                            child: ElevatedButton(
                                              child: Text("Link to recipe").tr(),
                                              onPressed: () {
                                                launch("https://" + evening.recipe);
                                              },
                                              style: recipeButtonStyle,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                actions: <Widget>[
/*                                  TextButton(
                                    child: Text(
                                      'Cancel'.tr(),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      asyncMethod().then((value) {
                                        setState(() {});
                                      });
                                    },
                                  ),*/
                                  ElevatedButton(
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(color: Colors.blue),
                                    ).tr(),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      asyncMethod().then((value) {
                                        setState(() {});
                                      });
                                    },
                                    style: cancelButtonStyle,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
/*                                  TextButton(
                                    child: Text(
                                      'Save'.tr(),
                                    ),
                                    onPressed: () {
                                      editDay(breakfast, lunch, evening, weekMap.keys.elementAt(index));
                                    },
                                  ),*/
                                  ElevatedButton(
                                    child: Text("Save").tr(),
                                    onPressed: () {
                                      editDay(breakfast, lunch, evening, weekMap.keys.elementAt(index));
                                    },
                                    style: saveButtonStyle,
                                  ),
                                ],
                              );
                            });
                      },
                      child: Card(
                        color: index % 2 == 0 ? Constants.thirdColor : Constants.thirdColor,
                        elevation: 6,
                        key: ValueKey(index),
                        margin: EdgeInsets.all(5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: allEntriesEmpty(currentMap)
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Text(
                                      '${formatter.format(weekMap.keys.elementAt(index))} ${weekMap.keys.elementAt(index).day.toString()}.${weekMap.keys.elementAt(index).month.toString()}.${weekMap.keys.elementAt(index).year.toString()}',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  Text(""),
                                  Text("-"),
                                  Text(""),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Text(
                                        '${formatter.format(weekMap.keys.elementAt(index))} ${weekMap.keys.elementAt(index).day.toString()}.${weekMap.keys.elementAt(index).month.toString()}.${weekMap.keys.elementAt(index).year.toString()}',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 8.0, bottom: 4),
                                          child: Column(
                                            children: [
                                              Text(
                                                "Breakfast".tr(),
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                              Text(
                                                breakfast.mealName ?? "-",
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        color: Constants.fourthColor,
                                        height: 30,
                                        width: 1,
                                        margin: EdgeInsets.all(4),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 4.0),
                                          child: Column(
                                            children: [
                                              Text(
                                                "Lunch".tr(),
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                              Text(
                                                lunch.mealName ?? "-",
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        color: Constants.fourthColor,
                                        height: 30,
                                        width: 1,
                                        margin: EdgeInsets.all(4),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 4.0),
                                          child: Column(
                                            children: [
                                              Text(
                                                "Dinner".tr(),
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                              Text(
                                                evening.mealName ?? "-",
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 75,
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            DateTime date = DateTime.now();
            selectedLocalMealTime = mealTimeListDropdown[0];
            mealTime = "Breakfast";
            mealDate = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20.0))),
                    backgroundColor: Constants.secondaryColor,
                    scrollable: true,
                    title: Text(
                      'Mealplan',
                      textAlign: TextAlign.center,
                    ),
                    content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                      return Container(
                        height: 300,
                        child: Form(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              TextFormField(
                                textCapitalization: TextCapitalization.sentences,
                                decoration: InputDecoration(labelText: 'Meal'.tr()),
                                textAlign: TextAlign.left,
                                onChanged: (value) {
                                  mealName = value;
                                },
                              ),
                              TextFormField(
                                readOnly: true,
                                decoration: InputDecoration(labelText: 'Date'.tr()),
                                controller: dateCtl,
                                onTap: () async {
                                  FocusScope.of(context).requestFocus(FocusNode());

                                  date = await showDatePicker(
                                      context: context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime(2100));

                                  dateCtl.text =
                                      '${DateFormat('EE').format(date)} ${date.day.toString()}.${date.month.toString()}.${date.year.toString()}';
                                  mealDate = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
                                },
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Container(
                                alignment: Alignment.centerLeft,
                                child: DropdownButton(
                                  value: selectedLocalMealTime ?? mealTimeListDropdown[0],
                                  icon: Icon(Icons.local_dining),
                                  elevation: 16,
                                  onChanged: (String newValue) {
                                    setState(() {
                                      if (mealTimeListDropdown.indexOf(newValue) == 0) {
                                        mealTime = "Breakfast";
                                        selectedLocalMealTime = mealTimeListDropdown[0];
                                      }
                                      if (mealTimeListDropdown.indexOf(newValue) == 1) {
                                        mealTime = "Lunch";
                                        selectedLocalMealTime = mealTimeListDropdown[1];
                                      }
                                      if (mealTimeListDropdown.indexOf(newValue) == 2) {
                                        mealTime = "Dinner";
                                        selectedLocalMealTime = mealTimeListDropdown[2];
                                      }
                                    });
                                  },
                                  items: mealTimeListDropdown.map<DropdownMenuItem<String>>(
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
                                textCapitalization: TextCapitalization.sentences,
                                keyboardType: TextInputType.multiline,
                                minLines: 2,
                                maxLines: 5,
                                decoration: InputDecoration(labelText: 'Notes'.tr()),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    actions: <Widget>[
                      ElevatedButton(
                        child: Text(
                          "Cancel",
                          style: TextStyle(color: Colors.blue),
                        ).tr(),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: cancelButtonStyle,
                      ),
                      /*FlatButton(
                        child: Text(
                          'Cancel'.tr(),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),*/
                      ElevatedButton(
                        child: Text("Save").tr(),
                        onPressed: () async {
                          try {
                            await _databaseHelper.db.insert(
                              "meals",
                              Meal(
                                mealName: mealName,
                                date: mealDate,
                                dayTime: mealTime,
                              ).toMapWithoutId(),
                            );
                            _sendAnalyticsEvent(mealName);
                            Navigator.of(context).pop();
                            asyncMethod().then((value) {
                              setState(() {});
                            });
                          } catch (e) {
                            print("Duplikat");
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Duplicate Meal Message").tr()));
                          }
                        },
                        style: saveButtonStyle,
                      ),
                      /* FlatButton(
                          child: Text(
                            'Save'.tr(),
                          ),
                          onPressed: () async {
                            try {
                              await _databaseHelper.db.insert(
                                "meals",
                                Meal(
                                  mealName: mealName,
                                  date: mealDate,
                                  dayTime: mealTime,
                                ).toMapWithoutId(),
                              );
                              _sendAnalyticsEvent(mealName);
                              Navigator.of(context).pop();
                              asyncMethod().then((value) {
                                setState(() {});
                              });
                            } catch (e) {
                              print("Duplikat");
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Duplicate Meal Message").tr()));
                            }
                          }),*/
                    ],
                  );
                });
          },
          child: Icon(Icons.add),
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }
}
