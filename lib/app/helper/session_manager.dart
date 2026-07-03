import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/controllers/favorites_controller.dart';
import 'package:appwrite_user_app/app/controllers/profile_controller.dart';
import 'package:get/get.dart';

/// Whether a user session is currently active.
///
/// Auth-scoped controller fetches guard on this so that **no user-only Appwrite
/// request runs while the app is browsed as a guest**. The value is the cached
/// `AuthController.isLoggedIn`, which is primed at startup and flipped on
/// login / signup / logout — so guarded fetches start working the moment the
/// user signs in.
bool isUserLoggedIn() =>
    Get.isRegistered<AuthController>() && Get.find<AuthController>().isLoggedIn;

/// Coordinates user-scoped controller state across a login / logout.
abstract class SessionManager {
  const SessionManager._();

  /// Loads the app-wide user data immediately after a successful login/signup
  /// (the things visible right away on the dashboard: profile, cart badge,
  /// favourite hearts). Page-specific data — orders, addresses, loyalty,
  /// notifications — loads when the user opens those now-unlocked pages.
  static void loadUserData() {
    _safe(() => Get.find<ProfileController>().fetchUserProfile());
    _safe(() => Get.find<CartController>().getCartItems());
    _safe(() => Get.find<FavoritesController>().fetchFavorites());
  }

  /// Clears locally cached user data on logout so a guest never sees stale
  /// info (cart badge, favourite hearts, profile). Server data is untouched.
  static void clearUserData() {
    _safe(() => Get.find<ProfileController>().clearLocal());
    _safe(() => Get.find<CartController>().clearLocal());
    _safe(() => Get.find<FavoritesController>().clearLocal());
  }

  static void _safe(void Function() action) {
    try {
      action();
    } catch (_) {
      // A controller may not be registered yet — ignore; it will load its own
      // data (guarded by [isUserLoggedIn]) when first used.
    }
  }
}
