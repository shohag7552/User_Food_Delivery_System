import 'dart:developer';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/products/domain/repository/product_repo_interface.dart';

class ProductRepository implements ProductRepoInterface {
  final AppwriteService appwriteService;
  static const int _searchBatchSize = 100;

  ProductRepository({required this.appwriteService});

  @override
  Future<List<ProductModel>> getProducts({
    int offset = 0,
    int limit = 10,
    bool? isVeg,
  }) async {
    try {
      final queries = <String>[
        Query.equal('is_available', true),
        Query.offset(offset),
        Query.limit(limit),
      ];

      if (isVeg != null) {
        queries.insert(1, Query.equal('is_veg', isVeg));
      }

      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.productsCollection,
        queries: queries,
      );
      return response.rows.map((row) {
        log('====\u003e Product Data: ${row.data}');
        return ProductModel.fromJson(row.data);
      }).toList();
    } catch (e) {
      log('====\u003e Error fetching products: $e');
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
        log('====\u003e Special Product Data: ${row.data}');
        return ProductModel.fromJson(row.data);
      }).toList();
    } catch (e) {
      log('====\u003e Error fetching special products: $e');
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
        log('====\u003e Popular Product Data: ${row.data}');
        return ProductModel.fromJson(row.data);
      }).toList();
    } catch (e) {
      log('====\u003e Error fetching popular products: $e');
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
        log('====\u003e New Product Data: ${row.data}');
        return ProductModel.fromJson(row.data);
      }).toList();
    } catch (e) {
      log('====\u003e Error fetching new products: $e');
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(
    String categoryId, {
    int offset = 0,
    int limit = 10,
  }) async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.productsCollection,
        queries: [
          Query.equal('category_id', categoryId),
          Query.equal('is_available', true),
          Query.offset(offset),
          Query.limit(limit),
        ],
      );
      return response.rows.map((row) {
        log('====\u003e Product Data for category $categoryId: ${row.data}');
        return ProductModel.fromJson(row.data);
      }).toList();
    } catch (e) {
      log('====\u003e Error fetching products by category: $e');
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final normalizedQuery = _normalizeSearchQuery(query);
      if (normalizedQuery.isEmpty) {
        return [];
      }

      final rankedResults = (await _searchProductsLocally(normalizedQuery))
        ..sort((a, b) {
          final aScore = _getSearchScore(a, normalizedQuery);
          final bScore = _getSearchScore(b, normalizedQuery);
          if (aScore != bScore) {
            return aScore.compareTo(bScore);
          }

          return a.nameMap.values.join(' ').compareTo(b.nameMap.values.join(' '));
        });

      return rankedResults;
    } catch (e) {
      log('====\\u003e Error searching products: $e');
      rethrow;
    }
  }

  Future<List<ProductModel>> _searchProductsLocally(String normalizedQuery) async {
    final List<ProductModel> products = [];
    int offset = 0;

    while (true) {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.productsCollection,
        queries: [
          Query.equal('is_available', true),
          Query.offset(offset),
          Query.limit(_searchBatchSize),
        ],
      );

      final rows = response.rows;
      if (rows.isEmpty) {
        break;
      }

      products.addAll(rows.map((row) => ProductModel.fromJson(row.data)));

      if (rows.length < _searchBatchSize) {
        break;
      }

      offset += _searchBatchSize;
    }

    return products.where((product) => _matchesSearch(product, normalizedQuery)).toList();
  }

  bool _matchesSearch(ProductModel product, String normalizedQuery) {
    final localizedName = _normalizeSearchQuery(product.nameMap.trLanguage);
    final localizedDescription = _normalizeSearchQuery(product.descriptionMap.trLanguage);
    final allNames = product.nameMap.values
        .map((value) => _normalizeSearchQuery(value.toString()))
        .where((value) => value.isNotEmpty);
    final allDescriptions = product.descriptionMap.values
        .map((value) => _normalizeSearchQuery(value.toString()))
        .where((value) => value.isNotEmpty);

    return localizedName.contains(normalizedQuery) ||
        localizedDescription.contains(normalizedQuery) ||
        allNames.any((value) => value.contains(normalizedQuery)) ||
        allDescriptions.any((value) => value.contains(normalizedQuery));
  }

  int _getSearchScore(ProductModel product, String normalizedQuery) {
    final localizedName = _normalizeSearchQuery(product.nameMap.trLanguage);
    final localizedDescription = _normalizeSearchQuery(product.descriptionMap.trLanguage);
    final names = product.nameMap.values
        .map((value) => _normalizeSearchQuery(value.toString()))
        .where((value) => value.isNotEmpty)
        .toList();
    final descriptions = product.descriptionMap.values
        .map((value) => _normalizeSearchQuery(value.toString()))
        .where((value) => value.isNotEmpty)
        .toList();

    if (localizedName == normalizedQuery) {
      return 0;
    }

    if (localizedName.startsWith(normalizedQuery)) {
      return 1;
    }

    if (localizedName.contains(normalizedQuery)) {
      return 2;
    }

    if (localizedDescription.contains(normalizedQuery)) {
      return 3;
    }

    if (names.any((value) => value == normalizedQuery)) {
      return 4;
    }

    if (names.any((value) => value.startsWith(normalizedQuery))) {
      return 5;
    }

    if (names.any((value) => value.contains(normalizedQuery))) {
      return 6;
    }

    if (descriptions.any((value) => value.contains(normalizedQuery))) {
      return 7;
    }

    return 8;
  }

  String _normalizeSearchQuery(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    try {
      final response = await appwriteService.getDocument(
        tableId: AppwriteConfig.productsCollection,
        rowId: id,
      );
      return ProductModel.fromJson(response.data);
    } catch (e) {
      log('====\\u003e Error fetching product by ID: $e');
      return null;
    }
  }
}
