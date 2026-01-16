import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
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
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  String _selectedPaymentMethod = 'cod';
  bool _isPlacingOrder = false;
  bool _showAllItems = false;
  
  final double deliveryFee = 5.00;
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderSummary(controller),
                        const SizedBox(height: 20),
                        _buildDeliveryAddress(),
                        const SizedBox(height: 20),
                        _buildPaymentMethod(),
                        const SizedBox(height: 100), // Space for bottom summary
                      ],
                    ),
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
                      '\$${item.itemTotal.toStringAsFixed(2)}',
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
            'Delivery Address',
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: ColorResource.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              if (value.length < 10) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressLine1Controller,
            decoration: InputDecoration(
              labelText: 'Address Line 1 *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressLine2Controller,
            decoration: InputDecoration(
              labelText: 'Address Line 2',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'City *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Constants.radiusDefault),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _postalCodeController,
                  decoration: InputDecoration(
                    labelText: 'Postal Code *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Constants.radiusDefault),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _instructionsController,
            decoration: InputDecoration(
              labelText: 'Delivery Instructions (Optional)',
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
    final total = controller.subtotal + controller.tax + deliveryFee;
    
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
            _buildSummaryRow('Cart Items (${controller.itemCount})', controller.subtotal),
            const SizedBox(height: 8),
            _buildSummaryRow('Delivery Fee', deliveryFee),
            const SizedBox(height: 8),
            _buildSummaryRow('Tax (10%)', controller.tax),
            const Divider(height: 20),
            _buildSummaryRow('Total', total, isTotal: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPlacingOrder ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResource.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Constants.radiusLarge),
                  ),
                ),
                child: _isPlacingOrder
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: ColorResource.textWhite,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Place Order - \$${total.toStringAsFixed(2)}',
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
          style: (isTotal ? poppinsBold : poppinsRegular).copyWith(
            fontSize: isTotal ? Constants.fontSizeLarge : Constants.fontSizeDefault,
            color: ColorResource.textPrimary,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: (isTotal ? poppinsBold : poppinsMedium).copyWith(
            fontSize: isTotal ? Constants.fontSizeLarge : Constants.fontSizeDefault,
            color: isTotal ? ColorResource.primaryDark : ColorResource.textPrimary,
          ),
        ),
      ],
    );
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        'Incomplete Form',
        'Please fill all required fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorResource.error,
        colorText: ColorResource.textWhite,
      );
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
          'Are you sure you want to place this order?',
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

    setState(() => _isPlacingOrder = true);

    try {
      // TODO: Save order to database
      await Future.delayed(const Duration(seconds: 2)); // Simulating API call

      // Clear cart
      await Get.find<CartController>().clearCart();

      // Show success and go back
      Get.back(); // Close checkout
      Get.snackbar(
        'Order Placed!',
        'Your order has been placed successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: ColorResource.textWhite,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to place order. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorResource.error,
        colorText: ColorResource.textWhite,
      );
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }
}
