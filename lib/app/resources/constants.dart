
import 'package:appwrite_user_app/app/resources/images.dart';

class Constants {

  static const String appName = 'Food User';
  static const double appVersion = 1.0;
  static const String packageName = 'com.example.appwrite_user_app';

  static const String defaultMapTheme = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String lightMapTheme = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
  static const String streetMapTheme = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
  static const String satelliteMapTheme = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  // static const String darkMapTheme = 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png';

  static double fontSizeExtraSmall = 10;
  static double fontSizeSmall = 12;
  static double fontSizeDefault = 14;
  static double fontSizeLarge = 16;
  static double fontSizeExtraLarge = 18;
  static double fontSizeOverLarge = 24;

  static const double paddingSizeExtraSmall = 5.0;
  static const double paddingSizeSmall = 10.0;
  static const double paddingSizeDefault = 15.0;
  static const double paddingSizeLarge = 20.0;
  static const double paddingSizeExtraLarge = 25.0;

  static const double radiusSmall = 5.0;
  static const double radiusDefault = 10.0;
  static const double radiusLarge = 15.0;
  static const double radiusExtraLarge = 20.0;

  /// Vertical gap between home sections.
  static const double spaceSection = 28.0;

  /// Bottom clearance so scrollable content / bottom bars are not hidden
  /// behind the floating bottom navigation bar.
  static const double bottomNavSpace = 90.0;

  static List<LanguageModel> languages = [
    LanguageModel(imageUrl: Images.english, languageName: 'English', countryCode: 'US', languageCode: 'en'),
    LanguageModel(imageUrl: Images.bengali, languageName: 'Bengali', countryCode: 'BN', languageCode: 'bn'),
  ];

  /// Shared Preferences Keys
  static const String countryCode = 'country_code';
  static const String languageCode = 'language_code';
  static const String theme = 'theme';
  static const String topic = 'loklagbe_topic';
  static const String categoryTopic = 'category_topic';
}

class LanguageModel {
  String imageUrl;
  String languageName;
  String languageCode;
  String countryCode;

  LanguageModel({required this.imageUrl, required this.languageName, required this.countryCode, required this.languageCode});
}