import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationHelper {

  static Future<void> initialize(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    // Local notifications + FCM listeners are mobile-only; bail out on web.
    if (kIsWeb) return;
    var androidInitialize = const AndroidInitializationSettings('notification_icon');
    var iOSInitialize = const DarwinInitializationSettings();
    var initializationsSettings = InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
    // Android-only, and null on iOS: force-unwrapping it threw before any
    // listener below was registered, so iOS had no notification handling.
    final android = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    // Created up front so pushes Firebase shows while the app is closed use
    // it too (it is the manifest's default channel) and pop up as banners.
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      'kikomart_notifications', 'KikoMart Notifications', importance: Importance.max,
    ));
    // iOS shows nothing while the app is open unless it is told to.
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );
    flutterLocalNotificationsPlugin.initialize(settings: initializationsSettings, onDidReceiveNotificationResponse: (NotificationResponse response) async {
      try{
        debugPrint('===payload: ${response.payload}');
      }catch (_) {}
      return;
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("onMessage: ${message.data}, message: ${message.notification} , title: ${message.notification?.title}, body: ${message.notification?.body}, ");

      NotificationHelper.showNotification(message, flutterLocalNotificationsPlugin);

    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("onOpenApp: ${message.data}");
      try{

      }catch (_) {}
    });
  }

  static Future<void> showNotification(RemoteMessage message, FlutterLocalNotificationsPlugin fln) async {
    if(!GetPlatform.isIOS && (message.notification != null || message.data.isNotEmpty)) {
      String? title;
      String? body;
      String? orderID;
      String? image;
      // NotificationBodyModel notificationBody = convertNotification(message.data);

      title = message.notification?.title ?? message.data['title'];
      body = message.notification?.body ?? message.data['body'];
      orderID = message.data['order_id'];
      // A data-only push has no title/body; force-unwrapping it threw here.
      if (title == null && body == null) return;
      image = '';
      // (message.data['image'] != null && message.data['image'].isNotEmpty)
          // ? message.data['image'].startsWith('http') ? message.data['image']
          // : '${AppUrls.baseUrl}/storage/app/public/notification/${message.data['image']}' : null;

      debugPrint('==========message : $title ,  $image');

      debugPrint('==========message 2: $title ,  $body');
      await showBigTextNotification(title, body ?? '', orderID, null, fln);
    }
  }

  static Future<void> showTextNotification(String title, String body, String orderID, Map<String, String>? notificationBody, FlutterLocalNotificationsPlugin fln) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'kikomart_alerts', 'KikoMart Alerts', playSound: true,
      importance: Importance.max, priority: Priority.max,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(id: 0, title: title, body: body, notificationDetails: platformChannelSpecifics, payload: notificationBody != null ? null : null);
  }

  static Future<void> showBigTextNotification(String? title, String body, String? orderID, Map<String, String>? notificationBody, FlutterLocalNotificationsPlugin fln) async {
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body, htmlFormatBigText: true,
      contentTitle: title, htmlFormatContentTitle: true,
    );
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'kikomart_notifications', 'KikoMart Notifications', importance: Importance.max,
      styleInformation: bigTextStyleInformation, priority: Priority.max, playSound: true,
      // sound: const RawResourceAndroidNotificationSound('notification'),
    );
    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(id: 0, title: title, body: body, notificationDetails: platformChannelSpecifics, payload: notificationBody != null ? null : null);
  }

}

@pragma('vm:entry-point')
Future<dynamic> myBackgroundMessageHandler(RemoteMessage message) async {
  // await Firebase.initializeApp();
  debugPrint("onBackground: ${message.data}");
}