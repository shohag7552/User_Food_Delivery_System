import 'dart:convert';
import 'package:dart_appwrite/dart_appwrite.dart';

Future<dynamic> start(final context) async {
  // 1. Setup Client with API Key (This provides the "Admin" permissions)
  final client = Client()
      .setEndpoint('https://sgp.cloud.appwrite.io/v1')
      .setProject(context.req.variables['APPWRITE_FUNCTION_PROJECT_ID'])
      .setKey(context.req.variables['APPWRITE_API_KEY']);

  final messaging = Messaging(client);

  try {
    context.log('Function Triggered');

    // 2. Parse Data sent from Flutter
    if (context.req.bodyRaw.isEmpty) {
      return context.res.json({'status': 'error', 'message': 'Body is empty'});
    }

    final payload = jsonDecode(context.req.bodyRaw);
    final userId = payload['userId'];
    final title = payload['title'] ?? 'Order Update';
    final body = payload['message'] ?? 'You have a new update';
    final orderId = payload['orderId'] ?? '123';

    // 3. Send Notification (Server-to-Client)
    // The server IS allowed to do this because it uses the API Key
    await messaging.createPush(
      messageId: ID.unique(),
      title: title,
      body: body,
      users: [userId], // Appwrite automatically finds the tokens for this User ID
      data: {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "order_id": orderId,
        "title": title,
        "body": body
      },
    );

    return context.res.json({'status': 'success', 'message': 'Notification sent to $userId'});

  } catch (e) {
    context.error("Error: $e");
    return context.res.json({'status': 'error', 'message': e.toString()}, statusCode: 500);
  }
}