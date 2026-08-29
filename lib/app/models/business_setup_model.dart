import 'package:appwrite_user_app/app/models/business_hours_model.dart';
import 'package:get/get.dart';

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

  /// Estimated ASAP delivery window in minutes (food module only). Powers the
  /// "ASAP (30-45 mins)" estimate at checkout; null when the store leaves it
  /// unset (e.g. ecommerce). See [asapEstimateLabel].
  final int? minDeliveryTime;
  final int? maxDeliveryTime;
  /// Master switch for the loyalty programme, owned by the store admin. When
  /// off the app must not advertise or promise points. Defaults to true so a
  /// store running the programme before this flag existed keeps working.
  final bool isLoyaltyPointEnabled;
  final double loyaltyPointEarningRate;
  final double loyaltyPointWalletRate;

  /// Store-wide VAT/tax rate in percent (e.g. 10 = 10%), applied to order
  /// subtotals at checkout. 0 disables tax.
  final double vatPercentage;
  final String storeLocation;

  /// Storefront banner the store uploads in the admin panel's module setup.
  ///
  /// Empty until one is set, which is why every reader falls back to the
  /// bundled asset rather than rendering a blank slot.
  final String otherBanner;

  bool get hasOtherBanner => otherBanner.trim().isNotEmpty;
  final double? storeLatitude;
  final double? storeLongitude;
  /// Require the deliveryman to enter the order's 6-digit verification code
  /// before marking it delivered. Configured in the store admin panel.
  final bool isOrderVerificationActive;
  final bool isStoreOpen;
  final bool isMaintenanceModeOn;
  // Module enablement — which storefront(s) this store runs.
  final bool isFoodModuleEnabled;
  final bool isEcommerceModuleEnabled;

  /// Ecommerce orders are fulfilled by courier against a chosen shipping
  /// method (tracking number, courier name) rather than by a deliveryman.
  final bool isShippingMethodEnabled;

  /// The store delivers orders itself, without the deliveryman app.
  final bool isSelfDelivery;
  final String defaultModule; // 'food' | 'ecommerce'
  // Force app update — the store admin flips these to require customers to
  // upgrade before continuing (see [requiresForceUpdate]).
  final bool isForceUpdateActive;
  final String? appMinVersion;
  final String? androidStoreUrl;
  final String? iosStoreUrl;
  // Store timezone — the source of truth for all order/schedule times. Times
  // are computed and displayed in this zone, never the customer's device zone.
  final String timezone; // IANA label, e.g. 'Asia/Dhaka' (display only)
  final int timezoneOffsetMinutes; // minutes east of UTC, e.g. 360 = +06:00
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? copyrightText;
  final String? cookiesText;

  /// The store's UTC offset as a [Duration].
  Duration get timezoneOffset => Duration(minutes: timezoneOffsetMinutes);

  /// Localized "ASAP (30-45 mins)" estimate for immediate ("now") orders,
  /// derived from the store's configured [minDeliveryTime]/[maxDeliveryTime].
  /// Falls back to 30-45 minutes when the store hasn't set a window.
  String get asapEstimateLabel {
    final min = minDeliveryTime ?? 30;
    final max = maxDeliveryTime ?? 45;
    return 'asap_estimate'.trParams({'min': '$min', 'max': '$max'});
  }

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
    this.minDeliveryTime,
    this.maxDeliveryTime,
    this.isLoyaltyPointEnabled = true,
    this.loyaltyPointEarningRate = 1.0,
    this.loyaltyPointWalletRate = 0.10,
    this.vatPercentage = 0.0,
    required this.storeLocation,
    this.otherBanner = '',
    this.storeLatitude,
    this.storeLongitude,
    this.isOrderVerificationActive = false,
    required this.isStoreOpen,
    required this.isMaintenanceModeOn,
    this.isFoodModuleEnabled = true,
    this.isEcommerceModuleEnabled = false,
    this.isShippingMethodEnabled = false,
    this.isSelfDelivery = false,
    this.defaultModule = 'food',
    this.isForceUpdateActive = false,
    this.appMinVersion,
    this.androidStoreUrl,
    this.iosStoreUrl,
    this.timezone = 'Asia/Dhaka',
    this.timezoneOffsetMinutes = 360,
    this.createdAt,
    this.updatedAt,
    this.copyrightText,
    this.cookiesText,
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
      minDeliveryTime: (json['min_delivery_time'] as num?)?.toInt(),
      maxDeliveryTime: (json['max_delivery_time'] as num?)?.toInt(),
      isLoyaltyPointEnabled: json['is_loyalty_point_enabled'] ?? true,
      loyaltyPointEarningRate: (json['loyalty_point_earning_rate'] ?? 1.0)
          .toDouble(),
      loyaltyPointWalletRate: (json['loyalty_point_wallet_rate'] ?? 0.10)
          .toDouble(),
      vatPercentage: (json['vat_percentage'] ?? 0.0).toDouble(),
      storeLocation: json['store_location'] ?? '',
      otherBanner: json['other_banner'] ?? '',
      storeLatitude: json['store_latitude']?.toDouble(),
      storeLongitude: json['store_longitude']?.toDouble(),
      isOrderVerificationActive: json['is_order_verification_active'] ?? false,
      isStoreOpen: json['is_store_open'] ?? true,
      isMaintenanceModeOn: json['is_maintenance_mode_on'] ?? false,
      isFoodModuleEnabled: json['is_food_module_enabled'] ?? true,
      isEcommerceModuleEnabled: json['is_ecommerce_module_enabled'] ?? false,
      isShippingMethodEnabled: json['is_shipping_method_enabled'] ?? false,
      isSelfDelivery: json['is_self_delivery'] ?? false,
      defaultModule: json['default_module'] ?? 'food',
      isForceUpdateActive: json['is_force_update_active'] ?? false,
      appMinVersion: json['app_min_version'],
      androidStoreUrl: json['android_store_url'],
      iosStoreUrl: json['ios_store_url'],
      timezone: json['timezone'] ?? 'Asia/Dhaka',
      timezoneOffsetMinutes: (json['timezone_offset'] as num?)?.toInt() ?? 360,
      createdAt: json['\$createdAt'] != null
          ? DateTime.parse(json['\$createdAt'])
          : null,
      updatedAt: json['\$updatedAt'] != null
          ? DateTime.parse(json['\$updatedAt'])
          : null,
      copyrightText: json['copyright_text'] as String?,
      cookiesText: json['cookies_text'] as String?,
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
      if (minDeliveryTime != null) 'min_delivery_time': minDeliveryTime,
      if (maxDeliveryTime != null) 'max_delivery_time': maxDeliveryTime,
      'is_loyalty_point_enabled': isLoyaltyPointEnabled,
      'loyalty_point_earning_rate': loyaltyPointEarningRate,
      'loyalty_point_wallet_rate': loyaltyPointWalletRate,
      'vat_percentage': vatPercentage,
      'store_location': storeLocation,
      'other_banner': otherBanner,
      if (storeLatitude != null) 'store_latitude': storeLatitude,
      if (storeLongitude != null) 'store_longitude': storeLongitude,
      'is_order_verification_active': isOrderVerificationActive,
      'is_store_open': isStoreOpen,
      'is_maintenance_mode_on': isMaintenanceModeOn,
      'is_food_module_enabled': isFoodModuleEnabled,
      'is_ecommerce_module_enabled': isEcommerceModuleEnabled,
      'is_shipping_method_enabled': isShippingMethodEnabled,
      'is_self_delivery': isSelfDelivery,
      'default_module': defaultModule,
      'is_force_update_active': isForceUpdateActive,
      if (appMinVersion != null) 'app_min_version': appMinVersion,
      if (androidStoreUrl != null) 'android_store_url': androidStoreUrl,
      if (iosStoreUrl != null) 'ios_store_url': iosStoreUrl,
      'timezone': timezone,
      'timezone_offset': timezoneOffsetMinutes,
      if (copyrightText != null) 'copyright_text': copyrightText,
      if (cookiesText != null) 'cookies_text': cookiesText,
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
    int? minDeliveryTime,
    int? maxDeliveryTime,
    bool? isLoyaltyPointEnabled,
    double? loyaltyPointEarningRate,
    double? loyaltyPointWalletRate,
    double? vatPercentage,
    String? storeLocation,
    String? otherBanner,
    double? storeLatitude,
    double? storeLongitude,
    bool? isOrderVerificationActive,
    bool? isStoreOpen,
    bool? isMaintenanceModeOn,
    bool? isFoodModuleEnabled,
    bool? isEcommerceModuleEnabled,
    bool? isShippingMethodEnabled,
    bool? isSelfDelivery,
    String? defaultModule,
    bool? isForceUpdateActive,
    String? appMinVersion,
    String? androidStoreUrl,
    String? iosStoreUrl,
    String? timezone,
    int? timezoneOffsetMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? copyrightText,
    String? cookiesText,
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
      minDeliveryTime: minDeliveryTime ?? this.minDeliveryTime,
      maxDeliveryTime: maxDeliveryTime ?? this.maxDeliveryTime,
      isLoyaltyPointEnabled:
          isLoyaltyPointEnabled ?? this.isLoyaltyPointEnabled,
      loyaltyPointEarningRate:
          loyaltyPointEarningRate ?? this.loyaltyPointEarningRate,
      loyaltyPointWalletRate:
          loyaltyPointWalletRate ?? this.loyaltyPointWalletRate,
      vatPercentage: vatPercentage ?? this.vatPercentage,
      storeLocation: storeLocation ?? this.storeLocation,
      otherBanner: otherBanner ?? this.otherBanner,
      storeLatitude: storeLatitude ?? this.storeLatitude,
      storeLongitude: storeLongitude ?? this.storeLongitude,
      isOrderVerificationActive:
          isOrderVerificationActive ?? this.isOrderVerificationActive,
      isStoreOpen: isStoreOpen ?? this.isStoreOpen,
      isMaintenanceModeOn: isMaintenanceModeOn ?? this.isMaintenanceModeOn,
      isFoodModuleEnabled: isFoodModuleEnabled ?? this.isFoodModuleEnabled,
      isEcommerceModuleEnabled:
          isEcommerceModuleEnabled ?? this.isEcommerceModuleEnabled,
      isShippingMethodEnabled:
          isShippingMethodEnabled ?? this.isShippingMethodEnabled,
      isSelfDelivery: isSelfDelivery ?? this.isSelfDelivery,
      defaultModule: defaultModule ?? this.defaultModule,
      isForceUpdateActive: isForceUpdateActive ?? this.isForceUpdateActive,
      appMinVersion: appMinVersion ?? this.appMinVersion,
      androidStoreUrl: androidStoreUrl ?? this.androidStoreUrl,
      iosStoreUrl: iosStoreUrl ?? this.iosStoreUrl,
      timezone: timezone ?? this.timezone,
      timezoneOffsetMinutes:
          timezoneOffsetMinutes ?? this.timezoneOffsetMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      copyrightText: copyrightText ?? this.copyrightText,
      cookiesText: cookiesText ?? this.cookiesText,
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

  /// Whether the running build ([currentVersion], e.g. "1.0.0") must be
  /// upgraded before the app can be used. True only when the admin has turned
  /// on [isForceUpdateActive] AND a valid [appMinVersion] is set that is higher
  /// than [currentVersion]. Fails open (returns false) on missing/unparseable
  /// config so a bad setting can never lock every customer out.
  bool requiresForceUpdate(String currentVersion) {
    if (!isForceUpdateActive) return false;
    final min = appMinVersion?.trim();
    if (min == null || min.isEmpty) return false;
    return _compareVersions(currentVersion, min) < 0;
  }

  /// Compares two dot-separated version strings numerically. Returns a negative
  /// number when [a] < [b], zero when equal, positive when [a] > [b]. Missing
  /// segments count as 0 ("1.2" == "1.2.0"); any non-numeric segment is treated
  /// as 0 rather than throwing.
  static int _compareVersions(String a, String b) {
    final aParts = a.split('.');
    final bParts = b.split('.');
    final length = aParts.length > bParts.length ? aParts.length : bParts.length;
    for (int i = 0; i < length; i++) {
      final aVal = i < aParts.length ? (int.tryParse(aParts[i].trim()) ?? 0) : 0;
      final bVal = i < bParts.length ? (int.tryParse(bParts[i].trim()) ?? 0) : 0;
      if (aVal != bVal) return aVal - bVal;
    }
    return 0;
  }
}
