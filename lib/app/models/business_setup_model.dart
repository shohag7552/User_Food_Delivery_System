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
  final double loyaltyPointEarningRate;
  final double loyaltyPointWalletRate;

  /// Store-wide VAT/tax rate in percent (e.g. 10 = 10%), applied to order
  /// subtotals at checkout. 0 disables tax.
  final double vatPercentage;
  final String storeLocation;
  final double? storeLatitude;
  final double? storeLongitude;
  final bool isStoreOpen;
  final bool isMaintenanceModeOn;
  // Module enablement — which storefront(s) this store runs.
  final bool isFoodModuleEnabled;
  final bool isEcommerceModuleEnabled;
  final String defaultModule; // 'food' | 'ecommerce'
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
    this.loyaltyPointEarningRate = 1.0,
    this.loyaltyPointWalletRate = 0.10,
    this.vatPercentage = 0.0,
    required this.storeLocation,
    this.storeLatitude,
    this.storeLongitude,
    required this.isStoreOpen,
    required this.isMaintenanceModeOn,
    this.isFoodModuleEnabled = true,
    this.isEcommerceModuleEnabled = false,
    this.defaultModule = 'food',
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
      loyaltyPointEarningRate: (json['loyalty_point_earning_rate'] ?? 1.0)
          .toDouble(),
      loyaltyPointWalletRate: (json['loyalty_point_wallet_rate'] ?? 0.10)
          .toDouble(),
      vatPercentage: (json['vat_percentage'] ?? 0.0).toDouble(),
      storeLocation: json['store_location'] ?? '',
      storeLatitude: json['store_latitude']?.toDouble(),
      storeLongitude: json['store_longitude']?.toDouble(),
      isStoreOpen: json['is_store_open'] ?? true,
      isMaintenanceModeOn: json['is_maintenance_mode_on'] ?? false,
      isFoodModuleEnabled: json['is_food_module_enabled'] ?? true,
      isEcommerceModuleEnabled: json['is_ecommerce_module_enabled'] ?? false,
      defaultModule: json['default_module'] ?? 'food',
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
      'loyalty_point_earning_rate': loyaltyPointEarningRate,
      'loyalty_point_wallet_rate': loyaltyPointWalletRate,
      'vat_percentage': vatPercentage,
      'store_location': storeLocation,
      if (storeLatitude != null) 'store_latitude': storeLatitude,
      if (storeLongitude != null) 'store_longitude': storeLongitude,
      'is_store_open': isStoreOpen,
      'is_maintenance_mode_on': isMaintenanceModeOn,
      'is_food_module_enabled': isFoodModuleEnabled,
      'is_ecommerce_module_enabled': isEcommerceModuleEnabled,
      'default_module': defaultModule,
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
    double? loyaltyPointEarningRate,
    double? loyaltyPointWalletRate,
    double? vatPercentage,
    String? storeLocation,
    double? storeLatitude,
    double? storeLongitude,
    bool? isStoreOpen,
    bool? isMaintenanceModeOn,
    bool? isFoodModuleEnabled,
    bool? isEcommerceModuleEnabled,
    String? defaultModule,
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
      loyaltyPointEarningRate:
          loyaltyPointEarningRate ?? this.loyaltyPointEarningRate,
      loyaltyPointWalletRate:
          loyaltyPointWalletRate ?? this.loyaltyPointWalletRate,
      vatPercentage: vatPercentage ?? this.vatPercentage,
      storeLocation: storeLocation ?? this.storeLocation,
      storeLatitude: storeLatitude ?? this.storeLatitude,
      storeLongitude: storeLongitude ?? this.storeLongitude,
      isStoreOpen: isStoreOpen ?? this.isStoreOpen,
      isMaintenanceModeOn: isMaintenanceModeOn ?? this.isMaintenanceModeOn,
      isFoodModuleEnabled: isFoodModuleEnabled ?? this.isFoodModuleEnabled,
      isEcommerceModuleEnabled:
          isEcommerceModuleEnabled ?? this.isEcommerceModuleEnabled,
      defaultModule: defaultModule ?? this.defaultModule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Whether [now] falls inside any of today's open time slots (ignores the
  /// master [isStoreOpen] switch — that's combined in [isOpenNow]).
  bool isWithinBusinessHours(DateTime now) {
    final day = businessHours.getDay(now.weekday % 7);
    if (!day.isOpen) return false;
    for (final slot in day.timeSlots) {
      final open = DateTime(now.year, now.month, now.day,
          slot.openTime.hour, slot.openTime.minute);
      final close = DateTime(now.year, now.month, now.day,
          slot.closeTime.hour, slot.closeTime.minute);
      if (!now.isBefore(open) && now.isBefore(close)) return true;
    }
    return false;
  }

  /// The store accepts immediate ("now") orders only when the master switch
  /// is on AND the current time is within business hours.
  bool isOpenNow(DateTime now) => isStoreOpen && isWithinBusinessHours(now);

  /// The next [DateTime] the store opens, scanning up to a week from [now].
  /// Returns null if no open slot is configured.
  DateTime? nextOpening(DateTime now) {
    final base = DateTime(now.year, now.month, now.day);
    for (int i = 0; i < 8; i++) {
      final day = base.add(Duration(days: i));
      final sched = businessHours.getDay(day.weekday % 7);
      if (!sched.isOpen) continue;
      for (final slot in sched.timeSlots) {
        final openDt = DateTime(day.year, day.month, day.day,
            slot.openTime.hour, slot.openTime.minute);
        if (openDt.isAfter(now)) return openDt;
      }
    }
    return null;
  }
}
