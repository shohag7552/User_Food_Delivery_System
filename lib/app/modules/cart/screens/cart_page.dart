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
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      appBar: AppBar(
        title: GetBuilder<CartController>(
          builder: (controller) => Text(
            'Cart (${controller.itemCount})',
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: ColorResource.textLight,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your cart is empty',
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeExtraLarge,
                      color: ColorResource.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add items to get started',
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

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
        },
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItemModel item, CartController controller, int index) {
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
            const SnackBar(content: Text('Failed to load product details')),
          );
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomNetworkImage(
                    image: item.productImage,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => controller.removeItem(item.id),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.black38,
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
                          fontSize: 13,
                          color: Colors.black45,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else ...[
                       const SizedBox(height: 4),
                       Text(
                        ' ', // spacer
                        style: poppinsRegular.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          CurrencyHelper.formatAmount(item.itemTotal),
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeLarge,
                            color: ColorResource.primaryDark,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: ColorResource.scaffoldBackground,
                            borderRadius: BorderRadius.circular(Constants.radiusDefault),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildQuantityButton(
                                icon: Icons.remove,
                                onTap: () => controller.decrementQuantity(item.id),
                                enabled: item.quantity > 1,
                              ),
                              Container(
                                width: 40,
                                alignment: Alignment.center,
                                child: Text(
                                  '${item.quantity}',
                                  style: poppinsBold.copyWith(
                                    fontSize: Constants.fontSizeLarge,
                                    color: ColorResource.textPrimary,
                                  ),
                                ),
                              ),
                              _buildQuantityButton(
                                icon: Icons.add,
                                onTap: () => controller.incrementQuantity(item.id),
                                enabled: (controller.getProductStock(item.productId) == null) || 
                                         (item.quantity < controller.getProductStock(item.productId)!),
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

          if (index < controller.cartItems.length - 1) ...[
            const SizedBox(height: 10),
            Divider(color: Theme.of(context).disabledColor,),
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled
              ? ColorResource.primaryDark
              : ColorResource.textLight.withOpacity(0.2),
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
        ),
        child: Icon(
          icon,
          color: enabled ? ColorResource.textWhite : ColorResource.textLight,
          size: 20,
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
        child: Column(
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
                          'Promocode applied',
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
              const SizedBox(height: 24),
            ],
            
            _buildSummaryRow('Subtotal', controller.subtotal),
            const SizedBox(height: 8),
            _buildSummaryRow('Tax (10%)', controller.tax),
            if (controller.discountAmount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discount',
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.textSecondary,
                    ),
                  ),
                  Text(
                    '- ${CurrencyHelper.formatAmount(controller.discountAmount)}',
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.success,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 20),
            _buildSummaryRow('Total', controller.total, isTotal: true),
            const SizedBox(height: 20),
            
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
                  'Proceed to Checkout',
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

