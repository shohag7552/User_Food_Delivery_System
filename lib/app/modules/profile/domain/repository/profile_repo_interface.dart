import 'package:appwrite_user_app/app/models/user_model.dart';
import 'package:image_picker/image_picker.dart';

abstract class ProfileRepoInterface {
  /// Get current user's profile data
  Future<UserModel> getUserProfile();

  /// Update user profile information
  Future<UserModel> updateProfile(UserModel user);

  /// Upload profile image and return image URL
  Future<String?> uploadProfileImage(XFile image);
}
