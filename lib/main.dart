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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Injection.initInjection();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp();
  runApp(EasyLocalization(
    useOnlyLangCode: true,
    supportedLocales: [Locale('en'), Locale('de')],
    path: 'assets/translations',
    fallbackLocale: Locale('en'),
    child: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  static FirebaseAnalytics analytics = FirebaseAnalytics();
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);
  static FirebaseDatabase database = FirebaseDatabase.instance;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    _getFireBaseStream();
    super.initState();
  }

  _getFireBaseStream() {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    _auth.authStateChanges().listen((User user) {
      if (user == null) {
        print('User is currently signed out!');
        print(user.uid);
      } else {
        print('User is signed in!');
      }
    });
  }

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
      navigatorObservers: [MyApp.observer],
      routes: {
        MainScreen.id: (context) =>
            MainScreen(analytics: MyApp.analytics, observer: MyApp.observer),
        FoodList.id: (context) =>
            FoodList(analytics: MyApp.analytics, observer: MyApp.observer),
        CategoryScreen.id: (context) => CategoryScreen(
            analytics: MyApp.analytics, observer: MyApp.observer),
        SettingsScreen.id: (context) => SettingsScreen(
            analytics: MyApp.analytics, observer: MyApp.observer),
      },
    );
  }
}
