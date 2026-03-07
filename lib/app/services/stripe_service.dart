import 'dart:convert';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeService {
  StripeService._();

  static final StripeService instance = StripeService._();

  Future<bool> makePayment(double amount, String currency, String userEmail) async {
    try {
      // 1. Create PaymentIntent on the Server
      final paymentIntentData = await _createPaymentIntent(amount, currency, userEmail);
      if (paymentIntentData == null || !paymentIntentData.containsKey('client_secret')) {
        return false;
      }

      final clientSecret = paymentIntentData['client_secret'];

      // 2. Initialize the Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: Constants.appName,
          // appearance: const PaymentSheetAppearance(
          //   colors: PaymentSheetAppearanceColors(
          //     primary: ColorResource.primaryDark,
          //   ),
          // ),
        ),
      );

      // 3. Display the Payment Sheet
      await _displayPaymentSheet();
      return true; // Payment was successful
      
    } on StripeException catch (e) {
      debugPrint("Stripe Exception: \${e.error.localizedMessage}");
      return false; // Payment failed or was canceled
    } catch (e) {
      debugPrint("Error in makePayment: \$e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> _createPaymentIntent(
      double amount, String currency, String userEmail) async {
    try {
      // Calculate amount in cents (or smallest currency unit)
      final int amountInCents = (amount * 100).toInt();

      final url = Uri.parse(Constants.stripeBackendUrl);
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amountInCents,
          'currency': currency,
          'email': userEmail,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to create PaymentIntent: \${response.body}');
        return null;
      }
    } catch (err) {
      debugPrint('Error creating PaymentIntent: \$err');
      return null;
    }
  }

  Future<void> _displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      throw Exception("Error presenting payment sheet: \$e");
    }
  }
}
