
import 'package:appwrite_user_app/app/resources/images.dart';

/// App-wide configuration.
///
/// **Do not import Flutter into this file.** The ids below are mirrored from
/// the store-admin app, whose `lib/scripts/seed_database.dart` owns this
/// database's schema and runs on the standalone Dart VM — no `dart:ui` there,
/// so a single `package:flutter/...` import fails with a wall of errors from
/// inside Flutter's own sources. Keeping this file Flutter-free means it (and
/// `AppwriteConfig`, which re-exports it) stays readable from plain Dart
/// tooling on either side. That is why the brand colour is stored as an `int`
/// and wrapped in a `Color` over in `resources/colors.dart`.
class Constants {

  static const String appName = 'Kiko Mart';
  static const String appVersion = "1.0.0";
  static const String packageName = 'com.kikomart.user';
  static const String webBaseUrl = 'https://kiko-mart.appwrite.network';

  /// The app's brand colour, as a plain ARGB int — the single knob for
  /// recolouring the whole UI.
  ///
  /// Change this one value and everything follows: the lighter accent steps,
  /// the brand gradient, the Material swatch and the light/dark [ThemeData] are
  /// all derived from it in `resources/colors.dart`. Nothing else needs editing.
  ///
  /// It is an `int` and not a `Color` on purpose — see the note on [Constants].
  /// Read it as `Color(Constants.primaryColorValue)`, or better, use
  /// `ColorResource.primary` / `context.*` which already do.
  ///
  /// Pick a colour dark enough to carry white text — it is painted behind the
  /// app bar, the primary buttons and every filled badge. Mid-tone brand
  /// colours (roughly 40-55% HSL lightness) work best; a very light one will
  /// leave white labels unreadable, and a near-black one flattens the gradient.
  static const int primaryColorValue = 0xFFC92A2A;

  // ── Appwrite backend ─────────────────────────────────────────────────────
  //
  // These MUST stay byte-identical to the same ids in the store-admin app
  // (`appWrite_store_app/lib/app/resources/constants.dart`) — both apps read
  // and write the one project, so a divergence here silently splits the two
  // halves of the product onto different databases.

  static const String projectId = '6aa44c20000b0b73b432';
  static const String endpoint = 'https://fra.cloud.appwrite.io/v1';
  static const String databaseId = '6aa44dc40005d989a0e4';
  static const String apiKey = 'standard_8e825bd4c06323a3e43d5941086078419bc3d82a2c6bb6760e21b91667e69982655826c89e2071ac20530339274ba38f5e5b9bfb36e39f7da4209d6379ef26aaac2548e0a8f75ea2145934a92bedde738ca48dfbbdf20e26afffa25f8650d26823fd0ef03aee008eb2edaa1e6eaee8692a4d0d6a7811d54d08df0a2f994e7172'; // MUST have 'databases.write' scope

  /// Alias of [databaseId], kept because callers use both spellings. Derived
  /// rather than repeated so the two can never drift apart.
  static const String dbId = databaseId;

  /// Storage bucket for every uploaded image (products, banners, logos).
  static const String postsBucketId = '6aa44e8d0013091f9c27';

  /// FCM push plumbing.
  static const String messagingProviderId = '6aa451f2002cbb748e9d';
  static const String notificationFunctionId = 'notification_function1';

  /// Topic customers subscribe to for promotional broadcasts. The store app
  /// calls this same id `broadCastTopicId`.
  static const String topicId = '6aa5a40a00120693b5eb';

  /// Topic every store-admin device subscribes to — carries new-order alerts.
  static const String storeAdminTopicId = '6aa5a4aa003371f66577';

  /// Processes Stripe payments via a cloud function. Customer-app only — the
  /// store app has no counterpart for this one.
  static const String stripePaymentFunctionId = 'stripe_payment1';

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