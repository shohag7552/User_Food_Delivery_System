import 'dart:convert';
import 'package:appwrite_user_app/app/controllers/localization_controller.dart';
import 'package:get/get.dart';

class ModelJsonConverter {
  static Map<String, dynamic> parseData(String input) {
    try {
      final decoded = jsonDecode(input);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {Get.find<LocalizationController>().locale.languageCode: decoded};
    } catch (e) {
      return {Get.find<LocalizationController>().locale.languageCode: input};
    }
  }
}