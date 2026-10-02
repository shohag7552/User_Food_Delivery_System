import 'dart:async';

import 'package:appwrite_user_app/app/common/widgets/custom_button.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/modules/auth/widgets/auth_field_decoration.dart';
import 'package:appwrite_user_app/app/modules/auth/widgets/auth_status_panel.dart';
import 'package:appwrite_user_app/app/modules/auth/widgets/reset_code_field.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/images.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// Password recovery, in whichever mode the store uses.
///
/// * **Link mode** (default): collect the email, ask Appwrite to send the
///   reset link, then confirm. The link lands on [AppRouter.resetPassword],
///   either in the installed app (App Link / Universal Link) or the browser.
/// * **Email-code mode** (the store switched it on): Appwrite emails a
///   6-digit code (`createEmailToken`); entering it signs the customer in and
///   opens the dashboard. Their password is left unchanged.
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

  /// Link mode: the "check your inbox" panel is showing.
  bool _emailSent = false;
  String _sentToEmail = '';

  /// Email-code mode progress.
  _CodeStep _codeStep = _CodeStep.email;
  final _codeController = TextEditingController();

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
    _codeController.dispose();
    _resendTimer?.cancel();
    // Never leave a reset token behind once the user leaves the flow.
    Get.find<AuthController>().clearCodeReset(notify: false);
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

  /// From the email form.
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await _send(_emailController.text.trim());
  }

  /// "Resend" on the sent / code steps — the email form is no longer on
  /// screen, so reuse the address the last request went to.
  Future<void> _resend() async {
    if (_resendIn > 0) return;
    await _send(_sentToEmail);
  }

  Future<void> _send(String email) async {
    final outcome = await Get.find<AuthController>().requestPasswordReset(
      email,
    );
    if (!mounted) return;

    switch (outcome) {
      case ResetRequestOutcome.codeSent:
        _codeController.clear();
        setState(() {
          _sentToEmail = email;
          _codeStep = _CodeStep.code;
        });
        _startResendCooldown();
        customToster('reset_code_sent'.tr, isSuccess: true);
      case ResetRequestOutcome.linkSent:
        setState(() {
          _emailSent = true;
          _sentToEmail = email;
          _codeStep = _CodeStep.email;
        });
        _startResendCooldown();
        customToster('reset_link_sent'.tr, isSuccess: true);
      case ResetRequestOutcome.failed:
        break;
    }
  }

  Future<void> _verifyCode() async {
    final controller = Get.find<AuthController>();
    final code = _codeController.text.trim();
    if (code.length != 6 || controller.isVerifyingResetCode) return;
    FocusScope.of(context).unfocus();

    final ok = await controller.signInWithEmailCode(
      email: _sentToEmail,
      code: code,
    );
    if (!mounted) return;
    if (ok) {
      customToster('signed_in_with_email_code'.tr, isSuccess: true);
      context.goNamed(RouteNames.dashboard);
      return;
    }
    _codeController.clear();
  }

  void _changeEmail() {
    Get.find<AuthController>().clearCodeReset();
    _codeController.clear();
    setState(() => _codeStep = _CodeStep.email);
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
                      _buildBody(),
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

  Widget _buildBody() {
    if (_emailSent) return _buildSentPanel();
    return switch (_codeStep) {
      _CodeStep.email => _buildForm(),
      _CodeStep.code => _buildCodeStep(),
    };
  }

  /// Title + subtitle for the current step.
  (String, String?) get _headerText => switch (_codeStep) {
    _ when _emailSent => ('forgot_password'.tr, null),
    _CodeStep.email => (
      'forgot_password'.tr,
      Get.find<AuthController>().usesEmailCodeReset
          ? 'forgot_password_code_subtitle'.tr
          : 'forgot_password_subtitle'.tr,
    ),
    _CodeStep.code => (
      'enter_reset_code'.tr,
      'reset_code_sent_to'.trParams({'email': _sentToEmail}),
    ),
  };

  Widget _buildHeader() {
    final (title, subtitle) = _headerText;
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
          title,
          textAlign: TextAlign.center,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeOverLarge,
            color: context.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: Constants.paddingSizeExtraSmall),
          Text(
            subtitle,
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
              builder: (controller) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomButton(
                    buttonText: controller.usesEmailCodeReset
                        ? 'send_reset_code'.tr
                        : 'send_reset_link'.tr,
                    onPressed: _submit,
                    isLoading:
                        controller.isSendingResetLink ||
                        controller.isSendingResetCode,
                  ),
                ],
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
      onSecondary: _resend,
    );
  }

  Widget _buildCodeStep() {
    return GetBuilder<AuthController>(
      builder: (controller) {
        final errorKey = controller.resetErrorKey;
        final cooling = _resendIn > 0;
        final String? errorText = errorKey?.tr;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResetCodeField(
              controller: _codeController,
              hasError: errorText != null,
              enabled: !controller.isVerifyingResetCode,
              onCompleted: (_) => _verifyCode(),
            ),
            if (errorText != null) _buildInlineError(errorText),
            const SizedBox(height: Constants.paddingSizeSmall),
            Text(
              'email_code_expiry_hint'.tr,
              textAlign: TextAlign.center,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: Constants.paddingSizeLarge),
            CustomButton(
              buttonText: 'verify_and_sign_in'.tr,
              onPressed: _verifyCode,
              isLoading: controller.isVerifyingResetCode,
            ),
            const SizedBox(height: Constants.paddingSizeSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: cooling || controller.isSendingResetCode
                      ? null
                      : _resend,
                  style: TextButton.styleFrom(
                    foregroundColor: ColorResource.primaryDark,
                  ),
                  child: Text(
                    cooling
                        ? 'resend_in_seconds'.trParams({
                            'seconds': '$_resendIn',
                          })
                        : 'resend_code'.tr,
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeDefault,
                    ),
                  ),
                ),
                Text(
                  '·',
                  style: poppinsMedium.copyWith(color: context.textSecondary),
                ),
                TextButton(
                  onPressed: _changeEmail,
                  style: TextButton.styleFrom(
                    foregroundColor: ColorResource.primaryDark,
                  ),
                  child: Text(
                    'change_email'.tr,
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeDefault,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildInlineError(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: Constants.paddingSizeSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: ColorResource.error,
          ),
          const SizedBox(width: Constants.paddingSizeExtraSmall + 1),
          Expanded(
            child: Text(
              text,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: ColorResource.error,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _CodeStep { email, code }
