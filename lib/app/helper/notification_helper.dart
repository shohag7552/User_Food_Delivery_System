import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class NotificationHelper {

  static Future<void> initialize(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
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

      if(message.data['type'] == 'chatting' && message.data['user_id'] != null && Get.currentRoute == '/ChattingScreen') {
        print('===chatting screen open : ${message.data['user_id']}');
        // Get.find<ChatController>().getMessageList(offset: 1, id: message.data['user_id']);
      } else {
        NotificationHelper.showNotification(message, flutterLocalNotificationsPlugin);
      }

    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("onOpenApp: ${message.data}");
      try{

      }catch (_) {}
    });
  }

  static Future<void> showNotification(RemoteMessage message, FlutterLocalNotificationsPlugin fln) async {
    if(!GetPlatform.isIOS && message.data.isNotEmpty) {
      String? title;
      String? body;
      String? orderID;
      String? image;
      // NotificationBodyModel notificationBody = convertNotification(message.data);

      title = message.data['title'];
      body = message.data['body'];
      orderID = message.data['order_id'];
      image = '';
      // (message.data['image'] != null && message.data['image'].isNotEmpty)
          // ? message.data['image'].startsWith('http') ? message.data['image']
          // : '${AppUrls.baseUrl}/storage/app/public/notification/${message.data['image']}' : null;

      print('==========message : $title ,  $image');

      if(image != null && image.isNotEmpty) {
        try{
          await showBigPictureNotificationHiddenLargeIcon(title, body, orderID, null, image, fln);
        }catch(e) {
          await showBigTextNotification(title, body!, orderID, null, fln);
        }
      }else {
        print('==========message 2: $title ,  $body');
        await showBigTextNotification(title, body!, orderID, null, fln);
      }
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

  static Future<void> showBigPictureNotificationHiddenLargeIcon(
      String? title, String? body, String? orderID, Map<String, String>? notificationBody, String image, FlutterLocalNotificationsPlugin fln,
      ) async {
    final String largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
    final String bigPicturePath = await _downloadAndSaveFile(image, 'bigPicture');
    final BigPictureStyleInformation bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath), hideExpandedLargeIcon: true,
      contentTitle: title, htmlFormatContentTitle: true,
      summaryText: body, htmlFormatSummaryText: true,
    );
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'stackfood', 'stackfood',
      largeIcon: FilePathAndroidBitmap(largeIconPath), priority: Priority.max, playSound: true,
      styleInformation: bigPictureStyleInformation, importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(id: 0, title: title, body: body, notificationDetails: platformChannelSpecifics, payload: notificationBody != null ? null : null);
  }

  static Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = Directory('print');//await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

}

@pragma('vm:entry-point')
Future<dynamic> myBackgroundMessageHandler(RemoteMessage message) async {
  // await Firebase.initializeApp();
  debugPrint("onBackground: ${message.data}");
}