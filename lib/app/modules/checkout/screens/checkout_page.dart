import 'package:appwrite_user_app/app/appwrite/payment_service.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/controllers/address_controller.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/controllers/order_controller.dart';
import 'package:appwrite_user_app/app/controllers/profile_controller.dart';
import 'package:appwrite_user_app/app/controllers/settings_controller.dart';
import 'package:appwrite_user_app/app/enums/payment_method_enum.dart';
import 'package:appwrite_user_app/app/helper/currency_helper.dart';
import 'package:appwrite_user_app/app/models/address_model.dart';
import 'package:appwrite_user_app/app/modules/address/screens/add_edit_address_page.dart';
import 'package:appwrite_user_app/app/modules/checkout/screens/order_failed_page.dart';
import 'package:appwrite_user_app/app/modules/checkout/screens/order_success_page.dart';
import 'package:appwrite_user_app/app/modules/checkout/widgets/address_selection_bottomsheet.dart';
import 'package:appwrite_user_app/app/modules/checkout/widgets/delivery_schedule_bottomsheet.dart';
import 'package:appwrite_user_app/app/modules/coupons/widgets/coupon_selection_bottomsheet.dart';
import 'package:appwrite_user_app/app/modules/payment/payment_webview_screen.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _instructionsController = TextEditingController();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cod;
  PaymentGateway _selectedGateway = PaymentGateway.sslcommerz;
  bool _isPriceExpanded = false;
  AddressModel? _selectedAddress;
  
  // Delivery schedule
  String? _scheduleDisplayText = 'ASAP (30-45 mins)';
  Map<String, dynamic>? scheduleData;

  String _deliveryType = 'now'; // 'now' or 'schedule'
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  @override
  void initState() {
    super.initState();
    // Auto-select default address
    final addressController = Get.find<AddressController>();
    if (addressController.defaultAddress != null) {
      _selectedAddress = addressController.defaultAddress;
    }
  }

  void _syncSelectedAddress(AddressController addressController) {
    final hasSelectedAddress = _selectedAddress != null &&
        addressController.addresses.any((address) => address.id == _selectedAddress!.id);

    if (!hasSelectedAddress && addressController.defaultAddress != null) {
      _selectedAddress = addressController.defaultAddress;
    }
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

    await Get.to(() => const AddEditAddressPage());
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
  
  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      appBar: CustomAppbar(title: 'checkout'.tr),
      body: GetBuilder<CartController>(
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
                    onPressed: () => Get.back(),
                    child: Text('go_back'.tr),
                  ),
                ],
              ),
            );
          }

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
                      _buildDeliverySchedule(),
                      const SizedBox(height: 20),
                      _buildCouponSection(controller),
                      const SizedBox(height: 20),
                      _buildPaymentMethod(),
                      const SizedBox(height: 20),
                      _buildDeliveryInstructions(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              _buildBottomSummary(controller),
            ],
          );
        },
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
        final hasAddress = _selectedAddress != null;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorResource.cardBackground,
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
            boxShadow: ColorResource.customShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _openAddressSelector,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.location_on_outlined,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              hasAddress
                                  ? _selectedAddress!.name
                                  : 'Delivery address',
                              style: poppinsMedium.copyWith(
                                fontSize: Constants.fontSizeDefault,
                                color: ColorResource.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hasAddress
                                  ? _selectedAddress!.shortAddress
                                  : 'Choose where you want the order delivered',
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
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _openAddressSelector,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            hasAddress ? 'Change' : 'Choose',
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeSmall,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasAddress && distanceKm != null) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    isOutsideRadius
                        ? 'Distance: ${distanceKm.toStringAsFixed(2)} km • Outside delivery radius'
                        : 'Distance: ${distanceKm.toStringAsFixed(2)} km',
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeExtraSmall,
                      color: isOutsideRadius ? Colors.red : ColorResource.textSecondary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _openMapAddressPicker,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6B3D),
                    side: const BorderSide(color: Color(0xFFFFD0C2)),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(
                    'Select from map',
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: const Color(0xFFFF6B3D),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCouponSection(CartController controller) {
    final hasCoupon = controller.appliedCoupon != null;

    return Container(
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    hasCoupon ? Icons.sell_rounded : Icons.discount_outlined,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasCoupon
                            ? controller.appliedCoupon!.code
                            : 'Apply a promo code',
                        style: poppinsMedium.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: ColorResource.textPrimary,
                        ),
                      ),
                      if (hasCoupon) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${'you_saved_amount'.tr} ${CurrencyHelper.formatAmount(controller.discountAmount)}',
                          style: poppinsRegular.copyWith(
                            fontSize: Constants.fontSizeSmall,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 40,
                  child: hasCoupon
                      ? OutlinedButton(
                          onPressed: () => controller.removeCoupon(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF6B3D),
                            side: const BorderSide(color: Color(0xFFFFD0C2)),
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Remove',
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeSmall,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () async {
                            final result = await CouponSelectionBottomSheet.show(context);

                            if (result != null) {
                              controller.applyCoupon(result);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Apply',
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeSmall,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ],
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
          RadioListTile<PaymentMethod>(
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
          RadioListTile<PaymentMethod>(
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
          AnimatedSize(
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
          GetBuilder<ProfileController>(
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
                        _buildSummaryRow('${'cart_items_count'.tr} (${controller.itemCount})', controller.subtotal),
                        const SizedBox(height: 8),
                        _buildSummaryRow('delivery_fee'.tr, deliveryFee),
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
                          _buildSummaryRow('discount'.tr, -controller.discountAmount, isDiscount: true),
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
            GetBuilder<OrderController>(
              builder: (orderController) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: orderController.isPlacingOrder || isOutsideRadius
                        ? null
                        : () => _placeOrder(controller, total, deliveryFee),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorResource.primaryDark,
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
            ),
          ],
        ),
      ),
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
  ) async {
    // Validate address selection
    if (_selectedAddress == null) {
      customToster('please_select_delivery_address'.tr, isSuccess: false);
      return;
    }

    final settingsController = Get.find<SettingsController>();
    if (_isOutsideDeliveryRadius(settingsController)) {
      customToster('Selected address is outside the delivery radius.', isSuccess: false);
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
      final result = await orderController.placeOrder(
        customerId: userId,
        address: _selectedAddress!,
        cartItems: cartController.cartItems,
        totalAmount: total,
        deliveryFee: deliveryFee,
        paymentMethod: _selectedPaymentMethod.name,
        paymentStatus: 'unpaid',
        deliveryInstructions: _instructionsController.text.trim(),
        deliveryType: _deliveryType,
        scheduledDate: _selectedDate,
        scheduledTimeSlot: _selectedTimeSlot,
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
        final webViewResult = await Navigator.push<PaymentResult>(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentWebViewScreen(
              paymentURL: paymentURL,
              gatewayName: _selectedGateway.displayName,
            ),
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

      // ─── Step 3: Clear cart & navigate to success ───
      await cartController.clearCart();

      if (mounted) {
        Get.off(() => OrderSuccessPage(
          orderNumber: orderNumber,
          totalAmount: total,
        ));
      }
    } catch (e) {
      // Navigate to failed page
      if (mounted) {
        Get.to(() => OrderFailedPage(
          errorMessage: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => _placeOrder(cartController, total, deliveryFee),
        ));
      }
    }
  }
  /// Build delivery schedule section with bottom sheet
  Widget _buildDeliverySchedule() {
    final settingsController = Get.find<SettingsController>();
    final businessSetup = settingsController.businessSetup;
    final isNow = _deliveryType == 'now';
    final isStoreClosed = businessSetup?.isStoreOpen == false;
    final scheduleTitle = isNow ? 'Deliver now' : 'Scheduled delivery';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _openDeliverySchedulePicker,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7F4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      isNow ? Icons.flash_on_rounded : Icons.schedule_outlined,
                      size: 20,
                      color: const Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          scheduleTitle,
                          style: poppinsMedium.copyWith(
                            fontSize: Constants.fontSizeDefault,
                            color: ColorResource.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
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
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _openDeliverySchedulePicker,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Change',
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeSmall,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isNow
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.12)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isNow ? 'ASAP' : 'Scheduled',
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: isNow
                        ? Theme.of(context).primaryColor
                        : ColorResource.textSecondary,
                  ),
                ),
              ),
              if (!isNow && _selectedTimeSlot != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _selectedTimeSlot!,
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          if (isStoreClosed && isNow) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'store_is_currently_closed'.tr,
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: Colors.orange[900],
                      ),
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
