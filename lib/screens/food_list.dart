import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mealpy/category.dart';
import 'package:mealpy/main.dart';
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
import 'package:mealpy/screens/category_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mealpy/buttons/buttonStyles.dart';
import 'package:clipboard/clipboard.dart';
import 'package:mealpy/category.dart';
import 'package:group_button/group_button.dart';
import 'package:get/get.dart' hide Trans;

class FoodList extends StatefulWidget {
  FoodList({Key? key, this.analytics, this.observer}) : super(key: key);
  static const String id = 'food_list';

  final FirebaseAnalytics? analytics;
  final FirebaseAnalyticsObserver? observer;

  @override
  _FoodListState createState() => _FoodListState();
}

class _FoodListState extends State<FoodList> {
  DatabaseHelper _databaseHelper = Injection.injector.get();
  List<Meallist> meallist = [];
  List<Category> categoryList = [];
  // List<CategoryPickerItem> categoryPickerItems = [];
  String? mealName;
  String? mealNote;
  String? mealTime = 'Breakfast';
  String? selectedLocalMealTime;
  int? mealDate;

  List<String>? selectedMealTimes = [];

  //TODO: ADD Snack to Dropdown
  var mealTimeListDropdown = <String>[
    'Breakfast'.tr(),
    'Lunch'.tr(),
    'Dinner'.tr(),
    'Snack'.tr()
  ];
  late SharedPreferences prefs;
  bool sortAlphabetical = false;

  int? selectedCategoryFilterID;
  int filterID = 0;

  var categoryDropDownItems = <DropdownMenuItem>[];

  int? selectedCategoryID;

  TextEditingController categoryCtrl = TextEditingController();
  TextEditingController categoryDropdownCtrl = TextEditingController();

  TextEditingController dateCtl = TextEditingController(
      text:
          '${DateFormat('EE').format(DateTime.now())} ${DateTime.now().day.toString()}.${DateTime.now().month.toString()}.${DateTime.now().year.toString()}');
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // categoryPickerItems = Category().catPickerItems();
    categoryDropDownItems = Category().createDropdownMenuItems();

