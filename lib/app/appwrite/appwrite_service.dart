import 'dart:convert';
import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:dart_appwrite/dart_appwrite.dart' as dart_appwrite;

class AppwriteService {
  late final Client client;
  late final TablesDB databases;
  late final Account account;
  late final Storage storage;
  late final Teams teams;
  // late final dart_appwrite.Messaging messaging;
  static final AppwriteService _instance = AppwriteService._internal();

  factory AppwriteService() => _instance;

  AppwriteService._internal() {
    // final dartClient = dart_appwrite.Client()
    //     .setEndpoint(AppwriteConfig.endpoint)
    //     .setProject(AppwriteConfig.projectId);
    client = Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);

    databases = TablesDB(client);
    account = Account(client);
    storage = Storage(client);
    teams = Teams(client);
    // messaging = dart_appwrite.Messaging(dartClient);
  }

  // Database operations
  Future<Row> createRow({
    required String collectionId,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {

    try {
      final user = await account.get();
      log('====> database: ${AppwriteConfig.databaseId}, tableId: $collectionId, rowId: $documentId and  with data: $data');
      // return await databases.createRow(databaseId: databaseId, tableId: tableId, rowId: rowId, data: data)
      return await databases.createRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: collectionId,
        rowId: documentId ?? ID.unique(),
        data: data,
        permissions: [
          Permission.write(Role.user(user.$id)),
        ],
      );
    } on AppwriteException catch (e) {
      log('===> AppwriteException: ${e.response}');
      rethrow;
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  Future<Row> getDocument({
    required String collectionId,
    required String documentId,
    List<String>? queries,
  }) async {
    return await databases.getRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: collectionId,
      rowId: documentId,
      queries: queries,
    );
  }

  Future<RowList> listTable({required String tableId, List<String>? queries}) async {
    try {
      log('====> listDocuments in database: ${AppwriteConfig.databaseId}, tableId: $tableId, with queries: $queries');

      return await databases.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: tableId,
        queries: queries ?? [],
      );

    } on AppwriteException catch (e) {
      log('===> AppWriteException: ${e.code} ${e.message} ${e.response}');
      rethrow;
    } catch (e) {
      log('Upload error: $e');
      rethrow;
    }
  }

  Future<Row> updateTable({
    required String tableId,
    required String rowId,
    required Map<String, dynamic> data,
  }) async {
    try {
      log('====> listDocuments in database: ${AppwriteConfig.databaseId}, tableId: $tableId, rowId: $rowId with data: $data');

      return await databases.updateRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: tableId,
        rowId: rowId,
        data: data,
      );

    } on AppwriteException catch (e) {
      log('===> AppWriteException: ${e.code} ${e.message} ${e.response}');
      rethrow;
    } catch (e) {
      log('Upload error: $e');
      rethrow;
    }

  }

  Future<void> deleteRow({
    required String collectionId,
    required String rowId,
  }) async {
    try {
      log('====> listDocuments in database: ${AppwriteConfig.databaseId}, tableId: $collectionId, rowId: $rowId');

      return await databases.deleteRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: collectionId,
        rowId: rowId,
      );

    } on AppwriteException catch (e) {
      log('===> AppWriteException: ${e.code} ${e.message} ${e.response}');
      rethrow;
    } catch (e) {
      log('Upload error: $e');
      rethrow;
    }
  }

  /// Authentication

  Future<User?> getCurrentUser() async {
    try {
      return await account.get();

    } on AppwriteException catch (e) {
      log('===> AppWriteException: ${e.code} ${e.message} ${e.response}');
      return null;
    } catch (e) {
      log('Upload error: $e');
      return null;
    }
  }

  Future<AppWriteResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    log('====> SignUp request- email:$email, name:$name, password:$password');
    try {
      final user = await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      print('====> Signup successful for user: ${user.$id}');
      // Automatically create a session after signup
      await account.createEmailPasswordSession(email: email, password: password);
      
      return AppWriteResponse(code: 200, message: 'user create successfully', response: user);
    } on AppwriteException catch (e) {
      log('===> AppWriteException: ${e.code} ${e.message} ${e.response}');
      return AppWriteResponse(code: e.code??404, message: e.message??'connection issue', response: e.response);
    } catch (e) {
      log('Signup error: $e');
      return AppWriteResponse(code: 000, message: 'connection issue', response: e);
    }
  }

  Future<Row> createUserDocument({
    required String userId,
    required String name,
    required String email,
    required String phone,
    String role = 'customer',
    String? fcmToken,
  }) async {
    try {
      log('====> Creating user document for: $email');

      return await databases.createRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.usersCollection,
        rowId: userId,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'role': role,
          'wallet_balance': 0.0,
          'fcm_token': fcmToken,
          // 'is_active': true,
        },
        // permissions: [
        //   Permission.read(Role.user(userId)),
        //   Permission.write(Role.user(userId)),
        //   Permission.update(Role.user(userId)),
        //   // Permission.read(Role.team('admin_team')),
        //   // Permission.update(Role.team('admin_team')),
        // ],
      );
    } on AppwriteException catch (e) {
      log('===> AppWriteException: ${e.code} ${e.message} ${e.response}');
      rethrow;
    } catch (e) {
      log('Create user document error: $e');
      rethrow;
    }
  }

  Future<String?> signIn({required String email, required String password}) async {
    log('====> signIn request- email:$email, password:$password');

    try {
     final response = await account.createEmailPasswordSession(email: email, password: password);
      log('====> Login successful for: $email // response is: ${response.userId}');
      return response.userId;
    } on AppwriteException catch (e) {
      log('===> AppWriteException: ${e.code} ${e.message} ${e.response}');
      customToster('${e.message}');
      return null;
    } catch (e) {
      log('Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<void> setupMessaging({required String fcmToken}) async {
    log('====> setupMessaging request- FcmToken:$fcmToken');

    try {
      // 2. Register this device as a "Target" in Appwrite
      // This automatically saves the token securely in Appwrite's internal system.
      await account.createPushTarget(
          targetId: ID.unique(), // Generates a unique ID for this phone
          identifier: fcmToken,  // The actual FCM token
          providerId: AppwriteConfig.messagingProviderId, // Get this from Messaging > Providers
      );

      print("✅ Device registered for notifications!");
    } on AppwriteException catch (e) {
      print("❌ Failed to register device: ${e.message}");
    } catch (e) {
      log('Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      // Step 1: Check if Session Exists
      // If this fails (throws error), user is not logged in at all.
      print('=====> Checking current user session...');
      // await account.get();
      User? user = await getCurrentUser();
      if (user != null && user.email.isNotEmpty) {
        print('===========here=====1');
        return true;
      } else {
        print('===========here=====2');
        return false;
      }

    } catch (e) {
      print("❌ User is not logged in.");
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await account.deleteSession(sessionId: 'current');

    } on AppwriteException catch (e) {
      log('===> AppWriteException: ${e.code} ${e.message} ${e.response}');
    } catch (e) {
      log('Upload error: $e');
    }
  }

  Future<void> updateName({required String name}) async {
    await account.updateName(name: name);
  }

  Future<void> updatePassword({required String password, required String oldPassword}) async {
    await account.updatePassword(password: password, oldPassword: oldPassword);
  }

  Future<String?> uploadImage(XFile file) async {
    try {
      final result = await storage.createFile(
        bucketId: AppwriteConfig.postsBucketId,     // Create bucket in Appwrite console
        fileId: ID.unique(),            // Auto-generate unique ID
        file: InputFile.fromPath(
          path: file.path,
          filename: file.path.split('/').last,
        ),
        permissions: [Permission.read(Role.any()) ],
      );

      // Return uploaded file ID
      log("Upload successful: ${result.$id} // ${result.toMap()}");
      // Construct a direct view/preview URL (public if bucket/file perms allow it)
      final fileUrl = '${AppwriteConfig.endpoint}/storage/buckets/${AppwriteConfig.postsBucketId}/files/${result.$id}/view?project=${AppwriteConfig.projectId}';

      log(fileUrl);
      return fileUrl;
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  Future<void> deleteImage(String fileId) async {
    try {
      await storage.deleteFile(
        bucketId: AppwriteConfig.postsBucketId,
        fileId: fileId,
      );
      print("Image deleted from storage.");
    } catch (e) {
      print("Delete error: $e");
    }
  }

  // Future<bool> sendNotificationToUser({required String userId, required String title, required String message}) async {
  //   try {
  //
  //     print("====> Sending notification to userId: $userId with title: $title and message: $message");
  //     // 🚀 THE NEW WAY: Use Appwrite Messaging API
  //     // We don't need to look up tokens manually. We just say "Send to this User ID".
  //     await messaging.createPush(
  //       messageId: ID.unique(),
  //       title: "Order Received! 🍳",
  //       body: "Your order #123 is being prepared.",
  //       topics: [], // Leave empty to target specific users
  //       users: [userId], // Appwrite finds the tokens for this user automatically
  //       draft: false,
  //       targets: [
  //         userId, // Target this specific user
  //       ],
  //       data: {
  //         "title": title,
  //         "body": message,
  //         "order_id": "1223"
  //       },
  //     );
  //
  //     print("✅ Notification sent to user $userId!");
  //     return true;
  //
  //   } catch (e) {
  //     print("Notification error: $e");
  //     return false;
  //   }
  // }

  Future<bool> sendNotificationToUser({required String userId, required String title, required String message}) async {
    // Ensure you have initialized 'client' somewhere globally or pass it in
    Functions functions = Functions(client);

    try {
      print("====> Requesting Server to send notification...");

      // 🚀 CORRECT WAY: Trigger the Appwrite Function
      // The function has the API Key with permission to send messages.
      final execution = await functions.createExecution(
        functionId: 'place_order', // Use your deployed Function ID here
        body: jsonEncode({
          "userId": userId,
          "title": title,
          "message": message,
          "orderId": "1223" // Example order ID
        }),
      );

      if (execution.status == 'completed') {
        print("✅ Notification request sent to server!");
        return true;
      } else {
        print("⚠️ Function failed: ${execution.responseBody}");
        return false;
      }

    } catch (e) {
      print("❌ Failed to trigger notification: $e");
      return false;
    }
  }

  // String getImageUrl(String fileId) {
  //   return storage.getFileView(
  //     bucketId: "YOUR_BUCKET_ID",
  //     fileId: fileId,
  //   ).href;
  // }


// Future<Map<String, dynamic>?> uploadXFileAndSave(XFile xfile, {String? userId}) async {
  //   try {
  //     // Build InputFile correctly for web vs mobile
  //     late InputFile input;
  //     if (kIsWeb) {
  //       final bytes = await xfile.readAsBytes(); // required on web
  //       input = InputFile.fromBytes(bytes: bytes, filename: xfile.name);
  //     } else {
  //       // mobile/desktop: path is available
  //       if (xfile.path == null || xfile.path!.isEmpty) {
  //         throw Exception('Invalid file path on non-web platform');
  //       }
  //       input = InputFile.fromPath(path: xfile.path!, filename: xfile.name);
  //     }
  //
  //     // Upload file
  //     final uploadedFile = await storage.createFile(
  //       bucketId: BUCKET_ID,
  //       fileId: ID.unique(),
  //       file: input,
  //       // Optional: set file-level permissions; remove or adjust as needed
  //       // permissions: [ Permission.read(Role.any()) ],
  //     );
  //
  //     final fileId = uploadedFile.$id;
  //
  //     // Construct a direct view/preview URL (public if bucket/file perms allow it)
  //     final fileUrl =
  //         'https://cloud.appwrite.io/v1/storage/buckets/$BUCKET_ID/files/$fileId/view?project=$PROJECT_ID';
  //     // If you use a custom endpoint, replace cloud.appwrite.io with your endpoint domain.
  //
  //     // Save metadata to database (optional)
  //     final doc = await databases.createDocument(
  //       databaseId: DATABASE_ID,
  //       collectionId: COLLECTION_ID,
  //       documentId: ID.unique(),
  //       data: {
  //         'fileId': fileId,
  //         'fileName': xfile.name,
  //         'fileUrl': fileUrl,
  //         'uploaderId': userId ?? 'anonymous',
  //         'createdAt': DateTime.now().toIso8601String(),
  //       },
  //     );
  //
  //     return {
  //       'fileId': fileId,
  //       'fileUrl': fileUrl,
  //       'document': doc,
  //     };
  //   } on AppwriteException catch (e) {
  //     // Appwrite-specific errors give helpful fields
  //     print('AppwriteException: ${e.code} ${e.message} ${e.response}');
  //     return null;
  //   } catch (e) {
  //     print('Upload error: $e');
  //     return null;
  //   }
  // }
}

class AppWriteResponse{
  final int code;
  final String message;
  final dynamic response;

  AppWriteResponse({
    required this.code,
    required this.message,
    required this.response,
  });
}