import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mealpy/my_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:multiselect/multiselect.dart';
import 'package:auth_buttons/auth_buttons.dart'
    show GoogleAuthButton, EmailAuthButton, AuthButtonType, AuthIconType;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart' hide Trans;
import 'package:mealpy/constants.dart' as Constants;

class ProfileScreen extends StatefulWidget {
  ProfileScreen({Key key, this.analytics, this.observer, this.database})
      : super(key: key);

  final FirebaseDatabase database;
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  static const String id = 'profile_screen';

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  SharedPreferences prefs;

  bool _isLoading = true;

  MyUser myUser = Get.find();

  int selectedValue = 0;

  @override
  void initState() {
    super.initState();
    if (myUser.isLoggedIn) {
      _getUserInfo();
    }
  }

  _getUserInfo() async {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref("Users/${myUser.UID}");
    DatabaseEvent event = await ref.once();
    print(event.snapshot.value);
  }

  final DateFormat formatter = DateFormat("EEEE");

  _addData() {
    if (myUser.UID != null) {
      print("USER UID:::" + myUser.UID);
    } else {
      print("UID Leer");
    }
  }

  _registerWithMail() async {
    TextEditingController mailText = TextEditingController();
    TextEditingController passwordText = TextEditingController();
    Get.defaultDialog(
      title: "Register with Mail".tr(),
      onConfirm: () {
        _doFirebaseMailRegistration(mailText.text, passwordText.text);
      },
      confirmTextColor: Colors.white,
      textConfirm: "Register".tr(),
      onCancel: () {
        Navigator.of(context).pop();
      },
      content: Column(
        children: [
          TextFormField(
            controller: mailText,
            decoration: InputDecoration(
                label: Text("Mail"), hintText: "Enter Mail".tr()),
          ),
          TextFormField(
            controller: passwordText,
            decoration: InputDecoration(
                label: Text("Password"), hintText: "Enter Password".tr()),
          ),
        ],
      ),
    );
  }

  _doFirebaseMailRegistration(String mail, String password) async {
    bool hasError = false;
    String title;
    String content;
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: mail, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        title = "Password weak".tr();
        content = "The password provided is too weak.".tr();
        print('The password provided is too weak.');
        hasError = true;
      } else if (e.code == 'email-already-in-use') {
        title = "E-Mail already in use".tr();
        content = "The account already exists for that email.".tr();
        print('The account already exists for that email.');
        hasError = true;
      } else {
        title = e.code;
        content = e.message;
        hasError = true;
      }
    } catch (e) {
      print(e);
      hasError = true;
    }
    Navigator.of(context).pop();
    print(hasError);
    if (hasError) {
      Get.snackbar(title, content, snackPosition: SnackPosition.TOP);
    }
  }

  _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  _loginWithMail() {
    TextEditingController mailText = TextEditingController();
    TextEditingController passwordText = TextEditingController();
    Get.defaultDialog(
      title: "Login with Mail".tr(),
      onConfirm: () {
        _doFireBaseLoginWithMail(mailText.text, passwordText.text);
      },
      confirmTextColor: Colors.white,
      textConfirm: "Login".tr(),
      onCancel: () {
        Navigator.of(context).pop();
      },
      content: Column(
        children: [
          TextFormField(
            controller: mailText,
            decoration: InputDecoration(
                label: Text("Mail"), hintText: "Enter Mail".tr()),
          ),
          TextFormField(
            controller: passwordText,
            decoration: InputDecoration(
                label: Text("Password"), hintText: "Enter Password".tr()),
          ),
        ],
      ),
    );
  }

  _doFireBaseLoginWithMail(String mail, String password) async {
    bool hasError = false;
    String title;
    String content;
    //              email: "barry.allen@example.com",
    //               password: "SuperSecretPassword!"
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: mail, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        title = "No User".tr();
        content = "No user found for that email.".tr();
        print('No user found for that email.');
        hasError = true;
      } else if (e.code == 'wrong-password') {
        title = "Wrong Password".tr();
        content = "Wrong password provided for that user.".tr();
        print('Wrong password provided for that user.');
        hasError = true;
      }
    }
    Navigator.of(context).pop();
    if (hasError) {
      Get.snackbar(title, content, snackPosition: SnackPosition.TOP);
    }
  }

  _changeScene(int index) {
    Get.toNamed(Constants.bottomNavigationRoutes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Profile".tr()),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                _signOut();
              },
              child: Icon(
                Icons.logout,
                size: 25,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(
              alignment: AlignmentDirectional.topStart,
              child: Text(
                "Login for sync and share".tr(),
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 80.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 34),
                    child: GoogleAuthButton(
                      onPressed: () {
                        _addData();
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: EmailAuthButton(
                      onPressed: () {
                        _registerWithMail();
                      },
                      text: "Register with Email".tr(),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 150,
            ),
            Align(
              alignment: AlignmentDirectional.bottomCenter,
              child: TextButton(
                onPressed: () {
                  _loginWithMail();
                },
                child: Text(
                  "Erneuter Login",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
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
        currentIndex: 1,
      ),
    );
  }
}