    selectedCategoryID = -1;
    selectedCategoryFilterID = 0;
    firstLoad().then((value) {
      setState(() {});
    });
  }

  Future firstLoad() async {
    meallist = await Meallist().generateMealList(-1);
    prefs = await SharedPreferences.getInstance();
    sortAlphabetical = prefs.getBool('sort') ?? false;
    selectedMealTimes = prefs.getStringList('mealTimes');
    print("SelectedMealTimes =" + selectedMealTimes.toString());
    if (sortAlphabetical) {
      meallist.sort((a, b) =>
          a.mealName!.toLowerCase().compareTo(b.mealName!.toLowerCase()));
    }
    categoryList = await Category().generateCategoryList();
  }

  Future asyncMethod(int? categoryID) async {
    // categoryPickerItems = Category().catPickerItems();
    categoryDropDownItems = Category().createDropdownMenuItems();
    meallist = await Meallist().generateMealList(categoryID);
    if (sortAlphabetical) {
      meallist.sort((a, b) =>
          a.mealName!.toLowerCase().compareTo(b.mealName!.toLowerCase()));
    }
    print("Meallist länge: " + meallist.length.toString());
    categoryList = await Category().generateCategoryList();
  }

  Future<void> _sendAnalyticsEvent(ideaName) async {
    await widget.analytics!.logEvent(
      name: 'created_Idea',
      parameters: <String, dynamic>{
        'Idea': ideaName,
      },
    );
    print('logEvent succeeded');
  }

  int? saveCategoryId() {
    if (selectedCategoryID == -1 || selectedCategoryID == null) {
      return null;
    } else {
      return selectedCategoryID;
    }
  }

  _changeScene(int index) {
    Get.offAllNamed(Constants.bottomNavigationRoutes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Constants.mainColor,
          centerTitle: true,
          title: Text('Idea List 🍽️'.tr()),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 30),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context)
                      .pushNamed(CategoryScreen.id)
                      .whenComplete(() {
                    asyncMethod(0).then((value) {
                      setState(() {});
                      selectedCategoryID = -1;
                      print(categoryDropDownItems.length);
                    });
                  });
                },
                child: Icon(
                  Icons.label,
                  size: 30,
                ),
              ),
            ),
          ],
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
          currentIndex: 3,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            mealName = null;
            mealNote = null;
            mealDate = DateTime.now().millisecondsSinceEpoch;
            textEditingController.clear();
            selectedCategoryID = -2;
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(32.0))),
                    backgroundColor: Constants.secondaryColor,
                    scrollable: true,
                    title: Text(
                      'Mealplan'.tr(),
                      textAlign: TextAlign.center,
                    ),
                    content: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                      return Container(
                        child: Form(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              TextFormField(
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration:
                                    InputDecoration(labelText: 'Meal'.tr()),
                                textAlign: TextAlign.left,
                                onChanged: (value) {
                                  mealName = value;
                                },
                              ),
                              Container(
                                child: DropdownButton(
                                  items: categoryDropDownItems,
                                  onChanged: (dynamic newVal) => setState(
                                      () => selectedCategoryID = newVal),
                                  value: selectedCategoryID,
                                  isExpanded: true,
                                  hint: Text("Choose category").tr(),
                                ),
                              ),
                              TextFormField(
                                textCapitalization:
                                    TextCapitalization.sentences,
                                maxLines: 3,
                                minLines: 2,
                                decoration:
                                    InputDecoration(labelText: 'Note'.tr()),
                                textAlign: TextAlign.left,
                                onChanged: (value) {
                                  mealNote = value;
                                },
                              ),
                              TextFormField(
                                keyboardType: TextInputType.url,
                                autofocus: false,
                                controller: textEditingController,
                                decoration: InputDecoration(
                                  labelText: 'Link to recipe'.tr(),
                                  prefixIcon: IconButton(
                                    onPressed: () async {
                                      if (textEditingController.text
                                                  .toString() ==
                                              null ||
                                          textEditingController.text
                                                  .toString() ==
                                              "") {
                                        print("null data");
                                      } else {
                                        print(textEditingController.text
                                            .toString());
                                        if (await canLaunch("https://" +
                                            textEditingController.text
                                                .toString())) {
                                          await launch("https://" +
                                              textEditingController.text
                                                  .toString());
                                        } else {
                                          throw 'Could not launch ${textEditingController.text.toString()}';
                                        }
                                      }
                                    },
                                    icon: Icon(Icons.open_in_browser),
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  FlutterClipboard.paste().then((value) {
                                    setState(() {
                                      textEditingController.text = value;
                                    });
                                  });
                                },
                                child: Text("Copy from Clipboard").tr(),
                                style: recipeButtonStyle,
                              )
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
                      ElevatedButton(
                        child: Text(
                          "Save",
                        ).tr(),
                        onPressed: () async {
                          if (mealName != null) {
                            Meallist mealToSave = Meallist(
                                mealName: mealName,
                                note: mealNote ?? "",
                                recipe: textEditingController.text.toString(),
                                categoryId: saveCategoryId());
                            _sendAnalyticsEvent(mealName);

                            textEditingController.clear();
                            mealToSave.saveMealtoDB();
                          }

                          Navigator.of(context).pop();
                          selectedCategoryFilterID = -1;
                          filterID = 0;
                          asyncMethod(selectedCategoryFilterID).then((value) {
                            setState(() {});
                          });
                        },
                        style: saveButtonStyle,
                      ),
                    ],
                  );
                });
          },
          child: Icon(Icons.add),
        ),
        body: Center(
          child: Column(
            children: [
              GroupButton(
                isRadio: true,
                controller: GroupButtonController(selectedIndex: filterID),
                options: GroupButtonOptions(
                    alignment: AlignmentDirectional.center,
                    direction: Axis.horizontal,
                    spacing: 10,
                    borderRadius: BorderRadius.all(Radius.circular(48)),
                    selectedColor: Constants.fourthColor),
                onSelected: (index, isSelected) {
                  print(categoryList[index].categoryName);
                  print("ID ist:::: " + categoryList[index].id.toString());
                  selectedCategoryFilterID = categoryList[index].id;
                  filterID = index;
                  asyncMethod(selectedCategoryFilterID).then((value) {
                    setState(() {});
                  });
                },
                buttons: List.generate(categoryList.length,
                    (index) => categoryList[index].categoryName!),
              ),
              Expanded(
                child: ListView.builder(
                    itemCount: meallist.length,
                    itemBuilder: (context, int index) {
                      Meallist currentMeal = meallist[index];
                      return GestureDetector(
                        onTap: () {
                          mealName = null;
                          mealNote = null;
                          selectedCategoryID = -2;
                          textEditingController.text = currentMeal.recipe ?? "";
                          var mealNameCtrl =
                              TextEditingController(text: currentMeal.mealName);
                          var mealNoteCtrl =
                              TextEditingController(text: currentMeal.note);
                          // categoryDropDownItems =
                          //     Category().createDropdownMenuItems();
                          selectedCategoryID = currentMeal.categoryId ?? -2;
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(20.0))),
                                  backgroundColor: Constants.secondaryColor,
                                  scrollable: true,
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Edit Meal'.tr()),
                                      IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            currentMeal.deleteMealFromDB();
                                            Navigator.of(context).pop();
                                            asyncMethod(
                                                    selectedCategoryFilterID)
                                                .then((value) {
                                              setState(() {});
                                            });
                                          })
                                    ],
                                  ),
                                  content: StatefulBuilder(
                                    builder: (BuildContext context,
                                        StateSetter setState) {
                                      DateTime date = DateTime.now();
                                      return Container(
                                        height: 350,
                                        child: Form(
                                          child: Column(
                                            children: [
                                              TextFormField(
                                                controller: mealNameCtrl,
                                                textCapitalization:
                                                    TextCapitalization
                                                        .sentences,
                                                decoration: InputDecoration(
                                                    labelText: 'Meal'.tr()),
                                                textAlign: TextAlign.left,
                                                onChanged: (value) {
                                                  mealName = value;
                                                },
                                              ),
                                              Container(
                                                child: DropdownButton(
                                                  items: categoryDropDownItems,
                                                  onChanged: (dynamic newVal) =>
                                                      setState(() =>
                                                          selectedCategoryID =
                                                              newVal),
                                                  value: selectedCategoryID,
                                                  isExpanded: true,
                                                  hint: Text("Choose category")
                                                      .tr(),
                                                ),
                                              ),
                                              TextFormField(
                                                maxLines: 3,
                                                minLines: 1,
                                                controller: mealNoteCtrl,
                                                textCapitalization:
                                                    TextCapitalization
                                                        .sentences,
                                                decoration: InputDecoration(
                                                    labelText: 'Note'.tr()),
                                                textAlign: TextAlign.left,
                                                onChanged: (value) {
                                                  mealNote = value;
                                                },
                                              ),
                                              TextFormField(
                                                keyboardType: TextInputType.url,
                                                autofocus: false,
                                                controller:
                                                    textEditingController,
                                                decoration: InputDecoration(
                                                  labelText:
                                                      "Link to recipe".tr(),
                                                  prefixIcon: IconButton(
                                                    onPressed: () async {
                                                      if (textEditingController
                                                                  .text
                                                                  .toString() ==
                                                              null ||
                                                          textEditingController
                                                                  .text
                                                                  .toString() ==
                                                              "") {
                                                      } else {
                                                        if (await canLaunch(
                                                            textEditingController
                                                                .text
                                                                .toString())) {
                                                          await launch(
                                                              textEditingController
                                                                  .text
                                                                  .toString());
                                                        } else {
                                                          throw 'Could not launch ${textEditingController.text.toString()}';
                                                        }
                                                      }
                                                    },
                                                    icon: Icon(
                                                        Icons.open_in_browser),
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  FlutterClipboard.paste()
                                                      .then((value) {
                                                    setState(() {
                                                      textEditingController
                                                          .text = value;
                                                    });
                                                  });
                                                },
                                                child:
                                                    Text("Copy from Clipboard")
                                                        .tr(),
                                                style: recipeButtonStyle,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      child: Text(
                                        "Cancel",
                                        style: TextStyle(color: Colors.blue),
                                      ).tr(),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        asyncMethod(selectedCategoryFilterID)
                                            .then((value) {
                                          setState(() {});
                                        });
                                      },
                                      style: cancelButtonStyle,
                                    ),
                                    ElevatedButton(
                                      child: Text("Save").tr(),
                                      onPressed: () {
                                        currentMeal.updateMealInDB(
                                            mealName,
                                            mealNote,
                                            textEditingController.text,
                                            saveCategoryId());

                                        Navigator.of(context).pop();
                                        selectedCategoryFilterID = -1;
                                        filterID = 0;
                                        asyncMethod(selectedCategoryFilterID)
                                            .then((value) {
                                          setState(() {});
                                        });
                                      },
                                      style: saveButtonStyle,
                                    ),
                                  ],
                                );
                              });
                        },
                        child: Card(
                          margin: EdgeInsets.all(6),
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        currentMeal.mealName ?? "",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold),
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
                                          mealDate = DateTime(date.year,
                                                  date.month, date.day)
                                              .millisecondsSinceEpoch;

                                          showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  20.0))),
                                                  backgroundColor:
                                                      Constants.secondaryColor,
                                                  scrollable: true,
                                                  title: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text('Plan Meal'.tr()),
                                                    ],
                                                  ),
                                                  content: StatefulBuilder(
                                                    builder: (BuildContext
                                                            context,
                                                        StateSetter setState) {
                                                      return Container(
                                                        height: 150,
                                                        child: Form(
                                                          child: Column(
                                                            children: [
                                                              Container(
                                                                alignment: Alignment
                                                                    .centerLeft,
                                                                child:
                                                                    DropdownButton(
                                                                  value: selectedLocalMealTime ??
                                                                      selectedMealTimes![
                                                                          0],
                                                                  icon: Icon(Icons
                                                                      .local_dining),
                                                                  elevation: 16,
                                                                  onChanged:
                                                                      (String?
                                                                          newValue) {
                                                                    setState(
                                                                        () {
                                                                      mealTime =
                                                                          newValue;
                                                                      selectedLocalMealTime =
                                                                          mealTime;
                                                                    });
                                                                  },
                                                                  items: selectedMealTimes!.map<
                                                                      DropdownMenuItem<
                                                                          String>>(
                                                                    (String
                                                                        value) {
                                                                      return DropdownMenuItem<
                                                                          String>(
                                                                        value:
                                                                            value,
                                                                        child: Text(
                                                                            value.tr()),
                                                                      );
                                                                    },
                                                                  ).toList(),
                                                                ),
                                                              ),
                                                              TextFormField(
                                                                readOnly: true,
                                                                decoration:
                                                                    InputDecoration(
                                                                        labelText:
                                                                            'Date'.tr()),
                                                                controller:
                                                                    dateCtl,
                                                                onTap:
                                                                    () async {
                                                                  FocusScope.of(
                                                                          context)
                                                                      .requestFocus(
                                                                          FocusNode());

                                                                  date = await showDatePicker(
                                                                          context:
                                                                              context,
                                                                          initialDate: DateTime
                                                                              .now(),
                                                                          firstDate: DateTime(
                                                                              1900),
                                                                          lastDate: DateTime(
                                                                              2100)) ??
                                                                      DateTime
                                                                          .now();

                                                                  dateCtl.text =
                                                                      '${DateFormat('EE').format(date)} ${date.day.toString()}.${date.month.toString()}.${date.year.toString()}';
                                                                  mealDate = DateTime(
                                                                          date.year,
                                                                          date.month,
                                                                          date.day)
                                                                      .millisecondsSinceEpoch;
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  actions: [
                                                    ElevatedButton(
                                                      child: Text(
                                                        "Cancel",
                                                        style: TextStyle(
                                                            color: Colors.blue),
                                                      ).tr(),
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                        asyncMethod(
                                                                selectedCategoryFilterID)
                                                            .then((value) {
                                                          setState(() {});
                                                        });
                                                      },
                                                      style: cancelButtonStyle,
                                                    ),
                                                    ElevatedButton(
                                                      child: Text(
                                                        "Save",
                                                      ).tr(),
                                                      onPressed: () async {
                                                        try {
                                                          if (myUser
                                                              .isLoggedIn) {
                                                            Meal(
                                                                    mealName: mealName ??
                                                                        currentMeal
                                                                            .mealName,
                                                                    dayTime:
                                                                        mealTime,
                                                                    date: date
                                                                        .millisecondsSinceEpoch,
                                                                    recipe: currentMeal
                                                                        .recipe)
                                                                .saveMealToFirebase(
                                                                    myUser
                                                                        .selectedMealPlan!);
                                                            print(
                                                                "save to Firebase");
                                                          } else {
                                                            Meal().saveMeal(
                                                                mealName ??
                                                                    currentMeal
                                                                        .mealName,
                                                                DateTime(
                                                                    date.year,
                                                                    date.month,
                                                                    date.day),
                                                                mealTime,
                                                                currentMeal
                                                                    .recipe);
                                                          }

                                                          Navigator.of(context)
                                                              .pop();
                                                        } catch (e) {
                                                          print(mealTime);
                                                          Navigator.of(context)
                                                              .pop();
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(SnackBar(
                                                                  content: Text(
                                                                          "Duplicate Meal Message")
                                                                      .tr()));
                                                        }
                                                      },
                                                      style: saveButtonStyle,
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
              ),
              SizedBox(
                height: 75,
              ),
            ],
          ),
        ));
  }
}
