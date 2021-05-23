import 'package:flutter/material.dart';
import 'package:mealpy/constants.dart' as Constants;

final ButtonStyle recipeButtonStyle = ElevatedButton.styleFrom(
    primary: Constants.primaryButtonColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))));

final ButtonStyle saveButtonStyle = ElevatedButton.styleFrom(
    primary: Constants.saveButtonColor, elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))));

final ButtonStyle cancelButtonStyle = ElevatedButton.styleFrom(
    primary: Constants.cancelButtonColor,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    side: BorderSide(
      width: 2.0,
      color: Colors.blue,
    ));
