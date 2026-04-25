class LoyaltyHistoryModel {
  final String id;
  final String userId;
  final String? orderId;
  final String type;
  final String title;
  final String description;
  final int points;
  final double walletAmount;
  final DateTime createdAt;

  LoyaltyHistoryModel({
    required this.id,
    required this.userId,
    this.orderId,
    required this.type,
    required this.title,
    required this.description,
    required this.points,
    this.walletAmount = 0.0,
    required this.createdAt,
  });

  bool get isEarned => type == 'earned';

  factory LoyaltyHistoryModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyHistoryModel(
      id: json['\$id'] ?? '',
      userId: json['user_id'] ?? '',
      orderId: json['order_id'],
      type: json['type'] ?? 'earned',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      points: (json['points'] ?? 0).toInt(),
      walletAmount: (json['wallet_amount'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['\$createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }
}
