import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mealpy/meal.dart';
import 'package:mealpy/injection.dart';
import 'package:mealpy/database_helper.dart';
import 'package:mealpy/screens/food_list.dart';

class MainScreen extends StatefulWidget {
  MainScreen({Key key}) : super(key: key);
  static const String id = 'main_screen';

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  DatabaseHelper _databaseHelper = Injection.injector.get();
  DateTime currentDate = DateTime.now();
  DateTime datePeriod = DateTime.now().add(Duration(days: 6));
  String mealTime = 'Breakfast';
  DateTime selectedDate;
  String mealName = '';

  List<Meal> meals = [
    new Meal(
        id: 0,
        mealName: 'TestMeal',
        date: DateTime.now().toIso8601String(),
        dayTime: "Breakfast"),
  ];
  TextEditingController dateCtl = TextEditingController(
      text:
          '${DateFormat('EE').format(DateTime.now())} ${DateTime.now().day.toString()}.${DateTime.now().month.toString()}.${DateTime.now().year.toString()}');

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    DatabaseHelper _databaseHelper = Injection.injector.get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actionsIconTheme: IconThemeData(size: 40),
        title: Text('Test'),
        centerTitle: true,
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
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
            Text(
              '${DateFormat('EE').format(currentDate)} ${currentDate.day.toString()}.${currentDate.month.toString()}.${currentDate.year.toString()}  -  '
              '${DateFormat('EE').format(datePeriod)} ${datePeriod.day.toString()}.${datePeriod.month.toString()}.${datePeriod.year.toString()}',
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: meals.length,
                itemBuilder: (context, int index) {
                  Meal currentMeal = meals[index];
                  return Card(
                    elevation: 6,
                    key: ValueKey(index),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: <Widget>[
                        Text(currentMeal.mealName),
                      ],
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
          print(currentDate);
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
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
                              decoration: InputDecoration(labelText: 'Meal'),
                              textAlign: TextAlign.center,
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
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime(2100));

                                dateCtl.text =
                                    '${DateFormat('EE').format(date)} ${DateTime.now().day.toString()}.${date.month.toString()}.${date.year.toString()}';
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
                                  'Other'
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
                                    dayTime: mealTime,
                                    date: dateCtl.text)
                                .toMapWithoutId());

                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              });
        },
        child: Icon(Icons.schedule),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
