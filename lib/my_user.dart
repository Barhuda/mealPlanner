class MyUser {
  String UID;
  bool hasPremium;
  bool isLoggedIn;
  String selectedMealPlan;
  List<String> allowedDbs;

  MyUser(
      {this.isLoggedIn = false,
      this.allowedDbs,
      this.UID,
      this.hasPremium = false});

  userLoggedIn(String UID) {
    this.isLoggedIn = true;
    this.UID = UID;
  }

  userLoggedOut() {
    this.isLoggedIn = false;
    this.UID = null;
  }

  setAllowedDbs(List allowedDbscoming) {
    allowedDbs = allowedDbscoming;
    print(this.allowedDbs);
  }

  setPremium() {
    this.hasPremium = true;
  }

  String getSelectedMealPlan() {
    if (this.selectedMealPlan == null) {
      this.selectedMealPlan = allowedDbs[0];
    }
    return this.selectedMealPlan;
  }
}
