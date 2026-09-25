// lib/services/payment_service.dart

import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';

class PaymentService {
  final Functions _functions;

  static const String _functionId = AppwriteConfig.stripePaymentFunctionId;

  // ── Callback paths — must match the Appwrite function's routes ──
  //
  // Detection matches on the path alone. The host the function is served on
  // changes every time it is redeployed (a move between Appwrite projects
  // gives it a brand-new domain), and a stale host would leave the customer
  // staring at a finished payment page the app never recognises.
  static const String successPath = '/payment/success';
  static const String failPath = '/payment/fail';
  static const String cancelPath = '/payment/cancel';

  // ── Absolute callback URLs — must match the function's own env vars ──
  static const String successURL =
      '${AppwriteConfig.paymentCallbackBaseUrl}$successPath';
  static const String failURL =
      '${AppwriteConfig.paymentCallbackBaseUrl}$failPath';
  static const String cancelURL =
      '${AppwriteConfig.paymentCallbackBaseUrl}$cancelPath';

  /// Singleton-friendly constructor that reuses the AppwriteService client.
  PaymentService() : _functions = AppwriteService().functions;

  /// Creates a payment session for the given [gateway].
  ///
  /// [gateway] — "stripe", "sslcommerz", "bkash", "razorpay", "paypal"
  /// [amount]  — amount in the smallest currency unit (cents / paise / poisha)
  /// [orderId] — a temporary order reference (not the DB order yet)
  ///
  /// Returns a map with `{ success: true, data: { paymentURL: "..." } }`.
  Future<Map<String, dynamic>> createPayment({
    required String gateway,
    required int amount,
    required String orderId,
    String? currency,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? productName,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
      'orderId': orderId,
    };

    if (currency != null) body['currency'] = currency;
    if (customerName != null) body['customerName'] = customerName;
    if (customerEmail != null) body['customerEmail'] = customerEmail;
    if (customerPhone != null) body['customerPhone'] = customerPhone;
    if (productName != null) body['productName'] = productName;

    // bKash needs an explicit callbackURL
    if (gateway == 'bkash') {
      body['callbackURL'] = successURL;
    }

    final Execution execution;
    try {
      execution = await _functions.createExecution(
        functionId: _functionId,
        path: '/$gateway/create',
        method: ExecutionMethod.pOST,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
    } catch (e) {
      throw PaymentException('Failed to reach payment server: $e');
    }

    final Map<String, dynamic> result;
    try {
      result = jsonDecode(execution.responseBody) as Map<String, dynamic>;
    } catch (_) {
      // An empty or non-JSON body means the function never ran its handler —
      // a build that failed, a timeout, or a deployment serving something
      // else entirely. Reporting the decode error would hide all of that.
      throw PaymentException(
        'Payment server returned an unreadable response '
        '(status ${execution.responseStatusCode}).',
      );
    }

    if (result['success'] != true) {
      // The function reports errors as {code, message}; older/other responses
      // use a plain string. Unwrapping keeps the customer-facing message free
      // of Dart map syntax.
      final error = result['error'];
      final message = error is Map
          ? error['message']?.toString()
          : error?.toString();
      throw PaymentException(message ?? 'Payment creation failed');
    }

    return result;
  }

  /// bKash execute step — call after user completes auth redirect.
  Future<Map<String, dynamic>> executeBkashPayment(String paymentID) async {
    final execution = await _functions.createExecution(
      functionId: _functionId,
      path: '/bkash/execute',
      method: ExecutionMethod.pOST,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'paymentID': paymentID}),
    );

    return jsonDecode(execution.responseBody) as Map<String, dynamic>;
  }
}

/// Custom exception so callers can distinguish payment errors from generic ones.
class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);

  @override
  String toString() => message;
}
