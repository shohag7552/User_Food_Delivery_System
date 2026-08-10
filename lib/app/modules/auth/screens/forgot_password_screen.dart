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
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// Step one of password recovery: collect the email, ask Appwrite to send the
/// reset link, then confirm.
///
/// The user never types a code here — Appwrite emails a one-hour link that
/// lands on [AppRouter.resetPassword], either in the installed app (App Link /
/// Universal Link) or in the browser.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  static const double _maxContentWidth = 440;
  static const double _logoSize = 76;

  /// Appwrite rate-limits `POST /account/recovery`; a cooldown keeps an
  /// impatient user from turning that into a confusing 429.
  static const int _resendCooldownSeconds = 60;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _emailSent = false;
  String _sentToEmail = '';

  Timer? _resendTimer;
  int _resendIn = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Someone who has just failed to sign in almost certainly wants to reset
    // the address they were trying — save them retyping it.
    final remembered = Get.find<AuthController>().rememberedCredentials;
    if (remembered != null) _emailController.text = remembered.email;

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
    _resendTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendIn = _resendCooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendIn--);
      if (_resendIn <= 0) timer.cancel();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final success = await Get.find<AuthController>().sendPasswordResetLink(
      email,
    );

    if (!mounted || !success) return;

    setState(() {
      _emailSent = true;
      _sentToEmail = email;
    });
    _startResendCooldown();
    customToster('reset_link_sent'.tr, isSuccess: true);
  }

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
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (context.canPop()) _buildBackButton(),
                      _buildHeader(),
                      const SizedBox(height: Constants.paddingSizeExtraLarge),
                      if (_emailSent) _buildSentPanel() else _buildForm(),
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

  Widget _buildBackButton() {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded),
        color: context.textPrimary,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      ),
    );
  }

  Widget _buildHeader() {
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
          'forgot_password'.tr,
          textAlign: TextAlign.center,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeOverLarge,
            color: context.textPrimary,
          ),
        ),
        if (!_emailSent) ...[
          const SizedBox(height: Constants.paddingSizeExtraSmall),
          Text(
            'forgot_password_subtitle'.tr,
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

  Widget _buildForm() {
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
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.username],
              onFieldSubmitted: (_) => _submit(),
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
            const SizedBox(height: Constants.paddingSizeLarge),
            GetBuilder<AuthController>(
              builder: (controller) => CustomButton(
                buttonText: 'send_reset_link'.tr,
                onPressed: _submit,
                isLoading: controller.isSendingResetLink,
              ),
            ),
            const SizedBox(height: Constants.paddingSizeDefault),
            Center(
              child: TextButton(
                onPressed: () => context.pop(),
                style: TextButton.styleFrom(
                  foregroundColor: ColorResource.primaryDark,
                ),
                child: Text(
                  'back_to_sign_in'.tr,
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

  /// Deliberately identical whether or not the address is registered — the
  /// repository swallows "user not found" so this form can't be used to work
  /// out who has an account.
  Widget _buildSentPanel() {
    final cooling = _resendIn > 0;

    return AuthStatusPanel(
      icon: Icons.mark_email_read_outlined,
      title: 'check_your_inbox'.tr,
      message: 'reset_link_sent_to'.trParams({'email': _sentToEmail}),
      footnote: 'reset_link_expires_in_one_hour'.tr,
      primaryLabel: 'back_to_sign_in'.tr,
      onPrimary: () => context.pop(),
      secondaryLabel: cooling
          ? 'resend_in_seconds'.trParams({'seconds': '$_resendIn'})
          : 'resend_reset_link'.tr,
      secondaryEnabled: !cooling,
      onSecondary: _submit,
    );
  }
}
