import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/controllers/address_controller.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/controllers/order_controller.dart';
import 'package:appwrite_user_app/app/controllers/settings_controller.dart';
import 'package:appwrite_user_app/app/helper/currency_helper.dart';
import 'package:appwrite_user_app/app/models/address_model.dart';
import 'package:appwrite_user_app/app/models/coupon_model.dart';
import 'package:appwrite_user_app/app/modules/address/screens/add_edit_address_page.dart';
import 'package:appwrite_user_app/app/modules/checkout/screens/order_failed_page.dart';
import 'package:appwrite_user_app/app/modules/checkout/screens/order_success_page.dart';
import 'package:appwrite_user_app/app/modules/checkout/widgets/address_selection_bottomsheet.dart';
import 'package:appwrite_user_app/app/modules/checkout/widgets/delivery_schedule_bottomsheet.dart';
import 'package:appwrite_user_app/app/modules/coupons/widgets/coupon_selection_bottomsheet.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _instructionsController = TextEditingController();
  String _selectedPaymentMethod = 'cod';
  bool _showAllItems = false;
  bool _isPriceExpanded = false;
  AddressModel? _selectedAddress;
  
  // Delivery schedule
  String? _scheduleDisplayText = 'ASAP (30-45 mins)';
  Map<String, dynamic>? scheduleData;

  String _deliveryType = 'asap'; // 'asap' or 'scheduled'
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  
  final double deliveryFee = 5.00;
  
  @override
  void initState() {
    super.initState();
    // Auto-select default address
    final addressController = Get.find<AddressController>();
    if (addressController.defaultAddress != null) {
      _selectedAddress = addressController.defaultAddress;
    }
  }
  
  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: ColorResource.textWhite,
          ),
        ),
        backgroundColor: ColorResource.primaryDark,
        elevation: 0,
      ),
      body: GetBuilder<CartController>(
        builder: (controller) {
          if (controller.cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: ColorResource.textLight),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: poppinsBold.copyWith(fontSize: Constants.fontSizeLarge),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderSummary(controller),
                      const SizedBox(height: 20),
                      _buildCouponSection(controller),
                      const SizedBox(height: 20),
                      _buildDeliveryAddress(),
                      const SizedBox(height: 20),
                      _buildDeliverySchedule(),
                      const SizedBox(height: 20),
                      _buildPaymentMethod(),
                      const SizedBox(height: 20),
                      _buildDeliveryInstructions(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              _buildBottomSummary(controller),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderSummary(CartController controller) {
    final itemsToShow = _showAllItems ? controller.cartItems : controller.cartItems.take(3).toList();
    
    return Container(
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Summary',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeLarge,
                    color: ColorResource.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Edit Cart',
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...itemsToShow.map((item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: poppinsMedium.copyWith(
                              fontSize: Constants.fontSizeDefault,
                              color: ColorResource.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.selectedVariants.isNotEmpty)
                            Text(
                              item.selectedVariants
                                  .expand((v) => v.selections)
                                  .map((s) => s.optionName)
                                  .join(', '),
                              style: poppinsRegular.copyWith(
                                fontSize: Constants.fontSizeExtraSmall,
                                color: ColorResource.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'x${item.quantity}',
                      style: poppinsMedium.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: ColorResource.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      CurrencyHelper.formatAmount(item.itemTotal),
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: ColorResource.primaryDark,
                      ),
                    ),
                  ],
                ),
              )),
          if (controller.cartItems.length > 3)
            TextButton(
              onPressed: () => setState(() => _showAllItems = !_showAllItems),
              child: Text(
                _showAllItems
                    ? 'Show less'
                    : '+${controller.cartItems.length - 3} more items',
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: ColorResource.primaryDark,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    return GetBuilder<AddressController>(
      builder: (addressController) {
        return GestureDetector(
          onTap: () async {
            final result = await AddressSelectionBottomSheet.show(
              context,
              initialAddress: _selectedAddress,
            );

            if (result != null) {
              setState(() {
                _selectedAddress = result;
              });
            }
          },
          child: Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: ColorResource.primaryGradient,
                            borderRadius: BorderRadius.circular(Constants.radiusDefault),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: ColorResource.textWhite,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Delivery Address',
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeLarge,
                            color: ColorResource.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () async {
                        final result = await AddressSelectionBottomSheet.show(
                          context,
                          initialAddress: _selectedAddress,
                        );

                        if (result != null) {
                          setState(() {
                            _selectedAddress = result;
                          });
                        }
                      },
                      child: Text(
                        'Change',
                        style: poppinsMedium.copyWith(
                          fontSize: Constants.fontSizeSmall,
                          color: ColorResource.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_selectedAddress == null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ColorResource.scaffoldBackground,
                      borderRadius: BorderRadius.circular(Constants.radiusDefault),
                      border: Border.all(
                        color: ColorResource.textLight.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          color: ColorResource.textLight,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No address selected',
                            style: poppinsRegular.copyWith(
                              fontSize: Constants.fontSizeDefault,
                              color: ColorResource.textSecondary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: ColorResource.textLight,
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ColorResource.primaryDark.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Constants.radiusDefault),
                      border: Border.all(
                        color: ColorResource.primaryDark,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: ColorResource.primaryDark,
                            borderRadius: BorderRadius.circular(Constants.radiusDefault),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _selectedAddress!.name,
                                    style: poppinsBold.copyWith(
                                      fontSize: Constants.fontSizeDefault,
                                      color: ColorResource.primaryDark,
                                    ),
                                  ),
                                  if (_selectedAddress!.isDefault) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: ColorResource.primaryGradient,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'DEFAULT',
                                        style: poppinsBold.copyWith(
                                          fontSize: 9,
                                          color: ColorResource.textWhite,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedAddress!.phone,
                                style: poppinsRegular.copyWith(
                                  fontSize: Constants.fontSizeSmall,
                                  color: ColorResource.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedAddress!.fullAddress,
                                style: poppinsRegular.copyWith(
                                  fontSize: Constants.fontSizeSmall,
                                  color: ColorResource.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: ColorResource.textLight,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCouponSection(CartController controller) {
    return Container(
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Apply Coupon',
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeLarge,
                  color: ColorResource.textPrimary,
                ),
              ),
              if (controller.appliedCoupon == null)
                TextButton.icon(
                  onPressed: () async {
                    final result = await CouponSelectionBottomSheet.show(context);
                    
                    if (result != null) {
                      controller.applyCoupon(result);
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Choose'),
                  style: TextButton.styleFrom(
                    foregroundColor: ColorResource.primaryDark,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Constants.paddingSizeSmall),
          if (controller.appliedCoupon == null)
            Container(
              padding: const EdgeInsets.all(Constants.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
                border: Border.all(
                  color: Colors.grey[300]!, width: 0.3,
                  // style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No coupon applied',
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: ColorResource.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorResource.primaryDark.withValues(alpha: 0.05),
                    Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
                border: Border.all(
                  color: ColorResource.primaryDark.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ColorResource.primaryDark,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_offer_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.appliedCoupon!.code,
                              style: poppinsBold.copyWith(
                                fontSize: Constants.fontSizeDefault,
                                color: ColorResource.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'You saved ${CurrencyHelper.formatAmount(controller.discountAmount)}!',
                                  style: poppinsBold.copyWith(
                                    fontSize: Constants.fontSizeSmall,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => controller.removeCoupon(),
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.red,
                        tooltip: 'Remove coupon',
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInstructions() {
    return Container(
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Instructions',
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: ColorResource.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _instructionsController,
            decoration: InputDecoration(
              hintText: 'E.g., Ring the doorbell twice',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
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
              'Payment Method',
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
                color: ColorResource.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          RadioListTile<String>(
            value: 'cod',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
            title: Row(
              children: [
                Icon(Icons.money, color: Colors.green),
                const SizedBox(width: 12),
                Text(
                  'Cash on Delivery',
                  style: poppinsMedium.copyWith(fontSize: Constants.fontSizeDefault),
                ),
              ],
            ),
            subtitle: Text(
              'Pay when you receive',
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: ColorResource.textSecondary,
              ),
            ),
            activeColor: ColorResource.primaryDark,
          ),
          RadioListTile<String>(
            value: 'card',
            groupValue: _selectedPaymentMethod,
            onChanged: null, // Disabled
            title: Row(
              children: [
                Icon(Icons.credit_card, color: ColorResource.textLight),
                const SizedBox(width: 12),
                Text(
                  'Credit/Debit Card',
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: ColorResource.textLight,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorResource.textLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Soon',
                    style: poppinsRegular.copyWith(
                      fontSize: 10,
                      color: ColorResource.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'Pay online securely',
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: ColorResource.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary(CartController controller) {
    final total = controller.total + deliveryFee;
    
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Expandable price breakdown
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isPriceExpanded
                  ? Column(
                      children: [
                        _buildSummaryRow('Cart Items (${controller.itemCount})', controller.subtotal),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Delivery Fee', deliveryFee),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Tax (10%)', controller.tax),
                        if (controller.appliedCoupon != null) ...[ 
                          const SizedBox(height: 8),
                          _buildSummaryRow('Discount', -controller.discountAmount, isDiscount: true),
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
                            'Total',
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
                        CurrencyHelper.formatAmount(total),
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
            
            // Place order button
            GetBuilder<OrderController>(
              builder: (orderController) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: orderController.isPlacingOrder ? null : () => _placeOrder(controller, total),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorResource.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Constants.radiusLarge),
                      ),
                    ),
                    child: orderController.isPlacingOrder
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: ColorResource.textWhite,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Place Order - ${CurrencyHelper.formatAmount(total)}',
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeLarge,
                              color: ColorResource.textWhite,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isTotal ? poppinsBold : poppinsRegular).copyWith(
            fontSize: isTotal ? Constants.fontSizeLarge : Constants.fontSizeDefault,
            color: isDiscount ? Colors.green : ColorResource.textPrimary,
          ),
        ),
        Text(
          CurrencyHelper.formatAmount(amount),
          style: (isTotal ? poppinsBold : poppinsMedium).copyWith(
            fontSize: isTotal ? Constants.fontSizeLarge : Constants.fontSizeDefault,
            color: isDiscount ? Colors.green : (isTotal ? ColorResource.primaryDark : ColorResource.textPrimary),
          ),
        ),
      ],
    );
  }

  Future<void> _placeOrder(CartController cartController, double total) async {
    // Validate address selection
    if (_selectedAddress == null) {
      customToster('Please select a delivery address', isSuccess: false);
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Order',
          style: poppinsBold.copyWith(fontSize: Constants.fontSizeLarge),
        ),
        content: Text(
          'Are you sure you want to place this order for ${CurrencyHelper.formatAmount(total)}?',
          style: poppinsRegular.copyWith(fontSize: Constants.fontSizeDefault),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: poppinsMedium.copyWith(color: ColorResource.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: ColorResource.primaryDark),
            child: Text('Confirm', style: poppinsBold.copyWith(color: ColorResource.textWhite)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final orderController = Get.find<OrderController>();
      final authController = Get.find<AuthController>();
      String? userId = await authController.getUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Place order
      final result = await orderController.placeOrder(
        customerId: userId,
        address: _selectedAddress!,
        cartItems: cartController.cartItems,
        totalAmount: total,
        deliveryFee: deliveryFee,
        paymentMethod: _selectedPaymentMethod,
        deliveryInstructions: _instructionsController.text.trim(),
        deliveryType: _deliveryType,
        scheduledDate: _selectedDate,
        scheduledTimeSlot: _selectedTimeSlot,
      );

      if (result['success'] == true) {
        // Clear cart
        await cartController.clearCart();

        // Navigate to success page
        if (mounted) {
          Get.off(() => OrderSuccessPage(
            orderNumber: result['orderNumber'],
            totalAmount: total,
          ));
        }
      } else {
        throw Exception(result['error'] ?? 'Failed to place order');
      }
    } catch (e) {
      // Navigate to failed page
      if (mounted) {
        Get.to(() => OrderFailedPage(
          errorMessage: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => _placeOrder(cartController, total),
        ));
      }
    }
  }
  /// Build delivery schedule section with bottom sheet
  Widget _buildDeliverySchedule() {
    final settingsController = Get.find<SettingsController>();
    final businessSetup = settingsController.businessSetup;

    return GestureDetector(
      onTap: () async {
        final result = await DeliveryScheduleBottomSheet.show(
          context,
          initialType: _deliveryType,
          initialDate: _selectedDate,
          initialTimeSlot: _selectedTimeSlot,
        );

        if (result != null) {
          setState(() {
            _deliveryType = result['type'];
            _selectedDate = result['date'];
            _selectedTimeSlot = result['timeSlot'];
            _scheduleDisplayText = result['displayText'];
          });
        }
      },
      child: Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: ColorResource.primaryGradient,
                        borderRadius: BorderRadius.circular(Constants.radiusDefault),
                      ),
                      child: Icon(
                        Icons.schedule,
                        color: ColorResource.textWhite,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Delivery Schedule',
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeLarge,
                        color: ColorResource.textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    final result = await DeliveryScheduleBottomSheet.show(
                      context,
                      initialType: _deliveryType,
                      initialDate: _selectedDate,
                      initialTimeSlot: _selectedTimeSlot,
                    );

                    if (result != null) {
                      setState(() {
                        _deliveryType = result['type'];
                        _selectedDate = result['date'];
                        _selectedTimeSlot = result['timeSlot'];
                        _scheduleDisplayText = result['displayText'];
                      });
                    }
                  },
                  child: Text(
                    'Change',
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _deliveryType == 'now'
                    ? ColorResource.primaryDark.withValues(alpha: 0.1)
                    : ColorResource.scaffoldBackground,
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
                border: Border.all(
                  color: _deliveryType == 'now'
                      ? ColorResource.primaryDark
                      : ColorResource.textLight.withValues(alpha: 0.3),
                  width: _deliveryType == 'now' ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _deliveryType == 'now'
                          ? ColorResource.primaryDark
                          : ColorResource.primaryDark.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Constants.radiusDefault),
                    ),
                    child: Icon(
                      _deliveryType == 'now'
                          ? Icons.flash_on_rounded
                          : Icons.calendar_today_rounded,
                      color: _deliveryType == 'now'
                          ? Colors.white
                          : ColorResource.primaryDark,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _deliveryType == 'now' ? 'Deliver Now' : 'Scheduled Delivery',
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeDefault,
                            color: _deliveryType == 'now'
                                ? ColorResource.primaryDark
                                : ColorResource.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _scheduleDisplayText ?? 'ASAP (30-45 mins)',
                          style: poppinsRegular.copyWith(
                            fontSize: Constants.fontSizeSmall,
                            color: ColorResource.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: ColorResource.textLight,
                  ),
                ],
              ),
            ),
            if (businessSetup?.isStoreOpen == false && _deliveryType == 'now') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(Constants.radiusDefault),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Store is currently closed. Please schedule for later.',
                        style: poppinsRegular.copyWith(
                          fontSize: Constants.fontSizeSmall,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }



}
