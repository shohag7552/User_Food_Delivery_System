import 'dart:convert';
import 'dart:developer';

import 'package:kikomart_user_app/app/models/address_model.dart';
import 'package:kikomart_user_app/app/models/cart_item_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Everything needed to write the order once the gateway says the money
/// arrived — held on disk while the customer is away paying.
///
/// Only the web redirect flow needs this: leaving for the gateway tears the
/// Flutter app down, so the checkout screen's state is gone by the time the
/// customer lands back on `/payment/success`. On Android and iOS the payment
/// runs in a WebView the checkout screen is still waiting behind, and none of
/// this is used.
class PendingPayment {
  final String customerId;
  final AddressModel address;
  final List<CartItemModel> cartItems;
  final double totalAmount;
  final double deliveryFee;
  final double taxAmount;
  final double discountAmount;
  final double couponDiscount;
  final String paymentMethod;
  final String? deliveryInstructions;
  final String? deliveryType;
  final DateTime? scheduledDate;
  final String? scheduledTimeSlot;
  final double? shippingCost;
  final String? shippingMethod;

  /// Storefront the order was placed in. Carried because the return lands on
  /// a cold app, where [ModuleController.current] has not been resolved yet
  /// and would silently fall back to food.
  final String moduleType;

  // ── Payment identity — what the return page verifies against Stripe ──

  /// Temporary reference the Checkout Session was created with (Stripe's
  /// client_reference_id). The function refuses to confirm a session that
  /// belongs to a different one.
  final String? reference;

  /// Stripe Checkout Session id returned by `/stripe/create`.
  final String? sessionId;

  /// Amount sent to Stripe, in minor units, and its currency — the paid
  /// session must match both before an order is written.
  final int? amountMinor;
  final String? currency;

  /// When the customer left for Stripe. Orders older than [maxAge] are not
  /// resumed: a checkout session expires long before that.
  final DateTime? createdAt;

  /// Set while a return page is writing the order, so a reload or second tab
  /// cannot write it twice.
  final DateTime? processingAt;

  static const Duration maxAge = Duration(hours: 24);

  /// How long a "processing" marker blocks another attempt. Longer than any
  /// order write; a page closed mid-write frees the order again after this.
  static const Duration processingLease = Duration(minutes: 2);

  bool get isExpired =>
      createdAt != null && DateTime.now().difference(createdAt!) > maxAge;

  bool get isBeingProcessed =>
      processingAt != null &&
      DateTime.now().difference(processingAt!) < processingLease;

  const PendingPayment({
    required this.customerId,
    required this.address,
    required this.cartItems,
    required this.totalAmount,
    required this.deliveryFee,
    required this.taxAmount,
    required this.discountAmount,
    required this.couponDiscount,
    required this.paymentMethod,
    this.deliveryInstructions,
    this.deliveryType,
    this.scheduledDate,
    this.scheduledTimeSlot,
    this.shippingCost,
    this.shippingMethod,
    required this.moduleType,
    this.reference,
    this.sessionId,
    this.amountMinor,
    this.currency,
    this.createdAt,
    this.processingAt,
  });

  PendingPayment withProcessingAt(DateTime? at) => PendingPayment(
        customerId: customerId,
        address: address,
        cartItems: cartItems,
        totalAmount: totalAmount,
        deliveryFee: deliveryFee,
        taxAmount: taxAmount,
        discountAmount: discountAmount,
        couponDiscount: couponDiscount,
        paymentMethod: paymentMethod,
        deliveryInstructions: deliveryInstructions,
        deliveryType: deliveryType,
        scheduledDate: scheduledDate,
        scheduledTimeSlot: scheduledTimeSlot,
        shippingCost: shippingCost,
        shippingMethod: shippingMethod,
        moduleType: moduleType,
        reference: reference,
        sessionId: sessionId,
        amountMinor: amountMinor,
        currency: currency,
        createdAt: createdAt,
        processingAt: at,
      );

  Map<String, dynamic> toJson() => {
        'customer_id': customerId,
        'address': address.toJson(),
        'cart_items': cartItems.map((e) => e.toJson()).toList(),
        'total_amount': totalAmount,
        'delivery_fee': deliveryFee,
        'tax_amount': taxAmount,
        'discount_amount': discountAmount,
        'coupon_discount': couponDiscount,
        'payment_method': paymentMethod,
        'delivery_instructions': deliveryInstructions,
        'delivery_type': deliveryType,
        'scheduled_date': scheduledDate?.toIso8601String(),
        'scheduled_time_slot': scheduledTimeSlot,
        'shipping_cost': shippingCost,
        'shipping_method': shippingMethod,
        'module_type': moduleType,
        'reference': reference,
        'session_id': sessionId,
        'amount_minor': amountMinor,
        'currency': currency,
        'created_at': createdAt?.toIso8601String(),
        'processing_at': processingAt?.toIso8601String(),
      };

  factory PendingPayment.fromJson(Map<String, dynamic> json) {
    return PendingPayment(
      customerId: json['customer_id'] as String,
      address: AddressModel.fromJson(
        Map<String, dynamic>.from(json['address'] as Map),
      ),
      cartItems: (json['cart_items'] as List)
          .map((e) => CartItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num).toDouble(),
      discountAmount: (json['discount_amount'] as num).toDouble(),
      couponDiscount: (json['coupon_discount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      deliveryInstructions: json['delivery_instructions'] as String?,
      deliveryType: json['delivery_type'] as String?,
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.tryParse(json['scheduled_date'] as String)
          : null,
      scheduledTimeSlot: json['scheduled_time_slot'] as String?,
      shippingCost: (json['shipping_cost'] as num?)?.toDouble(),
      shippingMethod: json['shipping_method'] as String?,
      moduleType: json['module_type'] as String,
      // Absent on payloads saved by an older build — still resumable, just
      // with fewer checks (Stripe verification itself always runs).
      reference: json['reference'] as String?,
      sessionId: json['session_id'] as String?,
      amountMinor: (json['amount_minor'] as num?)?.toInt(),
      currency: json['currency'] as String?,
      createdAt: _date(json['created_at']),
      processingAt: _date(json['processing_at']),
    );
  }

  static DateTime? _date(dynamic raw) =>
      raw is String ? DateTime.tryParse(raw) : null;
}

abstract class PendingPaymentStore {
  const PendingPaymentStore._();

  static const String _key = 'pending_payment_order';

  static Future<void> save(PendingPayment payment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(payment.toJson()));
  }

  /// Returns the order waiting on a payment, or null when there is none — a
  /// callback opened on another device, or a stored payload this build can no
  /// longer read.
  static Future<PendingPayment?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;

    try {
      return PendingPayment.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e) {
      log('Discarding unreadable pending payment: $e');
      await clear();
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Claims the pending order for writing. Returns false when another page
  /// (reload, second tab) is already writing it.
  static Future<bool> tryMarkProcessing() async {
    final pending = await read();
    if (pending == null || pending.isBeingProcessed) return false;
    await save(pending.withProcessingAt(DateTime.now()));
    return true;
  }

  /// Releases the claim after a failed write so a retry can run.
  static Future<void> releaseProcessing() async {
    final pending = await read();
    if (pending == null) return;
    await save(pending.withProcessingAt(null));
  }

  static const String _completedKey = 'last_completed_payment_session';

  /// Remembers the session whose order was written, so a reload of the
  /// success URL shows the order instead of reporting a missing payment.
  static Future<void> rememberCompleted(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_completedKey, sessionId);
  }

  static Future<bool> wasCompleted(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_completedKey) == sessionId;
  }
}
