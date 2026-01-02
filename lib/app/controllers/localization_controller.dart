
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationController extends GetxController implements GetxService {
  final SharedPreferences sharedPreferences;
  LocalizationController({required this.sharedPreferences}){
    loadCurrentLanguage();
  }

  // LocalizationController({required this.sharedPreferences, required this.apiClient}) {
  //   loadCurrentLanguage();
  // }

  Locale _locale = Locale(Constants.languages[0].languageCode!, Constants.languages[0].countryCode);
  Locale get locale => _locale;

  bool _isLtr = true;
  bool get isLtr => _isLtr;

  List<LanguageModel> _languages = [];
  List<LanguageModel> get languages => _languages;

  int _selectedLanguageIndex = 0;
  int get selectedLanguageIndex => _selectedLanguageIndex;

  bool _darkTheme = false;
  bool get darkTheme => _darkTheme;

  void toggleTheme() {
    _darkTheme = !_darkTheme;
    sharedPreferences.setBool(Constants.theme, _darkTheme);
    update();
  }

  void setLanguage(Locale locale, {bool fromBottomSheet = false}) {
    Get.updateLocale(locale);
    _locale = locale;
    if(locale.languageCode == 'ar') {
      _isLtr = false;
    }else {
      _isLtr = true;
    }

    saveLanguage(_locale);

    update();
  }

  void loadCurrentLanguage() async {
    _locale = Locale(
      sharedPreferences.getString(Constants.languageCode) ?? Constants.languages[0].languageCode!,
      sharedPreferences.getString(Constants.countryCode) ?? Constants.languages[0].countryCode,
    );

    _isLtr = _locale.languageCode != 'ar';
    _selectedLanguageIndex = _setSelectedLanguageIndex(Constants.languages, _locale);
    _languages = [];
    _languages.addAll(Constants.languages);
    // ApiService apiClient = Get.find<ApiService>();
    // apiClient.updateHeader(sharedPreferences.getString(AppUrls.token), _locale.languageCode);

    // if(Get.find<AuthController>().alreadyLoggedIn()) {
    //   Get.find<AuthController>().languageChange(_locale.languageCode);
    // }
    _darkTheme = sharedPreferences.getBool(Constants.theme) ?? false;
    update();
  }

  void saveLanguage(Locale locale) async {
    sharedPreferences.setString(Constants.languageCode, locale.languageCode);
    sharedPreferences.setString(Constants.countryCode, locale.countryCode!);
    // ApiService apiClient = Get.find<ApiService>();
    // apiClient.updateHeader(sharedPreferences.getString(AppUrls.token), _locale.languageCode);
    // if(Get.find<AuthController>().alreadyLoggedIn()) {
    //   Get.find<AuthController>().languageChange(_locale.languageCode);
    // }
  }

  int _setSelectedLanguageIndex(List<LanguageModel> languages, Locale locale) {
    int selectedLanguageIndex = 0;
    for(int index = 0; index<languages.length; index++) {
      if(languages[index].languageCode == locale.languageCode) {
        selectedLanguageIndex = index;
        break;
      }
    }
    return selectedLanguageIndex;
  }

  // void saveCacheLanguage(Locale? locale) {
  //   languageServiceInterface.saveCacheLanguage(locale ?? languageServiceInterface.getLocaleFromSharedPref());
  // }

  void setSelectLanguageIndex(int index) {
    _selectedLanguageIndex = index;
    update();
  }


  // Locale getCacheLocaleFromSharedPref() {
  //   return languageServiceInterface.getCacheLocaleFromSharedPref();
  // }
  //
  // void searchSelectedLanguage() {
  //   for (var language in AppConstants.languages) {
  //     if (language.languageCode!.toLowerCase().contains(_locale.languageCode.toLowerCase())) {
  //       _selectedLanguageIndex = AppConstants.languages.indexOf(language);
  //     }
  //   }
  // }
  //
  // void searchLanguage(String query) {
  //   if (query.isEmpty) {
  //     _languages  = [];
  //     _languages = AppConstants.languages;
  //   } else {
  //     _selectedLanguageIndex = -1;
  //     _languages = [];
  //     for (var language in AppConstants.languages) {
  //       if (language.languageName!.toLowerCase().contains(query.toLowerCase())) {
  //         _languages.add(language);
  //       }
  //     }
  //   }
  //   update();
  // }

}