import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/settings_controller.dart';
import 'package:appwrite_user_app/app/controllers/splash_controller.dart';
import 'package:appwrite_user_app/app/controllers/update_controller.dart';
import 'package:appwrite_user_app/app/helper/dependencies.dart';
import 'package:appwrite_user_app/app/helper/notification_helper.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class Global {
  /// core setup
  static Future<Map<String, Map<String, String>>> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Firebase + local push are wired for mobile only. The web build skips them
    // (web would need its own Firebase web config + service worker), so the rest
    // of the app still boots in the browser.
    if (!kIsWeb) {
      try {
        if (GetPlatform.isAndroid) {
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: 'AIzaSyC6vjmdqwOy4Yz9SHQ-OLw5TgDTKTpNW-k',
              appId: '1:660606682501:android:5bb210b0bcaefc5f27b0ec',
              messagingSenderId: '660606682501',
              projectId: 'food-app-c2fe8',
            ),
          );
        } else {
          await Firebase.initializeApp();
        }

        final RemoteMessage? remoteMessage =
            await FirebaseMessaging.instance.getInitialMessage();
        if (remoteMessage != null) {
          print('===initial message: ${remoteMessage.data}');
        }
        await NotificationHelper.initialize(flutterLocalNotificationsPlugin);
        FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
      } catch (_) {}
    }

    if (!kIsWeb) {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }

    setSystemUi(isDarkMode: false);

    final languages = await initializeDependencies();

    // On web there is no native splash and the index.html loader already covers
    // engine boot, so run the splash's bootstrap (auth check + settings/module
    // resolution) here and point the router straight at the dashboard/login.
    // The first Flutter frame then lands on the real screen — no splash. Mobile
    // keeps its splash flow (startLocation stays at the splash route).
    if (kIsWeb) {
      await _bootstrapWebStartLocation();
    }

    return languages;
  }

  /// Resolves the web start location by doing the splash bootstrap up front.
  /// On any failure it leaves [AppRouter.startLocation] as the splash route,
  /// which has its own offline/retry handling as a fallback.
  static Future<void> _bootstrapWebStartLocation() async {
    try {
      // Prime the cached auth state so login-gated pages render correctly.
      await Get.find<AuthController>().isAlreadyLoggedIn();
      final settingsOk = await Get.find<SplashController>().fetchSettings();
      if (settingsOk) {
        // Block behind the update screen when the store requires a newer
        // version; otherwise open on the dashboard — guests browse products and
        // are asked to sign in only when an action requires it.
        final updateController = Get.find<UpdateController>();
        updateController.checkForForceUpdate(
          Get.find<SettingsController>().businessSetup,
        );
        AppRouter.startLocation = updateController.forceUpdateRequired
            ? AppRouter.forceUpdate
            : AppRouter.dashboard;
      }
    } catch (e) {
      debugPrint('Web bootstrap failed, falling back to splash: $e');
    }
  }

  static void setSystemUi({required bool isDarkMode}) {
    if (GetPlatform.isAndroid) {
      final systemUiOverlayStyle = SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDarkMode
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarColor: isDarkMode
            ? const Color(0xFF0B1220)
            : Colors.white,
        systemNavigationBarIconBrightness: isDarkMode
            ? Brightness.light
            : Brightness.dark,
      );
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
  }
}
