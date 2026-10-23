import 'dart:developer';
import 'package:kikomart_user_app/app/common/widgets/custom_toster.dart';
import 'package:kikomart_user_app/app/helper/session_manager.dart';
import 'package:kikomart_user_app/app/models/user_model.dart';
import 'package:kikomart_user_app/app/modules/profile/domain/repository/profile_repo_interface.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController implements GetxService {
  final ProfileRepoInterface profileRepoInterface;

  ProfileController({required this.profileRepoInterface});

  UserModel? _userProfile;
  bool _isLoading = false;
  bool _isUpdating = false;
  bool _isUploadingImage = false;

  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  bool get isUploadingImage => _isUploadingImage;

  void setUserProfile(UserModel user) {
    _userProfile = user;
    nameController.text = user.name;
    emailController.text = user.email;
    phoneController.text = user.phone;
    update();
  }

  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Form key for validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    fetchUserProfile();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  /// Clears the in-memory profile (used on logout).
  void clearLocal() {
    _userProfile = null;
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    update();
  }

  /// Fetch user profile from database
  Future<void> fetchUserProfile() async {
    // Auth-required: never hit Appwrite for a guest.
    if (!isUserLoggedIn()) {
      _userProfile = null;
      return;
    }
    try {
      _isLoading = true;
      update();

      _userProfile = await profileRepoInterface.getUserProfile();

      // Populate form controllers
      nameController.text = _userProfile?.name ?? '';
      emailController.text = _userProfile?.email ?? '';
      phoneController.text = _userProfile?.phone ?? '';

      _isLoading = false;
      update();
    } catch (e) {
      _isLoading = false;
      update();
      log('Error fetching user profile: $e');
      customToster('failed_to_load_profile'.tr, isSuccess: false);
    }
  }

  /// Update user profile. Returns true on success — navigation (closing the
  /// edit page) is the calling view's responsibility, never the controller's.
  Future<bool> updateUserProfile() async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    try {
      _isUpdating = true;
      update();

      if (_userProfile == null) {
        throw Exception('No user profile loaded');
      }

      // Create updated user model
      final updatedUser = _userProfile!.copyWith(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
      );

      _userProfile = await profileRepoInterface.updateProfile(updatedUser);

      _isUpdating = false;
      update();

      customToster('profile_updated_successfully'.tr);
      return true;
    } catch (e) {
      _isUpdating = false;
      update();
      log('Error updating profile: $e');
      customToster('failed_to_update_profile'.tr, isSuccess: false);
      return false;
    }
  }

  /// Upload profile image
  Future<void> uploadProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      _isUploadingImage = true;
      update();

      // Upload image to storage
      final imageUrl = await profileRepoInterface.uploadProfileImage(image);

      if (imageUrl != null && _userProfile != null) {
        // Update profile with new image URL
        final updatedUser = _userProfile!.copyWith(profileImageUrl: imageUrl);
        _userProfile = await profileRepoInterface.updateProfile(updatedUser);

        customToster('profile_picture_updated'.tr);
      }

      _isUploadingImage = false;
      update();
    } catch (e) {
      _isUploadingImage = false;
      update();
      log('Error uploading profile image: $e');
      customToster('failed_to_upload_image'.tr, isSuccess: false);
    }
  }

  /// Take photo with camera
  Future<void> takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      _isUploadingImage = true;
      update();

      // Upload image to storage
      final imageUrl = await profileRepoInterface.uploadProfileImage(image);

      if (imageUrl != null && _userProfile != null) {
        // Update profile with new image URL
        final updatedUser = _userProfile!.copyWith(profileImageUrl: imageUrl);
        _userProfile = await profileRepoInterface.updateProfile(updatedUser);

        customToster('profile_picture_updated'.tr);
      }

      _isUploadingImage = false;
      update();
    } catch (e) {
      _isUploadingImage = false;
      update();
      log('Error taking photo: $e');
      customToster('failed_to_upload_image'.tr, isSuccess: false);
    }
  }

  /// Validate name
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'name_is_required'.tr;
    }
    if (value.trim().length < 2) {
      return 'name_min_2_chars'.tr;
    }
    return null;
  }

  /// Validate email
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'email_is_required'.tr;
    }

    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'please_enter_a_valid_email'.tr;
    }
    return null;
  }

  /// Validate phone
  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'phone_number_is_required'.tr;
    }

    // Remove spaces and dashes
    final cleanedPhone = value.replaceAll(RegExp(r'[\s-]'), '');

    // Basic phone validation (at least 10 digits)
    if (cleanedPhone.length < 10) {
      return 'invalid_phone'.tr;
    }
    return null;
  }

  /// Deduct amount from wallet balance
  /// Returns true if successful, false otherwise
  Future<bool> deductWalletBalance(double amount) async {
    try {
      final updatedUser = await profileRepoInterface.deductWalletBalance(amount);
      _userProfile = updatedUser;
      update();
      return true;
    } catch (e) {
      log('Error deducting wallet balance: $e');
      return false;
    }
  }

  /// Get current wallet balance
  double get walletBalance => _userProfile?.walletBalance ?? 0.0;
}
