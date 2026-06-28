import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:get/get.dart';

extension TranslatableMap on Map<String, dynamic>? {
  /// Automatically gets the string for the current GetX language code.
  /// Falls back to the default language, then to any available value, then ''.
  ///
  /// Defined on a nullable map and coerces values with `toString()` so it
  /// never throws — null maps, missing keys, or non-String values all resolve
  /// to a safe String (this also avoids dynamic-cast failures on Flutter web).
  String get trLanguage {
    final map = this;
    if (map == null || map.isEmpty) return '';

    final String currentLang =
        Get.locale?.languageCode ?? Constants.languages[0].languageCode;
    final String fallbackLang = Constants.languages[0].languageCode;

    final value = map[currentLang] ?? map[fallbackLang] ?? map.values.first;
    return value?.toString() ?? '';
  }
}