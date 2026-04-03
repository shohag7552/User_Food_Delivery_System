import 'dart:convert';

class OrderModel {
  final String id;
  final String orderNumber; // Readable order number like "ORD-20260117-001"
  final String customerId;
  final String? driverId;
  final DeliverymanInfo? deliveryman;
  final String status; // 'pending', 'cooking', etc.
  final double totalAmount;
  final double deliveryFee;
  final DeliveryAddress address; // <--- Parsed from JSON
  final List<OrderItem> items; // <--- Parsed from JSON
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    this.driverId,
    this.deliveryman,
    required this.status,
    required this.totalAmount,
    required this.deliveryFee,
    required this.address,
    required this.items,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['\$id'],
      orderNumber: json['order_number'] ?? 'N/A',
      customerId: json['customer_id'],
      driverId: json['driver_id'] ?? json['deliver_id'],
      deliveryman: DeliverymanInfo.fromOrderJson(json),
      status: json['status'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      createdAt: DateTime.parse(json['\$createdAt']), // Appwrite auto-timestamp
      // PARSE ADDRESS SNAPSHOT
      address: DeliveryAddress.fromJson(jsonDecode(json['delivery_address'])),

      // PARSE ITEMS SNAPSHOT
      items: (jsonDecode(json['order_items']) as List)
          .map((e) => OrderItem.fromJson(e))
          .toList(),
    );
  }

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    String? customerId,
    String? driverId,
    DeliverymanInfo? deliveryman,
    String? status,
    double? totalAmount,
    double? deliveryFee,
    DeliveryAddress? address,
    List<OrderItem>? items,
    DateTime? createdAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      driverId: driverId ?? this.driverId,
      deliveryman: deliveryman ?? this.deliveryman,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      address: address ?? this.address,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
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
  final double price;
  final int quantity;
  final List<String> selectedVariants; // e.g. ["Large", "Extra Cheese"]

  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.selectedVariants,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] ?? '',
      productName: json['product_name'],
      productImage: json['product_image'] ?? '',
      price: (json['price'] as num).toDouble(),
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
