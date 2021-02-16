import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class FoodList extends StatefulWidget {
  FoodList({Key key}) : super(key: key);
  static const String id = 'food_list';
  @override
  _FoodListState createState() => _FoodListState();
}

class _FoodListState extends State<FoodList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Mahlzeit Liste'),
      ),
      body: Center(
        child: ListView.builder(itemBuilder: (context, int index) {}),
      ),
    );
  }
}
