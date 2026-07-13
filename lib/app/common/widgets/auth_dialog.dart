import 'package:appwrite_user_app/app/common/widgets/custom_button.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// Entry point for opening the auth UI from anywhere.
///
/// On web the login / signup experience is a centered modal dialog; on mobile
/// it stays a full-page route. Call these instead of navigating to the auth
/// routes directly so the behaviour is consistent app-wide.
abstract class AuthFlow {
  const AuthFlow._();

  static void openLogin(BuildContext context) {
    if (kIsWeb) {
      AuthDialog.show(context);
    } else {
      context.pushNamed(RouteNames.login);
    }
  }

  static void openSignup(BuildContext context) {
    if (kIsWeb) {
      AuthDialog.show(context, signup: true);
    } else {
      context.pushNamed(RouteNames.signup);
    }
  }
}

/// Compact login / signup modal used on web. Toggles between the two modes,
/// drives [AuthController], and simply closes itself on success — the cached
/// `AuthController.isLoggedIn` flip lets any [AuthGate] reveal its content.
class AuthDialog extends StatefulWidget {
  final bool startWithSignup;

  const AuthDialog({super.key, this.startWithSignup = false});

  static Future<void> show(BuildContext context, {bool signup = false}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => AuthDialog(startWithSignup: signup),
    );
  }

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  late bool _isSignup = widget.startWithSignup;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isSignup = !_isSignup;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = Get.find<AuthController>();
    final success = _isSignup
        ? await auth.signup(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
          )
        : await auth.login(
            _emailController.text.trim(),
            _passwordController.text,
          );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _openForgotPassword() {
    Navigator.of(context).pop();
    AppRouter.router.pushNamed(RouteNames.forgotPassword);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.cardBackground,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                if (_isSignup) ...[
                  _field(
                    controller: _nameController,
                    label: 'full_name'.tr,
                    icon: Icons.person_outline_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'please_enter_your_name'.tr
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    controller: _phoneController,
                    label: 'phone_number'.tr,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'please_enter_your_phone'.tr
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],
                _field(
                  controller: _emailController,
                  label: 'email'.tr,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'please_enter_your_email'.tr;
                    }
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'please_enter_a_valid_email'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _passwordController,
                  label: 'password'.tr,
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscurePassword,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: context.textLight,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'please_enter_your_password'.tr;
                    }
                    if (v.length < 6) return 'password_min_6_chars'.tr;
                    return null;
                  },
                ),
                if (!_isSignup)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _openForgotPassword,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'forgot_password_q'.tr,
                        style: poppinsMedium.copyWith(
                          fontSize: Constants.fontSizeSmall,
                          color: ColorResource.primaryDark,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                GetBuilder<AuthController>(
                  builder: (auth) => CustomButton(
                    buttonText: _isSignup ? 'sign_up'.tr : 'login'.tr,
                    isLoading: auth.isLoading,
                    onPressed: _submit,
                  ),
                ),
                const SizedBox(height: 16),
                _buildToggle(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSignup ? 'create_account'.tr : 'welcome_back'.tr,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeOverLarge,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isSignup
                    ? 'sign_up_to_get_started'.tr
                    : 'login_to_your_account'.tr,
                style: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.close_rounded,
              color: context.textSecondary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggle() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            _isSignup
                ? 'already_have_an_account'.tr
                : 'dont_have_an_account'.tr,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: context.textSecondary,
            ),
          ),
          TextButton(
            onPressed: _toggleMode,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _isSignup ? 'login'.tr : 'sign_up'.tr,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: poppinsRegular.copyWith(fontSize: Constants.fontSizeDefault),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: ColorResource.primaryDark, size: 20),
        suffixIcon: suffix,
        labelStyle: poppinsRegular.copyWith(color: context.textLight),
        filled: true,
        fillColor: context.scaffoldBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          borderSide: BorderSide(
            color: context.textLight.withValues(alpha: 0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          borderSide: const BorderSide(
            color: ColorResource.primaryDark,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
