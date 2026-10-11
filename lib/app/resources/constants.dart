
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

  static const String appName = 'KikoMart';
  static const String appVersion = "1.0.0";
  static const String packageName = 'com.kikomart.user';
  static const String webBaseUrl = 'https://kiko-mart-user.appwrite.network';

  static const int primaryColorValue = 0xFFC92A2A;

  /// Appwrite Console → Settings. Replace every `YOUR_…` value below with the
  /// ids from your own Appwrite project.
  static const String projectId = 'YOUR_PROJECT_ID';
  /// Your project's API endpoint, e.g. `https://<region>.cloud.appwrite.io/v1`
  /// or `https://appwrite.your-domain.com/v1` when self-hosted.
  static const String endpoint = 'https://cloud.appwrite.io/v1';
  static const String databaseId = 'YOUR_DATABASE_ID';
  // No Appwrite API key here: a key compiled into a client app can be
  // extracted by anyone. Server keys live only in Function environments.

  /// Alias of [databaseId], kept because callers use both spellings. Derived
  /// rather than repeated so the two can never drift apart.
  static const String dbId = databaseId;

  /// Storage bucket for every uploaded image (products, banners, logos).
  static const String postsBucketId = 'YOUR_STORAGE_BUCKET_ID';

  /// FCM push plumbing.
  static const String messagingProviderId = 'YOUR_MESSAGING_PROVIDER_ID';
  static const String notificationFunctionId = 'YOUR_NOTIFICATION_FUNCTION_ID';

  /// Topic customers subscribe to for promotional broadcasts. The store app
  /// calls this same id `broadCastTopicId`.
  static const String topicId = 'YOUR_BROADCAST_TOPIC_ID';

  /// Topic every store-admin device subscribes to — carries new-order alerts.
  static const String storeAdminTopicId = 'YOUR_STORE_ADMIN_TOPIC_ID';

  /// Processes Stripe payments via a cloud function. Customer-app only — the
  /// store app has no counterpart for this one.
  static const String stripePaymentFunctionId = 'YOUR_STRIPE_PAYMENT_FUNCTION_ID';

  /// Host the gateway returns the customer to, as
  /// `<host>/payment/success|fail|cancel`.
  ///
  /// This is the web app itself, not the payment function's own domain, and it
  /// has to be: on web the customer comes back as a real page load, and only a
  /// URL this app serves can pick the order back up and finish it. Android and
  /// iOS match the same three paths inside the in-app WebView and pop before
  /// they load, so one setting covers every platform.
  ///
  /// MUST match the callback URLs configured on the payment function
  /// ([stripePaymentFunctionId]) — the function builds the gateway session
  /// with its own copies, and a mismatch strands the customer mid-payment.
  static const String paymentCallbackBaseUrl = webBaseUrl;

  // static const String defaultMapTheme = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  // static const String lightMapTheme = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
  static const String streetMapTheme = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
  // static const String satelliteMapTheme = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
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
    LanguageModel(imageUrl: Images.arabic, languageName: 'العربية', countryCode: 'SA', languageCode: 'ar'),
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