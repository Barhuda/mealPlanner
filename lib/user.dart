class User {
  String UID;
  bool isLoggedIn;
  List<String> allowedDbs;

  User({this.isLoggedIn = false, this.allowedDbs, this.UID});

  userLoggedIn(String UID) {
    this.isLoggedIn = true;
    this.UID = UID;
  }

  userLoggedOut() {
    this.isLoggedIn = false;
  }
}
