import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/helper/currency_helper.dart';
import 'package:appwrite_user_app/app/models/cart_item_model.dart';
import 'package:appwrite_user_app/app/modules/checkout/screens/checkout_page.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/product_detail_bottomsheet.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isPriceExpanded = false;

  // Web/desktop layout kicks in above this width.
  static const double _webBreakpoint = 900;
  static const double _maxContentWidth = 1100;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= _webBreakpoint;
    // As a dashboard tab on web the shared top-nav is already shown, so drop the
    // page's own app bar — unless this cart was pushed as a standalone route.
    final hideAppBar = kIsWeb && !Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      appBar: hideAppBar
          ? null
          : AppBar(
              title: GetBuilder<CartController>(
                builder: (controller) => Text(
                  '${'cart'.tr} (${controller.itemCount})',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeLarge,
                    color: ColorResource.textWhite,
                  ),
                ),
              ),
              backgroundColor: ColorResource.primaryDark,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
      body: GetBuilder<CartController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: ColorResource.primaryDark,
              ),
            );
          }

          if (controller.cartItems.isEmpty) {
            return _buildEmptyState();
          }

          return isWide
              ? _buildWebBody(context, controller, hideAppBar)
              : _buildMobileBody(context, controller);
        },
      ),
    );
  }

  Widget _buildMobileBody(BuildContext context, CartController controller) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: controller.cartItems.length,
            itemBuilder: (context, index) {
              CartItemModel item = controller.cartItems[index];
              return _buildCartItem(context, item, controller, index);
            },
          ),
        ),
        _buildBottomSummary(controller),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: ColorResource.textLight,
          ),
          const SizedBox(height: 20),
          Text(
            'your_cart_is_empty'.tr,
            style: poppinsBold.copyWith(
              fontSize: 24,
              color: ColorResource.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'add_items_to_get_started'.tr,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: ColorResource.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Web: items list (left) + sticky order-summary card (right).
  // ---------------------------------------------------------------------------

  Widget _buildWebBody(
    BuildContext context,
    CartController controller,
    bool showInlineTitle,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, showInlineTitle ? 8 : 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showInlineTitle) ...[
                _buildInlineTitle(controller.itemCount),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: controller.cartItems.length,
                        itemBuilder: (context, index) {
                          final item = controller.cartItems[index];
                          return _buildCartItem(
                              context, item, controller, index);
                        },
                      ),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 360,
                      child: SingleChildScrollView(
                        child: _buildWebSummaryCard(controller),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineTitle(int count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'cart'.tr,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeOverLarge,
            color: ColorResource.textPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '($count)',
          style: poppinsMedium.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: ColorResource.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildWebSummaryCard(CartController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'order_summary'.tr,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: ColorResource.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (controller.appliedCoupon != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: ColorResource.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ColorResource.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    controller.appliedCoupon!.code,
                    style: poppinsBold.copyWith(
                      color: Colors.green.shade700,
                      fontSize: Constants.fontSizeSmall,
                    ),
                  ),
                  Icon(Icons.check_circle,
                      color: ColorResource.success, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          _buildSummaryRow('subtotal'.tr, controller.originalSubtotal),
          if (controller.itemDiscountTotal > 0) ...[
            const SizedBox(height: 10),
            _buildDiscountRow('item_discount'.tr, controller.itemDiscountTotal),
          ],
          const SizedBox(height: 10),
          _buildSummaryRow('tax_10'.tr, controller.tax),
          if (controller.discountAmount > 0) ...[
            const SizedBox(height: 10),
            _buildDiscountRow('coupon_discount'.tr, controller.discountAmount),
          ],
          const Divider(height: 28),
          _buildSummaryRow('total'.tr, controller.total, isTotal: true),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.to(() => const CheckoutPage()),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResource.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
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
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItemModel item, CartController controller, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: ColorResource.primaryDark),
          ),
        );

        final productController = Get.find<ProductController>();
        final product = await productController.getProductById(item.productId);

        // Hide loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        if (product != null && context.mounted) {
          // Open the product bottom sheet and use the full product model
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => ProductDetailBottomSheet(
              product: product,
              cartItem: item, // Pass the existing cart item in
            ),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('failed_to_load_product_details'.tr)),
          );
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ColorResource.cardBackground,
              borderRadius: BorderRadius.circular(Constants.radiusLarge),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : ColorResource.textLight.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomNetworkImage(
                      image: item.productImage,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.productName,
                              style: poppinsBold.copyWith(
                                fontSize: 15,
                                color: ColorResource.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => controller.removeItem(item.id),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: isDark ? Colors.white54 : Colors.black38,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.selectedVariants.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.selectedVariants
                              .expand((v) => v.selections)
                              .map((s) => s.optionName)
                              .join(', '),
                          style: poppinsRegular.copyWith(
                            fontSize: 12.5,
                            color: ColorResource.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Price block (flexes so it can never overflow)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Original price + discount badge, if discounted
                                if (item.basePrice > item.finalPrice) ...[
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          CurrencyHelper.formatAmount(
                                            item.basePrice * item.quantity,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: poppinsRegular.copyWith(
                                            fontSize: Constants.fontSizeSmall,
                                            color: ColorResource.textLight,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            decorationColor:
                                                ColorResource.textLight,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${((1 - item.finalPrice / item.basePrice) * 100).round()}% OFF',
                                          style: poppinsBold.copyWith(
                                            fontSize: 10,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                ],
                                Text(
                                  CurrencyHelper.formatAmount(item.itemTotal),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: poppinsBold.copyWith(
                                    fontSize: Constants.fontSizeLarge,
                                    color: ColorResource.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Quantity stepper
                          Container(
                            decoration: BoxDecoration(
                              color: ColorResource.scaffoldBackground,
                              borderRadius: BorderRadius.circular(
                                Constants.radiusDefault,
                              ),
                              border: Border.all(
                                color: ColorResource.textLight.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildQuantityButton(
                                  icon: Icons.remove,
                                  onTap: () =>
                                      controller.decrementQuantity(item.id),
                                  enabled: item.quantity > 1,
                                ),
                                Container(
                                  width: 32,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${item.quantity}',
                                    style: poppinsBold.copyWith(
                                      fontSize: Constants.fontSizeDefault,
                                      color: ColorResource.textPrimary,
                                    ),
                                  ),
                                ),
                                _buildQuantityButton(
                                  icon: Icons.add,
                                  onTap: () =>
                                      controller.incrementQuantity(item.id),
                                  enabled:
                                      (controller.getProductStock(item.productId) ==
                                              null) ||
                                          (item.quantity <
                                              controller.getProductStock(
                                                item.productId,
                                              )!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (index < controller.cartItems.length - 1) ...[
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: enabled
              ? ColorResource.primaryDark
              : ColorResource.textLight.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
        ),
        child: Icon(
          icon,
          color: enabled ? ColorResource.textWhite : ColorResource.textLight,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildBottomSummary(CartController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        boxShadow: [
          BoxShadow(
            color: ColorResource.shadowMedium,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        // Keeps the checkout bar above the floating bottom nav bar.
        minimum: const EdgeInsets.only(bottom: Constants.bottomNavSpace),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.appliedCoupon != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: ColorResource.textLight.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller.appliedCoupon!.code,
                      style: poppinsMedium.copyWith(
                        color: ColorResource.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'promocode_applied'.tr,
                          style: poppinsMedium.copyWith(
                            color: ColorResource.success,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.check_circle,
                          color: ColorResource.success,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Expandable price breakdown
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isPriceExpanded
                  ? Column(
                      children: [
                        _buildSummaryRow('subtotal'.tr, controller.originalSubtotal),
                        if (controller.itemDiscountTotal > 0) ...[
                          const SizedBox(height: 8),
                          _buildDiscountRow('item_discount'.tr, controller.itemDiscountTotal),
                        ],
                        const SizedBox(height: 8),
                        _buildSummaryRow('tax_10'.tr, controller.tax),
                        if (controller.discountAmount > 0) ...[
                          const SizedBox(height: 8),
                          _buildDiscountRow('coupon_discount'.tr, controller.discountAmount),
                        ],
                        const Divider(height: 20),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // Total row with expand/collapse button
            GestureDetector(
              onTap: () {
                setState(() {
                  _isPriceExpanded = !_isPriceExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: ColorResource.primaryDark.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(Constants.radiusDefault),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        children: [
                          Text(
                            'total'.tr,
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeLarge,
                              color: ColorResource.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            duration: const Duration(milliseconds: 300),
                            turns: _isPriceExpanded ? 0.5 : 0,
                            child: Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: ColorResource.primaryDark,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        CurrencyHelper.formatAmount(controller.total),
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeLarge,
                          color: ColorResource.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Checkout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.to(() => const CheckoutPage());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResource.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: Colors.green.shade700,
          ),
        ),
        Text(
          '- ${CurrencyHelper.formatAmount(amount)}',
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: Colors.green.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal 
            ? poppinsBold.copyWith(fontSize: Constants.fontSizeLarge, color: ColorResource.textPrimary)
            : poppinsRegular.copyWith(fontSize: Constants.fontSizeDefault, color: ColorResource.textSecondary),
        ),
        Text(
          CurrencyHelper.formatAmount(amount),
          style: isTotal
            ? poppinsBold.copyWith(fontSize: Constants.fontSizeLarge, color: ColorResource.primaryDark)
            : poppinsBold.copyWith(fontSize: Constants.fontSizeDefault, color: ColorResource.textPrimary),
        ),
      ],
    );
  }
}
