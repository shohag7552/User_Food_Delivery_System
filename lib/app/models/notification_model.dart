class NotificationModel {
  final String id;
  final String userId;
  final String type; // 'order', 'promo', 'system'
  final String title;
  final String message;
  final String? imageUrl;
  final String? actionType; // 'order', 'product', 'url', 'none'
  final String? actionValue; // Order ID, Product ID, or URL
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.imageUrl,
    this.actionType,
    this.actionValue,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['\$id'],
      userId: json['user_id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      imageUrl: json['image_url'],
      actionType: json['action_type'],
      actionValue: json['action_value'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'image_url': imageUrl,
      'action_type': actionType,
      'action_value': actionValue,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    String? imageUrl,
    String? actionType,
    String? actionValue,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      actionType: actionType ?? this.actionType,
      actionValue: actionValue ?? this.actionValue,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
