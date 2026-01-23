import 'dart:developer';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/models/favorite_model.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/favorites/domain/repository/favorites_repo_interface.dart';
import 'package:get/get.dart';

class FavoritesController extends GetxController implements GetxService {
  final FavoritesRepoInterface favoritesRepoInterface;

  FavoritesController({required this.favoritesRepoInterface});

  List<FavoriteModel> _favorites = [];
  Set<String> _favoriteProductIds = {}; // For quick lookup
  bool _isLoading = false;
  Map<String, bool> _toggleLoadingStates = {}; // Track per-product loading

  List<FavoriteModel> get favorites => _favorites;
  Set<String> get favoriteProductIds => _favoriteProductIds;
  bool get isLoading => _isLoading;
  bool get hasFavorites => _favorites.isNotEmpty;

  // Get products from favorites
  List<ProductModel> get favoriteProducts {
    return _favorites
        .where((fav) => fav.product != null)
        .map((fav) => fav.product!)
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchFavorites();
  }

  /// Check if a product is favorited
  bool isFavorite(String productId) {
    return _favoriteProductIds.contains(productId);
  }

  /// Check if toggle is in progress for a product
  bool isToggleLoading(String productId) {
    return _toggleLoadingStates[productId] ?? false;
  }

  /// Fetch all favorites
  Future<void> fetchFavorites() async {
    try {
      _isLoading = true;
      update();

      _favorites = await favoritesRepoInterface.getFavorites();
      _favoriteProductIds = _favorites.map((fav) => fav.productId).toSet();

      _isLoading = false;
      update();
    } catch (e) {
      _isLoading = false;
      update();
      log('Error fetching favorites: $e');
      customToster('Failed to load favorites', isSuccess: false);
    }
  }

  /// Toggle favorite status (add or remove)
  Future<void> toggleFavorite(ProductModel product) async {
    try {
      final productId = product.id;
      
      // Set loading state for this product
      _toggleLoadingStates[productId] = true;
      update();

      if (isFavorite(productId)) {
        // Remove from favorites
        await _removeFavorite(productId);
      } else {
        // Add to favorites
        await _addFavorite(product);
      }

      // Clear loading state
      _toggleLoadingStates[productId] = false;
      update();
    } catch (e) {
      // Clear loading state on error
      _toggleLoadingStates[product.id] = false;
      update();
      log('Error toggling favorite: $e');
      customToster('Failed to update favorite', isSuccess: false);
    }
  }

  /// Add product to favorites
  Future<void> _addFavorite(ProductModel product) async {
    try {
      // Optimistic update
      _favoriteProductIds.add(product.id);
      update();

      final favorite = await favoritesRepoInterface.addFavorite(product.id);
      
      // Update with actual data
      _favorites.add(favorite.copyWith(product: product));
      
      customToster('Added to favorites', isSuccess: true);
    } catch (e) {
      // Revert optimistic update
      _favoriteProductIds.remove(product.id);
      update();
      rethrow;
    }
  }

  /// Remove product from favorites
  Future<void> _removeFavorite(String productId) async {
    try {
      // Find the favorite
      final favorite = _favorites.firstWhere(
        (fav) => fav.productId == productId,
      );

      // Optimistic update
      _favoriteProductIds.remove(productId);
      _favorites.removeWhere((fav) => fav.productId == productId);
      update();

      await favoritesRepoInterface.removeFavorite(favorite.id);
      
      customToster('Removed from favorites', isSuccess: true);
    } catch (e) {
      // Revert optimistic update by refetching
      await fetchFavorites();
      rethrow;
    }
  }

  /// Remove favorite directly by ID (for favorites screen)
  Future<void> removeFavoriteById(String favoriteId, String productId) async {
    try {
      // Set loading state
      _toggleLoadingStates[productId] = true;
      update();

      // Optimistic update
      _favoriteProductIds.remove(productId);
      _favorites.removeWhere((fav) => fav.id == favoriteId);
      update();

      await favoritesRepoInterface.removeFavorite(favoriteId);
      
      // Clear loading state
      _toggleLoadingStates[productId] = false;
      update();
      
      customToster('Removed from favorites', isSuccess: true);
    } catch (e) {
      // Revert and clear loading
      _toggleLoadingStates[productId] = false;
      await fetchFavorites();
      log('Error removing favorite: $e');
      customToster('Failed to remove favorite', isSuccess: false);
    }
  }
}
