class CouponModel {
  final String? id;
  final String code;
  final String description;
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final double? minOrderAmount;
  final double? maxDiscount; // Maximum discount cap for percentage coupons
  final int? usageLimit; // Total times coupon can be used (null = unlimited)
  final int usedCount; // Current usage count
  final DateTime validFrom;
  final DateTime validUntil;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CouponModel({
    this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount,
    this.maxDiscount,
    this.usageLimit,
    this.usedCount = 0,
    required this.validFrom,
    required this.validUntil,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  // Check if coupon is currently valid
  bool isValid({double? orderAmount}) {
    final now = DateTime.now();

    // Check active status
    if (!isActive) return false;

    // Check validity period
    if (now.isBefore(validFrom) || now.isAfter(validUntil)) return false;

    // Check usage limit
    if (usageLimit != null && usedCount >= usageLimit!) return false;

    // Check minimum order amount
    if (minOrderAmount != null &&
        orderAmount != null &&
        orderAmount < minOrderAmount!) {
      return false;
    }

    return true;
  }

  // Calculate discount amount for given order amount
  double calculateDiscount(double orderAmount) {
    if (!isValid(orderAmount: orderAmount)) return 0.0;

    double discount = 0.0;

    if (discountType == 'percentage') {
      discount = orderAmount * (discountValue / 100);
      // Apply max discount cap if specified
      if (maxDiscount != null && discount > maxDiscount!) {
        discount = maxDiscount!;
      }
    } else {
      // Fixed discount
      discount = discountValue;
      // Discount cannot exceed order amount
      if (discount > orderAmount) {
        discount = orderAmount;
      }
    }

    return discount;
  }

  // Get formatted discount display (e.g., "20%" or "$10")
  String get discountDisplay {
    if (discountType == 'percentage') {
      return '${discountValue.toStringAsFixed(0)}%';
    } else {
      return '\$${discountValue.toStringAsFixed(2)}';
    }
  }

  // Factory to convert Appwrite JSON -> Dart Object
  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['\$id'],
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discount_type'] ?? 'percentage',
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      minOrderAmount: json['min_order_amount'] != null
          ? (json['min_order_amount'] as num).toDouble()
          : null,
      maxDiscount: json['max_discount'] != null
          ? (json['max_discount'] as num).toDouble()
          : null,
      usageLimit: json['usage_limit'],
      usedCount: json['used_count'] ?? 0,
      validFrom: json['valid_from'] != null
          ? DateTime.parse(json['valid_from'])
          : DateTime.now(),
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'])
          : DateTime.now().add(const Duration(days: 30)),
      isActive: json['is_active'] ?? true,
      createdAt: json['\$createdAt'] != null
          ? DateTime.parse(json['\$createdAt'])
          : null,
      updatedAt: json['\$updatedAt'] != null
          ? DateTime.parse(json['\$updatedAt'])
          : null,
    );
  }

  // To send back to Appwrite
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      if (minOrderAmount != null) 'min_order_amount': minOrderAmount,
      if (maxDiscount != null) 'max_discount': maxDiscount,
      if (usageLimit != null) 'usage_limit': usageLimit,
      'used_count': usedCount,
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
      'is_active': isActive,
    };
  }

  // Create a copy with modified fields
  CouponModel copyWith({
    String? id,
    String? code,
    String? description,
    String? discountType,
    double? discountValue,
    double? minOrderAmount,
    double? maxDiscount,
    int? usageLimit,
    int? usedCount,
    DateTime? validFrom,
    DateTime? validUntil,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CouponModel(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
