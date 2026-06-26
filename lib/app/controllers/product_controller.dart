import 'dart:developer';
import 'package:appwrite_user_app/app/models/cart_item_model.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/products/domain/repository/product_repo_interface.dart';
import 'package:get/get.dart';

enum ProductListFilter { all, veg, nonVeg }

class ProductController extends GetxController implements GetxService {
  final ProductRepoInterface productRepoInterface;
  
  ProductController({required this.productRepoInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingSpecials = false;
  bool get isLoadingSpecials => _isLoadingSpecials;

  bool _isLoadingPopular = false;
  bool get isLoadingPopular => _isLoadingPopular;

  bool _isLoadingNew = false;
  bool get isLoadingNew => _isLoadingNew;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  int _currentPage = 0;
  int get currentPage => _currentPage;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  final int _pageSize = 10;
  ProductListFilter _selectedProductFilter = ProductListFilter.all;
  ProductListFilter get selectedProductFilter => _selectedProductFilter;
  bool? get _selectedIsVegFilter {
    switch (_selectedProductFilter) {
      case ProductListFilter.all:
        return null;
      case ProductListFilter.veg:
        return true;
      case ProductListFilter.nonVeg:
        return false;
    }
  }

  final List<ProductModel> _products = [];
  List<ProductModel> get products => _products;

  List<ProductModel> _specialProducts = [];
  List<ProductModel> get specialProducts => _specialProducts;

  List<ProductModel> _popularProducts = [];
  List<ProductModel> get popularProducts => _popularProducts;

  List<ProductModel> _newProducts = [];
  List<ProductModel> get newProducts => _newProducts;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _specialsErrorMessage;
  String? get specialsErrorMessage => _specialsErrorMessage;

  String? _popularErrorMessage;
  String? get popularErrorMessage => _popularErrorMessage;

  String? _newErrorMessage;
  String? get newErrorMessage => _newErrorMessage;

  /// Fetch all products (initial load)
  /// Drops all cached lists so the next fetch loads the active module fresh.
  void clearForModuleSwitch() {
    _products.clear();
    _specialProducts = [];
    _popularProducts = [];
    _newProducts = [];
    _currentPage = 0;
    _hasMore = true;
    update();
  }

  Future<void> getProducts({bool refresh = false, bool reload = false}) async {
    try {
      if (refresh || reload) {
        _currentPage = 0;
        _products.clear();
        _hasMore = true;
      }
      
      _isLoading = true;
      _errorMessage = null;
      update();

      final newProducts = await productRepoInterface.getProducts(
        offset: _currentPage * _pageSize,
        limit: _pageSize,
        isVeg: _selectedIsVegFilter,
      );
      
      if (newProducts.length < _pageSize) {
        _hasMore = false;
      }
      
      _products.addAll(newProducts);
      _currentPage++;
      log('====> Products loaded: ${_products.length}, hasMore: $_hasMore');
      
      _isLoading = false;
      update();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load products: $e';
      log('====> Error loading products: $e');
      update();
    }
  }

  /// Load more products (pagination)
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;
    
    try {
      _isLoadingMore = true;
      update();

      final newProducts = await productRepoInterface.getProducts(
        offset: _currentPage * _pageSize,
        limit: _pageSize,
        isVeg: _selectedIsVegFilter,
      );
      
      if (newProducts.length < _pageSize) {
        _hasMore = false;
      }
      
      _products.addAll(newProducts);
      _currentPage++;
      log('====> More products loaded: ${_products.length}, hasMore: $_hasMore');
      
      _isLoadingMore = false;
      update();
    } catch (e) {
      _isLoadingMore = false;
      log('====> Error loading more products: $e');
      update();
    }
  }

  /// Fetch special products (today's specials)
  Future<void> getSpecialProducts({bool reload = false}) async {
    try {
      _isLoadingSpecials = true;
      _specialsErrorMessage = null;
      if(!reload) {
        update();
      }

      _specialProducts = await productRepoInterface.getSpecialProducts();
      log('====> Special products loaded: ${_specialProducts.length}');
      
      _isLoadingSpecials = false;
      update();
    } catch (e) {
      _isLoadingSpecials = false;
      _specialsErrorMessage = 'Failed to load special products: $e';
      log('====> Error loading special products: $e');
      update();
    }
  }

  /// Fetch popular products
  Future<void> getPopularProducts({bool reload = false}) async {
    try {
      _isLoadingPopular = true;
      _popularErrorMessage = null;
      if(!reload) {
        update();
      }

      _popularProducts = await productRepoInterface.getPopularProducts();
      log('====> Popular products loaded: ${_popularProducts.length}');
      
      _isLoadingPopular = false;
      update();
    } catch (e) {
      _isLoadingPopular = false;
      _popularErrorMessage = 'Failed to load popular products: $e';
      log('====> Error loading popular products: $e');
      update();
    }
  }

  /// Fetch new products
  Future<void> getNewProducts({bool reload = false}) async {
    try {
      _isLoadingNew = true;
      _newErrorMessage = null;
      if(!reload) {
        update();
      }

      _newProducts = await productRepoInterface.getNewProducts();
      log('====> New products loaded: ${_newProducts.length}');
      
      _isLoadingNew = false;
      update();
    } catch (e) {
      _isLoadingNew = false;
      _newErrorMessage = 'Failed to load new products: $e';
      log('====> Error loading new products: $e');
      update();
    }
  }

  /// Fetch products by category
  Future<List<ProductModel>> getProductsByCategory(
    String categoryId, {
    int offset = 0,
    int limit = 10,
  }) async {
    try {
      return await productRepoInterface.getProductsByCategory(
        categoryId,
        offset: offset,
        limit: limit,
      );
    } catch (e) {
      log('====> Error loading products by category: $e');
      rethrow;
    }
  }

  /// Search products from Appwrite
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      log('====> Searching products for query: $query');
      return await productRepoInterface.searchProducts(query);
    } catch (e) {
      log('====> Error searching products: $e');
      rethrow;
    }
  }

  /// Fetch product by ID
  Future<ProductModel?> getProductById(String id) async {
    try {
      return await productRepoInterface.getProductById(id);
    } catch (e) {
      log('====> Error fetching product by ID: $e');
      return null;
    }
  }

  Future<void> setProductFilter(ProductListFilter filter) async {
    if (_selectedProductFilter == filter) {
      return;
    }

    _selectedProductFilter = filter;
    await getProducts(refresh: true);
  }

  void updateProductRatingSummary(
    String productId, {
    required double avgRating,
    required int ratingCount,
  }) {
    bool hasChanges = false;

    bool updateList(List<ProductModel> products) {
      final index = products.indexWhere((product) => product.id == productId);
      if (index == -1) {
        return false;
      }

      products[index] = products[index].copyWith(
        avgRating: avgRating,
        ratingCount: ratingCount,
      );
      return true;
    }

    hasChanges = updateList(_products) || hasChanges;
    hasChanges = updateList(_specialProducts) || hasChanges;
    hasChanges = updateList(_popularProducts) || hasChanges;
    hasChanges = updateList(_newProducts) || hasChanges;

    if (hasChanges) {
      update();
    }
  }

  /// Reduces stock in the database for every ordered item, then mirrors the
  /// new values into the cached product lists. Failures per product are logged
  /// but never abort the order flow.
  Future<void> reduceStockForItems(List<CartItemModel> items) async {
    if (items.isEmpty) return;

    // Aggregate quantities so the same product is only written once.
    final Map<String, int> quantities = {};
    for (final item in items) {
      if (item.productId.isEmpty) continue;
      quantities[item.productId] =
          (quantities[item.productId] ?? 0) + item.quantity;
    }

    bool hasChanges = false;
    for (final entry in quantities.entries) {
      try {
        final newStock =
            await productRepoInterface.reduceStock(entry.key, entry.value);
        hasChanges = _applyStockToCache(entry.key, newStock) || hasChanges;
      } catch (e) {
        log('====> Failed to reduce stock for ${entry.key}: $e');
      }
    }

    if (hasChanges) update();
  }

  bool _applyStockToCache(String productId, int newStock) {
    bool changed = false;

    bool updateList(List<ProductModel> products) {
      final index = products.indexWhere((product) => product.id == productId);
      if (index == -1) return false;
      products[index] = products[index].copyWith(stock: newStock);
      return true;
    }

    changed = updateList(_products) || changed;
    changed = updateList(_specialProducts) || changed;
    changed = updateList(_popularProducts) || changed;
    changed = updateList(_newProducts) || changed;
    return changed;
  }
}
