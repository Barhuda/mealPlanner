import 'dart:convert';
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
import 'package:mealpy/my_user.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  MyUser myUser = Get.find();
  Stream<DatabaseEvent> dbStream;
  final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');

  List<String> selectedMealTimes = [];

  List<String> mulitSelectMealTimesFullList = [
    "Breakfast",
    "Lunch",
    "Dinner",
    "Snack"
  ];

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

  _startup() async {
    await _getDbRef();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getDbRef();
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
        _getDbRef();
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
      setState(() {
        if (myUser.isLoggedIn) _getDbRef();
      });
    });
  }

  void subtractWeek() {
    currentDate = currentDate.subtract(Duration(days: 7));
    datePeriod = currentDate.add(Duration(days: 6));
    asyncMethod().then((value) {
      setState(() {
        if (myUser.isLoggedIn) _getDbRef();
      });
    });
  }

  void backToCurrentDate() {
    DateTime thisDateIs = DateTime.now();
    currentDate = thisDateIs.subtract(
        Duration(days: thisDateIs.weekday - selectedWeekDayAsFirstDay));
    datePeriod = currentDate.add(Duration(days: 6));
    _handleFirstDayOfWeek();
    asyncMethod().then((value) {
      setState(() {
        if (myUser.isLoggedIn) _getDbRef();
      });
    });
  }

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

  _changeScene(int index) {
    Get.offAllNamed(Constants.bottomNavigationRoutes[index]);
  }

  _getDbRef() async {
    final DateTime now = currentDate;
    String selectedMealplan = await myUser.getSelectedMealPlan();
    final String formatted = dateFormatter.format(now);
    final String endDate = dateFormatter.format(now.add(Duration(days: 6)));
    print("PLAN: " + selectedMealplan);
    if (myUser.UID != null) {
      try {
        dbStream = FirebaseDatabase.instance
            .ref()
            .child("mealDbs")
            .child(selectedMealplan)
            .child("weekdays")
            .orderByKey()
            .startAt(formatted)
            .endAt(endDate)
            .onValue;
        print("DAten: " + selectedMealplan + "  " + "$formatted ; $endDate");
        setState(() {});
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print(myUser.isLoggedIn);
    return Screenshot(
      controller: screenshotController,
      child: Scaffold(
        backgroundColor: Constants.secondaryColor,
        appBar: AppBar(
          backgroundColor: Constants.mainColor,
          actionsIconTheme: IconThemeData(size: 40),
          title: Text(
            'Meal planner'.tr(),
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
                child: myUser.isLoggedIn ? onlineWidget() : offlineList(),
              ),
              // FractionallySizedBox(
              //   widthFactor: 0.9,
              //   child: ElevatedButton(
              //       style:
              //           ElevatedButton.styleFrom(primary: Constants.mainColor),
              //       onPressed: () async {
              //         Navigator.of(context)
              //             .pushNamed(FoodList.id)
              //             .then((value) => setState(() {
              //                   asyncMethod();
              //                 }));
              //       },
              //       child: Padding(
              //         padding: const EdgeInsets.all(12.0),
              //         child: Text(
              //           "Idea List \uD83C\uDF7D️",
              //           style: TextStyle(fontSize: 18),
              //         ).tr(),
              //       )),
              // ),
              // SizedBox(
              //   height: 10,
              // )
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          unselectedItemColor: Colors.red,
          showUnselectedLabels: true,
          selectedItemColor: Constants.fourthColor,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings'.tr(),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile'.tr(),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant),
              label: 'Meal Plan'.tr(),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book),
              label: 'Ideas'.tr(),
            ),
          ],
          onTap: _changeScene,
          currentIndex: 2,
        ),
      ),
    );
  }

  StreamBuilder<dynamic> onlineWidget() {
    return StreamBuilder(
        stream: dbStream,
        builder: (BuildContext context, snapshot) {
          print(snapshot.connectionState);
          if (snapshot.hasData) {
            DataSnapshot dataValues = snapshot.data.snapshot;
            Map<dynamic, dynamic> values = dataValues.value;
            Map<dynamic, dynamic> parsed = {};
            print("Data:" + values.toString());
            if (values != null) {
              values.forEach((key, value) {
                print(value.toString());
                print(key.toString());
                parsed[key] = value;
              });
              return ListView.builder(
                  itemCount: 7,
                  itemBuilder: (BuildContext context, int index) {
                    String cardDate = dateFormatter
                        .format(currentDate.add(Duration(days: index)));
                    Map<dynamic, dynamic> mealsInDay = parsed[cardDate];
                    return Card(
                      color: Constants.thirdColor,
                      elevation: 6,
                      key: ValueKey(index),
                      margin: EdgeInsets.all(5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: parsed[cardDate] == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                                                .center,
                                                        children: [
                                                          Text(
                                                            selectedMealTimes[i]
                                                                .tr(),
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 14),
                                                          ),
                                                          Text(
                                                            mealsInDay != null
                                                                ? mealsInDay[selectedMealTimes[i]
                                                                            .toLowerCase()] !=
                                                                        null
                                                                    ? mealsInDay[
                                                                            selectedMealTimes[i].toLowerCase()]
                                                                        ["name"]
                                                                    : "-"
                                                                : "-",
                                                            textAlign: TextAlign
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
                                                              .contains("Snack")
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
                                    ? Padding(
                                        padding:
                                            const EdgeInsets.only(right: 15),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Snack".tr(),
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14),
                                            ),
                                            Text(
                                              mealsInDay != null
                                                  ? mealsInDay["Snack"] != null
                                                      ? mealsInDay["Snack"]
                                                          ["name"]
                                                      : "-"
                                                  : "-",
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      )
                                    : SizedBox(),
                              ],
                            ),
                    );
                  });
            } else {
              print("Alles leer");
              return ListView.builder(
                  itemCount: 7,
                  itemBuilder: (BuildContext context, int index) {
                    String cardDate = dateFormatter
                        .format(currentDate.add(Duration(days: index)));
                    Map<dynamic, dynamic> mealsInDay = parsed[cardDate];
                    return Card(
                        color: Constants.thirdColor,
                        elevation: 6,
                        margin: EdgeInsets.all(5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Text(
                                '${formatter.format(weekMap.keys.elementAt(index))} ${weekMap.keys.elementAt(index).day.toString()}.${weekMap.keys.elementAt(index).month.toString()}.${weekMap.keys.elementAt(index).year.toString()}',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            Text(""),
                            Text("-"),
                            Text(""),
                          ],
                        ));
                  });
            }
          } else {
            return Text("No Data");
          }
        });
  }

  ListView offlineList() {
    return ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: weekMap.length ?? 1,
      itemBuilder: (context, int index) {
        DateTime key = weekMap.keys.elementAt(index);
        Map currentMap = weekMap[key];
        Meal breakfast = currentMap["Breakfast"] ?? Meal();
        Meal lunch = currentMap["Lunch"] ?? Meal();
        Meal evening = currentMap["Dinner"] ?? Meal();
        Meal snack = currentMap["Snack"] ?? Meal();
        List<Meal> mealsInCurrentDayList = [breakfast, lunch, evening, snack];
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
            var breakfastCtrl = TextEditingController(text: breakfast.mealName);
            var lunchCtrl = TextEditingController(text: lunch.mealName);
            var dinnerCtrl = TextEditingController(text: evening.mealName);
            var snackCtrl = TextEditingController(text: snack.mealName);

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
            print(evening.recipe);
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Container(
                    child: AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(20.0))),
                      backgroundColor: Constants.secondaryColor,
                      scrollable: true,
                      title: Text(
                        '${formatter.format(weekMap.keys.elementAt(index))} ${weekMap.keys.elementAt(index).day.toString()}.${weekMap.keys.elementAt(index).month.toString()}.${weekMap.keys.elementAt(index).year.toString()}',
                        textAlign: TextAlign.center,
                      ),
                      content: StatefulBuilder(builder:
                          (BuildContext context, StateSetter setState) {
                        return Container(
                          height: 100 +
                              (20 *
                                  (countLinks(
                                      breakfast, lunch, evening, snack))) +
                              (50 * selectedMealTimes.length),
                          child: Form(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                for (var mealTimes in selectedMealTimes)
                                  Column(
                                    children: [
                                      TypeAheadField(
                                        textFieldConfiguration:
                                            TextFieldConfiguration(
                                          maxLines: 4,
                                          minLines: 1,
                                          keyboardType: TextInputType.multiline,
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          controller: txtControllersList[
                                              mulitSelectMealTimesFullList
                                                  .indexOf(mealTimes)],
                                          decoration: InputDecoration(
                                              labelText: mealTimes.tr(),
                                              suffixIcon: IconButton(
                                                onPressed: () {
                                                  _showDeleteDialog(
                                                      mealsInCurrentDayList[
                                                          mulitSelectMealTimesFullList
                                                              .indexOf(
                                                                  mealTimes)],
                                                      txtControllersList[
                                                          mulitSelectMealTimesFullList
                                                              .indexOf(
                                                                  mealTimes)]);
                                                },
                                                icon: Icon(Icons.delete),
                                              )),
                                          textAlign: TextAlign.left,
                                          onChanged: (value) {
                                            editMealStringList[
                                                    mulitSelectMealTimesFullList
                                                        .indexOf(mealTimes)] =
                                                value;
                                          },
                                        ),
                                        suggestionsCallback: (pattern) {
                                          return getIdeas(pattern);
                                        },
                                        itemBuilder: (context, idea) {
                                          return ListTile(
                                            title: Text(idea["mealName"]),
                                          );
                                        },
                                        hideOnEmpty: true,
                                        hideOnError: true,
                                        debounceDuration:
                                            Duration(milliseconds: 400),
                                        onSuggestionSelected: (idea) {
                                          editMealStringList[
                                                  mulitSelectMealTimesFullList
                                                      .indexOf(mealTimes)] =
                                              idea["mealName"];
                                          mealLinks[mulitSelectMealTimesFullList
                                              .indexOf(mealTimes)] = "";
                                          txtControllersList[
                                                  mulitSelectMealTimesFullList
                                                      .indexOf(mealTimes)]
                                              .text = idea["mealName"];
                                          if (idea["recipe"] != "" ||
                                              idea["recipe"] != null) {
                                            mealLinks[
                                                    mulitSelectMealTimesFullList
                                                        .indexOf(mealTimes)] =
                                                idea["recipe"];
                                          }
                                        },
                                      ),
                                      Visibility(
                                        visible: (mealsInCurrentDayList[
                                                        mulitSelectMealTimesFullList
                                                            .indexOf(mealTimes)]
                                                    .recipe !=
                                                "" &&
                                            mealsInCurrentDayList[
                                                        mulitSelectMealTimesFullList
                                                            .indexOf(mealTimes)]
                                                    .recipe !=
                                                null),
                                        child: ElevatedButton(
                                          child: Text("Link to recipe").tr(),
                                          onPressed: () {
                                            String recipeLink =
                                                mealsInCurrentDayList[
                                                        mulitSelectMealTimesFullList
                                                            .indexOf(mealTimes)]
                                                    .recipe;
                                            if (recipeLink
                                                    .startsWith("https://") ||
                                                recipeLink
                                                    .startsWith("http://")) {
                                              launch(recipeLink);
                                            } else {
                                              launch("https://" + recipeLink);
                                            }
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
                            for (int i = 0; i < selectedMealTimes.length; i++) {
                              int correctIndex = mulitSelectMealTimesFullList
                                  .indexOf(selectedMealTimes[i]);
                              mealsInCurrentDayList[correctIndex].saveMeal(
                                  txtControllersList[correctIndex].text,
                                  weekMap.keys.elementAt(index),
                                  selectedMealTimes[i],
                                  mealsInCurrentDayList[correctIndex].recipe);
                              editMealStringList[correctIndex] = null;
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
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text(
                          '${formatter.format(weekMap.keys.elementAt(index))} ${weekMap.keys.elementAt(index).day.toString()}.${weekMap.keys.elementAt(index).month.toString()}.${weekMap.keys.elementAt(index).year.toString()}',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
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
                                fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (int i = 0; i < selectedMealTimes.length; i++)
                            selectedMealTimes[i] == "Snack"
                                ? SizedBox()
                                : Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  selectedMealTimes[i].tr(),
                                                  textAlign: TextAlign.start,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14),
                                                ),
                                                Text(
                                                  mealsInCurrentDayList[
                                                              mulitSelectMealTimesFullList
                                                                  .indexOf(
                                                                      selectedMealTimes[
                                                                          i])]
                                                          .mealName ??
                                                      "-",
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: 8,
                                          ),
                                          Visibility(
                                            visible: selectedMealTimes
                                                    .contains("Snack")
                                                ? i <
                                                    selectedMealTimes.length - 2
                                                : i <
                                                    selectedMealTimes.length -
                                                        1,
                                            child: Container(
                                              color: Constants.fourthColor,
                                              height: 30,
                                              width: 1,
                                              margin: EdgeInsets.all(4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                        ],
                      ),
                      selectedMealTimes.contains("Snack")
                          ? Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
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
                              ),
                            )
                          : SizedBox(),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
