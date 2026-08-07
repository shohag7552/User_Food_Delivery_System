import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_button.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_text_field.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:flutter/material.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreeToTerms) {
        customToster(
          'Please agree to the Terms & Conditions',
          isSuccess: false,
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final success = await Get.find<AuthController>().signup(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          // Navigate to dashboard after successful signup
          context.goNamed(RouteNames.dashboard);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: isWide
          ? null
          : CustomAppbar(
              title: 'create_account'.tr,
              showBackButton: context.canPop(),
            ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: Constants.paddingSizeLarge,
              vertical: Constants.paddingSizeDefault,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isWide && context.canPop()) _buildBackButton(context),
                      _buildHeader(context),
                      const SizedBox(height: Constants.paddingSizeExtraLarge),
                      _buildForm(context),
                      const SizedBox(height: Constants.paddingSizeExtraLarge),
                      _buildDivider(context),
                      const SizedBox(height: Constants.paddingSizeLarge),
                      _buildSocialButtons(context),
                      const SizedBox(height: Constants.paddingSizeExtraLarge),
                      _buildLoginLink(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Constants.paddingSizeDefault),
        child: InkWell(
          onTap: () => context.pop(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.cardBackground,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: context.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: Constants.paddingSizeSmall),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorResource.primaryDark.withValues(alpha: 0.1),
          ),
          child: const Icon(
            Icons.person_add_rounded,
            size: 44,
            color: ColorResource.primaryDark,
          ),
        ),
        const SizedBox(height: Constants.paddingSizeLarge),
        Text(
          'create_account'.tr,
          textAlign: TextAlign.center,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeOverLarge,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: Constants.paddingSizeExtraSmall),
        Text(
          'sign_up_to_get_started'.tr,
          textAlign: TextAlign.center,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name Field
          CustomTextField(
            controller: _nameController,
            label: 'full_name'.tr,
            hintText: 'enter_your_full_name'.tr,
            icon: Icons.person_outline,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'please_enter_your_name'.tr;
              }
              if (value.length < 3) {
                return 'name_min_3_chars'.tr;
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Phone Field
          CustomTextField(
            controller: _phoneController,
            label: 'phone_number'.tr,
            hintText: 'enter_your_phone_number'.tr,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'please_enter_your_phone_number'.tr;
              }
              if (!RegExp(r'^[0-9+\-\s()]{10,}$').hasMatch(value)) {
                return 'please_enter_valid_phone_number'.tr;
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Email Field
          CustomTextField(
            controller: _emailController,
            label: 'email'.tr,
            hintText: 'enter_your_email'.tr,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'please_enter_your_email'.tr;
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'please_enter_a_valid_email'.tr;
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Password Field
          CustomTextField(
            controller: _passwordController,
            label: 'password'.tr,
            hintText: 'create_a_password'.tr,
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: context.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'please_enter_a_password'.tr;
              }
              if (value.length < 8) {
                return 'password_min_8_chars'.tr;
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Confirm Password Field
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'confirm_password'.tr,
            hintText: 'confirm_your_password_hint'.tr,
            icon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: context.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'please_confirm_your_password'.tr;
              }
              if (value != _passwordController.text) {
                return 'passwords_do_not_match'.tr;
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Terms and Conditions Checkbox
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _agreeToTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreeToTerms = value ?? false;
                    });
                  },
                  activeColor: ColorResource.primaryDark,
                  side: BorderSide(color: context.textLight, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: poppinsRegular.copyWith(
                      fontSize: 13,
                      color: context.textSecondary,
                    ),
                    children: [
                      const TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: poppinsMedium.copyWith(
                          fontSize: 13,
                          color: ColorResource.primaryDark,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: poppinsMedium.copyWith(
                          fontSize: 13,
                          color: ColorResource.primaryDark,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Signup Button
          CustomButton(
            buttonText: 'create_account'.tr,
            onPressed: _handleSignup,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: context.textLight.withValues(alpha: 0.2),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or'.tr,
            style: poppinsMedium.copyWith(
              fontSize: 14,
              color: context.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: context.textLight.withValues(alpha: 0.2),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialSignupButton(
          icon: Icons.g_mobiledata_rounded,
          label: 'Google',
          onTap: () {
            Get.find<AuthController>().logout();
            // TODO: Implement Google signup
          },
        ),
        const SizedBox(width: 16),
        _SocialSignupButton(
          icon: Icons.facebook,
          label: 'Facebook',
          onTap: () {
            // TODO: Implement Facebook signup
          },
        ),
        const SizedBox(width: 16),
        _SocialSignupButton(
          icon: Icons.apple,
          label: 'Apple',
          onTap: () {
            // TODO: Implement Apple signup
          },
        ),
      ],
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'already_have_an_account'.tr,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: context.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () => context.pop(),
          style: TextButton.styleFrom(
            foregroundColor: ColorResource.primaryDark,
            padding: const EdgeInsets.symmetric(
              horizontal: Constants.paddingSizeSmall,
            ),
          ),
          child: Text(
            'sign_in'.tr,
            style: poppinsBold.copyWith(fontSize: Constants.fontSizeDefault),
          ),
        ),
      ],
    );
  }
}

class _SocialSignupButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialSignupButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 32, color: ColorResource.primaryDark),
      ),
    );
  }
}
