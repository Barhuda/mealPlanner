import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mealpy/meallist.dart';
import 'package:mealpy/constants.dart' as Constants;
import 'package:mealpy/database_helper.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:mealpy/injection.dart';
import 'package:mealpy/meal.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:url_launcher/url_launcher.dart';

class FoodList extends StatefulWidget {
  FoodList({Key key, this.analytics, this.observer}) : super(key: key);
  static const String id = 'food_list';

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  _FoodListState createState() => _FoodListState();
}

class _FoodListState extends State<FoodList> {
  DatabaseHelper _databaseHelper = Injection.injector.get();
  List<Meallist> meallist = [];
  String mealName;
  String mealNote;
  String mealTime = 'Breakfast';
  String selectedLocalMealTime;
  int mealDate;
  var mealTimeListDropdown = <String>[
    'Breakfast'.tr(),
    'Lunch'.tr(),
    'Dinner'.tr(),
  ];

  TextEditingController dateCtl = TextEditingController(
      text:
          '${DateFormat('EE').format(DateTime.now())} ${DateTime.now().day.toString()}.${DateTime.now().month.toString()}.${DateTime.now().year.toString()}');

  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    asyncMethod().then((value) {
      setState(() {});
    });
    super.initState();
  }

  Future asyncMethod() async {
    meallist = await Meallist().generateMealList();
  }

  Future<void> _sendAnalyticsEvent(ideaName) async {
    await widget.analytics.logEvent(
      name: 'created_Idea',
      parameters: <String, dynamic>{
        'Idea': ideaName,
      },
    );
    print('logEvent succeeded');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Constants.mainColor,
          centerTitle: true,
          title: Text('Idea List 🍽️'.tr()),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            mealName = null;
            mealNote = null;
            mealDate = DateTime.now().millisecondsSinceEpoch;
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Constants.secondaryColor,
                    scrollable: true,
                    title: Text(
                      'Mealplan'.tr(),
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
                                textCapitalization: TextCapitalization.sentences,
                                maxLines: 3,
                                minLines: 2,
                                decoration: InputDecoration(labelText: 'Note'.tr()),
                                textAlign: TextAlign.left,
                                onChanged: (value) {
                                  mealNote = value;
                                },
                              ),
                              TextFormField(
                                keyboardType: TextInputType.name,
                                autofocus: false,
                                controller: textEditingController,
                                decoration: InputDecoration(
                                  labelText: ' Link to recipe ',
                                  hintText: 'Save your recipe here',
                                  prefixIcon: IconButton(
                                    onPressed: () async {
                                      if (textEditingController.text.toString() == null || textEditingController.text.toString() == "") {
                                        print("null data");
                                      } else {
                                        print(textEditingController.text.toString());
                                        if (await canLaunch("https://" + textEditingController.text.toString())) {
                                          await launch("https://" + textEditingController.text.toString());
                                        } else {
                                          throw 'Could not launch ${textEditingController.text.toString()}';
                                        }
                                      }
                                    },
                                    icon: Icon(Icons.open_in_browser),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    actions: <Widget>[
                      TextButton(
                        child: Text(
                          'Cancel'.tr(),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text(
                          'Save'.tr(),
                        ),
                        onPressed: () async {
                          if (mealName != null) {
                            Meallist mealToSave = Meallist(
                              mealName: mealName,
                              note: mealNote ?? "",
                            );
                            _sendAnalyticsEvent(mealName);
                            mealToSave.saveMealtoDB();
                          }

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
          child: Icon(Icons.add),
        ),
        body: Center(
          child: ListView.builder(
              itemCount: meallist.length,
              itemBuilder: (context, int index) {
                Meallist currentMeal = meallist[index];
                return GestureDetector(
                  onTap: () {
                    mealName = null;
                    mealNote = null;

                    var mealNameCtrl = TextEditingController(text: currentMeal.mealName);
                    var mealNoteCtrl = TextEditingController(text: currentMeal.note);
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Constants.secondaryColor,
                            scrollable: false,
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Edit Meal'.tr()),
                                IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () {
                                      currentMeal.deleteMealFromDB();
                                      Navigator.of(context).pop();
                                      asyncMethod().then((value) {
                                        setState(() {});
                                      });
                                    })
                              ],
                            ),
                            content: StatefulBuilder(
                              builder: (BuildContext context, StateSetter setState) {
                                DateTime date = DateTime.now();
                                return Container(
                                  height: 150,
                                  child: Form(
                                    child: Column(
                                      children: [
                                        TextFormField(
                                          controller: mealNameCtrl,
                                          textCapitalization: TextCapitalization.sentences,
                                          decoration: InputDecoration(labelText: 'Meal'.tr()),
                                          textAlign: TextAlign.left,
                                          onChanged: (value) {
                                            mealName = value;
                                          },
                                        ),
                                        TextFormField(
                                          controller: mealNoteCtrl,
                                          textCapitalization: TextCapitalization.sentences,
                                          decoration: InputDecoration(labelText: 'Note'.tr()),
                                          textAlign: TextAlign.left,
                                          onChanged: (value) {
                                            mealNote = value;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            actions: [
                              TextButton(
                                child: Text(
                                  'Cancel'.tr(),
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
                                  'Save'.tr(),
                                ),
                                onPressed: () {
                                  currentMeal.updateMealInDB(mealName, mealNote);
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
                  child: Card(
                    margin: EdgeInsets.all(6),
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  currentMeal.mealName ?? "",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.calendar_today,
                                    color: Constants.fourthColor,
                                  ),
                                  onPressed: () {
                                    mealName = null;
                                    mealNote = null;
                                    DateTime date = DateTime.now();
                                    mealDate = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;

                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor: Constants.secondaryColor,
                                            scrollable: false,
                                            title: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('Plan Meal'.tr()),
                                              ],
                                            ),
                                            content: StatefulBuilder(
                                              builder: (BuildContext context, StateSetter setState) {
                                                return Container(
                                                  height: 150,
                                                  child: Form(
                                                    child: Column(
                                                      children: [
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
                                                          readOnly: true,
                                                          decoration: InputDecoration(labelText: 'Date'.tr()),
                                                          controller: dateCtl,
                                                          onTap: () async {
                                                            FocusScope.of(context).requestFocus(FocusNode());

                                                            date = await showDatePicker(
                                                                context: context,
                                                                initialDate: DateTime.now(),
                                                                firstDate: DateTime(1900),
                                                                lastDate: DateTime(2100));

                                                            dateCtl.text =
                                                                '${DateFormat('EE').format(date)} ${date.day.toString()}.${date.month.toString()}.${date.year.toString()}';
                                                            mealDate = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  'Cancel'.tr(),
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
                                                  'Save'.tr(),
                                                ),
                                                onPressed: () async {
                                                  try {
                                                    await _databaseHelper.db.insert(
                                                      "meals",
                                                      Meal(
                                                        mealName: mealName ?? currentMeal.mealName,
                                                        date: mealDate,
                                                        dayTime: mealTime,
                                                      ).toMapWithoutId(),
                                                    );

                                                    Navigator.of(context).pop();
                                                  } catch (e) {
                                                    Navigator.of(context).pop();
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(SnackBar(content: Text("Duplicate Meal Message").tr()));
                                                  }
                                                },
                                              ),
                                            ],
                                          );
                                        });
                                  },
                                ),
                              )
                            ],
                          ),
                          Text(
                            currentMeal.note ?? "",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
        ));
  }
}
