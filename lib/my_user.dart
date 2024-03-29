import 'package:shared_preferences/shared_preferences.dart';

class MyUser {
  String? UID;
  String? username;
  bool hasPremium;
  bool isLoggedIn;
  String? selectedMealPlan;
  List<String?>? allowedDbs = [];

  MyUser(
      {this.isLoggedIn = false,
      this.allowedDbs,
      this.UID,
      this.hasPremium = false});

  userLoggedIn(String UID) {
    this.isLoggedIn = true;
    this.UID = UID;
  }

  setUsername(String? receivedName) {
    this.username = receivedName;
  }

  userLoggedOut() {
    this.isLoggedIn = false;
    this.UID = null;
  }

  setAllowedDbs(List allowedDbscoming) {
    this.allowedDbs = allowedDbscoming as List<String?>?;
    print(this.allowedDbs);
  }

  setPremium() {
    this.hasPremium = true;
  }

  setNotBought(){
    this.hasPremium = false;
  }

  Future<String?> getSelectedMealPlan() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (this.selectedMealPlan == null) {
      String? mealPlanFromPrefs = prefs.getString("selectedPlan");
      if (mealPlanFromPrefs != null) {
        this.selectedMealPlan = mealPlanFromPrefs;
      } else {
        this.selectedMealPlan = this.UID;
      }
    }
    return this.selectedMealPlan;
  }

  setSelectedMealPlan(String selectPlan) async {
    this.selectedMealPlan = selectPlan;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("selectedPlan", selectPlan);
    print(selectPlan);
  }
}
