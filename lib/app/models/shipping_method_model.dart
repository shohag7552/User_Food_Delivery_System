/// Ecommerce shipping option (flat / free / weight-based).
class ShippingMethodModel {
  final String id;
  final String name;
  final String type; // 'flat' | 'free' | 'weight_based'
  final double cost;
  final double? freeAbove; // free when the order subtotal reaches this
  final String? estimatedDays;
  final bool isActive;
  final int sortOrder;

  ShippingMethodModel({
    required this.id,
    required this.name,
    required this.type,
    required this.cost,
    this.freeAbove,
    this.estimatedDays,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory ShippingMethodModel.fromJson(Map<String, dynamic> json) {
    return ShippingMethodModel(
      id: json['\$id'] as String? ?? json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'flat',
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      freeAbove: (json['free_above'] as num?)?.toDouble(),
      estimatedDays: json['estimated_days'] as String?,
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  /// Resolve the fee this method charges for a given order subtotal.
  double feeFor(double orderSubtotal) {
    if (type == 'free') return 0;
    if (freeAbove != null && orderSubtotal >= freeAbove!) return 0;
    return cost;
  }
}
