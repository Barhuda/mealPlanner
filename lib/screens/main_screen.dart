import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mealpy/meal.dart';
import 'package:mealpy/injection.dart';
import 'package:mealpy/database_helper.dart';
import 'package:mealpy/screens/food_list.dart';
import 'package:mealpy/day_meals.dart';

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
  List<Meal> mealList = [];
  Map<int, Map<String, Meal>> weekMap = {};
  Meal defaultMeal = Meal(
      id: 0,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
            child: Icon(Icons.calendar_today),
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () async {
                weekMap = {};
                weekMap = await Meal().generateWeekList(currentDate);

                //Navigator.of(context).pushNamed(FoodList.id);
                setState(() {});
              },
              child: Icon(Icons.list),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                RaisedButton(
                  child: Text("<"),
                  onPressed: () {
                    subtractWeek();
                  },
                ),
                Text(
                  '${currentDate.day.toString()}.${currentDate.month.toString()}.${currentDate.year.toString()}  -  '
                  '${datePeriod.day.toString()}.${datePeriod.month.toString()}.${datePeriod.year.toString()}',
                ),
                RaisedButton(
                  onPressed: () {
                    addWeek();
                  },
                  child: Text(">"),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: weekMap.length ?? 1,
                itemBuilder: (context, int index) {
                  int key = weekMap.keys.elementAt(index);
                  Map currentMap = weekMap[key];
                  Meal breakfast = currentMap["Breakfast"] ?? defaultMeal;
                  Meal lunch = currentMap["Lunch"] ?? defaultMeal;
                  Meal evening = currentMap["Dinner"] ?? defaultMeal;
                  return Card(
                    color: index % 2 == 0 ? Colors.orange : Colors.orangeAccent,
                    elevation: 6,
                    key: ValueKey(index),
                    margin: EdgeInsets.all(6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                            '${formatter.format(DateTime.fromMillisecondsSinceEpoch(breakfast.date))} ${DateTime.fromMillisecondsSinceEpoch(breakfast.date).day.toString()}.${DateTime.fromMillisecondsSinceEpoch(breakfast.date).month.toString()}.${DateTime.fromMillisecondsSinceEpoch(breakfast.date).year.toString()}',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        Text(breakfast.mealName),
                        Text(lunch.mealName),
                        Text(evening.mealName),
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
                            ).toMapWithoutId());

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
