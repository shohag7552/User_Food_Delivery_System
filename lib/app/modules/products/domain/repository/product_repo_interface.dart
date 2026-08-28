import 'package:appwrite_user_app/app/models/product_model.dart';

abstract class ProductRepoInterface {
  /// The paginated product list for the active module.
  ///
  /// The optional filter arguments are all applied server-side as Appwrite
  /// queries, so paging stays correct. Omitting them all reproduces the
  /// unfiltered list exactly.
  ///
  /// [minPrice] / [maxPrice] bound the stored list price, not the discounted
  /// price — the latter is derived client-side and is not a queryable column.
  Future<List<ProductModel>> getProducts({
    int offset = 0,
    int limit = 10,
    bool? isVeg,
    bool onlyOffers = false,
    double? minPrice,
    double? maxPrice,
    String? categoryId,
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
  /// Commits one product's share of a placed order: stock down, sold count up.
  ///
  /// Both happen in the same write, so a product can never be sold without the
  /// sale being counted.
  Future<ProductSaleResult> recordSale(String productId, int quantity);
}

/// What a product row looks like after [ProductRepoInterface.recordSale].
class ProductSaleResult {
  const ProductSaleResult({required this.stock, required this.soldCount});

  final int stock;
  final int soldCount;
}
