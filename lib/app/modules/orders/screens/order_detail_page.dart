import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/models/order_model.dart';
import 'package:appwrite_user_app/app/modules/reviews/widgets/submit_review_bottomsheet.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/helper/price_helper.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OrderDetailPage extends StatelessWidget {
  final OrderModel order;

  const OrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: ColorResource.textWhite,
          ),
        ),
        backgroundColor: ColorResource.primaryDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildOrderInfo(),
            const SizedBox(height: 16),
            _buildItemsList(),
            const SizedBox(height: 16),
            _buildDeliveryInfo(),
            const SizedBox(height: 16),
            _buildPricingBreakdown(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ColorResource.primaryGradient,
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        children: [
          Text(
            '#${order.orderNumber}',
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeExtraLarge,
              color: ColorResource.textWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, MMMM dd, yyyy • hh:mm a').format(order.createdAt),
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: ColorResource.textWhite.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusBadge(order.status),
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem(
              icon: Icons.receipt_long,
              label: 'Order ID',
              value: order.orderNumber,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildInfoItem(
              icon: Icons.shopping_bag_outlined,
              label: 'Items',
              value: '${order.items.length}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: ColorResource.primaryDark, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeSmall,
            color: ColorResource.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: ColorResource.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Order Items',
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
                color: ColorResource.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: order.items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = order.items[index];
              return _buildOrderItem(item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    final itemTotal = item.price * item.quantity;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorResource.scaffoldBackground,
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: ColorResource.primaryGradient,
              borderRadius: BorderRadius.circular(Constants.radiusDefault),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Constants.radiusDefault),
              child: CustomNetworkImage(image: item.productImage),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: ColorResource.textPrimary,
                  ),
                ),
                if (item.selectedVariants.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: item.selectedVariants.map((variant) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ColorResource.primaryDark.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          variant,
                          style: poppinsRegular.copyWith(
                            fontSize: Constants.fontSizeSmall,
                            color: ColorResource.primaryDark,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${PriceHelper.formatPrice(item.price)} each',
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: ColorResource.textSecondary,
                      ),
                    ),
                    Text(
                      PriceHelper.formatPrice(itemTotal),
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeLarge,
                        color: ColorResource.primaryDark,
                      ),
                    ),
                  ],
                ),
                // Add review button for delivered orders
                if (_isOrderDelivered()) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showReviewBottomSheet(item),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(color: ColorResource.primaryDark),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Constants.radiusDefault),
                        ),
                      ),
                      icon: Icon(
                        Icons.rate_review,
                        size: 18,
                        color: ColorResource.primaryDark,
                      ),
                      label: Text(
                        'Rate this product',
                        style: poppinsMedium.copyWith(
                          fontSize: Constants.fontSizeSmall,
                          color: ColorResource.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: ColorResource.primaryDark,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Delivery Address',
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeLarge,
                  color: ColorResource.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorResource.scaffoldBackground,
              borderRadius: BorderRadius.circular(Constants.radiusDefault),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.home_outlined,
                  color: ColorResource.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    order.address.street,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingBreakdown() {
    final subtotal = order.totalAmount - order.deliveryFee;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: ColorResource.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Subtotal', subtotal, false),
          const SizedBox(height: 12),
          _buildPriceRow('Delivery Fee', order.deliveryFee, false),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildPriceRow('Total Amount', order.totalAmount, true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isTotal ? poppinsBold : poppinsRegular).copyWith(
            fontSize: isTotal
                ? Constants.fontSizeLarge
                : Constants.fontSizeDefault,
            color: ColorResource.textPrimary,
          ),
        ),
        Text(
          PriceHelper.formatPrice(amount),
          style: poppinsBold.copyWith(
            fontSize: isTotal
                ? Constants.fontSizeExtraLarge
                : Constants.fontSizeLarge,
            color: isTotal
                ? ColorResource.primaryDark
                : ColorResource.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        icon = Icons.schedule;
        label = 'Pending';
        break;
      case 'cooking':
      case 'preparing':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        icon = Icons.restaurant;
        label = 'Preparing';
        break;
      case 'delivering':
      case 'on_the_way':
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade700;
        icon = Icons.delivery_dining;
        label = 'On the Way';
        break;
      case 'completed':
      case 'delivered':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        label = 'Completed';
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        label = 'Cancelled';
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = Icons.info;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  bool _isOrderDelivered() {
    return order.status.toLowerCase() == 'delivered' || 
           order.status.toLowerCase() == 'completed';
  }

  Future<void> _showReviewBottomSheet(OrderItem item) async {
    final authController = Get.find<AuthController>();
    String? userId = await authController.getUserId();
    String? userName = await authController.getUserName();

    if (userId == null) {
      Get.snackbar(
        'Login Required',
        'Please login to write a review',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorResource.error,
        colorText: ColorResource.textWhite,
      );
      return;
    }

    // Show submit review bottom sheet with verified purchase
    await SubmitReviewBottomSheet.show(
      Get.context!,
      productId: item.productId, // Use actual product ID from order item
      userId: userId,
      userName: userName ?? 'User',
      productName: item.productName,
      verifiedPurchase: true, // User purchased this product
    );
  }
}
