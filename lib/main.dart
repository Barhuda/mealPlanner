import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mealpy/screens/category_screen.dart';
import 'package:mealpy/screens/food_list.dart';
import 'package:mealpy/screens/main_screen.dart';
import 'package:mealpy/screens/profile_screen.dart';
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
import 'my_user.dart';
import 'firebasertdb.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

MyUser myUser = MyUser();
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
    _setPremium();
    _getSharedPrefs();
    _handleDeepLink();
    _handleDeepLinkStream();
    super.initState();
  }

  _setPremium() {
    myUser.setPremium();
  }

  _getSharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> selectedMultiselectMealTimes =
        prefs.getStringList('mealTimes');
    if (selectedMultiselectMealTimes == null) {
      prefs.setStringList(
          "mealTimes", ["Breakfast", "Lunch", "Dinner", "Snack"]);
    }
  }

  Future<void> _getFireBaseStream() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    _auth.authStateChanges().listen((User user) async {
      if (user == null) {
        myUser.userLoggedOut();
        print('User is currently signed out!');
      } else {
        myUser.userLoggedIn(user.uid);
        _getUsersDB(user);
        String hisName = await FirebaseRTDB.getUserName(user.uid);
        myUser.setUsername(hisName);
      }
    });
  }

  _handleDeepLink() async {
    final PendingDynamicLinkData initialLink =
        await FirebaseDynamicLinks.instance.getInitialLink();
    if (initialLink != null) {
      final Uri deepLink = initialLink.link;

      print("test Deep Link");
      print(deepLink.queryParameters['data']);
      // Example of using the dynamic link to push the user to a different screen
      Get.offAndToNamed("/profile");
    }
  }

  _handleDeepLinkStream() {
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) async {
      await Future.delayed(Duration(seconds: 1));
      String dbUID = dynamicLinkData.link.queryParameters['uid'];
      print(dbUID);
      Get.offAllNamed("/profile", arguments: [dbUID]);
    }).onError((error) {
      print(error);
    });
  }

  Future<void> _getUsersDB(User user) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("Users/${user.uid}");

    DatabaseEvent event = await ref.once();

    if (event.snapshot.value == null) {
      _createNewUserInDB(user, ref);
      _getAvailableDbs(user, ref);
    } else {
      await _getAvailableDbs(user, ref);
    }
  }

  _getAvailableDbs(User user, DatabaseReference ref) async {
    List<String> allowedDbs = [];
    DatabaseEvent event = await ref.child("allowedDbs").once();
    Map<dynamic, dynamic> decoded = event.snapshot.value;
    decoded.forEach((key, value) {
      allowedDbs.add(key);
    });
    myUser.setAllowedDbs(allowedDbs);

    // myUser.setAllowedDbs(event.snapshot.value);
  }

  _createNewUserInDB(User user, DatabaseReference ref) async {
    String userUid = user.uid;
    await ref.parent.update({
      userUid: {
        "name": user.email ?? "User",
        "allowedDbs": {userUid: true}
      }
    });

    await ref.root.child("mealDbs").update({
      userUid: {
        "name": "My Plan",
        "weekdays": {},
        "allowedUsers": {"${user.uid}": true}
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
      initialBinding: BindingsBuilder(() {
        Get.put(myUser);
      }),
      getPages: [
        GetPage(
            transition: Transition.noTransition,
            name: "/",
            page: () => MainScreen(
                analytics: MyApp.analytics, observer: MyApp.observer)),
        GetPage(
            transition: Transition.noTransition,
            name: "/idea",
            page: () =>
                FoodList(analytics: MyApp.analytics, observer: MyApp.observer)),
        GetPage(
            transition: Transition.noTransition,
            name: "/settings",
            page: () => SettingsScreen(
                analytics: MyApp.analytics, observer: MyApp.observer)),
        GetPage(
            transition: Transition.noTransition,
            name: "/category",
            page: () => CategoryScreen(
                analytics: MyApp.analytics, observer: MyApp.observer)),
        GetPage(
            transition: Transition.noTransition,
            name: "/profile",
            page: () => ProfileScreen(
                analytics: MyApp.analytics, observer: MyApp.observer))
      ],
      routes: {
        MainScreen.id: (context) =>
            MainScreen(analytics: MyApp.analytics, observer: MyApp.observer),
        FoodList.id: (context) =>
            FoodList(analytics: MyApp.analytics, observer: MyApp.observer),
        CategoryScreen.id: (context) => CategoryScreen(
            analytics: MyApp.analytics, observer: MyApp.observer),
        SettingsScreen.id: (context) => SettingsScreen(
            analytics: MyApp.analytics, observer: MyApp.observer),
        ProfileScreen.id: (context) =>
            ProfileScreen(analytics: MyApp.analytics, observer: MyApp.observer),
      },
    );
  }
}
