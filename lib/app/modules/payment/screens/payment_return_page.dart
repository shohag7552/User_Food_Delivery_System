import 'package:appwrite_user_app/app/appwrite/payment_service.dart';
import 'package:appwrite_user_app/app/common/widgets/auth_dialog.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_button.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/order_controller.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/helper/session_manager.dart';
import 'package:appwrite_user_app/app/modules/payment/domain/services/pending_payment_store.dart';
import 'package:appwrite_user_app/app/modules/payment/payment_webview_screen.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// Where Stripe sends the customer back to on web
/// (`/payment/success?session_id=…`, `/payment/fail`, `/payment/cancel`).
///
/// The redirect flow leaves the app entirely, so the checkout screen is gone
/// by the time the payment resolves. This page picks the order back up from
/// [PendingPaymentStore] and writes it — but only after the payment function
/// confirms with Stripe that the session was really paid, for this order and
/// this amount. Landing on the success URL proves nothing on its own: anyone
/// can open it.
class PaymentReturnPage extends StatefulWidget {
  final PaymentResult result;

  /// Stripe Checkout Session id from the success URL's `session_id`.
  final String? sessionId;

  const PaymentReturnPage({super.key, required this.result, this.sessionId});

  @override
  State<PaymentReturnPage> createState() => _PaymentReturnPageState();
}

enum _ReturnState { working, needsSignIn, failed }

class _PaymentReturnPageState extends State<PaymentReturnPage> {
  _ReturnState _state = _ReturnState.working;
  String _messageKey = 'confirming_your_payment';
  bool _canRetry = false;
  bool _running = false;

