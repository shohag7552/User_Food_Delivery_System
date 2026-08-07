import 'package:appwrite/models.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/modules/auth/domain/repository/auth_repo_interface.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository implements AuthRepoInterface {
  final SharedPreferences sharedPreferences;
  final AppwriteService appwriteService;

  AuthRepository({
    required this.sharedPreferences,
    required this.appwriteService,
  });

  // @override
  // Future<bool> auth(String email, String password) async {
  //   // TODO: Implement actual auth logic with Appwrite
  //   // For now, return a placeholder
  //   return true;
  // }

  @override
  Future<void> logout() async {
    // TODO: Implement actual logout logic
    // Remembered credentials are intentionally left alone here — the whole
    // point of "remember me" is that they outlive the session.
    return await appwriteService.signOut();
  }

  @override
  Future<void> saveRememberedCredentials({
    required String email,
    required String password,
  }) async {
    await sharedPreferences.setBool(Constants.rememberMe, true);
    await sharedPreferences.setString(Constants.rememberedEmail, email);
    await sharedPreferences.setString(Constants.rememberedPassword, password);
  }

  @override
  Future<void> clearRememberedCredentials() async {
    await sharedPreferences.remove(Constants.rememberMe);
    await sharedPreferences.remove(Constants.rememberedEmail);
    await sharedPreferences.remove(Constants.rememberedPassword);
  }

  @override
  ({String email, String password})? getRememberedCredentials() {
    if (sharedPreferences.getBool(Constants.rememberMe) != true) return null;

    final email = sharedPreferences.getString(Constants.rememberedEmail);
    final password = sharedPreferences.getString(Constants.rememberedPassword);
    if (email == null || password == null) return null;

    return (email: email, password: password);
  }

  @override
  Future<void> closeAccount() async {
    // 1. Flag the user row inactive while the session is still valid — the
    //    admin panel reads `is_active`. Non-fatal if it fails; we still block.
    final user = await appwriteService.getCurrentUser();
    if (user != null) {
      try {
        await appwriteService.updateTable(
          tableId: AppwriteConfig.usersCollection,
          rowId: user.$id,
          data: {'is_active': false},
        );
      } catch (_) {
        // Non-fatal: proceed to block the auth account regardless.
      }
    }

    // 2. Permanently block the Appwrite auth account (server-side). After this,
    //    login is rejected until an admin restores the account.
    await appwriteService.blockCurrentAccount();

    // 3. Best-effort local session teardown — deleting the session on an
    //    already-blocked account may 401, so ignore any failure here.
    try {
      await appwriteService.signOut();
    } catch (_) {}
  }

  @override
  Future<bool> loginUser(String email, String password) async {
    try {
      // Attempt to sign in with Appwrite
      String? userId = await appwriteService.signIn(
        email: email,
        password: password,
      );

      if (userId != null) {
        // Best-effort push-notification registration — the session already
        // exists at this point, so a failure here (e.g. FCM/web issues) must
        // never turn a successful login into a failure.
        try {
          String? fcmToken = await _getDeviceToken();
          await appwriteService.updateTable(
            tableId: AppwriteConfig.usersCollection,
            rowId: userId,
            data: {'fcm_token': fcmToken},
          );

          if (fcmToken != null) {
            await appwriteService.setupMessaging(fcmToken: fcmToken);
          }
        } catch (e) {
          print('Post-login device registration skipped: $e');
        }
      }

      // If successful, show success message
      print('Login successful for: $userId');
      return userId != null;
    } catch (e) {
      // Handle login errors
      String errorMessage = 'Login failed. Please try again.';

      if (e.toString().contains('Invalid credentials') ||
          e.toString().contains('401') ||
          e.toString().contains('Invalid email or password')) {
        errorMessage = 'Invalid email or password.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.toString().contains('User not found')) {
        errorMessage = 'No account found with this email.';
      }

      print('Login error: $e');
      // Show error toast to user
      // Note: The toast will be shown by the controller/UI layer
      customToster(errorMessage);
      return false;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return await appwriteService.isLoggedIn();
  }

  @override
  Future<bool> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    // 1. Create Appwrite account
    AppWriteResponse data = await appwriteService.signUp(
      email: email,
      password: password,
      name: name,
    );

    print('Signup Response: ${data.response}');
    // 2. Create user document in users collection
    if (data.response.$id.isEmpty) {
      return false;
    }
    String? fcmToken = await _getDeviceToken();
    await appwriteService.createUserDocument(
      userId: data.response.$id,
      name: name,
      email: email,
      phone: phone,
      fcmToken: fcmToken,
    );

    if (fcmToken != null) {
      await appwriteService.setupMessaging(fcmToken: fcmToken);
    }

    return true;
  }

  @override
  Future<User?> getCurrentUser() async {
    return await appwriteService.getCurrentUser();
  }

  @override
  Future<bool> requestPasswordResetOtp(String email) async {
    try {
      await appwriteService.requestPasswordResetOtp(
        email: email.trim().toLowerCase(),
      );
      return true;
    } catch (e) {
      final message = e.toString().contains('Function with the requested ID could not be found')
          ? 'Forgot password OTP function is not deployed yet.'
          : 'Could not send OTP right now. Please try again.';
      customToster(message, isSuccess: false);
      return false;
    }
  }

  @override
  Future<bool> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      await appwriteService.resetPasswordWithOtp(
        email: email.trim().toLowerCase(),
        otp: otp.trim(),
        password: password,
      );
      return true;
    } catch (e) {
      final message = e.toString().contains('expired')
          ? 'OTP expired. Please request a new one.'
          : e.toString().contains('Invalid OTP')
          ? 'Invalid OTP. Please try again.'
          : 'Could not reset password. Please try again.';
      customToster(message, isSuccess: false);
      return false;
    }
  }

  Future<String?> _getDeviceToken() async {
    // Web push needs a VAPID key + service worker this app doesn't configure,
    // and getToken() throws without them. Skip FCM on web entirely.
    if (kIsWeb) return null;
    try {
      // 1. Request Permission
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Get the Token
        String? token = await messaging.getToken();

        if (token != null) {
          print('==> FCM Token: $token');
          return token;
        }
      }
    } catch (e) {
      // FCM is a non-critical add-on; never let it fail auth.
      print('FCM token unavailable: $e');
    }
    return null;
  }

  @override
  Future<bool> updatePassword({
    required String password,
    required String oldPassword,
  }) async {
    try {
      await appwriteService.updatePassword(
        password: password,
        oldPassword: oldPassword,
      );
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
