import 'dart:convert';

class OrderModel {
  final String id;
  final String orderNumber; // Readable order number like "ORD-20260117-001"
  final String customerId;
  final String? driverId;
  final DeliverymanInfo? deliveryman;
  final String status; // 'pending', 'cooking', etc.
  final String paymentMethod; // 'cod', 'online', 'wallet'
  final String paymentStatus; // 'unpaid', 'paid', 'failed', 'cancelled'
  final double totalAmount;
  final double deliveryFee;
  final double taxAmount;
  final double discountAmount; // Total item-level discount
  final double couponDiscount; // Coupon discount applied at checkout
  final DeliveryAddress address; // <--- Parsed from JSON
  final List<OrderItem> items; // <--- Parsed from JSON
  final DateTime createdAt;
  // Absolute UTC start/end of the scheduled delivery slot (null for ASAP / most
  // ecommerce orders). Display in the store timezone via StoreTime.
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final String moduleType; // 'food' | 'ecommerce'
  // --- Ecommerce fulfillment (nullable; food ignores them) ---
  final double shippingCost;
  final String? shippingMethod;
  final String? trackingNumber;
  final String? courierName;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    this.driverId,
    this.deliveryman,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.totalAmount,
    required this.deliveryFee,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.couponDiscount = 0.0,
    required this.address,
    required this.items,
    required this.createdAt,
    this.scheduledStart,
    this.scheduledEnd,
    this.moduleType = 'food',
    this.shippingCost = 0.0,
    this.shippingMethod,
    this.trackingNumber,
    this.courierName,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['\$id'],
      orderNumber: json['order_number'] ?? 'N/A',
      customerId: json['customer_id'],
      driverId: json['driver_id'] ?? json['deliver_id'],
      deliveryman: DeliverymanInfo.fromOrderJson(json),
      status: json['status'],
      paymentMethod: json['payment_method'] ?? 'cod',
      paymentStatus: json['payment_status'] ?? 'unpaid',
      totalAmount: (json['total_amount'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      couponDiscount: (json['coupon_discount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['\$createdAt']), // Appwrite auto-timestamp
      scheduledStart: json['scheduled_start'] != null
          ? DateTime.parse(json['scheduled_start'])
          : null,
      scheduledEnd: json['scheduled_end'] != null
          ? DateTime.parse(json['scheduled_end'])
          : null,
      // PARSE ADDRESS SNAPSHOT
      address: DeliveryAddress.fromJson(jsonDecode(json['delivery_address'])),

      // PARSE ITEMS SNAPSHOT
      items: (jsonDecode(json['order_items']) as List)
          .map((e) => OrderItem.fromJson(e))
          .toList(),
      moduleType: json['module_type'] as String? ?? 'food',
      shippingCost: (json['shipping_cost'] as num?)?.toDouble() ?? 0.0,
      shippingMethod: json['shipping_method'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      courierName: json['courier_name'] as String?,
    );
  }

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    String? customerId,
    String? driverId,
    DeliverymanInfo? deliveryman,
    String? status,
    String? paymentMethod,
    String? paymentStatus,
    double? totalAmount,
    double? deliveryFee,
    double? taxAmount,
    double? discountAmount,
    double? couponDiscount,
    DeliveryAddress? address,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    String? moduleType,
    double? shippingCost,
    String? shippingMethod,
    String? trackingNumber,
    String? courierName,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      driverId: driverId ?? this.driverId,
      deliveryman: deliveryman ?? this.deliveryman,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      couponDiscount: couponDiscount ?? this.couponDiscount,
      address: address ?? this.address,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      moduleType: moduleType ?? this.moduleType,
      shippingCost: shippingCost ?? this.shippingCost,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      courierName: courierName ?? this.courierName,
    );
  }
}

class DeliverymanInfo {
  final String? id;
  final String name;
  final String phone;
  final String? image;
  final double? latitude;
  final double? longitude;

  DeliverymanInfo({
    this.id,
    required this.name,
    required this.phone,
    this.image,
    this.latitude,
    this.longitude,
  });

  bool get hasLocation => latitude != null && longitude != null;

  bool get hasData =>
      name.isNotEmpty ||
      phone.isNotEmpty ||
      (image != null && image!.isNotEmpty) ||
      hasLocation;

  factory DeliverymanInfo.fromJson(Map<String, dynamic> json) {
    return DeliverymanInfo(
      id: json['\$id'] ?? json['id'] ?? json['driver_id'] ?? json['deliver_id'],
      name:
          json['name'] ??
          json['driver_name'] ??
          json['deliveryman_name'] ??
          json['deliver_name'] ??
          '',
      phone:
          json['phone'] ??
          json['driver_phone'] ??
          json['deliveryman_phone'] ??
          json['deliver_phone'] ??
          '',
      image:
          json['profile_image_url'] ??
          json['image'] ??
          json['driver_image'] ??
          json['deliveryman_image'] ??
          json['deliver_image'],
      latitude: _parseCoordinate(
        json['latitude'] ??
            json['lat'] ??
            json['current_latitude'] ??
            json['current_lat'] ??
            json['driver_latitude'] ??
            json['driver_lat'] ??
            json['deliveryman_latitude'] ??
            json['deliveryman_lat'] ??
            json['deliver_latitude'] ??
            json['deliver_lat'],
      ),
      longitude: _parseCoordinate(
        json['longitude'] ??
            json['lng'] ??
            json['current_longitude'] ??
            json['current_lng'] ??
            json['driver_longitude'] ??
            json['driver_lng'] ??
            json['deliveryman_longitude'] ??
            json['deliveryman_lng'] ??
            json['deliver_longitude'] ??
            json['deliver_lng'],
      ),
    );
  }

  static DeliverymanInfo? fromOrderJson(Map<String, dynamic> json) {
    final dynamic nestedData =
        json['deliveryman'] ??
        json['delivery_man'] ??
        json['driver'] ??
        json['deliver'];

    if (nestedData is Map<String, dynamic>) {
      final deliveryman = DeliverymanInfo.fromJson(nestedData);
      return deliveryman.hasData ? deliveryman : null;
    }

    final deliveryman = DeliverymanInfo.fromJson(json);
    return deliveryman.hasData ? deliveryman : null;
  }

  static double? _parseCoordinate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final double basePrice; // Original price before discount
  final double price; // Final price after discount
  final int quantity;
  final List<String> selectedVariants; // e.g. ["Large", "Extra Cheese"]

  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.basePrice,
    required this.price,
    required this.quantity,
    required this.selectedVariants,
  });

  bool get hasDiscount => basePrice > price;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final price = (json['price'] as num).toDouble();
    return OrderItem(
      productId: json['product_id'] ?? '',
      productName: json['product_name'],
      productImage: json['product_image'] ?? '',
      basePrice: (json['base_price'] as num?)?.toDouble() ?? price,
      price: price,
      quantity: json['quantity'],
      selectedVariants: List<String>.from(json['selected_variants'] ?? []),
    );
  }
}

class DeliveryAddress {
  final String street;
  final double lat;
  final double lng;

  DeliveryAddress({required this.street, required this.lat, required this.lng});

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      street: json['address'], // Mapped from your 'addresses' collection
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}
