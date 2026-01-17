import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderFailedPage extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;

  const OrderFailedPage({
    super.key,
    required this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Allow back button to go to checkout
        return true;
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
                    // Error Animation
                    _buildErrorAnimation(),
                    const SizedBox(height: 32),

                    // Error Message
                    Text(
                      'Order Failed',
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeExtraLarge + 4,
                        color: ColorResource.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Unfortunately, we couldn\'t process your order.',
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: ColorResource.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Error Details Card
                    _buildErrorDetailsCard(),
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

  Widget _buildErrorAnimation() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.red.shade400,
            Colors.red.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade200,
            blurRadius: 30,
            spreadRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        Icons.error_outline,
        size: 100,
        color: ColorResource.textWhite,
      ),
    );
  }

  Widget _buildErrorDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
        border: Border.all(
          color: Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 40,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Details',
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: ColorResource.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: ColorResource.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Retry Button
        if (onRetry != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.back(); // Go back to checkout
                onRetry?.call(); // Trigger retry
              },
              icon: const Icon(Icons.refresh),
              label: Text(
                'Try Again',
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
        if (onRetry != null) const SizedBox(height: 16),

        // Go Back Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Get.back(); // Go back to checkout
            },
            icon: const Icon(Icons.arrow_back),
            label: Text(
              'Go Back to Checkout',
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorResource.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                color: ColorResource.textSecondary,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Constants.radiusLarge),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Home Button
        TextButton.icon(
          onPressed: () {
            Get.until((route) => route.isFirst); // Go to home
          },
          icon: const Icon(Icons.home_outlined),
          label: Text(
            'Go to Home',
            style: poppinsMedium.copyWith(
              fontSize: Constants.fontSizeDefault,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: ColorResource.primaryDark,
          ),
        ),
      ],
    );
  }
}
