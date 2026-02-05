import 'dart:io';
import 'package:appwrite_user_app/app/helper/dependencies.dart';
import 'package:appwrite_user_app/app/helper/notification_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class Global {
  /// core setup
  static Future<Map<String, Map<String, String>>> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    // HttpOverrides.global = MyHttpOverrides();

    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyC6vjmdqwOy4Yz9SHQ-OLw5TgDTKTpNW-k',
        appId: '1:660606682501:android:5bb210b0bcaefc5f27b0ec',
        messagingSenderId: '660606682501',
        projectId: 'food-app-c2fe8',
      ),
    );
    try{
      final RemoteMessage? remoteMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (remoteMessage != null) {
        print('===initial message: ${remoteMessage.data}');
        // body = NotificationHelper.convertNotification(remoteMessage.data);
      }
      await NotificationHelper.initialize(flutterLocalNotificationsPlugin);
      FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
    }catch(_){}


    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    setSystemUi();

    return await initializeDependencies();
  }

  static void setSystemUi() {
    if (GetPlatform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      );
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
  }
}



class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}