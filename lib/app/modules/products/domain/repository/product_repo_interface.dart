import 'package:appwrite_user_app/app/models/product_model.dart';

abstract class ProductRepoInterface {
  Future<List<ProductModel>> getProducts({int offset = 0, int limit = 10});
  Future<List<ProductModel>> getSpecialProducts();
  Future<List<ProductModel>> getPopularProducts();
  Future<List<ProductModel>> getNewProducts();
  Future<List<ProductModel>> getProductsByCategory(String categoryId);
}
