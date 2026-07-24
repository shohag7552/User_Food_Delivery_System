import 'dart:ui';
import 'package:appwrite_user_app/app/common/widgets/auth_gate.dart';
import 'package:appwrite_user_app/app/controllers/profile_controller.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:appwrite_user_app/app/common/widgets/directional_flip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AuthGate(
        child: GetBuilder<ProfileController>(
        builder: (controller) {
          if (controller.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: ColorResource.primaryDark,
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // Animated App Bar with Gradient
              _buildSliverAppBar(context, controller),

              // Profile Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Profile Information Card
                        _buildGlassmorphicCard(
                          context: context,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('personal_information'.tr),
                              const SizedBox(height: 20),

                              // Name Field
                              _buildCustomTextField(
                                context: context,
                                controller: controller.nameController,
                                label: 'full_name_label'.tr,
                                icon: Icons.person_outline,
                                validator: controller.validateName,
                              ),
                              const SizedBox(height: 16),

                              // Email Field
                              _buildCustomTextField(
                                context: context,
                                controller: controller.emailController,
                                label: 'email_address_label'.tr,
                                icon: Icons.email_outlined,
                                validator: controller.validateEmail,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),

                              // Phone Field
                              _buildCustomTextField(
                                context: context,
                                controller: controller.phoneController,
                                label: 'phone_number_label'.tr,
                                icon: Icons.phone_outlined,
                                validator: controller.validatePhone,
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Save Button with Gradient
                        _buildSaveButton(context, controller),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    ProfileController controller,
  ) {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: ColorResource.primaryDark,
      leading: IconButton(
        icon: DirectionalFlip(
          child: Icon(Icons.arrow_back, color: ColorResource.textWhite),
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ColorResource.primaryDark,
                ColorResource.primaryDark.withValues(alpha: 0.8),
                ColorResource.primaryLight,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Profile Picture with Edit Overlay
                _buildProfilePicture(context, controller),

                const SizedBox(height: 16),

                Text(
                  'edit_profile'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: 24,
                    color: ColorResource.textWhite,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'update_your_personal_info'.tr,
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: ColorResource.textWhite.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicture(
    BuildContext context,
    ProfileController controller,
  ) {
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Animated Ring
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ColorResource.textWhite.withValues(alpha: 0.3),
              width: 3,
            ),
          ),
        ),

        // Profile Image
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(
            child: controller.userProfile?.profileImageUrl != null
                ? Image.network(
                    controller.userProfile!.profileImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildAvatarPlaceholder(controller);
                    },
                  )
                : _buildAvatarPlaceholder(controller),
          ),
        ),

        // Loading Indicator
        if (controller.isUploadingImage)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.5),
            ),
            child: Center(
              child: CircularProgressIndicator(color: ColorResource.textWhite),
            ),
          ),

        // Edit Button
        if (!controller.isUploadingImage)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _showImageSourceDialog(context, controller),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: ColorResource.primaryGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: ColorResource.textWhite, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: ColorResource.primaryDark.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: ColorResource.textWhite,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder(ProfileController controller) {
    return Container(
      color: ColorResource.primaryDark.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          controller.userProfile?.initials ?? '?',
          style: poppinsBold.copyWith(
            fontSize: 40,
            color: ColorResource.primaryDark,
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog(
    BuildContext context,
    ProfileController controller,
  ) {
    final theme = Theme.of(context);

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'choose_profile_picture'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeLarge,
                    color:
                        theme.textTheme.titleLarge?.color ??
                        context.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildImageSourceOption(
                        context: context,
                        icon: Icons.photo_library_outlined,
                        label: 'gallery'.tr,
                        onTap: () {
                          Navigator.pop(context);
                          controller.uploadProfileImage();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildImageSourceOption(
                        context: context,
                        icon: Icons.camera_alt_outlined,
                        label: 'camera'.tr,
                        onTap: () {
                          Navigator.pop(context);
                          controller.takePhoto();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  Widget _buildImageSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.inputDecorationTheme.fillColor?.withValues(alpha: 0.5),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: ColorResource.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: ColorResource.textWhite, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeDefault,
                color:
                    theme.textTheme.bodyMedium?.color ??
                    context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassmorphicCard({
    required BuildContext context,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: isDark ? 24 : 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.cardColor.withValues(alpha: isDark ? 0.92 : 0.9),
                  theme.cardColor.withValues(alpha: isDark ? 0.72 : 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: ColorResource.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: poppinsBold.copyWith(
            fontSize: 18,
            color: ColorResource.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: poppinsRegular.copyWith(
        fontSize: Constants.fontSizeDefault,
        color: theme.textTheme.bodyLarge?.color ?? context.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: poppinsMedium.copyWith(
          fontSize: Constants.fontSizeDefault,
          color: theme.hintColor,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: ColorResource.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: ColorResource.textWhite, size: 20),
        ),
        filled: true,
        fillColor:
            theme.inputDecorationTheme.fillColor ??
            theme.colorScheme.surface.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorResource.primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorResource.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorResource.error, width: 2),
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, ProfileController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: ColorResource.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorResource.primaryDark.withValues(
              alpha: isDark ? 0.25 : 0.4,
            ),
            blurRadius: isDark ? 14 : 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: controller.isUpdating
              ? null
              : () async {
                  final saved = await controller.updateUserProfile();
                  // Navigation stays in the view: return to the profile
                  // page once the save succeeds.
                  if (saved && context.mounted) {
                    context.pop();
                  }
                },
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: controller.isUpdating
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorResource.textWhite,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: ColorResource.textWhite,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'save_changes'.tr,
                        style: poppinsBold.copyWith(
                          fontSize: 16,
                          color: ColorResource.textWhite,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
