import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/order_controller.dart';
import 'package:appwrite_user_app/app/controllers/settings_controller.dart';
import 'package:appwrite_user_app/app/models/order_model.dart';
import 'package:appwrite_user_app/app/modules/orders/screens/order_delivery_map_page.dart';
import 'package:appwrite_user_app/app/modules/reviews/widgets/submit_review_bottomsheet.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/helper/price_helper.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  final OrderModel? initialOrder;

  const OrderDetailPage({super.key, required this.orderId, this.initialOrder});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late final OrderController _orderController;
  OrderModel? _fallbackOrder;

  @override
  void initState() {
    super.initState();
    _orderController = Get.find<OrderController>();
    _fallbackOrder = widget.initialOrder;
    _orderController.fetchOrderDetails(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      appBar: CustomAppbar(title: 'order_details'.tr),
      body: GetBuilder<OrderController>(
        builder: (controller) {
          final order = controller.selectedOrder?.id == widget.orderId
              ? controller.selectedOrder
              : _fallbackOrder;

          if (controller.isOrderDetailsLoading && order == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (order == null && controller.isOrderDetailsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (order == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: ColorResource.textLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to load order details',
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeLarge,
                        color: ColorResource.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pull to refresh or try again in a moment.',
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: ColorResource.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await controller.refreshOrderDetails(widget.orderId);
              if (controller.selectedOrder?.id == widget.orderId && mounted) {
                setState(() {
                  _fallbackOrder = controller.selectedOrder;
                });
              }
            },
            color: ColorResource.primaryDark,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(order),
                  const SizedBox(height: 16),
                  _buildOrderInfo(order),
                  const SizedBox(height: 16),
                  _buildItemsList(order),
                  const SizedBox(height: 16),
                  _buildDeliveryInfo(order),
                  if (_hasDeliveryman(order)) ...[
                    const SizedBox(height: 16),
                    _buildDeliverymanSection(order),
                  ],
                  const SizedBox(height: 16),
                  _buildPricingBreakdown(order),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(OrderModel order) {
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
              color: ColorResource.textWhite.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusBadge(order.status),
        ],
      ),
    );
  }

  Widget _buildOrderInfo(OrderModel order) {
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
              label: 'order_id'.tr,
              value: order.orderNumber,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(
            child: _buildInfoItem(
              icon: Icons.shopping_bag_outlined,
              label: 'items'.tr,
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

  Widget _buildItemsList(OrderModel order) {
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
              'order_items'.tr,
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
              return _buildOrderItem(order, item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderModel order, OrderItem item) {
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
                          color: ColorResource.primaryDark.withValues(
                            alpha: 0.1,
                          ),
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
                      '${PriceHelper.formatPrice(item.price)} ${'each'.tr}',
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
                if (_isOrderDelivered(order)) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showReviewBottomSheet(item),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(color: ColorResource.primaryDark),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Constants.radiusDefault,
                          ),
                        ),
                      ),
                      icon: Icon(
                        Icons.rate_review,
                        size: 18,
                        color: ColorResource.primaryDark,
                      ),
                      label: Text(
                        'rate_this_product'.tr,
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

  Widget _buildDeliveryInfo(OrderModel order) {
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
                'delivery_address'.tr,
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

  Widget _buildPricingBreakdown(OrderModel order) {
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
            'payment_summary'.tr,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: ColorResource.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('subtotal'.tr, subtotal, false),
          const SizedBox(height: 12),
          _buildPriceRow('delivery_fee'.tr, order.deliveryFee, false),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildPriceRow('total_amount'.tr, order.totalAmount, true),
        ],
      ),
    );
  }

  Widget _buildDeliverymanSection(OrderModel order) {
    final deliveryman = order.deliveryman;

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
                Icons.delivery_dining,
                color: ColorResource.primaryDark,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Deliveryman',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeLarge,
                    color: ColorResource.textPrimary,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _openDeliveryMap(order),
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorResource.primaryDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      Constants.radiusDefault,
                    ),
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: ColorResource.primaryDark,
                    size: 22,
                  ),
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
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: ColorResource.primaryDark.withValues(alpha: 0.08),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child:
                        deliveryman?.image != null &&
                            deliveryman!.image!.isNotEmpty
                        ? CustomNetworkImage(
                            image: deliveryman.image!,
                            width: 56,
                            height: 56,
                          )
                        : Icon(
                            Icons.person,
                            color: ColorResource.primaryDark,
                            size: 28,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deliveryman?.name.isNotEmpty == true
                            ? deliveryman!.name
                            : 'Deliveryman',
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: ColorResource.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deliveryman?.phone.isNotEmpty == true
                            ? deliveryman!.phone
                            : 'Phone number not available',
                        style: poppinsRegular.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: ColorResource.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
        label = 'pending'.tr;
        break;
      case 'cooking':
      case 'preparing':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        icon = Icons.restaurant;
        label = 'preparing'.tr;
        break;
      case 'delivering':
      case 'on_the_way':
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade700;
        icon = Icons.delivery_dining;
        label = 'on_the_way'.tr;
        break;
      case 'completed':
      case 'delivered':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        label = 'completed_status'.tr;
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        label = 'cancelled_status'.tr;
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

  bool _isOrderDelivered(OrderModel order) {
    return order.status.toLowerCase() == 'delivered' ||
        order.status.toLowerCase() == 'completed';
  }

  bool _hasDeliveryman(OrderModel order) {
    return (order.driverId?.isNotEmpty ?? false) || order.deliveryman != null;
  }

  Future<void> _openDeliveryMap(OrderModel order) async {
    final deliveryman = order.deliveryman;
    final settingsController = Get.find<SettingsController>();

    if (settingsController.businessSetup == null) {
      await settingsController.fetchBusinessSetup();
    }

    final businessSetup = settingsController.businessSetup;

    if (deliveryman == null || !deliveryman.hasLocation) {
      Get.snackbar(
        'Location unavailable',
        'Deliveryman current location is not available yet.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorResource.error,
        colorText: ColorResource.textWhite,
      );
      return;
    }

    if (businessSetup?.storeLatitude == null ||
        businessSetup?.storeLongitude == null) {
      Get.snackbar(
        'Location unavailable',
        'Business location is not available right now.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorResource.error,
        colorText: ColorResource.textWhite,
      );
      return;
    }

    Get.to(
      () => OrderDeliveryMapPage(
        deliveryman: deliveryman,
        businessName: businessSetup?.businessName ?? '',
        businessAddress: businessSetup?.storeLocation ?? '',
        businessLatitude: businessSetup!.storeLatitude!,
        businessLongitude: businessSetup.storeLongitude!,
      ),
    );
  }

  Future<void> _showReviewBottomSheet(OrderItem item) async {
    final authController = Get.find<AuthController>();
    String? userId = await authController.getUserId();
    String? userName = await authController.getUserName();

    if (userId == null) {
      Get.snackbar(
        'login_required'.tr,
        'please_login_to_write_a_review'.tr,
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
