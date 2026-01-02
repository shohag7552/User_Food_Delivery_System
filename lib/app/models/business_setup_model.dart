import 'package:appwrite_user_app/app/models/business_hours_model.dart';

class BusinessSetupModel {
  final String? id;
  final String businessName;
  final String registrationNumber;
  final String taxId;
  // final String businessType;
  final String currency;
  final WeeklyBusinessHours businessHours;
  final bool acceptsCash;
  // final bool acceptsCard;
  final bool acceptsDigitalWallet;
  final bool acceptsOnlinePayment;
  final double? deliveryFeePerKm;
  final double? minDeliveryFee;
  final double? freeDeliveryAbove;
  final double? maxDeliveryRadius;
  final String storeLocation;
  final bool isStoreOpen;
  final bool isMaintenanceModeOn;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BusinessSetupModel({
    this.id,
    required this.businessName,
    required this.registrationNumber,
    required this.taxId,
    // required this.businessType,
    required this.currency,
    required this.businessHours,
    required this.acceptsCash,
    // required this.acceptsCard,
    required this.acceptsDigitalWallet,
    required this.acceptsOnlinePayment,
    this.deliveryFeePerKm,
    this.minDeliveryFee,
    this.freeDeliveryAbove,
    this.maxDeliveryRadius,
    required this.storeLocation,
    required this.isStoreOpen,
    required this.isMaintenanceModeOn,
    this.createdAt,
    this.updatedAt,
  });

  factory BusinessSetupModel.fromJson(Map<String, dynamic> json) {
    return BusinessSetupModel(
      id: json['\$id'],
      businessName: json['business_name'] ?? '',
      registrationNumber: json['registration_number'] ?? '',
      taxId: json['tax_number'] ?? '',
      // businessType: json['business_type'] ?? 'restaurant',
      currency: json['currency_symbol'] ?? 'USD',
      businessHours: json['business_hours'] != null
          ? WeeklyBusinessHours.fromJson(json['business_hours'])
          : WeeklyBusinessHours.defaultSchedule(),
      acceptsCash: json['is_cod_active'] ?? true,
      // acceptsCard: json['accepts_card'] ?? true,
      acceptsDigitalWallet: json['is_wallet_active'] ?? false,
      acceptsOnlinePayment: json['is_digital_active'] ?? false,
      deliveryFeePerKm: json['delivery_fee_per_km']?.toDouble(),
      minDeliveryFee: json['min_delivery_fee']?.toDouble(),
      freeDeliveryAbove: json['free_delivery_above']?.toDouble(),
      maxDeliveryRadius: json['max_delivery_radius']?.toDouble(),
      storeLocation: json['store_location'] ?? '',
      isStoreOpen: json['is_store_open'] ?? true,
      isMaintenanceModeOn: json['is_maintenance_mode_on'] ?? false,
      createdAt: json['\$createdAt'] != null
          ? DateTime.parse(json['\$createdAt'])
          : null,
      updatedAt: json['\$updatedAt'] != null
          ? DateTime.parse(json['\$updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_name': businessName,
      'registration_number': registrationNumber,
      'tax_number': taxId,
      // 'business_type': businessType,
      'currency_symbol': currency,
      'business_hours': businessHours.toJsonString(),
      'is_cod_active': acceptsCash,
      // 'accepts_card': acceptsCard,
      'is_wallet_active': acceptsDigitalWallet,
      'is_digital_active': acceptsOnlinePayment,
      if (deliveryFeePerKm != null) 'delivery_fee_per_km': deliveryFeePerKm,
      if (minDeliveryFee != null) 'min_delivery_fee': minDeliveryFee,
      if (freeDeliveryAbove != null) 'free_delivery_above': freeDeliveryAbove,
      if (maxDeliveryRadius != null) 'max_delivery_radius': maxDeliveryRadius,
      'store_location': storeLocation,
      'is_store_open': isStoreOpen,
      'is_maintenance_mode_on': isMaintenanceModeOn ,
    };
  }

  BusinessSetupModel copyWith({
    String? id,
    String? businessName,
    String? registrationNumber,
    String? taxId,
    String? businessType,
    String? currency,
    WeeklyBusinessHours? businessHours,
    bool? acceptsCash,
    bool? acceptsCard,
    bool? acceptsDigitalWallet,
    bool? acceptsOnlinePayment,
    double? deliveryFeePerKm,
    double? minDeliveryFee,
    double? freeDeliveryAbove,
    double? maxDeliveryRadius,
    String? storeLocation,
    bool? isStoreOpen,
    bool? isMaintenanceModeOn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessSetupModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      taxId: taxId ?? this.taxId,
      // businessType: businessType ?? this.businessType,
      currency: currency ?? this.currency,
      businessHours: businessHours ?? this.businessHours,
      acceptsCash: acceptsCash ?? this.acceptsCash,
      // acceptsCard: acceptsCard ?? this.acceptsCard,
      acceptsDigitalWallet: acceptsDigitalWallet ?? this.acceptsDigitalWallet,
      acceptsOnlinePayment: acceptsOnlinePayment ?? this.acceptsOnlinePayment,
      deliveryFeePerKm: deliveryFeePerKm ?? this.deliveryFeePerKm,
      minDeliveryFee: minDeliveryFee ?? this.minDeliveryFee,
      freeDeliveryAbove: freeDeliveryAbove ?? this.freeDeliveryAbove,
      maxDeliveryRadius: maxDeliveryRadius ?? this.maxDeliveryRadius,
      storeLocation: storeLocation ?? this.storeLocation,
      isStoreOpen: isStoreOpen ?? this.isStoreOpen,
      isMaintenanceModeOn: isMaintenanceModeOn ?? this.isMaintenanceModeOn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
