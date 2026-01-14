import 'dart:developer';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/products/domain/repository/product_repo_interface.dart';

class ProductRepository implements ProductRepoInterface {
  final AppwriteService appwriteService;

  ProductRepository({required this.appwriteService});

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.productsCollection,
      );
      return response.rows.map((row) {
        log('====> Product Data: ${row.data}');
        return ProductModel.fromJson(row.data);
      }).toList();
    } catch (e) {
      log('====> Error fetching products: $e');
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> getSpecialProducts() async {
    try {
      // Query for products that have a discount (special products)
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.productsCollection,
        queries: [
          Query.isNotNull('discount_type'),
          Query.greaterThan('discount_value', 5),
          Query.equal('is_available', true),
        ],
      );
      return response.rows.map((row) {
        log('====> Special Product Data: ${row.data}');
        return ProductModel.fromJson(row.data);
      }).toList();
    } catch (e) {
      log('====> Error fetching special products: $e');
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> getPopularProducts() async {
    try {
      // Query for available products, can be sorted by rating, sales, etc.
      // For now, just returning available products (you can add sorting later)
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.productsCollection,
        queries: [
          Query.isNotNull('order_count'),
          Query.greaterThan('order_count', 3),
          Query.equal('is_available', true),
          Query.limit(10), // Limit to top 10 popular items
        ],
      );
      return response.rows.map((row) {
        log('====> Popular Product Data: ${row.data}');
        return ProductModel.fromJson(row.data);
      }).toList();
    } catch (e) {
      log('====> Error fetching popular products: $e');
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> getNewProducts() async {
    try {
      // Query for newly added products sorted by creation date
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.productsCollection,
        queries: [
          Query.equal('is_available', true),
          Query.orderDesc('\$createdAt'), // Sort by creation date, newest first
          Query.limit(10), // Limit to 10 newest items
        ],
      );
      return response.rows.map((row) {
        log('====> New Product Data: ${row.data}');
        return ProductModel.fromJson(row.data);
      }).toList();
    } catch (e) {
      log('====> Error fetching new products: $e');
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.productsCollection,
        queries: [
          Query.equal('category_id', categoryId),
          Query.equal('is_available', true),
        ],
      );
      return response.rows.map((row) {
        log('====> Product Data for category $categoryId: ${row.data}');
        return ProductModel.fromJson(row.data);
      }).toList();
    } catch (e) {
      log('====> Error fetching products by category: $e');
      rethrow;
    }
  }
}
