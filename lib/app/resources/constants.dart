
import 'package:appwrite_user_app/app/resources/images.dart';
import 'package:flutter/material.dart' show Color;

class Constants {

  static const String appName = 'Kiko Mart';
  static const String appVersion = "1.0.0";
  static const String packageName = 'com.mehedi.food';
  static const String webBaseUrl = 'https://kiko-mart.appwrite.network';

  /// The app's brand colour — the single knob for recolouring the whole UI.
  ///
  /// Change this one value and everything follows: the lighter accent steps,
  /// the brand gradient, the Material swatch and the light/dark [ThemeData] are
  /// all derived from it in `resources/colors.dart`. Nothing else needs editing.
  ///
  /// Pick a colour dark enough to carry white text — it is painted behind the
  /// app bar, the primary buttons and every filled badge. Mid-tone brand
  /// colours (roughly 40-55% HSL lightness) work best; a very light one will
  /// leave white labels unreadable, and a near-black one flattens the gradient.
  static const Color primaryColor = Color(0xFFC92A2A);

  static const String projectId = '694d7ed80012589bdb9c';
  static const String endpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const String databaseId = 'food_delivery_db';
  static const String apiKey = 'standard_94c9a3d62a86353f64c689846a4c8643086c533cebdcd99d1f6d38cc7d5cc91672e967c41f0092cfd47a11d0b84cb046ffbf19087b63ad8eab7f0b3454d00a37f6a0f37859d7c7ec36a2a96d5b5ec41e08dd81bc27bb2f5a2d78e3ce88e1f4bec6cd2e3c05ed016628a0e100e52e038146309b4be98c88598a6fa0c990f10188'; // MUST have 'databases.write' scope
  static const String dbId = 'food_delivery_db';
  static const String postsBucketId = '694d812100305bf791d7'; //it's for storing post images
  static const String messagingProviderId = '6984d1ef0023c0b30df1'; //it's for fcm push notifications topic and fcm token management
  static const String notificationFunctionId = '699735670009f8d132b6'; //it's for sending notifications using cloud functions
  static const String topicId = '6999d25e00167cf81dfe'; // it's for storing FCM topic subscriptions (e.g. for promo notifications)
  static const String storeAdminTopicId = '699b52b8002068aad61e'; // topic for store admin devices — new order alerts
  static const String stripePaymentFunctionId = '69ad6e63001c310396b7'; // it's for processing Stripe payments using cloud functions

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

  /// Corner radius of an elevated card surface — matches the radius
  /// [CustomClickableWidget] paints, so nested content can clip to it exactly.
  static const double radiusCard = radiusLarge + 4;

  /// Minimum comfortable tap target for controls embedded in dense layouts
  /// (product cards, list tiles). Keeps hit areas within accessibility limits.
  static const double minTapTarget = 40.0;

  /// Diameter of the tinted circle behind a status/result icon (empty states,
  /// auth outcome panels).
  static const double iconCircleSize = 88.0;

  /// Icon glyph size inside [iconCircleSize].
  static const double iconSizeLarge = 44.0;

  /// Vertical gap between home sections.
  static const double spaceSection = 28.0;

  /// Bottom clearance so scrollable content / bottom bars are not hidden
  /// behind the floating bottom navigation bar.
  static const double bottomNavSpace = 90.0;

  static List<LanguageModel> languages = [
    LanguageModel(imageUrl: Images.english, languageName: 'English', countryCode: 'US', languageCode: 'en'),
    LanguageModel(imageUrl: Images.bengali, languageName: 'Bengali', countryCode: 'BN', languageCode: 'bn'),
    LanguageModel(imageUrl: Images.world, languageName: 'العربية', countryCode: 'SA', languageCode: 'ar'),
  ];

  /// Shared Preferences Keys
  static const String countryCode = 'country_code';
  static const String languageCode = 'language_code';
  static const String theme = 'theme';
  static const String activeModule = 'active_module';

  /// "Remember me" on the sign-in form. These deliberately survive a logout —
  /// clearing them is only triggered by the user unticking the box.
  static const String rememberMe = 'remember_me';
  static const String rememberedEmail = 'remembered_email';
  static const String rememberedPassword = 'remembered_password';
}

class LanguageModel {
  String imageUrl;
  String languageName;
  String languageCode;
  String countryCode;

  LanguageModel({required this.imageUrl, required this.languageName, required this.countryCode, required this.languageCode});
}