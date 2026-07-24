import 'package:appwrite_user_app/app/common/widgets/custom_button.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:flutter/material.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(BuildContext context) async {
    print('------------Login button pressed');
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await Get.find<AuthController>()
          .login(_emailController.text.trim(), _passwordController.text.trim())
          .then((v) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });

              if (v) {
                context.goNamed(RouteNames.dashboard);
              }
            }
          });
      // // TODO: Implement auth logic
      // // Simulate auth delay
      // Future.delayed(const Duration(seconds: 2), () {
      //   if (mounted) {
      //     setState(() {
      //       _isLoading = false;
      //     });
      //   }
      // });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: ColorResource.primaryGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),

                    // Logo and Welcome Text
                    Center(
                      child: Column(
                        children: [
                          // Logo Container with glow effect
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.store_rounded,
                              size: 60,
                              color: ColorResource.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Welcome Text
                          Text(
                            'welcome_back'.tr,
                            style: poppinsBold.copyWith(
                              fontSize: 32,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'sign_in_to_continue'.tr,
                            style: poppinsRegular.copyWith(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 50),

                    // Login Form Card — theme-aware (dark card in dark mode).
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: context.cardBackground
                            .withValues(alpha: 0.97),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email Field
                            Text(
                              'email'.tr,
                              style: poppinsMedium.copyWith(
                                fontSize: 14,
                                color: ColorResource.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: poppinsRegular.copyWith(
                                fontSize: 16,
                                color: context.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'enter_your_email'.tr,
                                hintStyle: poppinsRegular.copyWith(
                                  fontSize: 14,
                                  color: context.textLight,
                                ),
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: ColorResource.primaryDark,
                                ),
                                filled: true,
                                // Dark surface in dark mode, light grey in light.
                                fillColor: context.scaffoldBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: ColorResource.primaryDark,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
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
                            Text(
                              'password'.tr,
                              style: poppinsMedium.copyWith(
                                fontSize: 14,
                                color: ColorResource.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: poppinsRegular.copyWith(
                                fontSize: 16,
                                color: context.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'enter_your_password'.tr,
                                hintStyle: poppinsRegular.copyWith(
                                  fontSize: 14,
                                  color: context.textLight,
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: ColorResource.primaryDark,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: ColorResource.primaryDark,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                // Dark surface in dark mode, light grey in light.
                                fillColor: context.scaffoldBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: ColorResource.primaryDark,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'please_enter_your_password'.tr;
                                }
                                if (value.length < 6) {
                                  return 'password_min_6_chars'.tr;
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 12),

                            // Forgot Password
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton(
                                onPressed: () {
                                  context.pushNamed(RouteNames.forgotPassword);
                                },
                                child: Text(
                                  'forgot_password_q'.tr,
                                  style: poppinsMedium.copyWith(
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Login Button
                            CustomButton(
                              buttonText: 'sign_in'.tr,
                              onPressed: () => _handleLogin(context),
                              isLoading: _isLoading,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                   /* // Or Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.3),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or'.tr,
                            style: poppinsMedium.copyWith(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.3),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Social Login Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialLoginButton(
                          icon: Icons.g_mobiledata_rounded,
                          onTap: () {
                            // TODO: Implement Google login
                          },
                        ),
                        const SizedBox(width: 16),
                        _SocialLoginButton(
                          icon: Icons.facebook,
                          onTap: () {
                            // TODO: Implement Facebook login
                          },
                        ),
                        const SizedBox(width: 16),
                        _SocialLoginButton(
                          icon: Icons.apple,
                          onTap: () {
                            // TODO: Implement Apple login
                          },
                        ),
                      ],
                    ),*/

                    const SizedBox(height: 32),

                    // Sign Up Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "don_t_have_an_account".tr,
                            style: poppinsRegular.copyWith(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              context.pushNamed(RouteNames.signup);
                            },
                            child: Text(
                              'sign_up'.tr,
                              style: poppinsBold.copyWith(
                                fontSize: 14,
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialLoginButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
