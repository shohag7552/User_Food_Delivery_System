
import 'package:appwrite_user_app/app/resources/images.dart';

class Constants {

  static const String appName = 'LokLagbe';

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

  static List<LanguageModel> languages = [
    LanguageModel(imageUrl: Images.bengali, languageName: 'Bengali', countryCode: 'BN', languageCode: 'bn'),
    LanguageModel(imageUrl: Images.english, languageName: 'English', countryCode: 'US', languageCode: 'en'),
  ];

  /// Shared Preferences Keys
  static const String countryCode = 'country_code';
  static const String languageCode = 'language_code';
  static const String theme = 'theme';
  static const String topic = 'loklagbe_topic';
  static const String categoryTopic = 'category_topic';
}

class LanguageModel {
  String? imageUrl;
  String? languageName;
  String? languageCode;
  String? countryCode;

  LanguageModel({this.imageUrl, this.languageName, this.countryCode, this.languageCode});
}