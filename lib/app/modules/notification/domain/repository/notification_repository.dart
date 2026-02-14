import 'dart:developer';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/models/notification_model.dart';
import 'package:appwrite_user_app/app/modules/notification/domain/repository/notification_repo_interface.dart';
import 'package:appwrite/models.dart' as models;

class NotificationRepository implements NotificationRepoInterface {
  final AppwriteService appwriteService;

  NotificationRepository({required this.appwriteService});

  @override
  Future<List<NotificationModel>> getNotifications() async {
    try {
      models.User? user = await appwriteService.getCurrentUser();
      
      if (user == null) {
        throw Exception('User not logged in');
      }

      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.notificationsCollection,
        queries: [
          // Query.equal('user_id', '694d8375733853c66d75'),
          Query.equal('user_id', user.$id),
          Query.orderDesc('created_at'),
          Query.limit(50),
        ],
      );

      print('==> Fetched ${response.rows.length} notifications for user ${user.$id}');

      return response.rows
          .map((row) => NotificationModel.fromJson(row.data))
          .toList();
    } catch (e) {
      log('Error fetching notifications: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await appwriteService.updateTable(
        tableId: AppwriteConfig.notificationsCollection,
        rowId: notificationId,
        data: {'is_read': true},
      );
    } catch (e) {
      log('Error marking notification as read: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      models.User? user = await appwriteService.getCurrentUser();
      
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get all unread notifications
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.notificationsCollection,
        queries: [
          Query.equal('user_id', user.$id),
          Query.equal('is_read', false),
        ],
      );

      // Mark each as read
      for (var row in response.rows) {
        await markAsRead(row.$id);
      }
    } catch (e) {
      log('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await appwriteService.deleteRow(
        collectionId: AppwriteConfig.notificationsCollection,
        rowId: notificationId,
      );
    } catch (e) {
      log('Error deleting notification: $e');
      rethrow;
    }
  }

  @override
  int getUnreadCount() {
    // This will be calculated in controller from cached notifications
    return 0;
  }
}
