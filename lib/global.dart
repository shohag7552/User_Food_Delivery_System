import 'package:appwrite_user_app/app/helper/dependencies.dart';
import 'package:appwrite_user_app/app/helper/notification_helper.dart';
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

    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    setSystemUi(isDarkMode: false);

    return await initializeDependencies();
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
