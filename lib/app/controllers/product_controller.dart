import 'dart:developer';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/products/domain/repository/product_repo_interface.dart';
import 'package:get/get.dart';

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

  List<ProductModel> _products = [];
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

  /// Fetch all products
  Future<void> getProducts() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      update();

      _products = await productRepoInterface.getProducts();
      log('====> Products loaded: ${_products.length}');
      
      _isLoading = false;
      update();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load products: $e';
      log('====> Error loading products: $e');
      update();
    }
  }

  /// Fetch special products (today's specials)
  Future<void> getSpecialProducts() async {
    try {
      _isLoadingSpecials = true;
      _specialsErrorMessage = null;
      update();

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
  Future<void> getPopularProducts() async {
    try {
      _isLoadingPopular = true;
      _popularErrorMessage = null;
      update();

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
  Future<void> getNewProducts() async {
    try {
      _isLoadingNew = true;
      _newErrorMessage = null;
      update();

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
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      return await productRepoInterface.getProductsByCategory(categoryId);
    } catch (e) {
      log('====> Error loading products by category: $e');
      rethrow;
    }
  }
}
