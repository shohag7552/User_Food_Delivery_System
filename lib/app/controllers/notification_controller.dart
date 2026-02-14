import 'dart:developer';
import 'package:appwrite_user_app/app/models/notification_model.dart';
import 'package:appwrite_user_app/app/modules/notification/domain/repository/notification_repo_interface.dart';
import 'package:get/get.dart';

class NotificationController extends GetxController implements GetxService {
  final NotificationRepoInterface notificationRepoInterface;

  NotificationController({required this.notificationRepoInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // @override
  // void onInit() {
  //   super.onInit();
  //   getNotifications();
  // }

  /// Fetch all notifications for the current user
  Future<void> getNotifications() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      update();

      _notifications = await notificationRepoInterface.getNotifications();

      _isLoading = false;
      update();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load notifications';
      log('Error loading notifications: $e');
      update();
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await notificationRepoInterface.markAsRead(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        update();
      }
    } catch (e) {
      log('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await notificationRepoInterface.markAllAsRead();

      // Update local state
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      update();
    } catch (e) {
      log('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await notificationRepoInterface.deleteNotification(notificationId);

      // Remove from local state
      _notifications.removeWhere((n) => n.id == notificationId);
      update();
    } catch (e) {
      log('Error deleting notification: $e');
      rethrow;
    }
  }
}
