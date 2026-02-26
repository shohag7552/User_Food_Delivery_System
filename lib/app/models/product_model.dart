import 'dart:convert';

class ProductModel {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final double price; // Original price (before discount)
  final String? discountType; // 'percentage' or 'fixed' or null
  final double? discountValue; // The discount amount or percentage
  final String imageId;
  final bool isVeg;
  final bool isAvailable;
  final int stock;
  final List<VariantGroup> variants;

  ProductModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    this.discountType,
    this.discountValue,
    required this.imageId,
    required this.isVeg,
    required this.isAvailable,
    required this.stock,
    required this.variants,
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
      name: json['name'],
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      discountType: json['discount_type'],
      discountValue: json['discount_value'] != null
          ? (json['discount_value'] as num).toDouble()
          : null,
      imageId: json['image_id'],
      isVeg: json['is_veg'] ?? false,
      isAvailable: json['is_available'] ?? true,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      // PARSING THE JSON STRING "VARIANTS"
      variants: json['variants'] != null && json['variants'].isNotEmpty
          ? (jsonDecode(json['variants']) as List)
              .map((e) => VariantGroup.fromJson(e))
              .toList()
          : [],
    );
  }

  // To send back to Appwrite (if needed for Admin App)
  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'discount_type': discountType,
      'discount_value': discountValue,
      'image_id': imageId,
      'is_veg': isVeg,
      'is_available': isAvailable,
      'stock': stock,
      'variants': jsonEncode(variants.map((e) => e.toJson()).toList()),
    };
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