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
    // Web only: where Stripe returns the customer. Built from the site's own
    // origin so the return always lands on the domain that holds the pending
    // order. Mobile leaves these null and the function's env URLs apply.
    String? successURL,
    String? cancelURL,
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
    if (successURL != null) body['successURL'] = successURL;
    if (cancelURL != null) body['cancelURL'] = cancelURL;

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

  /// Asks the payment function — which asks Stripe — whether a Checkout
  /// Session was actually paid.
  ///
  /// Landing on the success URL proves nothing: anyone can open it. This is
  /// the call that decides whether a paid order may be written. [orderId] is
  /// the temporary reference the session was created with; the function
  /// rejects a session that belongs to a different one.
  Future<StripeVerification> verifyStripeSession({
    required String sessionId,
    String? orderId,
  }) async {
    final Execution execution;
    try {
      execution = await _functions.createExecution(
        functionId: _functionId,
        path: '/stripe/verify',
        method: ExecutionMethod.pOST,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': sessionId,
          if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
        }),
      );
    } catch (e) {
      throw PaymentException('Failed to reach payment server: $e');
    }

    final Map<String, dynamic> result;
    try {
      result = jsonDecode(execution.responseBody) as Map<String, dynamic>;
    } catch (_) {
      throw PaymentException(
        'Payment server returned an unreadable response '
        '(status ${execution.responseStatusCode}).',
      );
    }

    if (result['success'] != true) {
      final error = result['error'];
      final code = error is Map ? error['code']?.toString() : null;
      final message = error is Map
          ? error['message']?.toString()
          : error?.toString();
      throw PaymentException(
        message ?? 'Payment verification failed',
        code: code,
      );
    }

    final data = Map<String, dynamic>.from(result['data'] as Map? ?? {});
    return StripeVerification(
      sessionId: (data['sessionId'] ?? sessionId).toString(),
      orderId: (data['orderId'] ?? '').toString(),
      paid: data['paid'] == true,
      status: (data['status'] ?? '').toString(),
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      currency: (data['currency'] ?? '').toString(),
    );
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

/// What Stripe says about a Checkout Session — see
/// [PaymentService.verifyStripeSession].
class StripeVerification {
  final String sessionId;
  final String orderId;

  /// The only flag an order may be released on. False for a session that is
  /// unpaid, expired, or still "processing" (a delayed method not settled).
  final bool paid;

  /// paid | no_payment_required | processing | pending | expired
  final String status;

  /// Charged amount in minor units, and its upper-case currency code.
  final int amount;
  final String currency;

  const StripeVerification({
    required this.sessionId,
    required this.orderId,
    required this.paid,
    required this.status,
    required this.amount,
    required this.currency,
  });
}

/// Custom exception so callers can distinguish payment errors from generic ones.
class PaymentException implements Exception {
  final String message;

  /// The function's error code (e.g. `order_mismatch`), when it sent one.
  final String? code;

  PaymentException(this.message, {this.code});

  @override
  String toString() => message;
}
