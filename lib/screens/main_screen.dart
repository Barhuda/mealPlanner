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
import 'settings_screen.dart';
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
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart' hide Trans;

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
  String editSnack = null;
  String breakfastLink = "";
  String lunchLink = "";
  String eveningLink = "";
  String snackLink = "";
  List<Meal> mealList = [];
  static List<Meallist> ideaList = [];
  FocusNode focusNode = FocusNode();
  ScreenshotController screenshotController = ScreenshotController();

  List<String> selectedMealTimes = [];

  List<String> mulitSelectMealTimesFullList = [
    "Breakfast",
    "Lunch",
    "Dinner",
    "Snack"
  ];

  // var mealTimeListDropdown = <String>[
  //   'Breakfast'.tr(),
  //   'Lunch'.tr(),
  //   'Dinner'.tr(),
  //   'Snack'.tr()
  // ];
  String selectedLocalMealTime;

  SharedPreferences prefs;
  int selectedWeekDayAsFirstDay;

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

  static List<Map<String, String>> getIdeas(String query) {
    List<Map<String, String>> resultList = [];
    if (query != "") {
      for (var idea in ideaList) {
        if (idea.mealName.toLowerCase().contains(query.toLowerCase())) {
          resultList.add({
            'mealName': idea.mealName,
            'recipe': idea.recipe,
            'id': idea.id.toString()
          });
        }
      }
    }

    return resultList;
  }

  @override
  void initState() {
    super.initState();
    initializeFlutterFire();
    currentDate = DateTime.now();
    _handleFirstDayOfWeek();
    DatabaseHelper _databaseHelper = Injection.injector.get();
  }

  _handleFirstDayOfWeek() async {
    await _getSharedPrefs();
    selectedWeekDayAsFirstDay = prefs.getInt('selectedWeekDay') ?? 0;
    if (selectedWeekDayAsFirstDay == 0) {
      currentDate = DateTime.now();
    } else {
      DateTime thisDateIs = DateTime.now();
      currentDate = thisDateIs.subtract(
          Duration(days: (thisDateIs.weekday - selectedWeekDayAsFirstDay) % 7));
    }
    asyncMethod().then((value) {
      setState(() {
        print('fired');
      });
    });
  }

  _getSharedPrefs() async {
    prefs = await SharedPreferences.getInstance();
    selectedWeekDayAsFirstDay = prefs.getInt('selectedWeekDay');
    selectedMealTimes = prefs.getStringList('mealTimes') ??
        ["Breakfast", "Lunch", "Dinner", "Snack"];
  }

  Future asyncMethod() async {
    print(currentDate);
    weekMap = await Meal().generateWeekList(currentDate);
    ideaList = await Meallist().generateMealList(0);
    setState(() {});
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
    DateTime thisDateIs = DateTime.now();
    currentDate = thisDateIs.subtract(
        Duration(days: thisDateIs.weekday - selectedWeekDayAsFirstDay));
    datePeriod = currentDate.add(Duration(days: 6));
    asyncMethod().then((value) {
      setState(() {});
    });
  }

  //TODO: Check auch Snack für AllEntriesEmpty
  bool allEntriesEmpty(Map mapToCheck) {
    if (mapToCheck["Breakfast"] == null &&
        mapToCheck["Lunch"] == null &&
        mapToCheck["Dinner"] == null &&
        mapToCheck["Snack"] == null) {
      return true;
    } else {
      return false;
    }
  }

  //TODO: Speichern in der Klasse Meal handlen
  //Snack ebenfalls speichern
  // Future<void> editDay(
  //     Meal breakfast, Meal lunch, Meal evening, DateTime date) async {
  //   print(editBreakfast);
  //   print(editEvening);
  //   print(editLunch);
  //   Batch batch = _databaseHelper.db.batch();
  //   if (breakfast.id != null && editBreakfast != null) {
  //     print("updated Breakfast");
  //     batch.update(
  //       "meals",
  //       Meal(
  //         id: breakfast.id,
  //         mealName: editBreakfast,
  //         date: breakfast.date,
  //         dayTime: breakfast.dayTime,
  //         recipe: breakfastLink,
  //       ).toMap(),
  //       where: "id = ?",
  //       whereArgs: [breakfast.id],
  //     );
  //   } else {
  //     if (editBreakfast != null) {
  //       await _databaseHelper.db.insert(
  //           "meals",
  //           Meal(
  //             mealName: editBreakfast,
  //             date: date.millisecondsSinceEpoch,
  //             dayTime: "Breakfast",
  //             recipe: breakfastLink,
  //           ).toMapWithoutId(),
  //           conflictAlgorithm: ConflictAlgorithm.replace);
  //       print("neu Breakfast");
  //     }
  //   }
  //   if (lunch.id != null && editLunch != null) {
  //     print("updated Lunch");
  //     batch.update(
  //         "meals",
  //         Meal(
  //           id: lunch.id,
  //           mealName: editLunch,
  //           date: lunch.date,
  //           dayTime: lunch.dayTime,
  //           recipe: lunchLink,
  //         ).toMap(),
  //         where: 'id = ?',
  //         whereArgs: [lunch.id]);
  //   } else {
  //     if (editLunch != null) {
  //       await _databaseHelper.db.insert(
  //         "meals",
  //         Meal(
  //           mealName: editLunch,
  //           date: date.millisecondsSinceEpoch,
  //           dayTime: "Lunch",
  //           recipe: lunchLink,
  //         ).toMapWithoutId(),
  //         conflictAlgorithm: ConflictAlgorithm.replace,
  //       );
  //       print("neu Lunch");
  //     }
  //   }
  //   if (evening.id != null && editEvening != null) {
  //     print("updated Dinner");
  //     batch.update(
  //         "meals",
  //         Meal(
  //           id: evening.id,
  //           mealName: editEvening,
  //           date: evening.date,
  //           dayTime: evening.dayTime,
  //           recipe: eveningLink,
  //         ).toMap(),
  //         where: "id = ?",
  //         whereArgs: [evening.id]);
  //   } else {
  //     if (editEvening != null) {
  //       await _databaseHelper.db.insert(
  //           "meals",
  //           Meal(
  //             mealName: editEvening,
  //             date: date.millisecondsSinceEpoch,
  //             dayTime: "Dinner",
  //             recipe: eveningLink,
  //           ).toMapWithoutId(),
  //           conflictAlgorithm: ConflictAlgorithm.replace);
  //       print("neu Dinner");
  //     }
  //   }
  //   await batch.commit(noResult: true, continueOnError: true);
  //   editBreakfast = null;
  //   editLunch = null;
  //   editEvening = null;
  //   editSnack = null;
  //   Navigator.of(context).pop();
  //   asyncMethod().then((value) {
  //     setState(() {});
  //   });
  // }

  Future<void> _sendAnalyticsEvent(mealName) async {
    await widget.analytics.logEvent(
      name: 'created_Meal',
      parameters: <String, dynamic>{
        'Meal': mealName,
      },
    );
    print('logEvent succeeded');
  }

  //TODO: Snack Links zählen
  double countLinks(breakfast, lunch, evening, snack) {
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
    if (snack.recipe != null && snack.recipe != "") {
      numberOfLinks++;
    }
    print(numberOfLinks);
    return numberOfLinks;
  }

  _showDeleteDialog(Meal mealToDelete, TextEditingController textCtrl) {
    Get.defaultDialog(
        title: "Delete Meal",
        middleText: "Do you really want to delete this meal?".tr(),
        textCancel: "Cancel".tr(),
        textConfirm: "Delete".tr(),
        confirmTextColor: Colors.red,
        cancelTextColor: Colors.black,
        buttonColor: Colors.white,
        onConfirm: () {
          mealToDelete.deleteMeal();
          textCtrl.clear();
          editBreakfast = null;
          Get.back();
        });
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
                  Navigator.of(context)
                      .pushNamed(SettingsScreen.id)
                      .then((value) => setState(() {
                            _handleFirstDayOfWeek();
                          }));
                },
                child: Icon(
                  Icons.settings,
                  size: 32,
                ),
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
                    Meal snack = currentMap["Snack"] ?? Meal();
                    List<Meal> mealsInCurrentDayList = [
                      breakfast,
                      lunch,
                      evening,
                      snack
                    ];
                    return GestureDetector(
                      onTap: () {
                        editBreakfast = null;
                        editLunch = null;
                        editEvening = null;
                        editSnack = null;
                        List<String> editMealStringList = [
                          editBreakfast,
                          editLunch,
                          editEvening,
                          editSnack
                        ];
                        var breakfastCtrl =
                            TextEditingController(text: breakfast.mealName);
                        var lunchCtrl =
                            TextEditingController(text: lunch.mealName);
                        var dinnerCtrl =
                            TextEditingController(text: evening.mealName);
                        var snackCtrl =
                            TextEditingController(text: snack.mealName);

                        List<TextEditingController> txtControllersList = [
                          breakfastCtrl,
                          lunchCtrl,
                          dinnerCtrl,
                          snackCtrl
                        ];

                        breakfastLink = "";
                        lunchLink = "";
                        eveningLink = "";
                        snackLink = "";
                        List<String> mealLinks = [
                          breakfastLink,
                          lunchLink,
                          eveningLink,
                          snackLink
                        ];
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Container(
                                child: AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(20.0))),
                                  backgroundColor: Constants.secondaryColor,
                                  scrollable: true,
                                  title: Text(
                                    '${formatter.format(weekMap.keys.elementAt(index))} ${weekMap.keys.elementAt(index).day.toString()}.${weekMap.keys.elementAt(index).month.toString()}.${weekMap.keys.elementAt(index).year.toString()}',
                                    textAlign: TextAlign.center,
                                  ),
                                  content: StatefulBuilder(builder:
                                      (BuildContext context,
                                          StateSetter setState) {
                                    return Container(
                                      height: 100 +
                                          (20 *
                                              (countLinks(breakfast, lunch,
                                                  evening, snack))) +
                                          (50 * selectedMealTimes.length),
                                      child: Form(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: <Widget>[
                                            for (var mealTimes
                                                in selectedMealTimes)
                                              Column(
                                                children: [
                                                  TypeAheadField(
                                                    textFieldConfiguration:
                                                        TextFieldConfiguration(
                                                      maxLines: 4,
                                                      minLines: 1,
                                                      keyboardType:
                                                          TextInputType
                                                              .multiline,
                                                      textCapitalization:
                                                          TextCapitalization
                                                              .sentences,
                                                      controller: txtControllersList[
                                                          mulitSelectMealTimesFullList
                                                              .indexOf(
                                                                  mealTimes)],
                                                      decoration:
                                                          InputDecoration(
                                                              labelText:
                                                                  mealTimes
                                                                      .tr(),
                                                              suffixIcon:
                                                                  IconButton(
                                                                onPressed: () {
                                                                  _showDeleteDialog(
                                                                      mealsInCurrentDayList[
                                                                          mulitSelectMealTimesFullList.indexOf(
                                                                              mealTimes)],
                                                                      txtControllersList[
                                                                          mulitSelectMealTimesFullList
                                                                              .indexOf(mealTimes)]);
                                                                },
                                                                icon: Icon(Icons
                                                                    .delete),
                                                              )),
                                                      textAlign: TextAlign.left,
                                                      onChanged: (value) {
                                                        editMealStringList[
                                                            mulitSelectMealTimesFullList
                                                                .indexOf(
                                                                    mealTimes)] = value;
                                                      },
                                                    ),
                                                    suggestionsCallback:
                                                        (pattern) {
                                                      return getIdeas(pattern);
                                                    },
                                                    itemBuilder:
                                                        (context, idea) {
                                                      return ListTile(
                                                        title: Text(
                                                            idea["mealName"]),
                                                      );
                                                    },
                                                    hideOnEmpty: true,
                                                    hideOnError: true,
                                                    debounceDuration: Duration(
                                                        milliseconds: 400),
                                                    onSuggestionSelected:
                                                        (idea) {
                                                      editMealStringList[
                                                              selectedMealTimes
                                                                  .indexOf(
                                                                      mealTimes)] =
                                                          idea["mealName"];
                                                      mealLinks[selectedMealTimes
                                                          .indexOf(
                                                              mealTimes)] = "";
                                                      txtControllersList[
                                                              selectedMealTimes
                                                                  .indexOf(
                                                                      mealTimes)]
                                                          .text = idea["mealName"];
                                                      if (idea["recipe"] !=
                                                              "" ||
                                                          idea["recipe"] !=
                                                              null) {
                                                        mealLinks[selectedMealTimes
                                                                .indexOf(
                                                                    mealTimes)] =
                                                            idea["recipe"];
                                                      }
                                                    },
                                                  ),
                                                  Visibility(
                                                    visible: (mealsInCurrentDayList[
                                                                    selectedMealTimes
                                                                        .indexOf(
                                                                            mealTimes)]
                                                                .recipe !=
                                                            "" &&
                                                        mealsInCurrentDayList[
                                                                    selectedMealTimes
                                                                        .indexOf(
                                                                            mealTimes)]
                                                                .recipe !=
                                                            null),
                                                    child: ElevatedButton(
                                                      child:
                                                          Text("Link to recipe")
                                                              .tr(),
                                                      onPressed: () {
                                                        launch(mealsInCurrentDayList[
                                                                selectedMealTimes
                                                                    .indexOf(
                                                                        mealTimes)]
                                                            .recipe);
                                                      },
                                                      style: recipeButtonStyle,
                                                    ),
                                                  ),
                                                ],
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
                                        asyncMethod().then((value) {
                                          setState(() {});
                                        });
                                      },
                                      style: cancelButtonStyle,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    ElevatedButton(
                                      child: Text("Save").tr(),
                                      onPressed: () {
                                        for (int i = 0;
                                            i < selectedMealTimes.length;
                                            i++) {
                                          int correctIndex =
                                              mulitSelectMealTimesFullList
                                                  .indexOf(
                                                      selectedMealTimes[i]);
                                          mealsInCurrentDayList[correctIndex]
                                              .saveMeal(
                                                  txtControllersList[
                                                          correctIndex]
                                                      .text,
                                                  weekMap.keys.elementAt(index),
                                                  selectedMealTimes[i],
                                                  mealLinks[correctIndex]);
                                          editMealStringList[correctIndex] =
                                              null;
                                        }
                                        Navigator.of(context).pop();
                                        asyncMethod().then((value) {
                                          setState(() {});
                                        });
                                        // editDay(breakfast, lunch, evening,
                                        //     weekMap.keys.elementAt(index));
                                      },
                                      style: saveButtonStyle,
                                    ),
                                  ],
                                ),
                              );
                            });
                      },
                      child: Card(
                        color: Constants.thirdColor,
                        elevation: 6,
                        key: ValueKey(index),
                        margin: EdgeInsets.all(5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Text(
                                        '${formatter.format(weekMap.keys.elementAt(index))} ${weekMap.keys.elementAt(index).day.toString()}.${weekMap.keys.elementAt(index).month.toString()}.${weekMap.keys.elementAt(index).year.toString()}',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      for (int i = 0;
                                          i < selectedMealTimes.length;
                                          i++)
                                        selectedMealTimes[i] == "Snack"
                                            ? SizedBox()
                                            : Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(4.0),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceEvenly,
                                                          children: [
                                                            Text(
                                                              selectedMealTimes[
                                                                      i]
                                                                  .tr(),
                                                              textAlign:
                                                                  TextAlign
                                                                      .start,
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14),
                                                            ),
                                                            Text(
                                                              mealsInCurrentDayList[
                                                                          mulitSelectMealTimesFullList
                                                                              .indexOf(selectedMealTimes[i])]
                                                                      .mealName ??
                                                                  "-",
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 8,
                                                      ),
                                                      Visibility(
                                                        visible: selectedMealTimes
                                                                .contains(
                                                                    "Snack")
                                                            ? i <
                                                                selectedMealTimes
                                                                        .length -
                                                                    2
                                                            : i <
                                                                selectedMealTimes
                                                                        .length -
                                                                    1,
                                                        child: Container(
                                                          color: Constants
                                                              .fourthColor,
                                                          height: 30,
                                                          width: 1,
                                                          margin:
                                                              EdgeInsets.all(4),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                    ],
                                  ),
                                  selectedMealTimes.contains("Snack")
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            // Container(
                                            //   color: Constants.fourthColor,
                                            //   height: 1,
                                            //   width: 150,
                                            //   margin: EdgeInsets.all(4),
                                            // ),
                                            Text(
                                              "Snack".tr(),
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14),
                                            ),
                                            Text(
                                              mealsInCurrentDayList[
                                                          mulitSelectMealTimesFullList
                                                              .indexOf("Snack")]
                                                      .mealName ??
                                                  "-",
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        )
                                      : SizedBox(),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.9,
                child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(primary: Constants.mainColor),
                    onPressed: () async {
                      Navigator.of(context)
                          .pushNamed(FoodList.id)
                          .then((value) => setState(() {
                                asyncMethod();
                              }));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        "Idea List \uD83C\uDF7D️",
                        style: TextStyle(fontSize: 18),
                      ).tr(),
                    )),
              ),
              SizedBox(
                height: 10,
              )
            ],
          ),
        ),
        // floatingActionButton: Padding(
        //   padding: const EdgeInsets.only(bottom: 24.0),
        //   child: FloatingActionButton(
        //     onPressed: () {
        //       DateTime date = DateTime.now();
        //       selectedLocalMealTime = selectedMealTimes[0];
        //       mealTime = "Breakfast";
        //       mealDate = DateTime(date.year, date.month, date.day)
        //           .millisecondsSinceEpoch;
        //       showDialog(
        //           context: context,
        //           builder: (BuildContext context) {
        //             var mealCtrl = TextEditingController();
        //             var link = "";
        //             return AlertDialog(
        //               shape: RoundedRectangleBorder(
        //                   borderRadius:
        //                       BorderRadius.all(Radius.circular(20.0))),
        //               backgroundColor: Constants.secondaryColor,
        //               scrollable: true,
        //               title: Text(
        //                 'Mealplan',
        //                 textAlign: TextAlign.center,
        //               ),
        //               content: StatefulBuilder(builder:
        //                   (BuildContext context, StateSetter setState) {
        //                 return Container(
        //                   height: 300,
        //                   child: Form(
        //                     child: Column(
        //                       mainAxisAlignment: MainAxisAlignment.start,
        //                       crossAxisAlignment: CrossAxisAlignment.center,
        //                       children: <Widget>[
        //                         TypeAheadField(
        //                           textFieldConfiguration:
        //                               TextFieldConfiguration(
        //                             controller: mealCtrl,
        //                             textCapitalization:
        //                                 TextCapitalization.sentences,
        //                             decoration:
        //                                 InputDecoration(labelText: 'Meal'.tr()),
        //                             textAlign: TextAlign.left,
        //                             autofocus: false,
        //                           ),
        //                           hideOnEmpty: true,
        //                           hideOnError: true,
        //                           debounceDuration: Duration(milliseconds: 400),
        //                           suggestionsCallback: (pattern) {
        //                             return getIdeas(pattern);
        //                           },
        //                           itemBuilder: (context, idea) {
        //                             return ListTile(
        //                               title: Text(idea["mealName"]),
        //                             );
        //                           },
        //                           onSuggestionSelected: (idea) {
        //                             link = "";
        //                             mealCtrl.text = idea["mealName"];
        //                             if (idea["recipe"] != "" ||
        //                                 idea["recipe"] != null) {
        //                               link = idea["recipe"];
        //                             }
        //                           },
        //                         ),
        //                         TextFormField(
        //                           readOnly: true,
        //                           decoration:
        //                               InputDecoration(labelText: 'Date'.tr()),
        //                           controller: dateCtl,
        //                           onTap: () async {
        //                             FocusScope.of(context)
        //                                 .requestFocus(FocusNode());

        //                             date = await showDatePicker(
        //                                 context: context,
        //                                 initialDate: DateTime.now(),
        //                                 firstDate: DateTime(1900),
        //                                 lastDate: DateTime(2100));

        //                             dateCtl.text =
        //                                 '${DateFormat('EE').format(date)} ${date.day.toString()}.${date.month.toString()}.${date.year.toString()}';
        //                             mealDate = DateTime(
        //                                     date.year, date.month, date.day)
        //                                 .millisecondsSinceEpoch;
        //                           },
        //                         ),
        //                         SizedBox(
        //                           height: 10,
        //                         ),
        //                         Container(
        //                           alignment: Alignment.centerLeft,
        //                           child: DropdownButton(
        //                             value: selectedLocalMealTime ??
        //                                 selectedMealTimes[0].tr(),
        //                             icon: Icon(Icons.local_dining),
        //                             elevation: 16,
        //                             onChanged: (String newValue) {
        //                               setState(() {
        //                                 selectedLocalMealTime = newValue;
        //                               });
        //                             },
        //                             items: selectedMealTimes
        //                                 .map<DropdownMenuItem<String>>(
        //                               (String value) {
        //                                 return DropdownMenuItem<String>(
        //                                   value: value,
        //                                   child: Text(value.tr()),
        //                                 );
        //                               },
        //                             ).toList(),
        //                           ),
        //                         ),
        //                       ],
        //                     ),
        //                   ),
        //                 );
        //               }),
        //               actions: <Widget>[
        //                 ElevatedButton(
        //                   child: Text(
        //                     "Cancel",
        //                     style: TextStyle(color: Colors.blue),
        //                   ).tr(),
        //                   onPressed: () {
        //                     Navigator.of(context).pop();
        //                   },
        //                   style: cancelButtonStyle,
        //                 ),
        //                 ElevatedButton(
        //                   child: Text("Save").tr(),
        //                   onPressed: () async {
        //                     try {
        //                       await _databaseHelper.db.insert(
        //                         "meals",
        //                         Meal(
        //                           mealName: mealCtrl.text.toString(),
        //                           date: mealDate,
        //                           dayTime: mealTime,
        //                           recipe: link,
        //                         ).toMapWithoutId(),
        //                       );
        //                       _sendAnalyticsEvent(mealCtrl.text.toString());
        //                       Navigator.of(context).pop();
        //                       asyncMethod().then((value) {
        //                         setState(() {});
        //                       });
        //                     } catch (e) {
        //                       print("Duplikat");
        //                       Navigator.of(context).pop();
        //                       ScaffoldMessenger.of(context).showSnackBar(
        //                           SnackBar(
        //                               content:
        //                                   Text("Duplicate Meal Message").tr()));
        //                     }
        //                   },
        //                   style: saveButtonStyle,
        //                 ),
        //               ],
        //             );
        //           });
        //     },
        //     child: Icon(Icons.add),
        //   ),
        // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }
}
