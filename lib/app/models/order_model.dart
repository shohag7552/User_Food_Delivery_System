import 'dart:convert';

class OrderModel {
  final String id;
  final String orderNumber; // Readable order number like "ORD-20260117-001"
  final String customerId;
  final String? driverId;
  final String status; // 'pending', 'cooking', etc.
  final double totalAmount;
  final double deliveryFee;
  final DeliveryAddress address; // <--- Parsed from JSON
  final List<OrderItem> items;   // <--- Parsed from JSON
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    this.driverId,
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
      driverId: json['driver_id'],
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
}

class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final List<String> selectedVariants; // e.g. ["Large", "Extra Cheese"]

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.selectedVariants,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] ?? '',
      productName: json['product_name'],
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