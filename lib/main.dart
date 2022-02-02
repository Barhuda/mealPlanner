import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mealpy/screens/category_screen.dart';
import 'package:mealpy/screens/food_list.dart';
import 'package:mealpy/screens/main_screen.dart';
import 'package:mealpy/screens/settings_screen.dart';
import 'injection.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart' hide Trans;
import 'package:mealpy/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setUser();
  await Injection.initInjection();
  await EasyLocalization.ensureInitialized();
  runApp(EasyLocalization(
    useOnlyLangCode: true,
    supportedLocales: [Locale('en'), Locale('de')],
    path: 'assets/translations',
    fallbackLocale: Locale('en'),
    child: MyApp(),
  ));
}

_setUser() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String userID = prefs.getString('user');
  if (userID != null) {
    FirebaseDatabase.instance.ref("Users/$userID");
  }
}

class MyApp extends StatelessWidget {
  static FirebaseAnalytics analytics = FirebaseAnalytics();
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);
  static FirebaseDatabase database = FirebaseDatabase.instance;
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Meal Planer App',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: MainScreen.id,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      navigatorObservers: [observer],
      routes: {
        MainScreen.id: (context) =>
            MainScreen(analytics: analytics, observer: observer),
        FoodList.id: (context) =>
            FoodList(analytics: analytics, observer: observer),
        CategoryScreen.id: (context) =>
            CategoryScreen(analytics: analytics, observer: observer),
        SettingsScreen.id: (context) =>
            SettingsScreen(analytics: analytics, observer: observer),
      },
    );
  }
}
