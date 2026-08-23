import 'package:appwrite_user_app/app/common/widgets/auth_gate.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/helper/currency_helper.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/models/cart_item_model.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// Slide-in cart panel for the desktop-web shell.
///
/// On web the cart icon opens this instead of navigating away, so the shopper
/// can check what they have and go straight to checkout without losing the page
/// they were browsing — the behaviour every desktop storefront has trained
/// people to expect. Mobile is untouched and still opens the full cart page.
///
/// Implemented as a routed overlay rather than [Scaffold.endDrawer] because
/// that slot is already taken by `WebProfileDrawer` on all 21 web pages. This
/// way the panel works from any page without touching a single Scaffold, and
/// the two can never fight over the same slot.
abstract class WebCartDrawer {
  const WebCartDrawer._();

  static const double _maxWidth = 420;

  /// Opens the panel. Dismissed by the scrim, Escape, or the close button.
  static Future<void> show(BuildContext context) {
    // Anchor to the trailing edge, which flips for Arabic.
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'cart'.tr,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => const _WebCartPanel(),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return Align(
          alignment: isRtl
              ? AlignmentDirectional.centerStart
              : AlignmentDirectional.centerEnd,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(isRtl ? -1 : 1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _WebCartPanel extends StatefulWidget {
  const _WebCartPanel();

  @override
  State<_WebCartPanel> createState() => _WebCartPanelState();
}

class _WebCartPanelState extends State<_WebCartPanel> {
  @override
  void initState() {
    super.initState();
    // Re-read the cart every time the panel opens — it may have changed on
    // another device, or in another tab, since this page was loaded. Guests
    // are handled inside getCartItems, which never calls Appwrite for them.
    //
    // Post-frame because the fetch flips isLoading and calls update()
    // synchronously, which would be a rebuild during the current build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Get.find<CartController>().getCartItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Material(
      color: context.cardBackground,
      elevation: 16,
      child: SizedBox(
        width: width < WebCartDrawer._maxWidth * 1.2
            ? width * 0.9
            : WebCartDrawer._maxWidth,
        height: double.infinity,
        child: SafeArea(
          child: GetBuilder<CartController>(
            builder: (cartController) => Column(
              children: [
                _Header(itemCount: cartController.itemCount),
                Divider(
                  height: 1,
                  color: context.textLight.withValues(alpha: 0.2),
                ),
                // The gate keeps the panel consistent with the cart page, which
                // is also login-only — a guest gets the same prompt either way.
                Expanded(child: AuthGate(child: _body(context, cartController))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, CartController controller) {
    if (controller.isLoading && controller.cartItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.cartItems.isEmpty) return const _EmptyState();

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: Constants.paddingSizeDefault,
              vertical: Constants.paddingSizeSmall,
            ),
            itemCount: controller.cartItems.length,
            separatorBuilder: (_, _) => Divider(
              height: Constants.paddingSizeLarge,
              color: context.textLight.withValues(alpha: 0.15),
            ),
            itemBuilder: (context, index) =>
                _CartRow(item: controller.cartItems[index]),
          ),
        ),
        _Summary(controller: controller),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final int itemCount;

  const _Header({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Constants.paddingSizeDefault,
        Constants.paddingSizeSmall,
        Constants.paddingSizeSmall,
        Constants.paddingSizeSmall,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.shopping_cart_rounded,
            color: ColorResource.primaryDark,
            size: 22,
          ),
          const SizedBox(width: Constants.paddingSizeSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'cart'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeExtraLarge,
                    color: context.textPrimary,
                  ),
                ),
                if (itemCount > 0)
                  Text(
                    itemCount == 1
                        ? 'cart_item_count_one'.tr
                        : 'cart_items_count'.trParams({'count': '$itemCount'}),
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: context.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            color: context.textSecondary,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ],
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  final CartItemModel item;

  const _CartRow({required this.item});

  static const double _thumbSize = 64;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CartController>();
    final stock = controller.getProductStock(item.productId);
    final canIncrement = stock == null || item.quantity < stock;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
          child: CustomNetworkImage(
            image: item.productImage,
            width: _thumbSize,
            height: _thumbSize,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: Constants.paddingSizeSmall),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: context.textPrimary,
                ),
              ),
              if (item.selectedVariants.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.selectedVariants
                      .expand((v) => v.selections)
                      .map((s) => s.optionName)
                      .join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: context.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: Constants.paddingSizeSmall),
              Row(
                children: [
                  _QtyStepper(
                    quantity: item.quantity,
                    onDecrement: () => controller.decrementQuantity(item.id),
                    onIncrement: canIncrement
                        ? () => controller.incrementQuantity(item.id)
                        : null,
                  ),
                  const Spacer(),
                  Text(
                    CurrencyHelper.formatAmount(item.itemTotal),
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.primaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Remove sits away from the stepper on purpose — a misfire here loses
        // the whole line, so it should not neighbour the "−" button.
        IconButton(
          onPressed: () => controller.removeItem(item.id),
          icon: const Icon(Icons.close_rounded, size: 18),
          color: context.textLight,
          visualDensity: VisualDensity.compact,
          tooltip: 'remove'.tr,
        ),
      ],
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;

  /// Null once the line has reached the product's remaining stock.
  final VoidCallback? onIncrement;

  const _QtyStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: context.textLight.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepButton(context, Icons.remove_rounded, onDecrement),
          Container(
            constraints: const BoxConstraints(minWidth: 26),
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: context.textPrimary,
              ),
            ),
          ),
          _stepButton(context, Icons.add_rounded, onIncrement),
        ],
      ),
    );
  }

  Widget _stepButton(
    BuildContext context,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Constants.radiusDefault),
      child: SizedBox(
        width: 30,
        height: 30,
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? context.textLight : ColorResource.primaryDark,
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final CartController controller;

  const _Summary({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Constants.paddingSizeDefault),
      decoration: BoxDecoration(
        color: context.cardBackground,
        border: Border(
          top: BorderSide(color: context.textLight.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(context, 'subtotal'.tr, controller.originalSubtotal),
          if (controller.itemDiscountTotal > 0)
            _row(
              context,
              'item_discount'.tr,
              -controller.itemDiscountTotal,
              isDiscount: true,
            ),
          _row(
            context,
            '${'tax'.tr} (${controller.vatPercentageLabel}%)',
            controller.tax,
          ),
          if (controller.discountAmount > 0)
            _row(
              context,
              'coupon_discount'.tr,
              -controller.discountAmount,
              isDiscount: true,
            ),
          Divider(
            height: Constants.paddingSizeLarge,
            color: context.textLight.withValues(alpha: 0.2),
          ),
          _row(context, 'total'.tr, controller.total, isTotal: true),
          const SizedBox(height: Constants.paddingSizeDefault),
          SizedBox(
            width: double.infinity,
            height: Constants.minTapTarget + Constants.paddingSizeDefault,
            child: ElevatedButton(
              // Close first, then navigate: leaving the panel open behind the
              // checkout page would strand it over the next route.
              onPressed: () {
                Navigator.of(context).pop();
                context.pushNamed(RouteNames.checkout);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResource.primaryDark,
                foregroundColor: ColorResource.textWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Constants.radiusLarge),
                ),
              ),
              child: Text(
                'proceed_to_checkout'.tr,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeLarge,
                  color: ColorResource.textWhite,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              DashboardTabs.open(context, 2);
            },
            style: TextButton.styleFrom(
              foregroundColor: ColorResource.primaryDark,
            ),
            child: Text(
              'view_cart'.tr,
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeDefault,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: (isTotal ? poppinsBold : poppinsRegular).copyWith(
                fontSize: isTotal
                    ? Constants.fontSizeLarge
                    : Constants.fontSizeSmall,
                color: isTotal ? context.textPrimary : context.textSecondary,
              ),
            ),
          ),
          Text(
            isDiscount
                ? '- ${CurrencyHelper.formatAmount(amount.abs())}'
                : CurrencyHelper.formatAmount(amount),
            style: (isTotal ? poppinsBold : poppinsMedium).copyWith(
              fontSize: isTotal
                  ? Constants.fontSizeLarge
                  : Constants.fontSizeSmall,
              color: isDiscount
                  ? ColorResource.success
                  : isTotal
                  ? ColorResource.primaryDark
                  : context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Constants.paddingSizeLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: Constants.iconSizeLarge,
              color: context.textLight,
            ),
            const SizedBox(height: Constants.paddingSizeDefault),
            Text(
              'your_cart_is_empty'.tr,
              textAlign: TextAlign.center,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: Constants.paddingSizeExtraSmall),
            Text(
              'cart_empty_hint'.tr,
              textAlign: TextAlign.center,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: Constants.paddingSizeLarge),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorResource.primaryDark,
                side: const BorderSide(color: ColorResource.primaryDark),
                padding: const EdgeInsets.symmetric(
                  horizontal: Constants.paddingSizeLarge,
                  vertical: Constants.paddingSizeSmall,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Constants.radiusDefault),
                ),
              ),
              child: Text(
                'continue_shopping'.tr,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
