import 'dart:async';

import 'package:appwrite_user_app/app/common/widgets/custom_button.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/modules/auth/widgets/auth_field_decoration.dart';
import 'package:appwrite_user_app/app/modules/auth/widgets/auth_status_panel.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/images.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// Landing page for the link in Appwrite's recovery email:
/// `…/reset-password?userId=…&secret=…&expire=…`.
///
/// Reached with **no session**, and usually on a cold start — a browser tab, or
/// an Android App Link / iOS Universal Link straight into the app. Everything
/// it needs therefore arrives through the query string; never through `extra`,
/// which is always null on a platform-delivered route.
class ResetPasswordScreen extends StatefulWidget {
  final String userId;
  final String secret;

  const ResetPasswordScreen({
    super.key,
    required this.userId,
    required this.secret,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const double _maxContentWidth = 440;
  static const double _logoSize = 76;

  /// Appwrite's server-side minimum. The sign-in form accepts 6 because older
  /// accounts may have shorter passwords, but anything under 8 is rejected
  /// here by the API with an error the user cannot act on.
  static const int _minPasswordLength = 8;

  /// Lock-out after each submit. Appwrite rate-limits the recovery endpoint,
  /// and a burst of retries on a bad link only earns a confusing 429.
  static const int _submitCooldownSeconds = 60;

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _done = false;

  Timer? _cooldownTimer;
  int _cooldownLeft = 0;
  bool get _coolingDown => _cooldownLeft > 0;

  bool get _hasCredentials =>
      widget.userId.isNotEmpty && widget.secret.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // A stale error from an earlier attempt must not greet the user here.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Get.find<AuthController>().clearResetError(),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _confirmFocus.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownLeft = _submitCooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldownLeft--);
      if (_cooldownLeft <= 0) timer.cancel();
    });
  }

  Future<void> _submit() async {
    final controller = Get.find<AuthController>();
    // The keyboard's "done" action reaches here too, so guard it as well as
    // disabling the button.
    if (_coolingDown || controller.isResettingPassword) return;

    FocusScope.of(context).unfocus();
    // A form the user still has to fix is not a request — no cooldown.
    if (!_formKey.currentState!.validate()) return;

    // The countdown starts the moment the request goes out, so it also covers
    // the time spent waiting on the server.
    _startCooldown();
    final success = await controller.resetPasswordWithLink(
      userId: widget.userId,
      secret: widget.secret,
      password: _passwordController.text,
    );

    if (!mounted || !success) return;

    _cooldownTimer?.cancel();
    customToster('password_updated_success'.tr, isSuccess: true);
    setState(() {
      _cooldownLeft = 0;
      _done = true;
    });
  }

  /// Appwrite does not create a session for a completed recovery, so the user
  /// is still signed out and has to sign in with the new password.
  ///
  /// On native this screen may have been opened by a cold deep link, which
  /// bypasses the splash — and with it `Global.init`'s settings/module
  /// bootstrap. Route back through the splash so the rest of the app is
  /// hydrated before the user reaches it. On web that bootstrap already ran
  /// before the first frame, so go straight to sign-in.
  void _goSignIn() {
    if (kIsWeb) {
      context.go(AppRouter.login);
    } else {
      context.go(
        '${AppRouter.splash}?next=${Uri.encodeComponent(AppRouter.login)}',
      );
    }
  }

  void _requestNewLink() => context.go(AppRouter.forgotPassword);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: Constants.paddingSizeExtraLarge),
                  _buildBody(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final showSubtitle = _hasCredentials && !_done;

    return Column(
      children: [
        const SizedBox(height: Constants.paddingSizeLarge),
        ClipRRect(
          borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
          child: Image.asset(
            Images.logo,
            width: _logoSize,
            height: _logoSize,
            fit: BoxFit.cover,
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: Constants.paddingSizeLarge),
          Text(
            'reset_your_password'.tr,
            textAlign: TextAlign.center,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeOverLarge,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: Constants.paddingSizeExtraSmall),
          Text(
            'reset_password_subtitle'.tr,
            textAlign: TextAlign.center,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: context.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBody() {
    // A link with no credentials can never succeed — say so without spending a
    // network call on it.
    if (!_hasCredentials) {
      return AuthStatusPanel(
        icon: Icons.link_off_rounded,
        iconColor: ColorResource.error,
        title: 'reset_link_invalid_title'.tr,
        message: 'reset_link_invalid_or_expired'.tr,
        primaryLabel: 'request_new_reset_link'.tr,
        onPrimary: _requestNewLink,
        secondaryLabel: 'back_to_sign_in'.tr,
        onSecondary: _goSignIn,
      );
    }

    if (_done) {
      return AuthStatusPanel(
        icon: Icons.check_circle_outline_rounded,
        iconColor: ColorResource.success,
        title: 'password_updated_title'.tr,
        message: 'password_updated_message'.tr,
        primaryLabel: 'sign_in'.tr,
        onPrimary: _goSignIn,
      );
    }

    return _buildForm();
  }

  Widget _buildForm() {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            authFieldLabel(context, 'new_password'.tr),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: context.textPrimary,
              ),
              decoration: authInputDecoration(
                context,
                hint: 'enter_new_password'.tr,
                icon: Icons.lock_outline_rounded,
                suffix: _visibilityToggle(
                  obscured: _obscurePassword,
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'please_enter_new_password'.tr;
                }
                if (value.length < _minPasswordLength) {
                  return 'password_must_be_at_least_8_characters'.tr;
                }
                return null;
              },
            ),

            const SizedBox(height: Constants.paddingSizeDefault),

            authFieldLabel(context, 'confirm_new_password'.tr),
            TextFormField(
              controller: _confirmController,
              focusNode: _confirmFocus,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _submit(),
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: context.textPrimary,
              ),
              decoration: authInputDecoration(
                context,
                hint: 're_enter_new_password'.tr,
                icon: Icons.lock_outline_rounded,
                suffix: _visibilityToggle(
                  obscured: _obscureConfirm,
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'please_confirm_new_password'.tr;
                }
                if (value != _passwordController.text) {
                  return 'passwords_do_not_match'.tr;
                }
                return null;
              },
            ),

            const SizedBox(height: Constants.paddingSizeLarge),

            GetBuilder<AuthController>(
              builder: (controller) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomButton(
                    // While cooling down the button is disabled and counts
                    // down, so the user can see when they may try again.
                    buttonText: _coolingDown && !controller.isResettingPassword
                        ? 'try_again_in_seconds'.trParams({
                            'seconds': '$_cooldownLeft',
                          })
                        : 'update_password'.tr,
                    onPressed: _coolingDown ? null : _submit,
                    isLoading: controller.isResettingPassword,
                  ),
                  if (controller.resetErrorKey != null)
                    _buildInlineError(controller.resetErrorKey!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Persistent explanation under the button. A toast has usually faded by the
  /// time the user looks up from the keyboard, and an expired link needs a way
  /// forward rather than just an apology.
  Widget _buildInlineError(String errorKey) {
    final isExpired = errorKey == 'reset_link_invalid_or_expired';

    return Padding(
      padding: const EdgeInsets.only(top: Constants.paddingSizeDefault),
      child: Container(
        padding: const EdgeInsets.all(Constants.paddingSizeDefault),
        decoration: BoxDecoration(
          color: ColorResource.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
          border: Border.all(
            color: ColorResource.error.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: ColorResource.error,
                ),
                const SizedBox(width: Constants.paddingSizeSmall),
                Expanded(
                  child: Text(
                    errorKey.tr,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: context.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (isExpired)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _requestNewLink,
                  style: TextButton.styleFrom(
                    foregroundColor: ColorResource.primaryDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Constants.paddingSizeSmall,
                    ),
                  ),
                  child: Text(
                    'request_new_reset_link'.tr,
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeDefault,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _visibilityToggle({
    required bool obscured,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: context.textSecondary,
      ),
      tooltip: obscured ? 'show_password'.tr : 'hide_password'.tr,
    );
  }
}
