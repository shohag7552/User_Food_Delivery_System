// import 'dart:convert';
// import 'package:dart_appwrite/dart_appwrite.dart';
// import 'package:googleapis_auth/auth_io.dart';
// import 'package:http/http.dart' as http;
//
// Future<dynamic> start(final context) async {
//   final client = Client()
//       .setEndpoint('https://sgp.cloud.appwrite.io/v1')
//       .setProject(context.req.variables['694d7ed80012589bdb9c'])
//       .setKey(context.req.variables['standard_94c9a3d62a86353f64c689846a4c8643086c533cebdcd99d1f6d38cc7d5cc91672e967c41f0092cfd47a11d0b84cb046ffbf19087b63ad8eab7f0b3454d00a37f6a0f37859d7c7ec36a2a96d5b5ec41e08dd81bc27bb2f5a2d78e3ce88e1f4bec6cd2e3c05ed016628a0e100e52e038146309b4be98c88598a6fa0c990f10188']);
//
//   final db = Databases(client);
//
//   try {
//     // 1. Parse the Event Data (The New Order)
//     // When triggered by Event, context.req.body contains the document data
//     final order = jsonDecode(context.req.body);
//     final customerId = order['customer_id']; // Ensure this matches your schema
//
//     // 2. Get the Customer's FCM Token
//     final userDoc = await db.getDocument(
//       databaseId: context.req.variables['DATABASE_ID']!,
//       collectionId: 'users',
//       documentId: customerId,
//     );
//
//     final fcmToken = userDoc.data['fcm_token'];
//
//     if (fcmToken == null || fcmToken.isEmpty) {
//       context.log('No FCM token found for user $customerId');
//       return context.res.json({'status': 'skipped', 'message': 'No token'});
//     }
//
//     // 3. Authenticate with Firebase
//     // Paste your Service Account JSON into an Environment Variable named 'FCM_JSON'
//     final serviceAccount = ServiceAccountCredentials.fromJson(
//         context.req.variables['FCM_JSON']!
//     );
//
//     final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
//     final authClient = await clientViaServiceAccount(serviceAccount, scopes);
//
//     // 4. Construct the Message
//     final projectId = serviceAccount.clientId;
//     final notification = {
//       "message": {
//         "token": fcmToken,
//         "notification": {
//           "title": "Order Received! 🍳",
//           "body": "Your order #{order['id'].substring(0,5)} has been placed successfully."
//           // "body": "Your order #${order['$id'].substring(0,5)} has been placed successfully."
//         },
//         "data": {
//           "click_action": "FLUTTER_NOTIFICATION_CLICK",
//           "order_id": '234543',
//           // "order_id": order['$id'],
//           "status": "pending"
//         }
//       }
//     };
//
//     // 5. Send to Firebase
//     final response = await authClient.post(
//       Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode(notification),
//     );
//
//     authClient.close();
//
//     if (response.statusCode == 200) {
//       return context.res.json({'status': 'success', 'message': 'Notification sent'});
//     } else {
//       context.error("FCM Error: ${response.body}");
//       return context.res.json({'status': 'error', 'body': response.body}, statusCode: 500);
//     }
//
//   } catch (e) {
//     context.error("Function failed: $e");
//     return context.res.json({'status': 'error', 'message': e.toString()}, statusCode: 500);
//   }
// }