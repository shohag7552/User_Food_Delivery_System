import 'dart:async' show unawaited;

import 'package:appwrite_user_app/app/appwrite/payment_service.dart';
import 'package:appwrite_user_app/app/common/widgets/auth_gate.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/controllers/address_controller.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/controllers/flash_sale_controller.dart';
import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/controllers/order_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/controllers/shipping_controller.dart';
import 'package:appwrite_user_app/app/models/shipping_method_model.dart';
import 'package:appwrite_user_app/app/controllers/profile_controller.dart';
import 'package:appwrite_user_app/app/controllers/settings_controller.dart';
import 'package:appwrite_user_app/app/enums/payment_method_enum.dart';
import 'package:appwrite_user_app/app/helper/currency_helper.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/models/address_model.dart';
import 'package:appwrite_user_app/app/models/business_hours_model.dart';
import 'package:appwrite_user_app/app/modules/checkout/widgets/address_selection_bottomsheet.dart';
import 'package:appwrite_user_app/app/modules/checkout/widgets/edit_address_info_bottomsheet.dart';
import 'package:appwrite_user_app/app/modules/checkout/widgets/delivery_schedule_bottomsheet.dart';
import 'package:appwrite_user_app/app/modules/coupons/widgets/coupon_selection_bottomsheet.dart';
import 'package:appwrite_user_app/app/modules/payment/payment_webview_screen.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Web shell: content cap + scaffold key for the top-nav profile drawer.
  static const double _maxContentWidth = 1160;
  final GlobalKey<ScaffoldState> _webScaffoldKey = GlobalKey<ScaffoldState>();

  final _instructionsController = TextEditingController();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cod;
  PaymentGateway _selectedGateway = PaymentGateway.sslcommerz;
  bool _isPriceExpanded = false;
  bool _isAddressExpanded = false;
  AddressModel? _selectedAddress;
  
  // Delivery schedule
  String? _scheduleDisplayText = 'ASAP (30-45 mins)';
  Map<String, dynamic>? scheduleData;

  String _deliveryType = 'now'; // 'now' or 'schedule'
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  // Ecommerce shipping
  ShippingMethodModel? _selectedShipping;

  bool get _isEcommerce => Get.find<ModuleController>().isEcommerce;

  @override
  void initState() {
    super.initState();
    // Auto-select default address
    final addressController = Get.find<AddressController>();
    if (addressController.defaultAddress != null) {
      _selectedAddress = addressController.defaultAddress;
    }

    // Load shipping methods for the ecommerce checkout.
    if (_isEcommerce) {
      final shippingController = Get.find<ShippingController>();
      shippingController.getShippingMethods().then((_) {
        if (!mounted) return;
        if (_selectedShipping == null &&
            shippingController.methods.isNotEmpty) {
          setState(() => _selectedShipping = shippingController.methods.first);
        }
      });
    }
  }

  void _syncSelectedAddress(AddressController addressController) {
    // Re-bind to the freshest instance by id so inline edits reflect at once.
    if (_selectedAddress != null) {
      for (final address in addressController.addresses) {
        if (address.id == _selectedAddress!.id) {
          _selectedAddress = address;
          return;
        }
      }
    }
    _selectedAddress = addressController.defaultAddress;
  }

  Future<void> _openEditAddressInfo() async {
    if (_selectedAddress == null) return;
    await EditAddressInfoBottomSheet.show(context, _selectedAddress!);
    // The GetBuilder rebuild re-syncs _selectedAddress; refresh the view.
    if (mounted) setState(() {});
  }

  Future<void> _openLocationEditor() async {
    final addressController = Get.find<AddressController>();
    final base = _selectedAddress;
    if (base == null) {
      await _openMapAddressPicker();
      return;
    }

    final initial = (base.latitude != null && base.longitude != null)
        ? LatLng(base.latitude!, base.longitude!)
        : const LatLng(23.8103, 90.4125); // Dhaka fallback

    final picked = await context.pushNamed<LatLng?>(
      RouteNames.mapPicker,
      extra: initial,
    );
    if (picked == null || !mounted) return;

    final updated = await _composeAddressFromLocation(base, picked);
    final ok = await addressController.saveAddressChanges(base.id, updated);
    if (!mounted) return;
    if (ok) {
      setState(() => _syncSelectedAddress(addressController));
      customToster('location_updated'.tr);
    } else {
      customToster('failed_to_update_address'.tr, isSuccess: false);
    }
  }

  /// Reverse-geocodes the picked point and merges it onto the address,
  /// keeping name/phone/default while refreshing street, city and postal.
  Future<AddressModel> _composeAddressFromLocation(
    AddressModel base,
    LatLng pos,
  ) async {
    String line1 = base.addressLine1;
    String city = base.city;
    String postal = base.postalCode;

    try {
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final street = [p.street, p.subLocality]
            .whereType<String>()
            .where((e) => e.trim().isNotEmpty && !e.contains('+'))
            .join(', ');
        if (street.isNotEmpty) line1 = street;
        final resolvedCity =
            p.locality ?? p.subAdministrativeArea ?? p.administrativeArea ?? '';
        if (resolvedCity.isNotEmpty) city = resolvedCity;
        if ((p.postalCode ?? '').isNotEmpty) postal = p.postalCode!;
      }
    } catch (_) {
      // Keep existing textual address if geocoding fails.
    }

    return base.copyWith(
      addressLine1: line1,
      city: city,
      postalCode: postal,
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
  }

  Future<void> _openAddressSelector() async {
    final result = await AddressSelectionBottomSheet.show(
      context,
      initialAddress: _selectedAddress,
    );

    if (result != null) {
      setState(() {
        _selectedAddress = result;
      });
      Get.find<AddressController>().selectAddress(result);
    }
  }

  Future<void> _openMapAddressPicker() async {
    final addressController = Get.find<AddressController>();
    final previousIds = addressController.addresses.map((address) => address.id).toSet();

    await context.pushNamed(RouteNames.addEditAddress);
    await addressController.fetchAddresses();

    AddressModel? nextSelection;

    for (final address in addressController.addresses) {
      if (!previousIds.contains(address.id)) {
        nextSelection = address;
        break;
      }
    }

    nextSelection ??= addressController.defaultAddress ?? _selectedAddress;

    if (nextSelection != null && mounted) {
      setState(() {
        _selectedAddress = nextSelection;
      });
      addressController.selectAddress(nextSelection);
    }
  }

  Future<void> _openDeliverySchedulePicker() async {
    final result = await DeliveryScheduleBottomSheet.show(
      context,
      initialType: _deliveryType,
      initialDate: _selectedDate,
      initialTimeSlot: _selectedTimeSlot,
    );

    if (result != null) {
      setState(() {
        _deliveryType = result['type'];
        _selectedDate = result['date'];
        _selectedTimeSlot = result['timeSlot'];
        _scheduleDisplayText = result['displayText'];
      });
    }
  }

  double? _calculateDistanceKm(SettingsController settingsController) {
    final businessSetup = settingsController.businessSetup;
    final address = _selectedAddress;

    if (businessSetup?.storeLatitude == null ||
        businessSetup?.storeLongitude == null ||
        address?.latitude == null ||
        address?.longitude == null) {
      return null;
    }

    return const Distance().as(
      LengthUnit.Kilometer,
      LatLng(businessSetup!.storeLatitude!, businessSetup.storeLongitude!),
      LatLng(address!.latitude!, address.longitude!),
    );
  }

  double _calculateDeliveryFee(
    CartController cartController,
    SettingsController settingsController,
  ) {
    // Ecommerce: fee comes from the selected shipping method.
    if (_isEcommerce) {
      return _selectedShipping?.feeFor(cartController.total) ?? 0;
    }

    final businessSetup = settingsController.businessSetup;
    final orderAmount = cartController.total;
    final freeDeliveryAbove = businessSetup?.freeDeliveryAbove;

    if (freeDeliveryAbove != null && orderAmount >= freeDeliveryAbove) {
      return 0;
    }

    final distanceKm = _calculateDistanceKm(settingsController);
    final minFee = businessSetup?.minDeliveryFee ?? 0;
    final feePerKm = businessSetup?.deliveryFeePerKm ?? 0;

    if (distanceKm == null) {
      return minFee;
    }

    final calculatedFee = distanceKm * feePerKm;
    return calculatedFee < minFee ? minFee : calculatedFee;
  }

  bool _isOutsideDeliveryRadius(SettingsController settingsController) {
    final maxRadius = settingsController.businessSetup?.maxDeliveryRadius;
    final distanceKm = _calculateDistanceKm(settingsController);

    if (maxRadius == null || distanceKm == null) {
      return false;
    }

    return distanceKm > maxRadius;
  }

  /// Current store availability for immediate ("now") orders, plus a
  /// human-readable next-opening label when closed.
  ({bool isOpenNow, String? nextOpenLabel}) _storeStatus() {
    final businessSetup = Get.find<SettingsController>().businessSetup;
    if (businessSetup == null) {
      return (isOpenNow: true, nextOpenLabel: null);
    }
    final now = DateTime.now();
    if (businessSetup.isOpenNow(now)) {
      return (isOpenNow: true, nextOpenLabel: null);
    }
    final next = businessSetup.nextOpening(now);
    return (
      isOpenNow: false,
      nextOpenLabel: next == null ? null : _formatNextOpen(now, next),
    );
  }

  String _formatNextOpen(DateTime now, DateTime next) {
    final today = DateTime(now.year, now.month, now.day);
    final nextDay = DateTime(next.year, next.month, next.day);
    final diffDays = nextDay.difference(today).inDays;
    final dayLabel = diffDays == 0
        ? 'today'.tr
        : diffDays == 1
            ? 'tomorrow'.tr
            : WeeklyBusinessHours.dayNames[next.weekday % 7];
    final time = TimeOfDay.fromDateTime(next).format(context);
    return '${'opens'.tr} $dayLabel ${'at'.tr} $time';
  }
  
  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // Desktop web gets the shared top-nav shell + a two-column layout;
    // mobile/tablet keep the original stacked flow with the bottom summary.
    final useWebShell = WebTopNav.isEnabled(context);

    return Scaffold(
      key: _webScaffoldKey,
      backgroundColor: ColorResource.scaffoldBackground,
      endDrawer: useWebShell ? const WebProfileDrawer() : null,
      appBar: useWebShell
          ? WebTopNav(
              selectedIndex: null,
              onDestinationSelected: (index) {
                DashboardTabBus.open(index);
                context.goNamed(RouteNames.dashboard);
              },
              onMenuTap: () => _webScaffoldKey.currentState?.openEndDrawer(),
            )
          : CustomAppbar(title: 'checkout'.tr),
      body: AuthGate(
        child: GetBuilder<CartController>(
        builder: (controller) {
          if (controller.cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: ColorResource.textLight),
                  const SizedBox(height: 16),
                  Text(
                    'your_cart_is_empty'.tr,
                    style: poppinsBold.copyWith(fontSize: Constants.fontSizeLarge),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: Text('go_back'.tr),
                  ),
                ],
              ),
            );
          }

          if (useWebShell) return _buildWebBody(controller);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDeliveryAddress(),
                      const SizedBox(height: 20),
                      _isEcommerce
                          ? _buildShippingSection()
                          : _buildDeliverySchedule(),
                      const SizedBox(height: 20),
                      _buildCouponSection(controller),
                      const SizedBox(height: 20),
                      _buildPaymentMethod(),
                      const SizedBox(height: 20),
                      _buildDeliveryInstructions(),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              _buildBottomSummary(controller),
            ],
          );
        },
        ),
      ),
    );
  }

  // ── Web/desktop: centered two-column checkout ──
  //   Left:  address · shipping/schedule · payment · instructions
  //   Right: order summary rail — coupon, always-open breakdown, place order
  Widget _buildWebBody(CartController controller) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'checkout'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeOverLarge,
                    color: ColorResource.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDeliveryAddress(),
                          const SizedBox(height: 20),
                          _isEcommerce
                              ? _buildShippingSection()
                              : _buildDeliverySchedule(),
                          const SizedBox(height: 20),
                          _buildPaymentMethod(),
                          const SizedBox(height: 20),
                          _buildDeliveryInstructions(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 380,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCouponSection(controller),
                          const SizedBox(height: 20),
                          _buildWebSummaryCard(controller),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Web order-summary rail: the full price breakdown (always expanded — no
  /// collapse toggle on desktop) plus the place-order button.
  Widget _buildWebSummaryCard(CartController controller) {
    final settingsController = Get.find<SettingsController>();
    final deliveryFee = _calculateDeliveryFee(controller, settingsController);
    final isOutsideRadius = _isOutsideDeliveryRadius(settingsController);
    final storeStatus = _storeStatus();
    final blockForClosed =
        !_isEcommerce && _deliveryType == 'now' && !storeStatus.isOpenNow;
    final total = controller.total + deliveryFee;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'order_summary'.tr,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: ColorResource.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            '${'cart_items_count'.tr} (${controller.itemCount})',
            controller.originalSubtotal,
          ),
          if (controller.itemDiscountTotal > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              'item_discount'.tr,
              -controller.itemDiscountTotal,
              isDiscount: true,
            ),
          ],
          const SizedBox(height: 8),
          _buildSummaryRow(
            _isEcommerce ? 'shipping'.tr : 'delivery_fee'.tr,
            deliveryFee,
          ),
          if (isOutsideRadius) ...[
            const SizedBox(height: 8),
            Text(
              'Selected address is outside the delivery radius.',
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: Colors.red,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _buildSummaryRow('tax_10'.tr, controller.tax),
          if (controller.appliedCoupon != null) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              'coupon_discount'.tr,
              -controller.discountAmount,
              isDiscount: true,
            ),
          ],
          const Divider(height: 24),
          _buildSummaryRow('total'.tr, total, isTotal: true),
          const SizedBox(height: 16),
          _buildPlaceOrderButton(
            controller,
            deliveryFee: deliveryFee,
            isOutsideRadius: isOutsideRadius,
            blockForClosed: blockForClosed,
            total: total,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    return GetBuilder<AddressController>(
      builder: (addressController) {
        _syncSelectedAddress(addressController);
        final settingsController = Get.find<SettingsController>();
        final distanceKm = _calculateDistanceKm(settingsController);
        final isOutsideRadius = _isOutsideDeliveryRadius(settingsController);
        final address = _selectedAddress;

        if (address == null) {
          return _buildNoAddressCard();
        }

        final hasLatLng = address.latitude != null && address.longitude != null;

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: ColorResource.cardBackground,
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
            boxShadow: ColorResource.customShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map preview with marker
              _buildMapPreview(address, hasLatLng),

              // Header — tap to expand/collapse
              InkWell(
                onTap: () => setState(
                  () => _isAddressExpanded = !_isAddressExpanded,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 22,
                        color: ColorResource.primaryDark,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${'deliver_to'.tr} • ${address.name}',
                              style: poppinsBold.copyWith(
                                fontSize: Constants.fontSizeDefault,
                                color: ColorResource.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              address.shortAddress,
                              style: poppinsRegular.copyWith(
                                fontSize: Constants.fontSizeSmall,
                                color: ColorResource.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 250),
                        turns: _isAddressExpanded ? 0.5 : 0,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: ColorResource.textSecondary,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Expandable details
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _isAddressExpanded
                    ? _buildAddressDetails(address, distanceKm, isOutsideRadius)
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapPreview(AddressModel address, bool hasLatLng) {
    if (!hasLatLng) {
      return GestureDetector(
        onTap: _openLocationEditor,
        child: Container(
          height: 130,
          width: double.infinity,
          color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 30, color: ColorResource.textLight),
              const SizedBox(height: 8),
              Text(
                'set_location_on_map'.tr,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: ColorResource.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final point = LatLng(address.latitude!, address.longitude!);

    return GestureDetector(
      onTap: _openLocationEditor,
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: Stack(
          children: [
            FlutterMap(
              key: ValueKey(
                '${address.id}_${address.latitude}_${address.longitude}',
              ),
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: Constants.streetMapTheme,
                  userAgentPackageName: Constants.packageName,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.location_on,
                        color: ColorResource.primaryDark,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (address.isDefault)
              Positioned(top: 8, left: 8, child: _buildDefaultChip()),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ColorResource.cardBackground.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_location_alt_outlined,
                      size: 14,
                      color: ColorResource.primaryDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'set_location_on_map'.tr,
                      style: poppinsMedium.copyWith(
                        fontSize: Constants.fontSizeExtraSmall,
                        color: ColorResource.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ColorResource.primaryDark,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'default'.tr,
        style: poppinsBold.copyWith(
          fontSize: Constants.fontSizeExtraSmall,
          color: ColorResource.textWhite,
        ),
      ),
    );
  }

  Widget _buildAddressDetails(
    AddressModel address,
    double? distanceKm,
    bool isOutsideRadius,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: ColorResource.textLight.withValues(alpha: 0.2)),
          _buildDetailRow('recipient'.tr, address.name),
          _buildDetailRow('phone'.tr, address.phone),
          _buildDetailRow('address'.tr, address.fullAddress),
          if (distanceKm != null)
            _buildDetailRow(
              'distance'.tr,
              isOutsideRadius
                  ? '${distanceKm.toStringAsFixed(2)} km • ${'outside_delivery_radius'.tr}'
                  : '${distanceKm.toStringAsFixed(2)} km',
              valueColor: isOutsideRadius ? Colors.red : null,
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openEditAddressInfo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorResource.primaryDark,
                    side: BorderSide(
                      color: ColorResource.primaryDark.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    'edit_details'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.primaryDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openAddressSelector,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: ColorResource.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: Text(
                    'change_address'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: ColorResource.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: valueColor ?? ColorResource.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ColorResource.primaryDark.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_location_alt_outlined,
              color: ColorResource.primaryDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'add_delivery_address'.tr,
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _openMapAddressPicker,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: ColorResource.primaryDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'add'.tr,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingSection() {
    return GetBuilder<ShippingController>(
      builder: (shippingController) {
        final methods = shippingController.methods;
        final cartTotal = Get.find<CartController>().total;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ColorResource.cardBackground,
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
            boxShadow: ColorResource.customShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    color: ColorResource.primaryDark,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'shipping_method'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeLarge,
                      color: ColorResource.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (shippingController.isLoading && methods.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (methods.isEmpty)
                Text(
                  'no_shipping_methods'.tr,
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: ColorResource.textSecondary,
                  ),
                )
              else
                ...methods.map((m) => _buildShippingTile(m, cartTotal)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShippingTile(ShippingMethodModel method, double cartTotal) {
    final isSelected = _selectedShipping?.id == method.id;
    final fee = method.feeFor(cartTotal);
    return GestureDetector(
      onTap: () => setState(() => _selectedShipping = method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorResource.primaryDark.withValues(alpha: 0.06)
              : ColorResource.scaffoldBackground,
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
          border: Border.all(
            color: isSelected
                ? ColorResource.primaryDark
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected
                  ? ColorResource.primaryDark
                  : ColorResource.textLight,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.textPrimary,
                    ),
                  ),
                  if ((method.estimatedDays ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      method.estimatedDays!,
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: ColorResource.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              fee <= 0 ? 'free'.tr : CurrencyHelper.formatAmount(fee),
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: fee <= 0
                    ? ColorResource.success
                    : ColorResource.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection(CartController controller) {
    return controller.appliedCoupon != null
        ? _buildAppliedCoupon(controller)
        : _buildApplyCouponPrompt(controller);
  }

  Future<void> _openCouponSheet(CartController controller) async {
    final result = await CouponSelectionBottomSheet.show(context);
    if (result != null) {
      controller.applyCoupon(result);
    }
  }

  Widget _buildApplyCouponPrompt(CartController controller) {
    return GestureDetector(
      onTap: () => _openCouponSheet(controller),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ColorResource.cardBackground,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          boxShadow: ColorResource.customShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ColorResource.primaryDark.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_offer_rounded,
                size: 22,
                color: ColorResource.primaryDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'have_a_promo_code'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'apply_to_save'.tr,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => _openCouponSheet(controller),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: ColorResource.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'apply'.tr,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppliedCoupon(CartController controller) {
    final coupon = controller.appliedCoupon!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorResource.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        border: Border.all(
          color: ColorResource.success.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ColorResource.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_offer_rounded,
              size: 22,
              color: ColorResource.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ColorResource.cardBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: ColorResource.success.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        size: 13,
                        color: ColorResource.success,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        coupon.code,
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeSmall,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${'you_saved_amount'.tr} ${CurrencyHelper.formatAmount(controller.discountAmount)}',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: Colors.green.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => controller.removeCoupon(),
            style: TextButton.styleFrom(
              foregroundColor: ColorResource.error,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              'remove'.tr,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: ColorResource.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInstructions() {
    return Container(
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'delivery_instructions'.tr,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: ColorResource.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _instructionsController,
            decoration: InputDecoration(
              hintText: 'delivery_instructions_hint'.tr,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    final businessSetup = Get.find<SettingsController>().businessSetup;
    final codActive = businessSetup?.acceptsCash ?? true; // is_cod_active
    final onlineActive =
        businessSetup?.acceptsOnlinePayment ?? false; // is_digital_active
    final walletActive =
        businessSetup?.acceptsDigitalWallet ?? false; // is_wallet_active

    // Keep the chosen method within what's actually enabled.
    final available = <PaymentMethod>[
      if (codActive) PaymentMethod.cod,
      if (onlineActive) PaymentMethod.online,
      if (walletActive) PaymentMethod.wallet,
    ];
    if (available.isNotEmpty && !available.contains(_selectedPaymentMethod)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedPaymentMethod = available.first);
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'payment_method'.tr,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
                color: ColorResource.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          if (codActive) RadioListTile<PaymentMethod>(
            value: PaymentMethod.cod,
            groupValue: _selectedPaymentMethod,
            onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
            title: Row(
              children: [
                Icon(Icons.money, color: Colors.green),
                const SizedBox(width: 12),
                Text(
                  'cash_on_delivery'.tr,
                  style: poppinsMedium.copyWith(fontSize: Constants.fontSizeDefault),
                ),
              ],
            ),
            subtitle: Text(
              'pay_when_you_receive'.tr,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: ColorResource.textSecondary,
              ),
            ),
            activeColor: ColorResource.primaryDark,
          ),
          if (onlineActive) RadioListTile<PaymentMethod>(
            value: PaymentMethod.online,
            groupValue: _selectedPaymentMethod,
            onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
            title: Row(
              children: [
                Icon(Icons.credit_card, color: _selectedPaymentMethod == PaymentMethod.online ? ColorResource.primaryDark : ColorResource.textLight),
                const SizedBox(width: 12),
                Text(
                  'online_payment'.tr,
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: _selectedPaymentMethod == PaymentMethod.online ? ColorResource.textPrimary : ColorResource.textLight,
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'pay_securely_online'.tr,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: _selectedPaymentMethod == PaymentMethod.online ? ColorResource.textSecondary : ColorResource.textLight,
              ),
            ),
            activeColor: ColorResource.primaryDark,
          ),
          // Gateway selection chips — visible when online is selected
          if (onlineActive) AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _selectedPaymentMethod == PaymentMethod.online
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose gateway',
                          style: poppinsMedium.copyWith(
                            fontSize: Constants.fontSizeSmall,
                            color: ColorResource.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: PaymentGateway.values.map((gateway) {
                            final isSelected = _selectedGateway == gateway;
                            return ChoiceChip(
                              label: Text(gateway.displayName),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedGateway = gateway),
                              selectedColor: ColorResource.primaryDark.withValues(alpha: 0.15),
                              backgroundColor: ColorResource.scaffoldBackground,
                              labelStyle: poppinsMedium.copyWith(
                                fontSize: Constants.fontSizeSmall,
                                color: isSelected ? ColorResource.primaryDark : ColorResource.textSecondary,
                              ),
                              side: BorderSide(
                                color: isSelected ? ColorResource.primaryDark : Colors.grey.shade300,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedGateway.description,
                          style: poppinsRegular.copyWith(
                            fontSize: Constants.fontSizeExtraSmall,
                            color: ColorResource.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (walletActive) GetBuilder<ProfileController>(
            builder: (profileController) {
              final walletBalance = profileController.walletBalance;
              return RadioListTile<PaymentMethod>(
                value: PaymentMethod.wallet,
                groupValue: _selectedPaymentMethod,
                onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                title: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: _selectedPaymentMethod == PaymentMethod.wallet ? ColorResource.primaryDark : ColorResource.textLight),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'wallet'.tr,
                        style: poppinsMedium.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: _selectedPaymentMethod == PaymentMethod.wallet ? ColorResource.textPrimary : ColorResource.textLight,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: walletBalance > 0
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        CurrencyHelper.formatAmount(walletBalance),
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeSmall,
                          color: walletBalance > 0 ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  'pay_from_wallet_balance'.tr,
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: _selectedPaymentMethod == PaymentMethod.wallet ? ColorResource.textSecondary : ColorResource.textLight,
                  ),
                ),
                activeColor: ColorResource.primaryDark,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary(CartController controller) {
    final settingsController = Get.find<SettingsController>();
    final deliveryFee = _calculateDeliveryFee(controller, settingsController);
    final isOutsideRadius = _isOutsideDeliveryRadius(settingsController);
    final storeStatus = _storeStatus();
    // Immediate orders are blocked while the store is closed; scheduled
    // orders for a future slot remain allowed.
    final blockForClosed =
        !_isEcommerce && _deliveryType == 'now' && !storeStatus.isOpenNow;
    final total = controller.total + deliveryFee;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        boxShadow: [
          BoxShadow(
            color: ColorResource.shadowMedium,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Expandable price breakdown
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isPriceExpanded
                  ? Column(
                      children: [
                        _buildSummaryRow('${'cart_items_count'.tr} (${controller.itemCount})', controller.originalSubtotal),
                        if (controller.itemDiscountTotal > 0) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow('item_discount'.tr, -controller.itemDiscountTotal, isDiscount: true),
                        ],
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          _isEcommerce ? 'shipping'.tr : 'delivery_fee'.tr,
                          deliveryFee,
                        ),
                        if (isOutsideRadius) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Selected address is outside the delivery radius.',
                              style: poppinsMedium.copyWith(
                                fontSize: Constants.fontSizeSmall,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _buildSummaryRow('tax_10'.tr, controller.tax),
                        if (controller.appliedCoupon != null) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow('coupon_discount'.tr, -controller.discountAmount, isDiscount: true),
                        ],
                        const Divider(height: 20),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            
            // Total row with expand/collapse button
            GestureDetector(
              onTap: () {
                setState(() {
                  _isPriceExpanded = !_isPriceExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: ColorResource.primaryDark.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(Constants.radiusDefault),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        children: [
                          Text(
                            'total'.tr,
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeLarge,
                              color: ColorResource.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            duration: const Duration(milliseconds: 300),
                            turns: _isPriceExpanded ? 0.5 : 0,
                            child: Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: ColorResource.primaryDark,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        CurrencyHelper.formatAmount(total),
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeLarge,
                          color: ColorResource.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Place order button
            _buildPlaceOrderButton(
              controller,
              deliveryFee: deliveryFee,
              isOutsideRadius: isOutsideRadius,
              blockForClosed: blockForClosed,
              total: total,
            ),
          ],
        ),
      ),
    );
  }

  /// Place-order CTA with its blocked states (outside radius / store closed /
  /// placing spinner). Shared by the mobile bottom bar and the web summary.
  Widget _buildPlaceOrderButton(
    CartController controller, {
    required double deliveryFee,
    required bool isOutsideRadius,
    required bool blockForClosed,
    required double total,
  }) {
    return GetBuilder<OrderController>(
      builder: (orderController) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: orderController.isPlacingOrder ||
                    isOutsideRadius ||
                    blockForClosed
                ? null
                : () => _placeOrder(controller, total, deliveryFee, controller.tax),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorResource.primaryDark,
              // Muted grey when unavailable, dimmed brand while placing.
              disabledBackgroundColor: (isOutsideRadius || blockForClosed)
                  ? ColorResource.textLight.withValues(alpha: 0.5)
                  : ColorResource.primaryDark.withValues(alpha: 0.6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Constants.radiusLarge),
              ),
            ),
            child: orderController.isPlacingOrder
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: ColorResource.textWhite,
                      strokeWidth: 2,
                    ),
                  )
                : isOutsideRadius
                    ? _buildBlockedButtonContent(
                        Icons.location_off_outlined,
                        'cannot_deliver_to_address'.tr,
                      )
                    : blockForClosed
                        ? _buildBlockedButtonContent(
                            Icons.store_mall_directory_outlined,
                            'store_closed'.tr,
                          )
                        : Text(
                            '${'place_order_with_total'.tr} - ${CurrencyHelper.formatAmount(total)}',
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeLarge,
                              color: ColorResource.textWhite,
                            ),
                          ),
          ),
        );
      },
    );
  }

  Widget _buildBlockedButtonContent(IconData icon, String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: ColorResource.textWhite, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: ColorResource.textWhite,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isTotal ? poppinsBold : poppinsRegular).copyWith(
            fontSize: isTotal ? Constants.fontSizeLarge : Constants.fontSizeDefault,
            color: isDiscount ? Colors.green : ColorResource.textPrimary,
          ),
        ),
        Text(
          CurrencyHelper.formatAmount(amount),
          style: (isTotal ? poppinsBold : poppinsMedium).copyWith(
            fontSize: isTotal ? Constants.fontSizeLarge : Constants.fontSizeDefault,
            color: isDiscount ? Colors.green : (isTotal ? ColorResource.primaryDark : ColorResource.textPrimary),
          ),
        ),
      ],
    );
  }

  Future<void> _placeOrder(
    CartController cartController,
    double total,
    double deliveryFee,
    double taxAmount,
  ) async {
    // Validate address selection
    if (_selectedAddress == null) {
      customToster('please_select_delivery_address'.tr, isSuccess: false);
      return;
    }

    final settingsController = Get.find<SettingsController>();
    // Delivery radius + store hours only constrain the food module.
    if (!_isEcommerce && _isOutsideDeliveryRadius(settingsController)) {
      customToster('Selected address is outside the delivery radius.', isSuccess: false);
      return;
    }

    if (!_isEcommerce && _deliveryType == 'now' && !_storeStatus().isOpenNow) {
      customToster('store_is_currently_closed'.tr, isSuccess: false);
      return;
    }

    // Ecommerce requires a shipping method.
    if (_isEcommerce && _selectedShipping == null) {
      customToster('please_select_shipping_method'.tr, isSuccess: false);
      return;
    }

    // ─── Wallet: pre-validate balance before confirmation dialog ───
    if (_selectedPaymentMethod == PaymentMethod.wallet) {
      final profileController = Get.find<ProfileController>();
      await profileController.fetchUserProfile();
      final walletBalance = profileController.walletBalance;

      if (walletBalance < total) {
        customToster(
          'Insufficient wallet balance. Your balance is ${CurrencyHelper.formatAmount(walletBalance)} but order total is ${CurrencyHelper.formatAmount(total)}.',
          isSuccess: false,
        );
        return;
      }
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'confirm_order'.tr,
          style: poppinsBold.copyWith(fontSize: Constants.fontSizeLarge),
        ),
        content: Text(
          'Are you sure you want to place this order for ${CurrencyHelper.formatAmount(total)}?',
          style: poppinsRegular.copyWith(fontSize: Constants.fontSizeDefault),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr, style: poppinsMedium.copyWith(color: ColorResource.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: ColorResource.primaryDark),
            child: Text('confirm'.tr, style: poppinsBold.copyWith(color: ColorResource.textWhite)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final orderController = Get.find<OrderController>();
      final authController = Get.find<AuthController>();
      final profileController = Get.find<ProfileController>();
      String? userId = await authController.getUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // ─── Step 1: Always create order first with paymentStatus = 'unpaid' ───
      final itemDiscountTotal = cartController.itemDiscountTotal;
      final couponDiscountAmount = cartController.discountAmount;

      final result = await orderController.placeOrder(
        customerId: userId,
        address: _selectedAddress!,
        cartItems: cartController.cartItems,
        totalAmount: total,
        deliveryFee: deliveryFee,
        taxAmount: taxAmount,
        discountAmount: itemDiscountTotal,
        couponDiscount: couponDiscountAmount,
        paymentMethod: _selectedPaymentMethod.name,
        paymentStatus: 'unpaid',
        deliveryInstructions: _instructionsController.text.trim(),
        deliveryType: _isEcommerce ? null : _deliveryType,
        scheduledDate: _isEcommerce ? null : _selectedDate,
        scheduledTimeSlot: _isEcommerce ? null : _selectedTimeSlot,
        shippingCost: _isEcommerce ? deliveryFee : null,
        shippingMethod: _isEcommerce ? _selectedShipping?.name : null,
      );

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to place order');
      }

      final orderId = result['orderId'] as String;
      final orderNumber = result['orderNumber'] as String;

      // ─── Step 2: Handle payment based on method ───

      // ── Online payment via WebView ──
      if (_selectedPaymentMethod == PaymentMethod.online) {
        final paymentService = PaymentService();
        final profile = profileController.userProfile;
        final currency = 'usd'; // settingsController.businessSetup?.currency ?? 'BDT';

        // Convert total to smallest currency unit (cents/poisha)
        final amountInSmallest = (total * 100).toInt();

        // Show loading while creating payment session
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
        }

        final Map<String, dynamic> paymentResult;
        try {
          paymentResult = await paymentService.createPayment(
            gateway: _selectedGateway.key,
            amount: amountInSmallest,
            orderId: orderId, // ✅ Real order ID from DB
            currency: currency,
            customerName: profile?.name,
            customerEmail: profile?.email,
            customerPhone: profile?.phone,
          );
        } catch (e) {
          print('Payment initiation error: $e');
          // Dismiss loading dialog safely
          if (mounted) Navigator.of(context).pop();
          // Mark payment as failed on the order
          await orderController.updatePaymentStatus(orderId, 'failed');
          rethrow;
        }

        // Dismiss loading dialog
        if (mounted) Navigator.of(context).pop();

        final paymentURL = paymentResult['data']?['paymentURL'] as String?;
        if (paymentURL == null || paymentURL.isEmpty) {
          await orderController.updatePaymentStatus(orderId, 'failed');
          throw Exception('Payment gateway returned no URL');
        }

        // Open WebView for user to complete payment
        if (!mounted) return;
        final webViewResult = await context.pushNamed<PaymentResult?>(
          RouteNames.payment,
          extra: PaymentArgs(
            paymentURL: paymentURL,
            gatewayName: _selectedGateway.displayName,
          ),
        );

        if (webViewResult == PaymentResult.success) {
          // ✅ Payment succeeded — update order status
          await orderController.updatePaymentStatus(orderId, 'paid');
        } else {
          // ❌ Payment failed or cancelled — update order status
          final status = webViewResult == PaymentResult.failed ? 'failed' : 'cancelled';
          await orderController.updatePaymentStatus(orderId, status);

          final message = webViewResult == PaymentResult.failed
              ? 'Payment failed. Your order #$orderNumber has been saved. You can retry payment later.'
              : 'Payment was cancelled. Your order #$orderNumber has been saved.';
          customToster(message, isSuccess: false);
          return;
        }
      }

      // ── Wallet payment — deduct balance ──
      if (_selectedPaymentMethod == PaymentMethod.wallet) {
        final deducted = await profileController.deductWalletBalance(total);
        if (!deducted) {
          await orderController.updatePaymentStatus(orderId, 'failed');
          customToster('Failed to deduct wallet balance. Please try again.', isSuccess: false);
          return;
        }
        // ✅ Wallet deducted — mark as paid
        await orderController.updatePaymentStatus(orderId, 'paid');
      }

      // ─── Step 3: Reduce stock, clear cart & coupon, navigate to success ───
      // Capture items before the cart is cleared.
      await Get.find<ProductController>()
          .reduceStockForItems(cartController.cartItems);
      // Flash sale sold counters (best effort — no-op when no sale is live).
      if (Get.isRegistered<FlashSaleController>()) {
        unawaited(
          Get.find<FlashSaleController>()
              .recordSoldItems(List.of(cartController.cartItems)),
        );
      }
      await cartController.clearCart();
      cartController.removeCoupon();

      if (mounted) {
        context.goNamed(
          RouteNames.orderSuccess,
          extra: OrderSuccessArgs(
            orderNumber: orderNumber,
            totalAmount: total,
          ),
        );
      }
    } catch (e) {
      // Navigate to failed page
      if (mounted) {
        context.pushNamed(
          RouteNames.orderFailed,
          extra: OrderFailedArgs(
            errorMessage: e.toString().replaceAll('Exception: ', ''),
            onRetry: () => _placeOrder(cartController, total, deliveryFee, taxAmount),
          ),
        );
      }
    }
  }
  /// Build delivery schedule section with bottom sheet
  Widget _buildDeliverySchedule() {
    final isNow = _deliveryType == 'now';
    final storeStatus = _storeStatus();
    final showClosed = isNow && !storeStatus.isOpenNow;
    final scheduleTitle = isNow ? 'deliver_now'.tr : 'scheduled_delivery'.tr;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ColorResource.primaryDark.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isNow ? Icons.flash_on_rounded : Icons.schedule_rounded,
                  size: 22,
                  color: ColorResource.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            scheduleTitle,
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeDefault,
                              color: ColorResource.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: ColorResource.primaryDark
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isNow ? 'asap'.tr : 'scheduled'.tr,
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeExtraSmall,
                              color: ColorResource.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _scheduleDisplayText ?? 'asap_30_45_mins'.tr,
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: ColorResource.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: _openDeliverySchedulePicker,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorResource.primaryDark,
                  side: BorderSide(
                    color: ColorResource.primaryDark.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'change'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: ColorResource.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          if (showClosed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'store_is_currently_closed'.tr,
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeSmall,
                            color: Colors.orange[900],
                          ),
                        ),
                        if (storeStatus.nextOpenLabel != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            storeStatus.nextOpenLabel!,
                            style: poppinsRegular.copyWith(
                              fontSize: Constants.fontSizeSmall,
                              color: Colors.orange[900],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }



}
