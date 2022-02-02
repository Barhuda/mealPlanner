class MyUser {
  String UID;
  bool isLoggedIn;
  List<String> allowedDbs;

  MyUser({this.isLoggedIn = false, this.allowedDbs, this.UID});

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
  }
}
