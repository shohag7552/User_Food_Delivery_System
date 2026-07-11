import 'package:appwrite_user_app/app/models/product_model.dart';

abstract class ProductRepoInterface {
  Future<List<ProductModel>> getProducts({
    int offset = 0,
    int limit = 10,
    bool? isVeg,
  });
  Future<List<ProductModel>> getSpecialProducts();
  Future<List<ProductModel>> getPopularProducts();
  Future<List<ProductModel>> getNewProducts();

  /// Highest-rated available products for the active module.
  Future<List<ProductModel>> getTopProducts({int limit = 10});

  /// Discounted (offer) available products for the active module.
  Future<List<ProductModel>> getOfferProducts({int limit = 10});
  Future<List<ProductModel>> getProductsByCategory(
    String categoryId, {
    int offset = 0,
    int limit = 10,
  });

  /// Products of one brand, paginated (brand products page).
  Future<List<ProductModel>> getProductsByBrand(
    String brandId, {
    int offset = 0,
    int limit = 10,
  });
  Future<List<ProductModel>> searchProducts(String query);
  Future<ProductModel?> getProductById(String id);

  /// Decrease a product's stock by [quantity] (never below 0).
  /// Returns the product's new stock value.
  Future<int> reduceStock(String productId, int quantity);
}
