/// A customer's rating of the deliveryman who handed one order over.
///
/// Deliberately separate from [ReviewModel] (which rates a *product*): a
/// delivery is rated once per order, the comment is optional, and the average
/// it feeds lives on the driver row rather than on a product.
class DeliverymanReviewModel {
  final String id;

  /// The driver as of handover, snapshotted at review time so a later
  /// reassignment cannot retarget an existing review.
  final String driverId;

  /// Name snapshot — keeps the review readable if the driver row is removed.
  final String driverName;

  /// One review per order; the collection enforces this with a unique index.
  final String orderId;
  final String orderNumber;
  final String userId;
  final String userName;

  /// 1–5.
  final int rating;

  /// Optional: stars alone are a complete delivery review.
  final String? comment;

  /// Quick-tap chips stored as translation keys (`on_time`, `polite`, …), not
  /// prose, so they read correctly in whatever language they are shown in.
  final List<String> tags;

  final DateTime createdAt;

  const DeliverymanReviewModel({
    required this.id,
    required this.driverId,
    this.driverName = '',
    required this.orderId,
    this.orderNumber = '',
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment,
    this.tags = const [],
    required this.createdAt,
  });

  bool get hasComment => comment != null && comment!.trim().isNotEmpty;

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static DateTime _parseDate(dynamic createdAt, dynamic fallback) {
    final raw = (createdAt ?? fallback)?.toString();
    if (raw == null || raw.isEmpty) {
      return DateTime.now();
    }
    return DateTime.tryParse(raw) ?? DateTime.now();
  }

  factory DeliverymanReviewModel.fromJson(Map<String, dynamic> json) {
    return DeliverymanReviewModel(
      id: json['\$id']?.toString() ?? '',
      driverId: json['driver_id']?.toString() ?? '',
      driverName: json['driver_name']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'Anonymous',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString(),
      tags: _parseStringList(json['tags']),
      createdAt: _parseDate(json['created_at'], json['\$createdAt']),
    );
  }

  /// Payload for Appwrite. `$id` is never sent — the server owns it.
  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'driver_name': driverName,
      'order_id': orderId,
      'order_number': orderNumber,
      'user_id': userId,
      'user_name': userName,
      'rating': rating,
      'comment': comment,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
    };
  }

  DeliverymanReviewModel copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? orderId,
    String? orderNumber,
    String? userId,
    String? userName,
    int? rating,
    String? comment,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return DeliverymanReviewModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
