import 'dart:developer';
import 'package:appwrite/models.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/models/user_model.dart';
import 'package:appwrite_user_app/app/modules/profile/domain/repository/profile_repo_interface.dart';
import 'package:image_picker/image_picker.dart';

class ProfileRepository implements ProfileRepoInterface {
  final AppwriteService appwriteService;

  ProfileRepository({required this.appwriteService});

  @override
  Future<UserModel> getUserProfile() async {
    try {
      // Get current authenticated user
      User? user = await appwriteService.getCurrentUser();

      if (user == null) {
        throw Exception('User not logged in');
      }

      // Fetch user document from users collection
      final response = await appwriteService.getDocument(
        tableId: AppwriteConfig.usersCollection,
        rowId: user.$id,
      );

      return UserModel.fromJson(response.data);
    } catch (e) {
      log('Error fetching user profile: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    try {
      // Update user document
      final response = await appwriteService.updateTable(
        tableId: AppwriteConfig.usersCollection,
        rowId: user.id,
        data: user.toJson(),
      );

      // Also update the account name if it changed
      try {
        await appwriteService.updateName(name: user.name);
      } catch (e) {
        log('Warning: Could not update account name: $e');
      }

      return UserModel.fromJson(response.data);
    } catch (e) {
      log('Error updating profile: $e');
      rethrow;
    }
  }

  @override
  Future<String?> uploadProfileImage(XFile image) async {
    try {
      final imageUrl = await appwriteService.uploadImage(image);
      return imageUrl;
    } catch (e) {
      log('Error uploading profile image: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel> deductWalletBalance(double amount) async {
    try {
      // Get current user
      User? user = await appwriteService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Fetch current wallet balance from database
      final response = await appwriteService.getDocument(
        tableId: AppwriteConfig.usersCollection,
        rowId: user.$id,
      );

      final currentUser = UserModel.fromJson(response.data);
      final currentBalance = currentUser.walletBalance;

      if (currentBalance < amount) {
        throw Exception('Insufficient wallet balance');
      }

      final newBalance = currentBalance - amount;

      // Update only the wallet_balance field in Appwrite
      final updatedResponse = await appwriteService.updateTable(
        tableId: AppwriteConfig.usersCollection,
        rowId: user.$id,
        data: {'wallet_balance': newBalance},
      );

      return UserModel.fromJson(updatedResponse.data);
    } catch (e) {
      log('Error deducting wallet balance: $e');
      rethrow;
    }
  }
}
