import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:get/get.dart';

class StripeService {
  StripeService._();

  static final StripeService instance = StripeService._();

  Future<bool> makePayment(double amount, String currency, String userEmail) async {
    try {
      // 1. Create PaymentIntent on the Server
      final paymentIntentData = await _createPaymentIntent(amount, currency, userEmail);
      print('PaymentIntent Data: $paymentIntentData');
      if (paymentIntentData == null || !paymentIntentData.containsKey('clientSecret')) {
        return false;
      }

      final clientSecret = paymentIntentData['clientSecret'];

      // 2. Initialize the Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: Constants.appName,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Theme.of(Get.context!).primaryColor,
            ),
          ),
        ),
      );

      // 3. Display the Payment Sheet
      await _displayPaymentSheet();
      return true; // Payment was successful
      
    } on StripeException catch (e) {
      debugPrint("Stripe Exception: ${e.error.localizedMessage}");
      return false; // Payment failed or was canceled
    } catch (e) {
      debugPrint("Error in makePayment: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> _createPaymentIntent(
      double amount, String currency, String userEmail) async {
    try {
      // Calculate amount in cents (or smallest currency unit)
      final int amountInCents = (amount * 100).toInt();

      return await AppwriteService().requestStripPayment(
        amount: amountInCents,
        currency: currency,
        userEmail: userEmail,
      );
    } catch (err) {
      debugPrint('Error creating PaymentIntent: $err');
      return null;
    }
  }

  Future<void> _displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      throw Exception("Error presenting payment sheet: $e");
    }
  }
}
