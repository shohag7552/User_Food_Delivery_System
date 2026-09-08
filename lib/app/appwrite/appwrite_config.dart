import 'package:appwrite_user_app/app/resources/constants.dart';

class AppwriteConfig {
  static const String projectId = Constants.projectId;
  static const String endpoint = Constants.endpoint;

  /// Deployed Flutter web build.
  ///
  /// MUST be registered as a **Web platform** on the Appwrite project —
  /// `account.createRecovery` validates its `url` argument against the
  /// project's web platform hostnames, so an unregistered host fails the call
  /// even when it originates from the Android or iOS app.
  static const String webAppBaseUrl = Constants.webBaseUrl;

  /// Page Appwrite links to in the password-recovery email; it appends
  /// `?userId=…&secret=…&expire=…`. The link is valid for one hour and can be
  /// used once.
  ///
  /// This same URL is claimed by the Android App Link and iOS Universal Link,
  /// so it opens the installed app and falls back to the browser otherwise.
  /// Keep the path in sync with `AppRouter.resetPassword`, the
  /// `<data android:pathPrefix>` in `AndroidManifest.xml`, and the components
  /// in `web/.well-known/apple-app-site-association`.
  static const String passwordRecoveryUrl = '${Constants.webBaseUrl}/reset-password';
  static const String databaseId = Constants.databaseId;
  static const String apiKey = Constants.apiKey;
  static const String dbId = Constants.dbId;
  static const String postsBucketId = Constants.postsBucketId;
  static const String messagingProviderId = Constants.messagingProviderId;
  static const String notificationFunctionId = Constants.notificationFunctionId;
  static const String topicId = Constants.topicId;
  static const String storeAdminTopicId = Constants.storeAdminTopicId;
  static const String stripePaymentFunctionId = Constants.stripePaymentFunctionId;

  // Collection IDs
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';
  static const String categoriesCollection = 'categories';
  static const String productsCollection = 'products';
  static const String likes = 'likes';
  // static const String storeProfile = 'store_profile';
  static const String businessSetup = 'business_setup';
  static const String couponsCollection = 'coupons';
  static const String storeSetup = 'store_setup';
  static const String bannersCollection = 'banners';
  static const String cartCollection = 'cart_items';
  static const String addressesCollection = 'addresses';
  static const String ordersCollection = 'orders';
  static const String favoritesCollection = 'favorites';
  static const String reviewsCollection = 'reviews';
  static const String notificationsCollection = 'notifications';
  static const String privacyPolicyCollection = 'privacy_policy';
  static const String driversCollection = 'drivers';
  /// Customer ratings of the deliveryman who handed an order over.
  /// Kept apart from [reviewsCollection] (products) so neither table's
  /// queries or rating aggregates leak into the other.
  static const String deliverymanReviewsCollection = 'deliveryman_reviews';
  static const String loyaltyHistoryCollection = 'loyalty_history';

  // Ecommerce module collections
  static const String brandsCollection = 'brands';
  static const String shippingMethodsCollection = 'shipping_methods';
  static const String attributesCollection = 'product_attributes';
  static const String flashSalesCollection = 'flash_sales';
  static const String flashSaleItemsCollection = 'flash_sale_items';
}
