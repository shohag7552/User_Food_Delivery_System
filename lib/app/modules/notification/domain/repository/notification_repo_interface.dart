import 'package:appwrite_user_app/app/models/notification_model.dart';

abstract class NotificationRepoInterface {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String notificationId);
  int getUnreadCount();
}
