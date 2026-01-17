import 'package:appwrite_user_app/app/modules/orders/screens/orders_page.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderSuccessPage extends StatelessWidget {
  final String orderNumber;
  final double totalAmount;

  const OrderSuccessPage({
    super.key,
    required this.orderNumber,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back button, force user to use navigation buttons
        return false;
      },
      child: Scaffold(
        backgroundColor: ColorResource.scaffoldBackground,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Animation
                    _buildSuccessAnimation(),
                    const SizedBox(height: 32),

                    // Success Message
                    Text(
                      'Order Placed Successfully!',
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeExtraLarge + 4,
                        color: ColorResource.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Thank you for your order. We\'ve received it and will start preparing soon.',
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: ColorResource.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Order Details Card
                    _buildOrderDetailsCard(),
                    const SizedBox(height: 40),

                    // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.green.shade400,
            Colors.green.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200,
            blurRadius: 30,
            spreadRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        Icons.check_circle,
        size: 100,
        color: ColorResource.textWhite,
      ),
    );
  }

  Widget _buildOrderDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        children: [
          Text(
            'Order Number',
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: ColorResource.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: ColorResource.primaryDark.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              orderNumber,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
                color: ColorResource.primaryDark,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textSecondary,
                ),
              ),
              Text(
                '\$${totalAmount.toStringAsFixed(2)}',
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeExtraLarge,
                  color: ColorResource.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // View Order Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to orders page and clear all previous routes
              Get.offAll(() => const OrdersPage());
            },
            icon: const Icon(Icons.receipt_long),
            label: Text(
              'View My Orders',
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorResource.primaryDark,
              foregroundColor: ColorResource.textWhite,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Constants.radiusLarge),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Continue Shopping Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // Go back to home/dashboard, clear navigation stack
              Get.until((route) => route.isFirst);
            },
            icon: const Icon(Icons.shopping_bag_outlined),
            label: Text(
              'Continue Shopping',
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorResource.primaryDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                color: ColorResource.primaryDark,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Constants.radiusLarge),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
