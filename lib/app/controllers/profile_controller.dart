import 'dart:developer';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/models/user_model.dart';
import 'package:appwrite_user_app/app/modules/profile/domain/repository/profile_repo_interface.dart';
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

  /// Fetch user profile from database
  Future<void> fetchUserProfile() async {
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
      customToster('Failed to load profile', isSuccess: false);
    }
  }

  /// Update user profile
  Future<void> updateUserProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
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

      customToster('Profile updated successfully');
      Get.back(); // Return to profile page
    } catch (e) {
      _isUpdating = false;
      update();
      log('Error updating profile: $e');
      customToster('Failed to update profile', isSuccess: false);
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

        customToster('Profile picture updated');
      }

      _isUploadingImage = false;
      update();
    } catch (e) {
      _isUploadingImage = false;
      update();
      log('Error uploading profile image: $e');
      customToster('Failed to upload image', isSuccess: false);
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

        customToster('Profile picture updated');
      }

      _isUploadingImage = false;
      update();
    } catch (e) {
      _isUploadingImage = false;
      update();
      log('Error taking photo: $e');
      customToster('Failed to upload image', isSuccess: false);
    }
  }

  /// Validate name
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validate email
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  /// Validate phone
  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove spaces and dashes
    final cleanedPhone = value.replaceAll(RegExp(r'[\s-]'), '');
    
    // Basic phone validation (at least 10 digits)
    if (cleanedPhone.length < 10) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}
