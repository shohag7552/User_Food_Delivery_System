import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:get/get.dart';

extension TranslatableMap on Map<String, dynamic> {
  /// Automatically gets the string for the current GetX language code.
  /// Falls back to English ('en') if the translation is missing.
  String get trLanguage {
    // 1. Ask GetX what the current app language is right now
    String currentLang = Get.locale?.languageCode ?? Constants.languages[0].languageCode;

    // 2. Return the correct string from your database Map
    return this[currentLang] ?? this[Constants.languages[0].languageCode] ?? '';
  }
}