  AuthController get _auth => Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    // Signing in from this page resumes the order automatically.
    _auth.addListener(_onAuthChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resume();
    });
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (_state == _ReturnState.needsSignIn && isUserLoggedIn()) _resume();
  }

  void _show(_ReturnState state, String messageKey, {bool canRetry = false}) {
    if (!mounted) return;
    setState(() {
      _state = state;
      _messageKey = messageKey;
      _canRetry = canRetry;
    });
  }

  Future<void> _resume() async {
    if (_running) return;
    _running = true;
    try {
      await _run();
    } finally {
      _running = false;
    }
  }

  Future<void> _run() async {
    _show(_ReturnState.working, 'confirming_your_payment');

    // ── Cancelled / failed at Stripe: nothing was charged or written. ──
    if (widget.result != PaymentResult.success) {
      await PendingPaymentStore.clear();
      if (!mounted) return;
      customToster(
        widget.result == PaymentResult.failed
            ? 'payment_failed_try_again'.tr
            : 'payment_was_cancelled'.tr,
        isSuccess: false,
      );
      context.go(AppRouter.checkout);
      return;
    }

    // Stripe always appends the session id; without it nothing can be
    // confirmed, so no order is written.
    final sessionId = widget.sessionId?.trim() ?? '';
    if (sessionId.isEmpty) {
      _show(_ReturnState.failed, 'could_not_confirm_payment');
      return;
    }

    // Reload of a success page whose order was already written.
    if (await PendingPaymentStore.wasCompleted(sessionId)) {
      if (!mounted) return;
      customToster('order_already_placed'.tr, isSuccess: true);
      context.go(AppRouter.orders);
      return;
    }

    final pending = await PendingPaymentStore.read();

    // Paid, but this browser is not holding the order — a callback opened on
    // another device, or storage cleared mid-payment. The money is real, so
    // hand it to the store rather than silently dropping it.
    if (pending == null || pending.isExpired) {
      if (pending != null) await PendingPaymentStore.clear();
      if (!mounted) return;
      customToster('payment_received_contact_support'.tr, isSuccess: false);
      context.go(AppRouter.orders);
      return;
    }

    // A different checkout than the one this browser is holding.
    if (pending.sessionId != null && pending.sessionId != sessionId) {
      _show(_ReturnState.failed, 'payment_received_contact_support');
      return;
    }

    // The order is written as the signed-in customer. The session normally
    // survives the redirect; if it did not, ask them to sign in and resume.
    if (!isUserLoggedIn()) {
      await _auth.isAlreadyLoggedIn();
    }
    if (!isUserLoggedIn()) {
      _show(_ReturnState.needsSignIn, 'sign_in_to_finish_order');
      return;
    }
    final userId = await _auth.getUserId();
    if (userId != pending.customerId) {
      _show(_ReturnState.failed, 'payment_received_contact_support');
      return;
    }

    // Another tab (or a reload) is already writing this order.
    if (!await PendingPaymentStore.tryMarkProcessing()) {
      _show(_ReturnState.failed, 'order_being_finished');
      return;
    }

    // ── Ask Stripe, through the payment function, whether it was paid. ──
    final StripeVerification verification;
    try {
      verification = await PaymentService().verifyStripeSession(
        sessionId: sessionId,
        orderId: pending.reference,
      );
    } on PaymentException catch (e) {
      await PendingPaymentStore.releaseProcessing();
      if (e.code == 'order_mismatch') {
        _show(_ReturnState.failed, 'payment_received_contact_support');
      } else {
        _show(_ReturnState.failed, 'could_not_confirm_payment', canRetry: true);
      }
      return;
    } catch (_) {
      await PendingPaymentStore.releaseProcessing();
      _show(_ReturnState.failed, 'could_not_confirm_payment', canRetry: true);
      return;
    }

    if (!verification.paid) {
      if (verification.status == 'processing') {
        // Checkout finished but a delayed method has not settled — keep the
        // order on hold; reloading this page later retries.
        await PendingPaymentStore.releaseProcessing();
        _show(_ReturnState.failed, 'payment_still_processing', canRetry: true);
        return;
      }
      // Unpaid or expired: nothing was charged, nothing to write.
      await PendingPaymentStore.clear();
      if (!mounted) return;
      customToster('payment_not_completed'.tr, isSuccess: false);
      context.go(AppRouter.checkout);
      return;
    }

    // Paid — but for exactly what this browser is about to write?
    final amountMatches = pending.amountMinor == null ||
        verification.amount == pending.amountMinor;
    final currencyMatches = pending.currency == null ||
        verification.currency.toLowerCase() == pending.currency!.toLowerCase();
    if (!amountMatches || !currencyMatches) {
      await PendingPaymentStore.releaseProcessing();
      _show(_ReturnState.failed, 'payment_received_contact_support');
      return;
    }

    // ── Verified: write the order as paid. ──
    _show(_ReturnState.working, 'finishing_your_order');
    final orderController = Get.find<OrderController>();
    final result = await orderController.placeOrder(
      customerId: pending.customerId,
      address: pending.address,
      cartItems: pending.cartItems,
      totalAmount: pending.totalAmount,
      deliveryFee: pending.deliveryFee,
      taxAmount: pending.taxAmount,
      discountAmount: pending.discountAmount,
      couponDiscount: pending.couponDiscount,
      paymentMethod: pending.paymentMethod,
      paymentStatus: 'paid',
      deliveryInstructions: pending.deliveryInstructions,
      deliveryType: pending.deliveryType,
      scheduledDate: pending.scheduledDate,
      scheduledTimeSlot: pending.scheduledTimeSlot,
      shippingCost: pending.shippingCost,
      shippingMethod: pending.shippingMethod,
      moduleType: pending.moduleType,
    );

    if (result['success'] != true) {
      // The money is taken and this is the only copy of what it bought, so
      // the payload stays on disk and the customer can retry the write.
      await PendingPaymentStore.releaseProcessing();
      _show(_ReturnState.failed, 'payment_order_failed_retry', canRetry: true);
      return;
    }

    await PendingPaymentStore.rememberCompleted(sessionId);
    await PendingPaymentStore.clear();
    await orderController.finalizePlacedOrder(pending.cartItems);

    if (!mounted) return;
    context.goNamed(
      RouteNames.orderSuccess,
      extra: OrderSuccessArgs(
        orderNumber: result['orderNumber'] as String,
        totalAmount: pending.totalAmount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(Constants.paddingSizeLarge),
              child: _state == _ReturnState.working
                  ? _buildWorking()
                  : _buildMessage(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorking() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: ColorResource.primaryDark),
        const SizedBox(height: Constants.paddingSizeDefault),
        Text(
          _messageKey.tr,
          textAlign: TextAlign.center,
          style: poppinsMedium.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMessage() {
    final needsSignIn = _state == _ReturnState.needsSignIn;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          needsSignIn ? Icons.lock_outline_rounded : Icons.info_outline_rounded,
          size: 48,
          color: needsSignIn ? ColorResource.primaryDark : ColorResource.error,
        ),
        const SizedBox(height: Constants.paddingSizeDefault),
        Text(
          _messageKey.tr,
          textAlign: TextAlign.center,
          style: poppinsMedium.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: context.textPrimary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: Constants.paddingSizeLarge),
        if (needsSignIn)
          CustomButton(
            buttonText: 'sign_in'.tr,
            height: 48,
            elevation: 0,
            onPressed: () => AuthFlow.openLogin(context),
          )
        else if (_canRetry)
          CustomButton(
            buttonText: 'retry'.tr,
            height: 48,
            elevation: 0,
            onPressed: _resume,
          ),
        const SizedBox(height: Constants.paddingSizeSmall),
        TextButton(
          onPressed: () => context.go(AppRouter.orders),
          style: TextButton.styleFrom(
            foregroundColor: ColorResource.primaryDark,
          ),
          child: Text(
            'view_orders'.tr,
            style: poppinsMedium.copyWith(fontSize: Constants.fontSizeDefault),
          ),
        ),
      ],
    );
  }
}
