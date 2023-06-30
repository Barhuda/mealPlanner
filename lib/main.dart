import 'dart:async';
import 'dart:convert';
import 'firebase_options.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

MyUser myUser = MyUser();
late SharedPreferences prefs;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Injection.initInjection();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  prefs = await SharedPreferences.getInstance();
  runApp(EasyLocalization(
    useOnlyLangCode: true,
    supportedLocales: [Locale('en'), Locale('de')],
    path: 'assets/translations',
    fallbackLocale: Locale('en'),
    child: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);
  static FirebaseDatabase database =
      FirebaseDatabase.instance;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// The In App Purchase plugin
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  @override
  void initState() {
    _getFireBaseStream();
    _getPurchaseStream();
    // _setPremium();
    _getSharedPrefs();
    _handleDeepLink();
    _handleDeepLinkStream();
    super.initState();
  }

  _getPurchaseStream() async {
    final Stream purchaseUpdated = InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      print(error);
    }) as StreamSubscription<List<PurchaseDetails>>;
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        print("Purchase Loading");
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          print(purchaseDetails.error);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          print("Gekauft!");
          myUser.setPremium();
          prefs.setBool("premium", true);
          setState(() {});
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchaseDetails);
        }
      }
    });
  }

  _getPastPurchases() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      InAppPurchaseAndroidPlatformAddition androidAddition = InAppPurchase
          .instance
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

      QueryPurchaseDetailsResponse response =
          await androidAddition.queryPastPurchases();
      if (response.pastPurchases.isNotEmpty) {
        int? purchaseIndex = response.pastPurchases
            .indexWhere((item) => item.productID == "premium");

        if (purchaseIndex >= 0) {
          print("Der hat das schon gekauft");
          myUser.setPremium();
          prefs.setBool("premium", true);
        }
      }
    }
  }

  _setPremium() {
    myUser.setPremium();
  }

  _getSharedPrefs() async {
    List<String>? selectedMultiselectMealTimes =
        prefs.getStringList('mealTimes');
    if (selectedMultiselectMealTimes == null) {
      prefs.setStringList(
          "mealTimes", ["Breakfast", "Lunch", "Dinner", "Snack"]);
    }
    bool userPremium = await prefs.getBool("premium") ?? false;
    if (userPremium) {
      myUser.setPremium();
    } else {
      _getPastPurchases();
    }
  }

  Future<void> _getFireBaseStream() async {
    final FirebaseAuth _auth =
        FirebaseAuth.instance;
    _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        myUser.userLoggedOut();
        print('User is currently signed out!');
        setState(() {});
      } else {
        myUser.userLoggedIn(user.uid);
        _getUsersDB(user);
        String? hisName = await FirebaseRTDB.getUserName(user.uid);
        myUser.setUsername(hisName);
        setState(() {});
      }
    });
  }

  _handleDeepLink() async {
    final PendingDynamicLinkData? initialLink =
        await FirebaseDynamicLinks.instance.getInitialLink();
    if (initialLink != null) {
      final Uri deepLink = initialLink.link;
      await Future.delayed(Duration(seconds: 1));
      String? dbUID = deepLink.queryParameters['uid'];
      print(dbUID);
      Get.offAllNamed("/profile", arguments: [dbUID]);
    }
  }

  _handleDeepLinkStream() {
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) async {
      await Future.delayed(Duration(seconds: 1));
      String? dbUID = dynamicLinkData.link.queryParameters['uid'];
      print(dbUID);
      Get.offAllNamed("/profile", arguments: [dbUID]);
    }).onError((error) {
      print(error);
    });
  }

  Future<void> _getUsersDB(User user) async {
    DatabaseReference ref =
        FirebaseDatabase.instance
            .ref("Users/${user.uid}");

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
    Map<dynamic, dynamic> decoded =
        event.snapshot.value as Map<dynamic, dynamic>;
    decoded.forEach((key, value) {
      allowedDbs.add(key);
    });
    myUser.setAllowedDbs(allowedDbs);

    // myUser.setAllowedDbs(event.snapshot.value);
  }

  _createNewUserInDB(User user, DatabaseReference ref) async {
    String userUid = user.uid;
    await ref.parent!.update({
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
  void dispose() async {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
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
