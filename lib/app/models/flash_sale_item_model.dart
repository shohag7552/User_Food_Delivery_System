import 'package:appwrite_user_app/app/models/product_model.dart';

/// A product participating in a flash sale. [flashPrice] is the absolute sale
/// price; the joined [product] (hydrated by the repository) supplies the
/// original price and display data.
class FlashSaleItemModel {
  final String id;
  final String flashSaleId;
  final String productId;
  final double flashPrice;
  final int? flashStock;
  final int soldCount;
  final String moduleType;

  /// Hydrated by the repository from the products collection; null when the
  /// product no longer exists or is unavailable.
  final ProductModel? product;

  const FlashSaleItemModel({
    required this.id,
    required this.flashSaleId,
    required this.productId,
    required this.flashPrice,
    this.flashStock,
    this.soldCount = 0,
    this.moduleType = 'ecommerce',
    this.product,
  });

  /// Percentage saved vs the product's original price (0 when unknown).
  int get discountPercent {
    final original = product?.price ?? 0;
    if (original <= 0 || flashPrice >= original) return 0;
    return (((original - flashPrice) / original) * 100).round();
  }

  /// Units still sellable in this sale. Falls back to the product's own stock
  /// when the sale carries no per-item cap.
  int get remainingStock {
    if (flashStock != null) {
      final left = flashStock! - soldCount;
      return left < 0 ? 0 : left;
    }
    return product?.stock ?? 0;
  }

  /// 0..1 progress of the sold bar (0 when the sale has no per-item cap).
  double get soldRatio {
    if (flashStock == null || flashStock! <= 0) return 0;
    final ratio = soldCount / flashStock!;
    return ratio.clamp(0.0, 1.0);
  }

  factory FlashSaleItemModel.fromJson(
    Map<String, dynamic> json, {
    ProductModel? product,
  }) {
    return FlashSaleItemModel(
      id: json[r'$id'] as String? ?? '',
      flashSaleId: json['flash_sale_id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      flashPrice: (json['flash_price'] as num?)?.toDouble() ?? 0,
      flashStock: (json['flash_stock'] as num?)?.toInt(),
      soldCount: (json['sold_count'] as num?)?.toInt() ?? 0,
      moduleType: json['module_type'] as String? ?? 'ecommerce',
      product: product,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flash_sale_id': flashSaleId,
      'product_id': productId,
      'flash_price': flashPrice,
      'flash_stock': flashStock,
      'sold_count': soldCount,
      'module_type': moduleType,
    };
  }

  FlashSaleItemModel copyWith({
    String? id,
    String? flashSaleId,
    String? productId,
    double? flashPrice,
    int? flashStock,
    int? soldCount,
    String? moduleType,
    ProductModel? product,
  }) {
    return FlashSaleItemModel(
      id: id ?? this.id,
      flashSaleId: flashSaleId ?? this.flashSaleId,
      productId: productId ?? this.productId,
      flashPrice: flashPrice ?? this.flashPrice,
      flashStock: flashStock ?? this.flashStock,
      soldCount: soldCount ?? this.soldCount,
      moduleType: moduleType ?? this.moduleType,
      product: product ?? this.product,
    );
  }
}
