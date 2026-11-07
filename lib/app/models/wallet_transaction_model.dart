/// One change to the customer's wallet balance (`wallet_transactions` row).
///
/// Rows are written by the backend function (wallet order payments, refunds,
/// loyalty conversions) and the store's "Add to wallet"; the customer can only
/// read their own.
class WalletTransactionModel {
  static const String typeOrderPayment = 'order_payment';
  static const String typeOrderRefund = 'order_refund';
  static const String typeLoyaltyConversion = 'loyalty_conversion';
  static const String typeAdminAdjustment = 'admin_adjustment';

  final String id;
  final String userId;
  final String type;

  /// Signed: positive into the wallet, negative out of it.
  final double amount;
  final double? balanceAfter;
  final String? orderId;
  final String? orderNumber;
  final String? note;
  final DateTime createdAt;

  WalletTransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.balanceAfter,
    this.orderId,
    this.orderNumber,
    this.note,
    required this.createdAt,
  });

  bool get isCredit => amount >= 0;

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['\$id'] ?? '',
      userId: json['user_id'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balance_after'] as num?)?.toDouble(),
      orderId: json['order_id'],
      orderNumber: json['order_number'],
      note: json['note'],
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['\$createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'type': type,
    'amount': amount,
    'balance_after': ?balanceAfter,
    'order_id': ?orderId,
    'order_number': ?orderNumber,
    'note': ?note,
    'created_at': createdAt.toIso8601String(),
  };

  WalletTransactionModel copyWith({
    String? id,
    String? userId,
    String? type,
    double? amount,
    double? balanceAfter,
    String? orderId,
    String? orderNumber,
    String? note,
    DateTime? createdAt,
  }) {
    return WalletTransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
