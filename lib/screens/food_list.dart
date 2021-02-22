import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mealpy/meallist.dart';
import 'package:mealpy/constants.dart' as Constants;
import 'package:mealpy/database_helper.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:mealpy/injection.dart';

class FoodList extends StatefulWidget {
  FoodList({Key key}) : super(key: key);
  static const String id = 'food_list';
  @override
  _FoodListState createState() => _FoodListState();
}

class _FoodListState extends State<FoodList> {
  DatabaseHelper _databaseHelper = Injection.injector.get();
  List<Meallist> meallist = [];
  String mealName;
  String mealNote;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Idea List'),
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
                                decoration: InputDecoration(labelText: 'Meal'),
                                textAlign: TextAlign.left,
                                onChanged: (value) {
                                  mealName = value;
                                },
                              ),
                              TextFormField(
                                decoration: InputDecoration(labelText: 'Note'),
                                textAlign: TextAlign.left,
                                onChanged: (value) {
                                  mealNote = value;
                                },
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
                            "meallist",
                            Meallist(
                              mealName: mealName,
                              note: mealNote,
                            ).toMapWithoutId(),
                          );

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
                return Card(
                  child: Column(
                    children: [Text(currentMeal.mealName)],
                  ),
                );
              }),
        ));
  }
}
