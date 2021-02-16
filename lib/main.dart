import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mealpy/screens/food_list.dart';
import 'package:mealpy/screens/main_screen.dart';
import 'injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Injection.initInjection();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meal Planer App',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: MainScreen.id,
      routes: {
        MainScreen.id: (context) => MainScreen(),
        FoodList.id: (context) => FoodList(),
      },
    );
  }
}
