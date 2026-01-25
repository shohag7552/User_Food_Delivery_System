import 'package:appwrite_user_app/app/models/favorite_model.dart';

abstract class FavoritesRepoInterface {
  /// Get all favorites for the current user
  Future<List<FavoriteModel>> getFavorites({bool loadWithProduct = false});

  /// Add a product to favorites
  Future<FavoriteModel> addFavorite(String productId);

  /// Remove a product from favorites
  Future<void> removeFavorite(String favoriteId);

  /// Check if a product is favorited
  Future<bool> isFavorite(String productId);

  /// Get favorite ID for a product (if exists)
  Future<String?> getFavoriteId(String productId);
}
