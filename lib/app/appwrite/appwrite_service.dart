import 'dart:convert';
import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:image_picker/image_picker.dart';

class AppwriteService {
  late final Client client;
  late final TablesDB databases;
  late final Account account;
  late final Storage storage;
  late final Functions functions;
  late final Teams teams;
  late final Messaging messaging;
  static final AppwriteService _instance = AppwriteService._internal();

  factory AppwriteService() => _instance;

  AppwriteService._internal() {
    client = Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);

    databases = TablesDB(client);
    account = Account(client);
    storage = Storage(client);
    functions = Functions(client);
    teams = Teams(client);
    messaging = Messaging(client);
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
      log(
        '====> database: ${AppwriteConfig.databaseId}, tableId: $collectionId, rowId: $documentId and  with data: $data',
      );
      // return await databases.createRow(databaseId: databaseId, tableId: tableId, rowId: rowId, data: data)
      return await databases.createRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: collectionId,
        rowId: documentId ?? ID.unique(),
        data: data,
        permissions: [Permission.write(Role.user(user.$id))],
      );
    } on AppwriteException catch (e) {
      log('===> AppwriteException: ${e.response}');
      rethrow;
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  Future<Row> getDocument({
    required String tableId,
    required String rowId,
    List<String>? queries,
  }) async {
    try {
      log(
        '====> listDocuments in database: ${AppwriteConfig.databaseId}, tableId: $tableId, rowId: $rowId, with queries: $queries',
      );

      return await databases.getRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: tableId,
        rowId: rowId,
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

  Future<RowList> listTable({
    required String tableId,
    List<String>? queries,
  }) async {
    try {
      log(
        '====> listDocuments in database: ${AppwriteConfig.databaseId}, tableId: $tableId, with queries: $queries',
      );

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
      log(
        '====> listDocuments in database: ${AppwriteConfig.databaseId}, tableId: $tableId, rowId: $rowId with data: $data',
      );

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
      log(
        '====> listDocuments in database: ${AppwriteConfig.databaseId}, tableId: $collectionId, rowId: $rowId',
      );

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

      return AppWriteResponse(
        code: 200,
        message: 'user create successfully',
        response: user,
      );
    } on AppwriteException catch (e) {
      log('===> AppWriteException: ${e.code} ${e.message} ${e.response}');
      return AppWriteResponse(
        code: e.code ?? 404,
        message: e.message ?? 'connection issue',
        response: e.response,
      );
    } catch (e) {
      log('Signup error: $e');
      return AppWriteResponse(
        code: 000,
        message: 'connection issue',
        response: e,
      );
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

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    log('====> signIn request- email:$email, password:$password');

    try {
      final response = await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      log(
        '====> Login successful for: $email // response is: ${response.userId}',
      );
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
      final target = await account.createPushTarget(
        targetId: ID.unique(), // Generates a unique ID for this phone
        identifier: fcmToken, // The actual FCM token
        providerId: AppwriteConfig
            .messagingProviderId, // Get this from Messaging > Providers
      );
      print("✅ Device registered for notifications!");

      await messaging.createSubscriber(
        topicId: AppwriteConfig
            .topicId, // Use the topic you created in Appwrite console
        subscriberId: ID.unique(),
        targetId: target.$id, // Link the device target we just created
      );
      print("✅ Subscriber created for topic 'all_users'!");
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

  Future<void> updatePassword({
    required String password,
    required String oldPassword,
  }) async {
    await account.updatePassword(password: password, oldPassword: oldPassword);
  }

  Future<String?> uploadImage(XFile file) async {
    try {
      final result = await storage.createFile(
        bucketId: AppwriteConfig.postsBucketId, // Create bucket in Appwrite console
        fileId: ID.unique(), // Auto-generate unique ID
        file: InputFile.fromPath(
          path: file.path,
          filename: file.path.split('/').last,
        ),
        permissions: [Permission.read(Role.any())],
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

  Future<void> notifyOrderPlaced(String currentUserId, String orderId) async {
    // 1. Notify the customer that their order was received
    try {
      await functions.createExecution(
        functionId: AppwriteConfig.notificationFunctionId,
        body: jsonEncode({
          "type": "order_update",
          "userId": currentUserId,
          "title": "Order Placed Successfully! 🍔",
          "message": "We will deliver your order #$orderId soon.",
          "orderId": orderId,
        }),
      );
      print("✅ Customer order notification sent");
    } catch (e) {
      print("❌ Failed to send customer notification: $e");
    }

    // 2. Notify the store admin that a new order has been placed
    try {
      await functions.createExecution(
        functionId: AppwriteConfig.notificationFunctionId,
        body: jsonEncode({
          "type": "broadcast",
          "topic": AppwriteConfig.storeAdminTopicId,
          "title": "New Order! 🛒",
          "message": "Order #$orderId has been placed. Tap to view.",
          "orderId": orderId,
        }),
      );
      print("✅ Store admin order notification sent");
    } catch (e) {
      print("❌ Failed to send store admin notification: $e");
    }
  }

  Future<Map<String, dynamic>?> requestStripPayment({
    required int amount,
    required String currency,
    required String userEmail,
  }) async {
    // Ensure you have initialized 'client' somewhere globally or pass it in
    // Functions functions = Functions(client);

    try {
      print("====> Requesting Server to send Stripe payment...");

      /// Executing the serverless function directly via the Appwrite SDK
      final execution = await functions.createExecution(
        functionId: AppwriteConfig.stripePaymentFunctionId,
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
          'email': userEmail,
        }),
        // body: jsonEncode({'amount': 1500}), // $15.00
      );

      if (execution.status == ExecutionStatus.completed) {
        print("✅ Stripe payment request sent to server!");
        return jsonDecode(execution.responseBody);
      } else {
        print("⚠️ Function failed: ${execution.responseBody}");
        return null;
      }
    } catch (e) {
      print("❌ Failed to trigger Stripe payment function: $e");
      return null;
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

extension AppwritePasswordRecovery on AppwriteService {
  Future<void> requestPasswordResetOtp({required String email}) async {
    await _executeForgotPasswordOtpFunction(
      body: {'action': 'request_otp', 'email': email},
    );
  }

  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String password,
  }) async {
    await _executeForgotPasswordOtpFunction(
      body: {
        'action': 'reset_password',
        'email': email,
        'otp': otp,
        'password': password,
      },
    );
  }

  Future<Map<String, dynamic>> _executeForgotPasswordOtpFunction({
    required Map<String, dynamic> body,
  }) async {
    try {
      final execution = await functions.createExecution(
        functionId: AppwriteConfig.forgotPasswordOtpFunctionId,
        body: jsonEncode(body),
      );

      final responseBody = execution.responseBody;
      final parsed = responseBody.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(responseBody) as Map<String, dynamic>;

      if (execution.status != ExecutionStatus.completed ||
          parsed['success'] != true) {
        throw Exception(parsed['message'] ?? 'OTP request failed.');
      }

      return parsed;
    } on AppwriteException catch (e) {
      log('===> AppWriteException: ${e.code} ${e.message} ${e.response}');
      rethrow;
    } catch (e) {
      log('Forgot password OTP function error: $e');
      rethrow;
    }
  }
}

class AppWriteResponse {
  final int code;
  final String message;
  final dynamic response;

  AppWriteResponse({
    required this.code,
    required this.message,
    required this.response,
  });
}
