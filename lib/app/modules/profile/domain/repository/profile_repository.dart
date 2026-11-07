import 'dart:developer';
import 'package:appwrite/models.dart';
import 'package:kikomart_user_app/app/appwrite/appwrite_config.dart';
import 'package:kikomart_user_app/app/appwrite/appwrite_service.dart';
import 'package:kikomart_user_app/app/models/user_model.dart';
import 'package:kikomart_user_app/app/modules/profile/domain/repository/profile_repo_interface.dart';
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
      // Through the backend: the row also holds the wallet and loyalty points,
      // so only the profile fields of this map are written.
      final updated = await appwriteService.updateOwnProfile(user.toJson());

      // Also update the account name if it changed
      try {
        await appwriteService.updateName(name: user.name);
      } catch (e) {
        log('Warning: Could not update account name: $e');
      }

      return UserModel.fromJson(updated);
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
}
