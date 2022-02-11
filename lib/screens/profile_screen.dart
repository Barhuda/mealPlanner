import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
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
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mealpy/firebasertdb.dart';
import 'package:mealpy/buttons/buttonStyles.dart' as MyButton;
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

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
  GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );
  SharedPreferences prefs;

  bool _isLoading = true;

  MyUser myUser = Get.find();

  int selectedValue = 0;
  Map<String, dynamic> mealDbsNames = {};
  Map<String, dynamic> mealDbsUsers = {};
  TextEditingController newNameCtr = TextEditingController();
  var arguments;
  String dbUIDtoAddFromFriend;

  @override
  void initState() {
    super.initState();
    print("User has Premium? " + myUser.hasPremium.toString());
    if (myUser.isLoggedIn) {
      _getMealPlanNamesAndUsers();
      newNameCtr.text = myUser.username ?? "User";
      if (Get.arguments != null) {
        arguments = Get.arguments;
        dbUIDtoAddFromFriend = arguments[0];
        print("UID from Friend is::::: $dbUIDtoAddFromFriend");
        _handleAddingNewMealplanThroughLink(dbUIDtoAddFromFriend);
      }
    }
  }

  final DateFormat formatter = DateFormat("EEEE");

  _addData() {
    if (myUser.UID != null) {
      print("USER UID:::" + myUser.UID);
    } else {
      print("UID Leer");
    }
  }

  _signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    Get.offAllNamed("/profile"); // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  _registerWithMail() async {
    TextEditingController mailText = TextEditingController();
    TextEditingController passwordText = TextEditingController();
    Get.defaultDialog(
      title: "Register with Mail".tr(),
      onConfirm: () async {
        await _doFirebaseMailRegistration(mailText.text, passwordText.text);
        Get.offAllNamed("/profile");
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
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
                label: Text("Mail"), hintText: "Enter Mail".tr()),
          ),
          TextFormField(
            controller: passwordText,
            obscureText: true,
            keyboardType: TextInputType.visiblePassword,
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
    setState(() {});
    print(hasError);
    if (hasError) {
      Get.snackbar(title, content, snackPosition: SnackPosition.TOP);
    } else {
      Get.snackbar("Success".tr(), "Account has been registred".tr(),
          snackPosition: SnackPosition.TOP);
    }
  }

  _signOut() async {
    await FirebaseAuth.instance.signOut();
    setState(() {});
  }

  _loginWithMail() {
    TextEditingController mailText = TextEditingController();
    TextEditingController passwordText = TextEditingController();
    Get.defaultDialog(
      title: "Login with Mail".tr(),
      onConfirm: () async {
        await _doFireBaseLoginWithMail(mailText.text, passwordText.text);
        Get.offAllNamed("/profile");
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
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
                label: Text("Mail"), hintText: "Enter Mail".tr()),
          ),
          TextFormField(
            controller: passwordText,
            obscureText: true,
            keyboardType: TextInputType.visiblePassword,
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
      } else {
        title = e.code;
        content = e.message;
        hasError = true;
      }
    }
    Navigator.of(context).pop();
    if (hasError) {
      Get.snackbar(title, content, snackPosition: SnackPosition.TOP);
    }
    setState(() {});
  }

  _changeScene(int index) {
    Get.offAllNamed(Constants.bottomNavigationRoutes[index]);
  }

  selectMealPlan(String mealPlan) {
    myUser.setSelectedMealPlan(mealPlan);
  }

  _getMealPlanNamesAndUsers() async {
    for (var dbs in myUser.allowedDbs) {
      DatabaseEvent event =
          await FirebaseDatabase.instance.ref("mealDbs/$dbs").once();
      Map<dynamic, dynamic> results = event.snapshot.value;

      if (results != null) {
        results.forEach((key, value) async {
          mealDbsNames[dbs] = results["name"] ?? "";
        });
      }
      List<String> myList = await FirebaseRTDB.getAllowedUsersNames(dbs);
      mealDbsUsers[dbs] = myList;
      print(mealDbsNames);
      print(mealDbsUsers);
    }
    setState(() {});
  }

  _selectMealPlan(String selectPlan) {
    myUser.setSelectedMealPlan(selectPlan);
    setState(() {});
  }

  _saveName(String newName) async {
    await FirebaseRTDB.changeUserName(myUser.UID, newName);
    myUser.setUsername(newName);
    setState(() {});
  }

  _setNewMealplanName(String dbUID, String newName) {
    if (newName != "") {
      FirebaseRTDB.changeMealPlanName(dbUID, newName);
    }
  }

  _setNewMealplanNameDialog(String dbUID, String initialName) {
    TextEditingController mealPlanName =
        TextEditingController(text: initialName);

    Get.defaultDialog(
      title: "Set new meal plan name".tr(),
      onConfirm: () {
        _setNewMealplanName(dbUID, mealPlanName.text);
        Get.offAllNamed("/profile");
      },
      confirmTextColor: Colors.white,
      textConfirm: "Save".tr(),
      onCancel: () {
        Navigator.of(context).pop();
      },
      content: Column(
        children: [
          TextFormField(
            controller: mealPlanName,
            decoration: InputDecoration(
                label: Text("Plan".tr()), hintText: "Enter Mail".tr()),
          ),
        ],
      ),
    );
  }

  Future<String> _addFriend(String dbUID) async {
    FirebaseDynamicLinks dynamicLinks = FirebaseDynamicLinks.instance;

    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://mealpy.page.link',
      link: Uri.parse(
          'https://mealpy.page.link/sharemeals?uid=$dbUID'), // <- your paramaters

      androidParameters: AndroidParameters(
        packageName: 'com.mk.mealpy',
        minimumVersion: 9,
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: "Add Mealplan",
      ),
    );
    final ShortDynamicLink shortenedLink =
        await dynamicLinks.buildShortLink(parameters);

    final Uri uri = shortenedLink.shortUrl;
    return "$uri";
  }

  _handleAddingNewMealplanThroughLink(String newDBUID) async {
    if (myUser.allowedDbs.contains(newDBUID)) {
      return;
    } else {
      await FirebaseRTDB.addDBtoAllowedDbs(myUser.UID, newDBUID);
      List allowedDbs = myUser.allowedDbs;
      allowedDbs.add(newDBUID);
      myUser.setAllowedDbs(allowedDbs);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Constants.mainColor,
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
        child: myUser.hasPremium
            ? myUser.isLoggedIn
                ? Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextField(
                            controller: newNameCtr,
                            decoration: InputDecoration(
                              label: Text("Change your Username".tr()),
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton(
                          onPressed: () {
                            _saveName(newNameCtr.text);
                          },
                          child: Text("Save".tr()),
                          style: MyButton.saveButtonStyle),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            "Mealpan".tr(),
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: myUser.allowedDbs.length,
                          itemBuilder: (BuildContext context, int index) {
                            String currentDbInIndex = myUser.allowedDbs[index];
                            return GestureDetector(
                              onTap: () {
                                selectMealPlan(myUser.allowedDbs[index]);
                              },
                              child: GestureDetector(
                                onTap: () {
                                  _selectMealPlan(currentDbInIndex);
                                },
                                child: Card(
                                  color: myUser.selectedMealPlan ==
                                          currentDbInIndex
                                      ? Colors.teal
                                      : Colors.blueGrey,
                                  elevation: 6,
                                  key: ValueKey(index),
                                  margin: EdgeInsets.all(5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          mealDbsNames[currentDbInIndex] ?? "",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                        Row(
                                          children: [
                                            Text("User: ".tr(),
                                                style: TextStyle(
                                                  color: Constants.thirdColor,
                                                )),
                                            Expanded(
                                              child: Center(
                                                child: mealDbsUsers[
                                                            currentDbInIndex] ==
                                                        null
                                                    ? Text("")
                                                    : Text(
                                                        mealDbsUsers[
                                                                    currentDbInIndex]
                                                                .toString()
                                                                .replaceAll(
                                                                    "[", "")
                                                                .replaceAll(
                                                                    "]", "")
                                                                .replaceAll(
                                                                    ",", " ") ??
                                                            "",
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            color: Constants
                                                                .secondaryColor)),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 32,
                                            )
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 24.0, bottom: 12),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () async {
                                                  String url = await _addFriend(
                                                      myUser.allowedDbs[index]);
                                                  print(url);
                                                },
                                                child:
                                                    Text("+ Add Friend".tr()),
                                                style: MyButton
                                                    .addFriendButtonStyle,
                                              ),
                                              ElevatedButton(
                                                  onPressed: () {
                                                    _setNewMealplanNameDialog(
                                                        currentDbInIndex,
                                                        mealDbsNames[
                                                            currentDbInIndex]);
                                                  },
                                                  child:
                                                      Text("Rename plan".tr()),
                                                  style: MyButton
                                                      .addFriendButtonStyle)
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : SignInWidgets()
            : getPremium(),
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

  Column SignInWidgets() {
    return Column(
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
                    _signInWithGoogle();
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
    );
  }
}

class getPremium extends StatefulWidget {
  const getPremium({
    Key key,
  }) : super(key: key);

  @override
  State<getPremium> createState() => _getPremiumState();
}

class _getPremiumState extends State<getPremium> {
  List<ProductDetails> products = [];

  _purchasePremium() {
    final ProductDetails productDetails = products[0];
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);

    InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  void initState() {
    _getProductDetails();
    super.initState();
  }

  _getProductDetails() async {
    const Set<String> _kIds = <String>{'premium'};
    final ProductDetailsResponse response =
        await InAppPurchase.instance.queryProductDetails(_kIds);
    print(response.productDetails);
    products = response.productDetails;
    setState(() {});
  }

  _getPastPurchases() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      InAppPurchaseAndroidPlatformAddition androidAddition = InAppPurchase
          .instance
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

      QueryPurchaseDetailsResponse response =
          await androidAddition.queryPastPurchases();
      print(response.pastPurchases[0].productID);
      print("Hat gekauft: " + response.pastPurchases[0].productID);

    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Get Premium",
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey),
        ),
        ElevatedButton(
            style: MyButton.buyPremiumButton,
            onPressed: () {
              print("Premium Handler");
              _purchasePremium();
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.grade),
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: Text(
                      "Buy Premium",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            )),
        ElevatedButton(
            style: MyButton.buyPremiumButton,
            onPressed: () {
              print("Premium Handler");
              _getPastPurchases();
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.grade),
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0),
                    child: Text(
                      "Test History",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ))
      ],
    );
  }
}
