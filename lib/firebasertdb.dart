import 'package:firebase_database/firebase_database.dart';

class FirebaseRTDB {
  static changeUserName(String userUID, String newName) async {
    if (newName != "") {
      Map<String, dynamic> newMap = {};
      newMap["name"] = newName;
      await FirebaseDatabase.instance.ref("Users/$userUID").update(newMap);
    }
  }

  static Future<List<String>> getAllowedUsersNames(String UserUID) async {
    List<String> allowedUsers = [""];
    DatabaseEvent event = await FirebaseDatabase.instance
        .ref("mealDbs/$UserUID/allowedUsers")
        .once();
    Map<dynamic, dynamic> results = event.snapshot.value;
    print("Erster Event: $results");
    if (results != null) {
      results.forEach((key, value) async {
        print("KEY: $key");
        DatabaseEvent secondEvent =
            await FirebaseDatabase.instance.ref("Users/$key/name").once();
        if (secondEvent != null) {
          String newResults = secondEvent.snapshot.value;
          print("Zweiter Event: $newResults");
          allowedUsers.add(newResults ?? "");
        }
      });
    }
    return allowedUsers;
  }

  static Future<String> getUserName(String userUID) async {
    DatabaseEvent event =
        await FirebaseDatabase.instance.ref("Users/$userUID").once();
    Map<dynamic, dynamic> results = event.snapshot.value;
    return results["name"];
  }

  static Future<void> changeMealPlanName(String dbID, String newName) async {
    Map<String, dynamic> newMap = {};
    newMap["name"] = newName;
    await FirebaseDatabase.instance.ref("mealDbs/$dbID").update(newMap);
  }

  static Future<void> addDBtoAllowedDbs(
      String userUID, String newDBToAdd) async {
    Map<String, dynamic> newMap = {};
    newMap[newDBToAdd] = true;
    await FirebaseDatabase.instance
        .ref("Users/$userUID/allowedDbs")
        .update(newMap);
    Map<String, dynamic> userMap = {};
    userMap[userUID] = true;
    await FirebaseDatabase.instance
        .ref("mealDbs/$newDBToAdd/allowedUsers")
        .update(userMap);
    return;
  }
}
