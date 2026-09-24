import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/controllers/order_controller.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/modules/payment/domain/services/pending_payment_store.dart';
import 'package:appwrite_user_app/app/modules/payment/payment_webview_screen.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// Where the gateway sends the customer back to on web.
///
/// The redirect flow leaves the app entirely, so the order cannot be written by
/// the checkout screen the way it is on mobile — that screen is long gone by
/// the time the payment resolves. This page picks the order back up from
/// [PendingPaymentStore] and writes it, but only for [PaymentResult.success]:
/// a failed or cancelled payment must leave nothing behind in the orders table.
class PaymentReturnPage extends StatefulWidget {
  final PaymentResult result;

  const PaymentReturnPage({super.key, required this.result});

  @override
  State<PaymentReturnPage> createState() => _PaymentReturnPageState();
}

class _PaymentReturnPageState extends State<PaymentReturnPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resume();
    });
  }

  Future<void> _resume() async {
    final pending = await PendingPaymentStore.read();

    if (widget.result != PaymentResult.success) {
      // Nothing was ever written, so there is nothing to undo — just drop the
      // held order so a later payment cannot resurrect it.
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

    // Paid, but this browser is not holding the order — a callback opened on
    // another device, or storage cleared mid-payment. Nothing can be rebuilt
    // from here, and the money is real, so hand it to the store rather than
    // silently dropping it.
    if (pending == null) {
      if (!mounted) return;
      customToster('payment_received_contact_support'.tr, isSuccess: false);
      context.go(AppRouter.orders);
      return;
    }

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
      // The payload stays on disk: the money is gone and this is the only copy
      // of what it bought, so a reload can try the write again.
      if (!mounted) return;
      customToster('payment_received_contact_support'.tr, isSuccess: false);
      context.go(AppRouter.orders);
      return;
    }

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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: Constants.paddingSizeDefault),
            Text(
              'finishing_your_order'.tr,
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
