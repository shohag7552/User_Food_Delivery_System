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
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!.requestNotificationsPermission();
    flutterLocalNotificationsPlugin.initialize(settings: initializationsSettings, onDidReceiveNotificationResponse: (NotificationResponse response) async {
      try{
        print('===payload: ${response.payload}');
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
      image = '';
      // (message.data['image'] != null && message.data['image'].isNotEmpty)
          // ? message.data['image'].startsWith('http') ? message.data['image']
          // : '${AppUrls.baseUrl}/storage/app/public/notification/${message.data['image']}' : null;

      print('==========message : $title ,  $image');

      print('==========message 2: $title ,  $body');
      await showBigTextNotification(title, body!, orderID, null, fln);
    }
  }

  static Future<void> showTextNotification(String title, String body, String orderID, Map<String, String>? notificationBody, FlutterLocalNotificationsPlugin fln) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'stackfood', 'stackfood', playSound: true,
      importance: Importance.max, priority: Priority.max, sound: RawResourceAndroidNotificationSound('notification'),
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
      'loklagbe', 'loklagbe', importance: Importance.max,
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