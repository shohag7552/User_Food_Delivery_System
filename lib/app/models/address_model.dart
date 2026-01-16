class AddressModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String postalCode;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.addressLine1,
    this.addressLine2 = '',
    required this.city,
    required this.postalCode,
    this.isDefault = false,
  });

  // Get full address as single string
  String get fullAddress {
    final line2 = addressLine2.isNotEmpty ? ', $addressLine2' : '';
    return '$addressLine1$line2, $city - $postalCode';
  }

  // Get short address (first line + city)
  String get shortAddress => '$addressLine1, $city';

  // Create copy with updated fields
  AddressModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? postalCode,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['\$id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      addressLine1: json['address_line_1'] ?? '',
      addressLine2: json['address_line_2'] ?? '',
      city: json['city'] ?? '',
      postalCode: json['postal_code'] ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'phone': phone,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'postal_code': postalCode,
      'is_default': isDefault,
    };
  }
}
