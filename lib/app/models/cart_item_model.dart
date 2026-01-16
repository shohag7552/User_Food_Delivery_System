import 'dart:convert';

class CartItemModel {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final String productImage;
  final double basePrice;
  final String? discountType;
  final double? discountValue;
  final double finalPrice;
  final List<SelectedVariant> selectedVariants;
  final int quantity;
  final double itemTotal;

  CartItemModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.basePrice,
    this.discountType,
    this.discountValue,
    required this.finalPrice,
    required this.selectedVariants,
    required this.quantity,
    required this.itemTotal,
  });

  // Calculate variant price
  double get variantPrice {
    double total = 0.0;
    for (var variant in selectedVariants) {
      for (var selection in variant.selections) {
        total += selection.optionPrice;
      }
    }
    return total;
  }

  // Calculate unit price (finalPrice + variantPrice)
  double get unitPrice => finalPrice + variantPrice;

  // Create copy with updated fields
  CartItemModel copyWith({
    String? id,
    String? userId,
    String? productId,
    String? productName,
    String? productImage,
    double? basePrice,
    String? discountType,
    double? discountValue,
    double? finalPrice,
    List<SelectedVariant>? selectedVariants,
    int? quantity,
    double? itemTotal,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      basePrice: basePrice ?? this.basePrice,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      finalPrice: finalPrice ?? this.finalPrice,
      selectedVariants: selectedVariants ?? this.selectedVariants,
      quantity: quantity ?? this.quantity,
      itemTotal: itemTotal ?? this.itemTotal,
    );
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['\$id'],
      userId: json['user_id'],
      productId: json['product_id'],
      productName: json['product_name'],
      productImage: json['product_image'],
      basePrice: (json['base_price'] as num).toDouble(),
      discountType: json['discount_type'],
      discountValue: json['discount_value'] != null
          ? (json['discount_value'] as num).toDouble()
          : null,
      finalPrice: (json['final_price'] as num).toDouble(),
      selectedVariants: json['selected_variants'] != null &&
              json['selected_variants'].isNotEmpty
          ? (jsonDecode(json['selected_variants']) as List)
              .map((e) => SelectedVariant.fromJson(e))
              .toList()
          : [],
      quantity: json['quantity'] as int,
      itemTotal: (json['item_total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'base_price': basePrice,
      'discount_type': discountType,
      'discount_value': discountValue,
      'final_price': finalPrice,
      'selected_variants':
          jsonEncode(selectedVariants.map((e) => e.toJson()).toList()),
      'quantity': quantity,
      'item_total': itemTotal,
    };
  }
}

class SelectedVariant {
  final String groupTitle;
  final String groupType; // 'radio' or 'checkbox'
  final List<VariantSelection> selections;

  SelectedVariant({
    required this.groupTitle,
    required this.groupType,
    required this.selections,
  });

  factory SelectedVariant.fromJson(Map<String, dynamic> json) {
    return SelectedVariant(
      groupTitle: json['group_title'],
      groupType: json['group_type'],
      selections: (json['selections'] as List)
          .map((e) => VariantSelection.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'group_title': groupTitle,
        'group_type': groupType,
        'selections': selections.map((e) => e.toJson()).toList(),
      };
}

class VariantSelection {
  final String optionName;
  final double optionPrice;

  VariantSelection({
    required this.optionName,
    required this.optionPrice,
  });

  factory VariantSelection.fromJson(Map<String, dynamic> json) {
    return VariantSelection(
      optionName: json['option_name'],
      optionPrice: (json['option_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'option_name': optionName,
        'option_price': optionPrice,
      };
}
