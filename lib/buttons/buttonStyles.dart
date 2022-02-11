import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mealpy/constants.dart' as Constants;

final ButtonStyle recipeButtonStyle = ElevatedButton.styleFrom(
    primary: Constants.primaryButtonColor,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12))));

final ButtonStyle addFriendButtonStyle = ElevatedButton.styleFrom(
    primary: Colors.teal,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12))));

final ButtonStyle saveButtonStyle = ElevatedButton.styleFrom(
    primary: Constants.saveButtonColor,
    elevation: 2,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12))));

final ButtonStyle cancelButtonStyle = ElevatedButton.styleFrom(
    primary: Constants.cancelButtonColor,
    elevation: 2,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12))),
    side: BorderSide(
      width: 2.0,
      color: Colors.blue,
    ));

final ButtonStyle categorieButton = ElevatedButton.styleFrom(
  primary: Constants.fourthColor,
  padding: EdgeInsets.all(20),
  shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12))),
);

final ButtonStyle buyPremiumButton = ElevatedButton.styleFrom(
    primary: Color.fromARGB(255, 238, 12, 12),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12))));
