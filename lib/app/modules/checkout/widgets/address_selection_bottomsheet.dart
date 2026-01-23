import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/controllers/address_controller.dart';
import 'package:appwrite_user_app/app/models/address_model.dart';
import 'package:appwrite_user_app/app/modules/address/screens/add_edit_address_page.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddressSelectionBottomSheet extends StatefulWidget {
  final AddressModel? initialAddress;

  const AddressSelectionBottomSheet({
    super.key,
    this.initialAddress,
  });

  @override
  State<AddressSelectionBottomSheet> createState() =>
      _AddressSelectionBottomSheetState();

  static Future<AddressModel?> show(
    BuildContext context, {
    AddressModel? initialAddress,
  }) async {
    return await showModalBottomSheet<AddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressSelectionBottomSheet(
        initialAddress: initialAddress,
      ),
    );
  }
}

class _AddressSelectionBottomSheetState
    extends State<AddressSelectionBottomSheet> {
  AddressModel? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.initialAddress;
  }

  void _confirm() {
    if (_selectedAddress == null) {
      customToster('Please select a delivery address', isSuccess: false);
      return;
    }
    Navigator.pop(context, _selectedAddress);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: ColorResource.cardBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(Constants.radiusExtraLarge),
            ),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Content
              Expanded(
                child: GetBuilder<AddressController>(
                  builder: (addressController) {
                    if (addressController.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (addressController.addresses.isEmpty) {
                      return _buildEmptyState();
                    }

                    return SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Delivery Address',
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeLarge,
                              color: ColorResource.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...addressController.addresses.map(
                            (address) => _buildAddressCard(address),
                          ),
                          const SizedBox(height: 12),
                          _buildAddNewButton(),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Confirm button
              _buildConfirmButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Constants.radiusExtraLarge),
        ),
        boxShadow: [
          BoxShadow(
            color: ColorResource.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorResource.textLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ColorResource.primaryGradient,
                  borderRadius: BorderRadius.circular(Constants.radiusDefault),
                ),
                child: Icon(
                  Icons.location_on,
                  color: ColorResource.textWhite,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Delivery Address',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeExtraLarge,
                    color: ColorResource.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded,
                    color: ColorResource.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(AddressModel address) {
    final isSelected = _selectedAddress?.id == address.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAddress = address;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorResource.primaryDark.withValues(alpha: 0.1)
              : ColorResource.scaffoldBackground,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          border: Border.all(
            color: isSelected ? ColorResource.primaryDark : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? ColorResource.primaryDark
                    : ColorResource.primaryDark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
              ),
              child: Icon(
                Icons.location_on,
                color: isSelected ? Colors.white : ColorResource.primaryDark,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.name,
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: isSelected
                              ? ColorResource.primaryDark
                              : ColorResource.textPrimary,
                        ),
                      ),
                      if (address.isDefault) ...[ 
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: ColorResource.primaryGradient,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'DEFAULT',
                            style: poppinsBold.copyWith(
                              fontSize: 9,
                              color: ColorResource.textWhite,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.phone,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.fullAddress,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: ColorResource.primaryDark,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewButton() {
    return GestureDetector(
      onTap: () async {
        final result = await Get.to(() => const AddEditAddressPage());
        if (result == true) {
          // Address was added, refresh the controller
          Get.find<AddressController>().fetchAddresses();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorResource.scaffoldBackground,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          border: Border.all(
            color: ColorResource.primaryDark.withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorResource.primaryDark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
              ),
              child: Icon(
                Icons.add_location_alt_outlined,
                color: ColorResource.primaryDark,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Add New Address',
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 80,
              color: ColorResource.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No Saved Addresses',
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
                color: ColorResource.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your delivery address to continue',
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Get.to(() => const AddEditAddressPage());
                if (result == true) {
                  Get.find<AddressController>().fetchAddresses();
                }
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Address'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResource.primaryDark,
                foregroundColor: ColorResource.textWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        boxShadow: [
          BoxShadow(
            color: ColorResource.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorResource.primaryDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Constants.radiusLarge),
              ),
            ),
            child: Text(
              'Confirm Address',
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
