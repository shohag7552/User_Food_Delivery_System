import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_button.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/modules/auth/widgets/auth_field_decoration.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/images.dart';
import 'package:flutter/material.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// Full-page sign-in (mobile). The web flow uses `AuthDialog` instead.
///
/// The page sits on the normal app background rather than a full-bleed brand
/// gradient: the brand shows up where it carries meaning — the logo, the focus
/// ring, the primary action — so the form itself stays high-contrast and
/// readable in both light and dark mode.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  /// Caps the form on tablets / large phones so fields never stretch into
  /// unreadably long lines.
  static const double _maxContentWidth = 440;
  static const double _logoSize = 76;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Prefill from the last "remember me" sign-in, if there was one.
    final remembered = Get.find<AuthController>().rememberedCredentials;
    if (remembered != null) {
      _emailController.text = remembered.email;
      _passwordController.text = remembered.password;
      _rememberMe = true;
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_fadeAnimation);
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Dismiss the keyboard so the result (error toast / navigation) is visible.
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await Get.find<AuthController>().login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      rememberMe: _rememberMe,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      context.goNamed(RouteNames.dashboard);
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
          : CustomAppbar(title: 'sign_in'.tr, showBackButton: context.canPop()),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: Constants.paddingSizeLarge,
              vertical: Constants.paddingSizeDefault,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
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
                      _buildSignupLink(context),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
          child: Image.asset(
            Images.logo,
            width: _logoSize,
            height: _logoSize,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: Constants.paddingSizeLarge),
        Text(
          'welcome_back'.tr,
          textAlign: TextAlign.center,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeOverLarge,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: Constants.paddingSizeExtraSmall),
        Text(
          'sign_in_to_continue'.tr,
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
    // AutofillGroup lets the OS password manager offer to fill / save the pair.
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            authFieldLabel(context, 'email'.tr),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: context.textPrimary,
              ),
              decoration: authInputDecoration(
                context,
                hint: 'enter_your_email'.tr,
                icon: Icons.mail_outline_rounded,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'please_enter_your_email'.tr;
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value.trim())) {
                  return 'please_enter_a_valid_email'.tr;
                }
                return null;
              },
            ),

            const SizedBox(height: Constants.paddingSizeDefault),

            authFieldLabel(context, 'password'.tr),
            TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _handleLogin(),
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: context.textPrimary,
              ),
              decoration: authInputDecoration(
                context,
                hint: 'enter_your_password'.tr,
                icon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: context.textSecondary,
                  ),
                  tooltip: _obscurePassword
                      ? 'show_password'.tr
                      : 'hide_password'.tr,
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

            const SizedBox(height: Constants.paddingSizeSmall),

            // Remember me / forgot password — the conventional pairing, so
            // both options are found where users already look for them.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: _buildRememberMe(context)),
                TextButton(
                  onPressed: () => context.pushNamed(RouteNames.forgotPassword),
                  style: TextButton.styleFrom(
                    foregroundColor: ColorResource.primaryDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Constants.paddingSizeSmall,
                    ),
                  ),
                  child: Text(
                    'forgot_password_q'.tr,
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeSmall,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: Constants.paddingSizeDefault),

            CustomButton(
              buttonText: 'sign_in'.tr,
              onPressed: _handleLogin,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  /// The label is part of the control's tap target — tapping the text toggles
  /// the box, which a bare [Checkbox] does not give you.
  Widget _buildRememberMe(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _rememberMe = !_rememberMe),
      borderRadius: BorderRadius.circular(Constants.radiusDefault),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          0,
          Constants.paddingSizeExtraSmall,
          Constants.paddingSizeExtraSmall,
          Constants.paddingSizeExtraSmall,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: Constants.paddingSizeLarge,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) =>
                    setState(() => _rememberMe = value ?? false),
                activeColor: ColorResource.primaryDark,
                side: BorderSide(color: context.textLight, width: 1.5),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Constants.radiusSmall),
                ),
              ),
            ),
            const SizedBox(width: Constants.paddingSizeSmall),
            Flexible(
              child: Text(
                'remember_me'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: context.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'don_t_have_an_account'.tr,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: context.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () => context.pushNamed(RouteNames.signup),
          style: TextButton.styleFrom(
            foregroundColor: ColorResource.primaryDark,
            padding: const EdgeInsets.symmetric(
              horizontal: Constants.paddingSizeSmall,
            ),
          ),
          child: Text(
            'sign_up'.tr,
            style: poppinsBold.copyWith(fontSize: Constants.fontSizeDefault),
          ),
        ),
      ],
    );
  }

}
