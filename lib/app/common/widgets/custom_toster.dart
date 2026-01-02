import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void customToster(String message, {bool isSuccess = true}) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: isSuccess ? Colors.green : Colors.red,
    textColor: Colors.white,
    fontSize: Constants.fontSizeDefault,
  );
}
