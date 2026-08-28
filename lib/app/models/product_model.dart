import 'dart:convert';

import 'package:appwrite_user_app/app/helper/model_json_converter.dart';

class ProductModel {
  final String id;
  final String categoryId;
  final Map<String, dynamic> nameMap;
  final Map<String, dynamic> descriptionMap;
  final double price; // Original price (before discount)
  final String? discountType; // 'percentage' or 'fixed' or null
  final double? discountValue; // The discount amount or percentage
  final String imageId;
  final bool isVeg;
  final bool isAvailable;
  final int stock;
  final double avgRating;
  final int ratingCount;

  /// Units sold, accumulated across every placed order.
  ///
  /// Stored in Appwrite as `order_count`. The attribute predates this field and
  /// renaming it would be a migration, so the mapping is deliberate: the column
  /// is the store of record, `soldCount` is what the app calls it — units, not
  /// orders, because "12 sold" is what a shopper reads off a card.
  final int soldCount;
  final List<VariantGroup> variants;
  final String moduleType; // 'food' | 'ecommerce'
  // --- Ecommerce-specific (nullable; food ignores them) ---
  final String? brandId;
  final List<String> imageGallery;
  final String? sku;
  final double? weight;
  final String? weightUnit;

  ProductModel({
    required this.id,
    required this.categoryId,
    required this.nameMap,
    required this.descriptionMap,
    required this.price,
    this.discountType,
    this.discountValue,
    required this.imageId,
    required this.isVeg,
    required this.isAvailable,
    required this.stock,
    required this.avgRating,
    required this.ratingCount,
    this.soldCount = 0,
    required this.variants,
    this.moduleType = 'food',
    this.brandId,
    this.imageGallery = const [],
    this.sku,
    this.weight,
    this.weightUnit,
  });

  // Check if out of stock
  bool get isOutOfStock => stock <= 0;

  // Calculate final price after discount
  double get finalPrice {
    if (discountType == null || discountValue == null || discountValue == 0) {
      return price;
    }
    if (discountType == 'percentage') {
      // Deduct percentage from original price
      return price - (price * (discountValue! / 100));
    } else {
      // Deduct fixed amount from original price
      return price - discountValue!;
    }
  }

  // Check if product has discount
  bool get hasDiscount =>
      discountType != null && discountValue != null && discountValue! > 0;

  // Factory to convert Appwrite JSON -> Dart Object
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['\$id'], // Appwrite uses $id
      categoryId: json['category_id'],
      nameMap: ModelJsonConverter.parseData(json['name'] ?? ''),
      descriptionMap: ModelJsonConverter.parseData(json['description'] ?? ''),
      price: (json['price'] as num).toDouble(),
      discountType: json['discount_type'],
      discountValue: json['discount_value'] != null
          ? (json['discount_value'] as num).toDouble()
          : null,
      imageId: json['image_id'],
      isVeg: json['is_veg'] ?? false,
      isAvailable: json['is_available'] ?? true,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      soldCount: (json['order_count'] as num?)?.toInt() ?? 0,
      // PARSING THE JSON STRING "VARIANTS"
      variants: json['variants'] != null && json['variants'].isNotEmpty
          ? (jsonDecode(json['variants']) as List)
              .map((e) => VariantGroup.fromJson(e))
              .toList()
          : [],
      moduleType: json['module_type'] as String? ?? 'food',
      brandId: json['brand_id'] as String?,
      imageGallery: json['image_gallery'] is List
          ? (json['image_gallery'] as List).map((e) => e.toString()).toList()
          : const [],
      sku: json['sku'] as String?,
      weight: (json['weight'] as num?)?.toDouble(),
      weightUnit: json['weight_unit'] as String?,
    );
  }

  // To send back to Appwrite (if needed for Admin App)
  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'name': jsonEncode(nameMap),
      'description': jsonEncode(descriptionMap),
      'price': price,
      'discount_type': discountType,
      'discount_value': discountValue,
      'image_id': imageId,
      'is_veg': isVeg,
      'is_available': isAvailable,
      'stock': stock,
      'avg_rating': avgRating,
      'rating_count': ratingCount,
      'order_count': soldCount,
      'variants': jsonEncode(variants.map((e) => e.toJson()).toList()),
      'module_type': moduleType,
      if (brandId != null) 'brand_id': brandId,
      'image_gallery': imageGallery,
      if (sku != null) 'sku': sku,
      if (weight != null) 'weight': weight,
      if (weightUnit != null) 'weight_unit': weightUnit,
    };
  }

  ProductModel copyWith({
    String? id,
    String? categoryId,
    Map<String, dynamic>? nameMap,
    Map<String, dynamic>? descriptionMap,
    double? price,
    String? discountType,
    double? discountValue,
    String? imageId,
    bool? isVeg,
    bool? isAvailable,
    int? stock,
    double? avgRating,
    int? ratingCount,
    int? soldCount,
    List<VariantGroup>? variants,
    String? moduleType,
    String? brandId,
    List<String>? imageGallery,
    String? sku,
    double? weight,
    String? weightUnit,
    bool clearDiscountType = false,
    bool clearDiscountValue = false,
  }) {
    return ProductModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      nameMap: nameMap ?? this.nameMap,
      descriptionMap: descriptionMap ?? this.descriptionMap,
      price: price ?? this.price,
      discountType: clearDiscountType
          ? null
          : (discountType ?? this.discountType),
      discountValue: clearDiscountValue
          ? null
          : (discountValue ?? this.discountValue),
      imageId: imageId ?? this.imageId,
      isVeg: isVeg ?? this.isVeg,
      isAvailable: isAvailable ?? this.isAvailable,
      stock: stock ?? this.stock,
      avgRating: avgRating ?? this.avgRating,
      ratingCount: ratingCount ?? this.ratingCount,
      soldCount: soldCount ?? this.soldCount,
      variants: variants ?? this.variants,
      moduleType: moduleType ?? this.moduleType,
      brandId: brandId ?? this.brandId,
      imageGallery: imageGallery ?? this.imageGallery,
      sku: sku ?? this.sku,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
    );
  }
}

// --- HELPER CLASSES FOR VARIANTS ---

class VariantGroup {
  final String title; // e.g., "Size"
  final String type; // "radio" or "checkbox"
  final bool required;
  final List<VariantOption> options;

  VariantGroup({required this.title, required this.type, required this.required, required this.options});

  factory VariantGroup.fromJson(Map<String, dynamic> json) {
    return VariantGroup(
      title: json['title'],
      type: json['type'],
      required: json['required'],
      options: (json['options'] as List).map((e) => VariantOption.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title, 'type': type, 'required': required,
    'options': options.map((e) => e.toJson()).toList(),
  };
}

class VariantOption {
  final String name; // e.g., "Large"
  final double price; // e.g., 2.50

  VariantOption({required this.name, required this.price});

  factory VariantOption.fromJson(Map<String, dynamic> json) {
    return VariantOption(
      name: json['name'],
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'price': price};
}
