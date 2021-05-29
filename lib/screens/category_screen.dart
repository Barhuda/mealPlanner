import 'package:flutter/material.dart';
import 'package:mealpy/category.dart';
import 'package:mealpy/constants.dart' as Constants;
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:mealpy/buttons/buttonStyles.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class CategoryScreen extends StatefulWidget {
  CategoryScreen({Key key, this.analytics, this.observer}) : super(key: key);

  static const String id = 'category_screen';

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Category> categoryList = [];

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
                    return Container(
                      child: Form(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            TextFormField(
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(labelText: 'Category Name'.tr()),
                              textAlign: TextAlign.left,
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
                      },
                      style: cancelButtonStyle,
                    ),
                    ElevatedButton(
                      child: Text(
                        "Save",
                      ).tr(),
                      onPressed: () {},
                      style: saveButtonStyle,
                    ),
                  ],
                );
              });
        },
        child: Icon(Icons.add),
      ),
      body: ListView.builder(
          itemCount: categoryList.length,
          itemBuilder: (context, int index) {
            return Container(
              child: Text("Test"),
            );
          }),
    );
  }
}
