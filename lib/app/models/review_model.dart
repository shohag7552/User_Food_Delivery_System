import 'package:appwrite/models.dart' as models;

class ReviewModel {
  final String id;
  final String? orderId;
  final String productId;
  final String userId;
  final String userName;
  final int rating; // 1-5
  final String? title;
  final String comment;
  final int helpfulCount;
  final List<String> helpfulUserIds; // users who marked this review helpful
  final bool verifiedPurchase;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    this.orderId,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    this.title,
    required this.comment,
    this.helpfulCount = 0,
    this.helpfulUserIds = const [],
    this.verifiedPurchase = false,
    required this.createdAt,
  });

  /// Whether the given user has marked this review as helpful.
  bool isMarkedHelpfulBy(String? userId) =>
      userId != null && helpfulUserIds.contains(userId);

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  /// Create from Appwrite Document
  factory ReviewModel.fromDocument(models.Document doc) {
    return ReviewModel(
      id: doc.$id,
      orderId: doc.data['order_id']?.toString(),
      productId: doc.data['product_id'] ?? '',
      userId: doc.data['user_id'] ?? '',
      userName: doc.data['user_name'] ?? 'Anonymous',
      rating: doc.data['rating'] ?? 0,
      title: doc.data['title'],
      comment: doc.data['comment'] ?? '',
      helpfulCount: doc.data['helpful_count'] ?? 0,
      helpfulUserIds: _parseStringList(doc.data['helpful_user_ids']),
      verifiedPurchase: doc.data['verified_purchase'] ?? false,
      createdAt: DateTime.parse(doc.data['created_at'] ?? doc.data['\$createdAt']),
    );
  }

  /// Create from JSON Map
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['\$id'] ?? '',
      orderId: json['order_id']?.toString(),
      productId: json['product_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? 'Anonymous',
      rating: json['rating'] ?? 0,
      title: json['title'],
      comment: json['comment'] ?? '',
      helpfulCount: json['helpful_count'] ?? 0,
      helpfulUserIds: _parseStringList(json['helpful_user_ids']),
      verifiedPurchase: json['verified_purchase'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : (json['\$createdAt'] != null 
              ? DateTime.parse(json['\$createdAt'])
              : DateTime.now()),
    );
  }

  /// Convert to Map for Appwrite
  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'product_id': productId,
      'user_id': userId,
      'user_name': userName,
      'rating': rating,
      'title': title,
      'comment': comment,
      'helpful_count': helpfulCount,
      'verified_purchase': verifiedPurchase,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to JSON Map
  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'product_id': productId,
      'user_id': userId,
      'user_name': userName,
      'rating': rating,
      'title': title,
      'comment': comment,
      'helpful_count': helpfulCount,
      'verified_purchase': verifiedPurchase,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Copy with
  ReviewModel copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? userId,
    String? userName,
    int? rating,
    String? title,
    String? comment,
    int? helpfulCount,
    List<String>? helpfulUserIds,
    bool? verifiedPurchase,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      helpfulUserIds: helpfulUserIds ?? this.helpfulUserIds,
      verifiedPurchase: verifiedPurchase ?? this.verifiedPurchase,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
