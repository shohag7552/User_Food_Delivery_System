import 'package:appwrite_user_app/app/common/widgets/custom_button.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _otpRequested = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_emailFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await Get.find<AuthController>().requestPasswordResetOtp(
      _emailController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      if (success) {
        _otpRequested = true;
      }
    });

    if (success) {
      customToster('OTP sent to your email. Please check your inbox.');
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await Get.find<AuthController>().resetPasswordWithOtp(
      email: _emailController.text.trim(),
      otp: _otpController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      customToster('Password updated successfully. Please sign in.');
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: ColorResource.primaryGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    IconButton(
                      onPressed: Get.back,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  blurRadius: 28,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mark_email_read_outlined,
                              size: 48,
                              color: ColorResource.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _otpRequested
                                ? 'Enter OTP & new password'
                                : 'Forgot password?',
                            style: poppinsBold.copyWith(
                              fontSize: 30,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _otpRequested
                                ? 'Use the OTP sent to your email to set a new password.'
                                : 'Enter your email and we will send a password reset OTP.',
                            textAlign: TextAlign.center,
                            style: poppinsRegular.copyWith(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 42),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Form(
                            key: _emailFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildLabel('Email'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  readOnly: _otpRequested,
                                  style: poppinsRegular.copyWith(fontSize: 16),
                                  decoration: _inputDecoration(
                                    hintText: 'Enter your email',
                                    icon: Icons.email_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(
                                      r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value.trim())) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F6FB),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              _otpRequested
                                  ? 'Did not get the OTP? You can request a new one below.'
                                  : 'The OTP will be delivered to the user email through your Appwrite email provider.',
                              style: poppinsRegular.copyWith(
                                fontSize: 13,
                                color: ColorResource.primaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (!_otpRequested)
                            CustomButton(
                              buttonText: 'Send OTP',
                              onPressed: _requestOtp,
                              isLoading: _isLoading,
                            ),
                          if (_otpRequested)
                            Form(
                              key: _resetFormKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildLabel('OTP'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _otpController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    style: poppinsRegular.copyWith(fontSize: 16),
                                    decoration: _inputDecoration(
                                      hintText: 'Enter 6-digit OTP',
                                      icon: Icons.password_outlined,
                                      counterText: '',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter the OTP';
                                      }
                                      if (value.trim().length != 6) {
                                        return 'OTP must be 6 digits';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildLabel('New password'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: poppinsRegular.copyWith(fontSize: 16),
                                    decoration: _passwordDecoration(
                                      hintText: 'Enter your new password',
                                      obscureText: _obscurePassword,
                                      onToggle: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a new password';
                                      }
                                      if (value.length < 8) {
                                        return 'Password must be at least 8 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildLabel('Confirm password'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirmPassword,
                                    style: poppinsRegular.copyWith(fontSize: 16),
                                    decoration: _passwordDecoration(
                                      hintText: 'Re-enter your new password',
                                      obscureText: _obscureConfirmPassword,
                                      onToggle: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please confirm your password';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  CustomButton(
                                    buttonText: 'Update password',
                                    onPressed: _resetPassword,
                                    isLoading: _isLoading,
                                  ),
                                  TextButton(
                                    onPressed: _isLoading ? null : _requestOtp,
                                    child: Text(
                                      'Resend OTP',
                                      style: poppinsMedium.copyWith(
                                        fontSize: 14,
                                        color: ColorResource.primaryDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Text _buildLabel(String text) {
    return Text(
      text,
      style: poppinsMedium.copyWith(
        fontSize: 14,
        color: ColorResource.primaryDark,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    String? counterText,
  }) {
    return InputDecoration(
      hintText: hintText,
      counterText: counterText,
      prefixIcon: Icon(icon, color: ColorResource.primaryDark),
      filled: true,
      fillColor: Colors.grey[100],
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
        borderSide: const BorderSide(color: ColorResource.primaryDark, width: 2),
      ),
    );
  }

  InputDecoration _passwordDecoration({
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return _inputDecoration(
      hintText: hintText,
      icon: Icons.lock_outline,
    ).copyWith(
      suffixIcon: IconButton(
        icon: Icon(
          obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: ColorResource.primaryDark,
        ),
        onPressed: onToggle,
      ),
    );
  }
}
