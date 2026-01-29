import 'package:appwrite_user_app/app/models/product_model.dart';

class FavoriteModel {
  final String id;
  final String userId;
  final String productId;
  final ProductModel? product; // Populated from relationship
  final DateTime? createdAt;

  FavoriteModel({
    required this.id,
    required this.userId,
    required this.productId,
    this.product,
    this.createdAt,
  });

  // Create copy with updated fields
  FavoriteModel copyWith({
    String? id,
    String? userId,
    String? productId,
    ProductModel? product,
    DateTime? createdAt,
  }) {
    return FavoriteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      product: product ?? this.product,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Create from JSON (Appwrite document)
  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['\$id'] ?? '',
      userId: json['user_id'] ?? '',
      productId: json['product_id'] ?? '',
      product: json['product'] != null 
          ? ProductModel.fromJson(json['product'])
          : null,
      createdAt: json['\$createdAt'] != null 
          ? DateTime.parse(json['\$createdAt']) 
          : null,
    );
  }

  ProductModel? _getProduct(Map<String, dynamic> jsonData) {
    try{
      if(jsonData?['product'] == null) {
        return null;
      }
      return ProductModel.fromJson(jsonData?['product']);
    } catch(e) {
      return null;
    }
  }

  // Convert to JSON for Appwrite
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'product_id': productId,
    };
  }

  @override
  String toString() {
    return 'FavoriteModel(id: $id, userId: $userId, productId: $productId)';
  }
}
