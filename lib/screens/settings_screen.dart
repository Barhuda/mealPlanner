import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mealpy/my_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:multiselect/multiselect.dart';
import 'package:auth_buttons/auth_buttons.dart'
    show GoogleAuthButton, EmailAuthButton, AuthButtonType, AuthIconType;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart' hide Trans;

class SettingsScreen extends StatefulWidget {
  SettingsScreen({Key key, this.analytics, this.observer, this.database})
      : super(key: key);

  final FirebaseDatabase database;
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  static const String id = 'settings_screen';

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SharedPreferences prefs;
  bool firstDayIsCurrentDay;
  int selectedWeekDayAsFirstDay;
  var days;
  bool _isLoading = true;
  bool sortAlphabetical = false;
  List<DropdownMenuItem<int>> dropDownList = [];
  MyUser myUser = Get.find();

  int selectedValue = 0;

  List<String> mulitSelectMealTimesFullList = [
    "Breakfast",
    "Lunch",
    "Dinner",
    "Snack"
  ];
  List<String> selectedMultiselectMealTimes = [];
  List<String> translatedMultiSelectMeals = [];

  @override
  void initState() {
    super.initState();
    if (myUser.isLoggedIn) {
      _getUserInfo();
    }

    _getSharedPrefs();
    _generateWeekDayList();
  }

  _getUserInfo() async {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref("Users/${myUser.UID}");
    DatabaseEvent event = await ref.once();
    print(event.snapshot.value);
  }

  _getSharedPrefs() async {
    prefs = await SharedPreferences.getInstance();
    selectedWeekDayAsFirstDay = prefs.getInt('selectedWeekDay') ?? 0;
    sortAlphabetical = prefs.getBool('sort') ?? false;
    selectedMultiselectMealTimes = prefs.getStringList('mealTimes') ??
        ["Breakfast", "Lunch", "Dinner", "Snack"];

    if (selectedMultiselectMealTimes == []) {
      selectedMultiselectMealTimes = ["Breakfast", "Lunch", "Dinner", "Snack"];
    }
    setState(() {
      selectedValue = selectedWeekDayAsFirstDay;
    });
  }

  final DateFormat formatter = DateFormat("EEEE");

  _generateWeekDayList() {
    DateTime startDateTime = DateTime(2020, 09, 21);
    int startDay = 1;
    DropdownMenuItem<int> firstDropDownItem = DropdownMenuItem(
      value: 0,
      child: Text("Always Current Day").tr(),
    );
    dropDownList.add(firstDropDownItem);
    while (dropDownList.length <= 7) {
      DropdownMenuItem<int> newDropDownItem = DropdownMenuItem(
        value: startDay,
        child: Text("${formatter.format(startDateTime)}"),
      );
      newDropDownItem.toString();
      dropDownList.add(newDropDownItem);
      startDay++;
      startDateTime = startDateTime.add(Duration(days: 1));
    }
    setState(() {
      _isLoading = false;
    });
  }

  _addData() {
    if (myUser.UID != null) {
      print("USER UID:::" + myUser.UID);
    } else {
      print("UID Leer");
    }
  }

  _registerWithMail() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: "barry.allen@example.com",
              password: "SuperSecretPassword!");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print(e);
    }
  }

  _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  _loginWithMail() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: "barry.allen@example.com",
              password: "SuperSecretPassword!");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Settings".tr()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Set your first Day of the week").tr(),
            _isLoading
                ? SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    child: DropdownButton<int>(
                      items: dropDownList,
                      value: selectedValue,
                      onChanged: (value) {
                        prefs.setInt('selectedWeekDay', value);
                        setState(() {
                          selectedValue = value;
                        });
                      },
                    ),
                  ),
            SizedBox(
              height: 30,
            ),
            Text("Sort Lists in alphabetical order").tr(),
            Switch(
                value: sortAlphabetical,
                onChanged: (value) {
                  prefs.setBool('sort', value);
                  setState(() {
                    sortAlphabetical = value;
                    print(selectedMultiselectMealTimes);
                  });
                }),
            SizedBox(
              height: 30,
            ),
            Text("Meals to show".tr()),
            DropDownMultiSelect(
                options: mulitSelectMealTimesFullList,
                selectedValues: selectedMultiselectMealTimes,
                onChanged: (List<String> x) {
                  setState(() {
                    selectedMultiselectMealTimes = x;

                    selectedMultiselectMealTimes.sort((a, b) =>
                        mulitSelectMealTimesFullList.indexOf(a).compareTo(
                            mulitSelectMealTimesFullList.indexOf(b)));
                    print(selectedMultiselectMealTimes);
                    prefs.setStringList(
                        'mealTimes', selectedMultiselectMealTimes);
                  });
                },
                whenEmpty: "Chose meals to show".tr()),
            Divider(
              thickness: 4,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        "Login for sync and share".tr(),
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 34),
                      child: GoogleAuthButton(
                        onPressed: () {
                          _addData();
                        },
                        darkMode: false, // if true second example
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: EmailAuthButton(onPressed: () {
                        _registerWithMail();
                      }),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: EmailAuthButton(
                        onPressed: () {
                          _loginWithMail();
                        },
                        text: "Erneuter Login",
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          _signOut();
                        },
                        icon: Icon(Icons.logout)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
