import 'package:appwrite_user_app/app/controllers/address_controller.dart';
import 'package:appwrite_user_app/app/modules/address/screens/add_edit_address_page.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Saved Addresses',
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: ColorResource.textWhite,
          ),
        ),
        backgroundColor: ColorResource.primaryDark,
        elevation: 0,
      ),
      body: GetBuilder<AddressController>(
        builder: (controller) {
          if (controller.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: ColorResource.primaryDark,
              ),
            );
          }

          if (!controller.hasAddresses) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.addresses.length,
            itemBuilder: (context, index) {
              final address = controller.addresses[index];
              return _buildAddressCard(context, address, controller);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => const AddEditAddressPage());
        },
        backgroundColor: ColorResource.primaryDark,
        label: Text(
          'Add Address',
          style: poppinsBold.copyWith(color: ColorResource.textWhite),
        ),
        icon: Icon(Icons.add, color: ColorResource.textWhite),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 100,
            color: ColorResource.textLight,
          ),
          const SizedBox(height: 20),
          Text(
            'No addresses saved',
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: ColorResource.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add an address to get started',
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: ColorResource.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, address, AddressController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
        border: address.isDefault
            ? Border.all(color: ColorResource.primaryDark, width: 2)
            : Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          // Header Section with Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: address.isDefault 
                  ? ColorResource.primaryDark.withOpacity(0.05)
                  : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Constants.radiusLarge),
                topRight: Radius.circular(Constants.radiusLarge),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: address.isDefault 
                              ? ColorResource.primaryGradient
                              : LinearGradient(
                                  colors: [Colors.grey.shade300, Colors.grey.shade400],
                                ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on_rounded, 
                          color: ColorResource.textWhite,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              address.name,
                              style: poppinsBold.copyWith(
                                fontSize: Constants.fontSizeLarge,
                                color: ColorResource.textPrimary,
                              ),
                            ),
                            if (address.isDefault)
                              Text(
                                'Default Address',
                                style: poppinsMedium.copyWith(
                                  fontSize: 11,
                                  color: ColorResource.primaryDark,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle Switch for Default
                Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: address.isDefault,
                    onChanged: (value) {
                      if (value && !address.isDefault) {
                        controller.setDefaultAddress(address.id);
                      }
                    },
                    activeColor: ColorResource.primaryDark,
                    activeTrackColor: ColorResource.primaryDark.withOpacity(0.3),
                    inactiveThumbColor: Colors.grey.shade400,
                    inactiveTrackColor: Colors.grey.shade200,
                  ),
                ),
              ],
            ),
          ),
          
          // Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phone Number
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined, 
                      size: 16, 
                      color: ColorResource.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      address.phone,
                      style: poppinsMedium.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: ColorResource.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Full Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.home_outlined, 
                      size: 16, 
                      color: ColorResource.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address.fullAddress,
                        style: poppinsRegular.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: ColorResource.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Get.to(() => AddEditAddressPage(address: address));
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorResource.primaryDark,
                          side: BorderSide(color: ColorResource.primaryDark),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeleteConfirmation(context, address, controller),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorResource.error,
                          side: BorderSide(color: ColorResource.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, address, AddressController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Address',
          style: poppinsBold.copyWith(fontSize: Constants.fontSizeLarge),
        ),
        content: Text(
          'Are you sure you want to delete this address?',
          style: poppinsRegular.copyWith(fontSize: Constants.fontSizeDefault),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: poppinsMedium.copyWith(color: ColorResource.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteAddress(address.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorResource.error,
            ),
            child: Text(
              'Delete',
              style: poppinsBold.copyWith(color: ColorResource.textWhite),
            ),
          ),
        ],
      ),
    );
  }
}
