import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({Key key, this.analytics, this.observer}) : super(key: key);

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

  int selectedValue = 0;

  @override
  void initState() {
    super.initState();

    _getSharedPrefs();
    _generateWeekDayList();
  }

  _getSharedPrefs() async {
    prefs = await SharedPreferences.getInstance();
    selectedWeekDayAsFirstDay = prefs.getInt('selectedWeekDay') ?? 0;
    sortAlphabetical = prefs.getBool('sort') ?? false;
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
                  });
                })
          ],
        ),
      ),
    );
  }
}
