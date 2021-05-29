import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mealpy/category.dart';
import 'package:mealpy/constants.dart' as Constants;
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:mealpy/buttons/buttonStyles.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mealpy/database_helper.dart';
import 'package:mealpy/injection.dart';
import 'package:mealpy/meallist.dart';

class CategoryScreen extends StatefulWidget {
  CategoryScreen({Key key, this.analytics, this.observer}) : super(key: key);

  static const String id = 'category_screen';

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  DatabaseHelper _databaseHelper = Injection.injector.get();
  List<Category> categoryList = [];
  Color currentColor = Colors.blue;
  void changeColor(Color color) => setState(() => currentColor = color);

  TextEditingController categoryTxtCtrl = TextEditingController();

  StateSetter _setState;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    updateList().then((value) {
      setState(() {});
    });
    super.initState();
  }

  Future updateList() async {
    categoryList = await Category().generateCategoryList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Constants.mainColor,
        centerTitle: true,
        title: Text('Category'.tr()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          categoryTxtCtrl.clear();
          currentColor = Colors.blue;
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(32.0))),
                  backgroundColor: Constants.secondaryColor,
                  scrollable: true,
                  title: Text(
                    'Category'.tr(),
                    textAlign: TextAlign.center,
                  ),
                  content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                    _setState = setState;
                    return Container(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            TextFormField(
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(labelText: 'Category Name'.tr()),
                              textAlign: TextAlign.left,
                              controller: categoryTxtCtrl,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please add a name".tr();
                                }
                                return null;
                              },
                            ),
                            SizedBox(
                              height: 40,
                            ),
                            GestureDetector(
                              child: Container(
                                width: 280,
                                height: 40,
                                decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(32.0)), color: currentColor),
                              ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      titlePadding: const EdgeInsets.all(0.0),
                                      contentPadding: const EdgeInsets.all(0.0),
                                      content: SingleChildScrollView(
                                        child: ColorPicker(
                                          pickerColor: currentColor,
                                          onColorChanged: changeColor,
                                          colorPickerWidth: 300.0,
                                          pickerAreaHeightPercent: 0.7,
                                          enableAlpha: true,
                                          displayThumbColor: true,
                                          showLabel: true,
                                          paletteType: PaletteType.hsl,
                                          pickerAreaBorderRadius: const BorderRadius.only(
                                            topLeft: const Radius.circular(2.0),
                                            topRight: const Radius.circular(2.0),
                                          ),
                                        ),
                                      ),
                                      actions: [
                                        ElevatedButton(
                                          child: Text(
                                            "Save",
                                          ).tr(),
                                          onPressed: () {
                                            print(currentColor);
                                            Navigator.of(context).pop();
                                            _setState(() {
                                              updateList();
                                            });
                                          },
                                          style: saveButtonStyle,
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
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
                        if (_formKey.currentState.validate()) {
                          try {
                            await _databaseHelper.db.insert(
                              "category",
                              Category(
                                categoryName: categoryTxtCtrl.text.toString(),
                                colorValue: currentColor.toString(),
                              ).toMapWithoutId(),
                            );
                            Navigator.of(context).pop();
                            updateList().then((value) {
                              setState(() {});
                            });
                          } catch (e) {
                            Navigator.of(context).pop();
                            print(e);
                          }
                        }
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
            Expanded(
              child: ListView.builder(
                  itemCount: categoryList.length,
                  itemBuilder: (context, int index) {
                    Category currentCategory = categoryList[index];
                    String valueString = currentCategory.colorValue.split('(0x')[1].split(')')[0]; // kind of hacky..
                    int value = int.parse(valueString, radix: 16);
                    Color currentCategoryColor = new Color(value);
                    return Center(
                      child: GestureDetector(
                        child: Card(
                            color: Colors.white,
                            margin: EdgeInsets.all(6),
                            elevation: 6,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 10),
                                          child: Container(
                                              height: 45,
                                              width: 45,
                                              decoration:
                                                  BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(32.0)), color: currentCategoryColor)),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          currentCategory.categoryName,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )),
                        onTap: () {
                          categoryTxtCtrl.text = currentCategory.categoryName;
                          currentColor = currentCategoryColor;
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(32.0))),
                                  backgroundColor: Constants.secondaryColor,
                                  scrollable: true,
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Category'.tr(),
                                        textAlign: TextAlign.center,
                                      ),
                                      IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            currentCategory.deleteFromDB();
                                            Meallist().deleteCategoryId(currentCategory.id);
                                            Navigator.of(context).pop();
                                            updateList().then((value) {
                                              setState(() {});
                                            });
                                          })
                                    ],
                                  ),
                                  content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                                    _setState = setState;
                                    return Container(
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: <Widget>[
                                            TextFormField(
                                              textCapitalization: TextCapitalization.sentences,
                                              decoration: InputDecoration(labelText: 'Category Name'.tr()),
                                              textAlign: TextAlign.left,
                                              controller: categoryTxtCtrl,
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return "Please add a name".tr();
                                                }
                                                return null;
                                              },
                                            ),
                                            SizedBox(
                                              height: 40,
                                            ),
                                            GestureDetector(
                                              child: Container(
                                                width: 280,
                                                height: 40,
                                                decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(32.0)), color: currentColor),
                                              ),
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return AlertDialog(
                                                      titlePadding: const EdgeInsets.all(0.0),
                                                      contentPadding: const EdgeInsets.all(0.0),
                                                      content: SingleChildScrollView(
                                                        child: ColorPicker(
                                                          pickerColor: currentColor,
                                                          onColorChanged: changeColor,
                                                          colorPickerWidth: 300.0,
                                                          pickerAreaHeightPercent: 0.7,
                                                          enableAlpha: true,
                                                          displayThumbColor: true,
                                                          showLabel: true,
                                                          paletteType: PaletteType.hsl,
                                                          pickerAreaBorderRadius: const BorderRadius.only(
                                                            topLeft: const Radius.circular(2.0),
                                                            topRight: const Radius.circular(2.0),
                                                          ),
                                                        ),
                                                      ),
                                                      actions: [
                                                        ElevatedButton(
                                                          child: Text(
                                                            "Save",
                                                          ).tr(),
                                                          onPressed: () {
                                                            print(currentColor);
                                                            Navigator.of(context).pop();
                                                            _setState(() {
                                                              updateList();
                                                            });
                                                          },
                                                          style: saveButtonStyle,
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
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
                                        if (_formKey.currentState.validate()) {
                                          try {
                                            currentCategory.updateInDB(categoryTxtCtrl.text, currentColor.toString());
                                            Navigator.of(context).pop();
                                            updateList().then((value) {
                                              setState(() {});
                                            });
                                          } catch (e) {
                                            Navigator.of(context).pop();
                                            print(e);
                                          }
                                        }
                                      },
                                      style: saveButtonStyle,
                                    ),
                                  ],
                                );
                              });
                        },
                      ),
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
