import 'dart:developer';
import 'package:appwrite/models.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/models/favorite_model.dart';
import 'package:appwrite_user_app/app/modules/favorites/domain/repository/favorites_repo_interface.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

class FavoritesRepository implements FavoritesRepoInterface {
  final AppwriteService appwriteService;

  FavoritesRepository({required this.appwriteService});

  @override
  Future<List<FavoriteModel>> getFavorites({bool loadWithProduct = false}) async {
    try {
      User? user = await appwriteService.getCurrentUser();

      if (user == null) {
        throw Exception('User not logged in');
      }

      List<String>? queries = [
        Query.equal('user_id', user.$id),
        Query.orderDesc('\$createdAt'),
      ];

      if(loadWithProduct) {
        queries.add(Query.select([
          '\$id',
          'product.*',
          '\$createdAt',
        ]));
      }

      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.favoritesCollection,
        queries: queries,
      );

      return response.rows
          .map((doc) => FavoriteModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      log('Error fetching favorites: $e');
      rethrow;
    }
  }

  @override
  Future<FavoriteModel> addFavorite(String productId) async {
    try {
      User? user = await appwriteService.getCurrentUser();

      if (user == null) {
        throw Exception('User not logged in');
      }

      // Check if already favorited
      final existing = await getFavoriteId(productId);
      if (existing != null) {
        throw Exception('Product already in favorites');
      }

      final response = await appwriteService.createRow(
        collectionId: AppwriteConfig.favoritesCollection,
        data: {
          'user_id': user.$id,
          'product_id': productId,
          'product': productId,
        },
      );

      return FavoriteModel.fromJson(response.data);
    } catch (e) {
      log('Error adding favorite: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeFavorite(String favoriteId) async {
    try {
      await appwriteService.deleteRow(
        collectionId: AppwriteConfig.favoritesCollection,
        rowId: favoriteId,
      );
    } catch (e) {
      log('Error removing favorite: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isFavorite(String productId) async {
    try {
      final favoriteId = await getFavoriteId(productId);
      return favoriteId != null;
    } catch (e) {
      log('Error checking favorite status: $e');
      return false;
    }
  }

  @override
  Future<String?> getFavoriteId(String productId) async {
    try {
      User? user = await appwriteService.getCurrentUser();

      if (user == null) {
        return null;
      }

      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.favoritesCollection,
        queries: [
          Query.equal('user_id', user.$id),
          Query.equal('product_id', productId),
          Query.limit(1),
        ],
      );

      if (response.rows.isNotEmpty) {
        return response.rows.first.data['\$id'];
      }

      return null;
    } catch (e) {
      log('Error getting favorite ID: $e');
      return null;
    }
  }
}
